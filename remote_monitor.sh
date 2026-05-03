#!/usr/bin/env bash
set -euo pipefail

# Unified remote job monitor.
#
# Usage:
#   remote_monitor.sh slurm  <host> <job_id>        <remote_dir> <local_dir> <run_dir_pre> <run_id> <proj_name>
#   remote_monitor.sh docker <host> <container_id>   <remote_dir> <local_dir>
#   remote_monitor.sh pid    <host> <remote_pid>     <remote_dir> <local_dir> [port_forward <ports_before_file>]

mode="$1"; shift
host="$1"; shift
job_id="$1"; shift   # slurm job id, docker container id, OR remote pid
remote_dir="$1"; shift
local_dir="$1"; shift

port_forward=false
ports_before_file=""
if [[ "$mode" == "slurm" ]]; then
    run_dir_pre="$1"; shift
    run_id="$1"; shift
    proj_name="$1"; shift
elif [[ "${1:-}" == "port_forward" ]]; then
    port_forward=true; shift
    ports_before_file="${1:-}"; shift
fi

mkdir -p "$local_dir"

print_slurm_summary() {
    ssh "$host" "squeue --job=${job_id} -h -o '%T' 2>/dev/null" \
        | sort | uniq -c | awk '{printf "  %s=%s", $2, $1} END {print ""}' \
        || true
}

_log_state_file=""
fetch_new_content() {
    [[ -z "$_log_state_file" ]] && _log_state_file="${local_dir}/.log_state" && touch "$_log_state_file"
    local files=()
    if [[ -e "${local_dir}/slurm-${job_id}_1.out" ]]; then
        files=("${local_dir}/slurm-${job_id}_1.out")
    else
        for f in "${local_dir}"/slurm-${job_id}*.out "${local_dir}"/slurm_out.log "${local_dir}"/nohup.out; do
            [[ -e "$f" ]] && files+=("$f")
        done
    fi
    [[ ${#files[@]} -eq 0 ]] && return 0
    for f in "${files[@]}"; do
        local fname
        fname=$(basename "$f")
        local prev_lines
        prev_lines=$(grep "^${fname} " "$_log_state_file" 2>/dev/null | awk '{print $2}')
        prev_lines=${prev_lines:-0}
        local cur_lines
        cur_lines=$(wc -l < "$f" | tr -d '[:space:]')
        [[ "$cur_lines" -lt "$prev_lines" ]] && prev_lines=0
        if [[ "$cur_lines" -gt "$prev_lines" ]]; then
            local new_start=$((prev_lines + 1))
            sed -n "${new_start},${cur_lines}p" "$f"
            if grep -q "^${fname} " "$_log_state_file" 2>/dev/null; then
                sed -i '' "s/^${fname} .*/${fname} ${cur_lines}/" "$_log_state_file"
            else
                echo "${fname} ${cur_lines}" >>"$_log_state_file"
            fi
        fi
    done
}

refresh_ssh_auth_sock() {
    local sock
    sock=$(ls /private/tmp/com.apple.launchd.*/Listeners 2>/dev/null | head -1)
    if [[ -n "$sock" && -S "$sock" ]]; then
        export SSH_AUTH_SOCK="$sock"
    fi
}

wait_for_ssh() {
    while true; do
        refresh_ssh_auth_sock
        ssh -o ConnectTimeout=10 -o BatchMode=yes "$host" true 2>/dev/null && break
        echo "$(date '+%H:%M:%S') - SSH connection failed, waiting 1 minute before retry..."
        sleep 60
    done
}

is_job_running() {
    local output rc
    if [[ "$mode" == "slurm" ]]; then
        output=$(ssh -o ConnectTimeout=10 -o BatchMode=yes "$host" "squeue --job=${job_id} --noheader 2>/dev/null" 2>/dev/null)
        rc=$?
    elif [[ "$mode" == "docker" ]]; then
        output=$(ssh -o ConnectTimeout=10 -o BatchMode=yes "$host" "test -f ${remote_dir}/remote_job_id.txt && echo true || echo false" 2>/dev/null)
        rc=$?
    else
        ssh -o ConnectTimeout=10 -o BatchMode=yes "$host" "kill -0 ${job_id} 2>/dev/null" 2>/dev/null
        return $?
    fi
    if [[ $rc -ne 0 && $rc -ne 1 ]]; then
        return 0
    fi
    if [[ "$mode" == "slurm" ]]; then
        [[ -n "$output" ]]
    else
        [[ "$output" == "true" ]]
    fi
}

# --- slurm: wait for job to enter RUNNING state ---
if [[ "$mode" == "slurm" ]]; then
    echo "Waiting for slurm job to start running (job ID: $job_id)..."
    while true; do
        sleep 10
        all_states=$(ssh -o ConnectTimeout=10 -o BatchMode=yes "$host" "squeue --job=${job_id} --noheader -o '%T' 2>/dev/null" 2>/dev/null)
        _ssh_rc=$?
        if [[ $_ssh_rc -eq 255 ]]; then
            echo "$(date '+%H:%M:%S') - SSH connection lost, retrying..."
            wait_for_ssh
            continue
        fi
        if [[ -z "$all_states" ]]; then
            echo "Job no longer in queue (may have finished or failed instantly)."
            break
        elif echo "$all_states" | grep -q "RUNNING"; then
            echo "Job is now RUNNING."
            echo "$all_states" | sort | uniq -c | awk '{printf "  %s=%s", $2, $1} END {print ""}'
            break
        fi
        echo "$(date '+%H:%M:%S') - $(echo "$all_states" | sort | uniq -c | awk '{printf "%s=%s ", $2, $1} END {print ""}')"
    done
fi

sync_remote() {
    local _rsync_out _rsync_rc=0
    if [[ "$mode" == "slurm" || "$mode" == "docker" ]]; then
        _rsync_out=$(ssh "$host" "cd '${remote_dir}' && find . -newer .submit_marker -type f" 2>/dev/null \
            | rsync -av --files-from=- "$host":"${remote_dir}/" "$local_dir/" 2>&1) || _rsync_rc=$?
    else
        _rsync_out=$(rsync -av "$host":"${remote_dir}/" "$local_dir/" 2>&1) || _rsync_rc=$?
    fi
    if [[ $_rsync_rc -ne 0 ]]; then
        echo "$_rsync_out"
        return $_rsync_rc
    fi
}

# --- main monitoring loop ---
_check_count=0
while true; do
    _check_count=$((_check_count + 1))
    _interval=$(( ((_check_count - 1) / 5 + 1) * 15 ))
    echo "=== $(date '+%H:%M:%S') - checking job (check #${_check_count}, next in ${_interval}s) ==="
    wait_for_ssh
    sync_remote || echo "WARNING: rsync failed, will retry next cycle"
    [[ "$mode" == "slurm" ]] && print_slurm_summary
    fetch_new_content 2>/dev/null || true

    if ! is_job_running; then
        sleep 15
        wait_for_ssh
        sync_remote || echo "WARNING: final rsync failed, results may be incomplete"
        [[ "$mode" == "slurm" ]] && print_slurm_summary
        fetch_new_content 2>/dev/null || true

        # if $port_forward; then
        #     pkill -f "ssh.*ControlPath=none.*-N.*${host}" 2>/dev/null && echo "Killed existing SSH tunnel to ${host}" || true

            # ports_after=$(
            #     ssh "$host" "ss -tlnp 2>/dev/null" \
            #     | { grep -oE '0\.0\.0\.0:[0-9]+' || true; } \
            #     | awk -F: '$2 >= 1024 {print $2}' \
            #     | sort -un
            # )

            # ports=()
            # while IFS= read -r p; do
            #     [[ -n "$p" ]] && ports+=("$p")
            # done < <(comm -23 <(echo "$ports_after") <(cat "$ports_before_file" 2>/dev/null || true))

            # if [[ ${#ports[@]} -gt 0 ]]; then
            #     ssh_args=(-o ControlPath=none -N -f)
            #     for p in "${ports[@]}"; do
            #         ssh_args+=(-L "${p}:localhost:${p}")
            #     done
            #     echo "New ports from this run: ${ports[*]}"
            #     echo "ssh ${ssh_args[*]} $host"
            #     ssh "${ssh_args[@]}" "$host" 
            # else
            #     echo "No new ports detected from this run."
            # fi
        # fi

        echo ""
        echo "DONE: Remote job finished (${mode} id: ${job_id}). Output saved to: ${local_dir}"
        break
    fi

    sleep $_interval
done
