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

# Next line number to fetch from the remote log (1-based).
_next_line=1

get_remote_log_path() {
    if [[ "$mode" == "slurm" ]]; then
        echo "${remote_dir}/slurm-${job_id}.out"
    elif [[ "$mode" == "docker" ]]; then
        echo ""
    else
        echo "${remote_dir}/nohup.out"
    fi
}

fetch_new_log_content() {
    if [[ "$mode" == "docker" ]]; then
        local total_lines
        total_lines=$(ssh "$host" "docker logs ${job_id} 2>&1 | wc -l" 2>/dev/null) || return 0
        total_lines=$(echo "$total_lines" | tr -d '[:space:]')
        [[ -z "$total_lines" || "$total_lines" -lt "$_next_line" ]] && return 0
        local new_content
        new_content=$(ssh "$host" "docker logs ${job_id} 2>&1 | sed -n '${_next_line},${total_lines}p'" 2>/dev/null) || return 0
        if [[ -n "$new_content" ]]; then
            echo "$new_content"
        fi
        _next_line=$(( total_lines + 1 ))
    else
        local rlog
        rlog=$(get_remote_log_path)
        local local_log="${local_dir}/${rlog#${remote_dir}/}"
        [[ ! -f "$local_log" ]] && return 0
        local total_lines
        total_lines=$(wc -l < "$local_log" 2>/dev/null) || return 0
        total_lines=$(echo "$total_lines" | tr -d '[:space:]')
        [[ -z "$total_lines" || "$total_lines" -lt "$_next_line" ]] && return 0
        local new_content
        new_content=$(sed -n "${_next_line},${total_lines}p" "$local_log" 2>/dev/null) || return 0
        if [[ -n "$new_content" ]]; then
            echo "$new_content"
        fi
        _next_line=$(( total_lines + 1 ))
    fi
}

wait_for_ssh() {
    while ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$host" true 2>/dev/null; do
        echo "$(date '+%H:%M:%S') - SSH connection failed, waiting 1 minute before retry..."
        sleep 60
    done
}

is_job_running() {
    local output rc
    if [[ "$mode" == "slurm" ]]; then
        output=$(ssh "$host" "squeue --job=${job_id} --noheader 2>/dev/null" 2>/dev/null)
        rc=$?
    elif [[ "$mode" == "docker" ]]; then
        output=$(ssh "$host" "docker inspect -f '{{.State.Running}}' ${job_id} 2>/dev/null" 2>/dev/null)
        rc=$?
    else
        ssh "$host" "kill -0 ${job_id} 2>/dev/null" 2>/dev/null
        return $?
    fi
    # SSH failure (255) or other connection errors: assume still running, don't exit loop.
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
        job_state=$(ssh "$host" "squeue --job=${job_id} --noheader -o '%T' 2>/dev/null" 2>/dev/null | head -1)
        if [[ "$job_state" == "RUNNING" ]]; then
            echo "Job is now RUNNING."
            break
        elif [[ -z "$job_state" ]]; then
            echo "Job no longer in queue (may have finished or failed instantly)."
            break
        fi
        echo "$(date '+%H:%M:%S') - job state: $job_state"
    done
fi

sync_remote() {
    local _rsync_out _rsync_rc=0
    if [[ "$mode" == "slurm" ]]; then
        local marker="${remote_dir}/.slurm_submit_marker"
        _rsync_out=$(ssh "$host" "cd '${remote_dir}' && find . -newer .slurm_submit_marker -type f" 2>/dev/null \
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
    _interval=$(( ((_check_count - 1) / 10 + 1) * 30 ))
    echo "=== $(date '+%H:%M:%S') - checking job (check #${_check_count}, next in ${_interval}s) ==="
    wait_for_ssh
    sync_remote || echo "WARNING: rsync failed, will retry next cycle"
    fetch_new_log_content 2>/dev/null || echo "WARNING: failed to fetch remote log, will retry next cycle"

    if ! is_job_running; then
        wait_for_ssh
        sync_remote || echo "WARNING: final rsync failed, results may be incomplete"
        fetch_new_log_content 2>/dev/null || true

        if $port_forward; then
            pkill -f "ssh.*ControlPath=none.*-N.*${host}" 2>/dev/null && echo "Killed existing SSH tunnel to ${host}" || true

            ports_after=$(
                ssh "$host" "ss -tlnp 2>/dev/null" \
                | { grep -oE '0\.0\.0\.0:[0-9]+' || true; } \
                | awk -F: '$2 >= 1024 {print $2}' \
                | sort -un
            )

            ports=()
            while IFS= read -r p; do
                [[ -n "$p" ]] && ports+=("$p")
            done < <(comm -23 <(echo "$ports_after") <(cat "$ports_before_file" 2>/dev/null || true))

            if [[ ${#ports[@]} -gt 0 ]]; then
                ssh_args=(-o ControlPath=none -N -f)
                for p in "${ports[@]}"; do
                    ssh_args+=(-L "${p}:localhost:${p}")
                done
                echo "New ports from this run: ${ports[*]}"
                echo "ssh ${ssh_args[*]} $host"
                ssh "${ssh_args[@]}" "$host" || echo "WARNING: SSH tunnel failed (port conflict?)"
            else
                echo "No new ports detected from this run."
            fi
        fi

        echo ""
        echo "DONE: Remote job finished (${mode} id: ${job_id}). Output saved to: ${local_dir}"
        break
    fi

    sleep $_interval
done
