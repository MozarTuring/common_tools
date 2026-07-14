#!/usr/bin/env bash
set -euo pipefail

# Unified remote job monitor.
#
# Usage:
#   remote_monitor.sh slurm  <host> <job_id>        <remote_dir> <local_dir> <run_dir_pre> <run_id> <proj_name>
#   remote_monitor.sh docker <host> <container_id>   <remote_dir> <local_dir>
#   remote_monitor.sh pid    <host> <remote_pid>     <remote_dir> <local_dir> [port_forward <ports_before_file>]

mode="$1"
shift
host="$1"
shift
job_id="$1"
shift # slurm job id, docker container id, OR remote pid
remote_dir="$1"
shift
local_dir="$1"
shift
JWM_RUN_START_TIME="$1"

port_forward=false
ports_before_file=""
mkdir -p "$local_dir"

print_slurm_summary() {
    ssh "$host" "squeue --job=${job_id} -h -o '%T' 2>/dev/null" |
        sort | uniq -c | awk '{printf "  %s=%s", $2, $1} END {print ""}' ||
        true
}

fetch_new_content() {
    cd "${local_dir}/jwmlogs/${JWM_RUN_START_TIME}/"
    _log_state_file=".log_state" && touch "$_log_state_file"
    local files=("job-${job_id}_1.out" "job-${job_id}.out" "job_out.log")
    for fname in "${files[@]}"; do
        if [[ -f ${fname} ]]; then
            # echo "fetch from ${fname}"
            local prev_lines
            prev_lines=$(awk -v f="${fname}" '$1 == f {print $2}' "$_log_state_file")
            prev_lines=${prev_lines:-0}
            local cur_lines safe_lines
            cur_lines=$(awk 'END {print NR}' "${fname}")
            # echo "cur_lines, ${cur_lines}"
            safe_lines=$((cur_lines > 0 ? cur_lines - 1 : 0))
            if [[ $1 == "finish" ]]; then
                safe_lines=${cur_lines}
            fi
            # [[ "$safe_lines" -lt "$prev_lines" ]] && prev_lines=0 # in case file is overwritten, wich shall never happen
            if [[ "$safe_lines" -gt "$prev_lines" ]]; then
                local new_start=$((prev_lines + 1))
                sed -n "${new_start},${safe_lines}p" "${fname}"
                if grep -q "^${fname} " "$_log_state_file" 2>/dev/null; then
                    sed -i '' "s/^${fname} .*/${fname} ${safe_lines}/" "$_log_state_file"
                else
                    echo "${fname} ${safe_lines}" >>"$_log_state_file"
                fi
            fi
            break
        fi
    done
}

refresh_ssh_auth_sock() {
    local sock
    for sock in /private/tmp/com.apple.launchd.*/Listeners; do
        if [[ -S "$sock" ]]; then
            export SSH_AUTH_SOCK="$sock"
            return 0
        fi
    done
}

_clear_stale_control_socket() {
    local ctl_path
    ctl_path=$(ssh -G "$host" 2>/dev/null | awk '/^controlpath / {print $2}')
    if [[ -n "$ctl_path" && -e "$ctl_path" ]]; then
        ssh -o ControlPath="$ctl_path" -O check "$host" 2>/dev/null && return 0
        echo "$(date '+%H:%M:%S') - removing stale control socket: $ctl_path"
        rm -f "$ctl_path"
    fi
}

wait_for_ssh() {
    while true; do
        refresh_ssh_auth_sock
        ssh -o ConnectTimeout=10 -o BatchMode=yes "$host" true 2>/dev/null && break
        # Default SSH failed — check if stale ControlMaster socket is the cause
        if ssh -o ControlPath=none -o ConnectTimeout=10 -o BatchMode=yes "$host" true 2>/dev/null; then
            echo "$(date '+%H:%M:%S') - SSH via control socket failed but direct connection works, resetting control socket"
            _clear_stale_control_socket
            ssh -o ConnectTimeout=10 -o BatchMode=yes "$host" true 2>/dev/null && break
        fi
        echo "$(date '+%H:%M:%S') - SSH connection failed, waiting 1 minute before retry..."
        sleep 60
    done
}

is_job_running() {
    local output rc
    output=$(ssh -o ConnectTimeout=10 -o BatchMode=yes "$host" "test -f ${remote_dir}/${job_id}.txt && echo true || echo false" 2>/dev/null)
    rc=$?
    if [[ $rc -ne 0 && $rc -ne 1 ]]; then
        return 0
    fi
    [[ "$output" == "true" ]]
    # if output is true then return 0, which indicated success status; otherwise, return 1, which indicates fail status
}

sync_remote() {
    local _rsync_out _rsync_rc=0
    _rsync_out=$(ssh "$host" "cd '${remote_dir}' && find . -newer .submit_marker -type f" 2>/dev/null |
        rsync -av --files-from=- "$host":"${remote_dir}/" "$local_dir/" 2>&1) || _rsync_rc=$?
    # $() this will be a child process and it will show the same commnd as parent in ps -ef output
    find "${local_dir}" -maxdepth 1 -name "*.ipynb" -exec cp {} "$HOME/project/${_project_name}/" \;
    if [[ $_rsync_rc -ne 0 ]]; then
        echo "$_rsync_out"
        return $_rsync_rc
    fi
}

_project_name=$(basename "$(dirname "$local_dir")")
tmpdirname=$(basename "$local_dir")

jobsfile=$HOME/project/${_project_name}/jwm_configs/jobs.txt
grep -qxF ${tmpdirname} ${jobsfile} || echo "${tmpdirname}" >>${jobsfile}
# --- main monitoring loop ---
_check_count=0
finish_flag=0
while [[ ${finish_flag} == 0 ]]; do
    _check_count=$((_check_count + 1))
    _capped=$((_check_count < 12 ? _check_count : 11))
    _interval=$((((_capped - 1) / 5 + 1) * 10))
    echo "=== $(date '+%H:%M:%S') - checking job (check #${_check_count}, next in ${_interval}s) ==="
    wait_for_ssh
    sync_remote || echo "WARNING: rsync failed, will retry next cycle"
    # [[ "$mode" == "slurm" ]] && print_slurm_summary
    fetch_new_content
    # 2>/dev/null || true

    total=0
    while [[ total -lt ${_interval} ]]; do
        ((total += 5))
        sleep 5
        if ! is_job_running; then
            echo "job ends, sleep 5"
            sleep 5
            wait_for_ssh
            sync_remote || echo "WARNING: final rsync failed, results may be incomplete"
            # [[ "$mode" == "slurm" ]] && print_slurm_summary
            fetch_new_content "finish"
            # 2>/dev/null || true

            echo "DONE: Remote job finished (id: ${job_id}). Output saved to: ${local_dir}"

            finish_flag=1
            sed -i '' "s|^${tmpdirname}|${tmpdirname}  finished|g" ${jobsfile}
            echo "current dir ${PWD}"
            break
        fi
    done
done
