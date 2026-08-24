#!/usr/bin/env bash
set -euo pipefail
trap 'echo "ERROR: remote_monitor failed at line $LINENO (exit code $?)" >&2' ERR
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
mkdir -p "$local_dir/jwmlogs"

print_slurm_summary() {
    ssh "$host" "squeue --job=${job_id} -h -o '%T' 2>/dev/null" |
        sort | uniq -c | awk '{printf "  %s=%s", $2, $1} END {print ""}' ||
        true
}

fetch_new_content() {
    local tmppath="${local_dir}/jwmlogs/${JWM_RUN_START_TIME}/"
    if [[ -d ${tmppath} ]]; then
        cd "${local_dir}/jwmlogs/${JWM_RUN_START_TIME}/"
    else
        echo "no log yet"
        return 0
    fi
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
            # [[ "$safe_lines" -lt "$prev_lines" ]] && prev_lines=0 # in case file is overwritten, wich shall never happen
            if [[ "$safe_lines" -gt "$prev_lines" ]]; then
                local new_start=$((prev_lines + 1))
                sed -n "${new_start},${safe_lines}p" "${fname}" | tr '\r' '\n' | awk 'NF && /[0-9]+%\|/ { last=$0; next } { if (last) { print last; last="" } print } END { if (last) print last }'
                if grep -q "^${fname} " "$_log_state_file" 2>/dev/null; then
                    sed -i '' "s/^${fname} .*/${fname} ${safe_lines}/" "$_log_state_file"
                else
                    echo "${fname} ${safe_lines}" >>"$_log_state_file"
                fi
            elif [[ "$safe_lines" == "$prev_lines" ]]; then
                if [[ "$safe_lines" != "$_final_lines" ]]; then
                    _final_lines="$safe_lines"
                    sed -n "${cur_lines}p" "${fname}" | tr '\r' '\n' | awk 'NF && /[0-9]+%\|/ { last=$0; next } { if (last) { print last; last="" } print } END { if (last) print last }'
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
    local tmpprint=""
    while true; do
        refresh_ssh_auth_sock
        ssh -o ConnectTimeout=10 -o BatchMode=yes "$host" true 2>/dev/null && break
        # Default SSH failed — check if stale ControlMaster socket is the cause
        if ssh -o ControlPath=none -o ConnectTimeout=10 -o BatchMode=yes "$host" true 2>/dev/null; then
            echo "$(date '+%H:%M:%S') - SSH via control socket failed but direct connection works, resetting control socket"
            _clear_stale_control_socket
            ssh -o ConnectTimeout=10 -o BatchMode=yes "$host" true 2>/dev/null && break
        fi
        if [[ -z ${tmpprint} ]]; then
            echo "$(date '+%H:%M:%S') - SSH connection failed, waiting 1 minute before retry..."
            tmpprint=1
        fi
        sleep 60
    done
}

is_job_running() {
    if [[ "$mode" == "remotenone" ]]; then
        ssh -o ConnectTimeout=10 -o BatchMode=yes "$host" "kill -0 ${job_id} 2>/dev/null" 2>/dev/null
    elif [[ "$mode" == "remoteslurm" ]]; then
        ssh -o ConnectTimeout=10 -o BatchMode=yes "$host" "squeue -j ${job_id} -h -o '%T' 2>/dev/null | grep -qiE 'PENDING|RUNNING|COMPLETING'" 2>/dev/null
    elif [[ "$mode" == "remotedocker" ]]; then
        ssh -o ConnectTimeout=10 -o BatchMode=yes "$host" "docker inspect -f '{{.State.Running}}' ${job_id} 2>/dev/null | grep -q true" 2>/dev/null
    else
        return 0
    fi
}

if false; then
    rsync -aP berzeliusampere:/home/x_jinma/project_remote_jwm/llm2vec_jingwei/output/mntp/Meta-Llama-3.1-8B-msmarco ./
fi

sync_remote() {
    local _rsync_out _rsync_rc=0
    # ssh "$host" "cd '${remote_dir}' && find . -newer .submit_marker -type f -size -10M" 2>/dev/null |
        # rsync -a --files-from=- "$host":"${remote_dir}/" "$local_dir/" 2>&1

    rsync -a --delete "$host":"${remote_dir}/jwm_configs/" "$local_dir/jwm_configs/"

    rsync -a --delete "$host":"${remote_dir}/jwmlogs/${JWM_RUN_START_TIME}" "$local_dir/jwmlogs/"


    # using $() will produce a child process, which will show the same commnd as parent in ps -ef output
    tmppath="$local_dir/jwm_configs"
    if [[ -d ${tmppath} ]]; then
        rsync -a --delete --include='*.ipynb' --exclude='*' ${tmppath}/ "$HOME/project/${_project_name}/jwm_configs/"
    fi
}

_project_name=$(basename "$(dirname "$local_dir")")
tmpdirname=$(basename "$local_dir")

jobsfile=$HOME/project/${_project_name}/jwm_configs/${_project_name}/jobs.txt

# --- main monitoring loop ---
_check_count=0
_final_lines="-1"
slurm_job_status_checked=""
JWM_NOTEBOOK=$(sed -n 's/^export JWM_NOTEBOOK=//p' "$HOME/project/${_project_name}/jwm_configs/${mode}/remote_tmps/remote.sh" | tail -1)
JWM_NOTEBOOK_start=""

if [[ ${JWM_NOTEBOOK} != 1 ]]; then

    grep -qxF ${tmpdirname} ${jobsfile} || echo "${tmpdirname}" >>${jobsfile}
fi

while true; do
    is_job_running && run_flag=0 || run_flag=$?

    _check_count=$((_check_count + 1))
    _capped=$((_check_count < 24 ? _check_count : 23))
    _interval=$((((_capped - 1) / 5 + 1) * 5))
    echo "
=== $(date '+%Y-%m-%d %H:%M:%S') - checking job (check #${_check_count}, next in ${_interval}s) ===
"
    node="localhost"
    if [[ ${mode} == "remoteslurm" && -z ${slurm_job_status_checked} ]]; then
        echo "slrum job status checking"
        wait_for_ssh
        bash "$(dirname "$0")/slurm_job_status.sh" "ssh ${host}" ${job_id}
        node=$(ssh -o ConnectTimeout=10 -o BatchMode=yes ${host} squeue -j ${job_id} -o "%N" --noheader) || true

        slurm_job_status_checked=1
    fi

    sleep ${_interval}

    wait_for_ssh
    sync_remote || echo "WARNING: rsync failed, will retry next cycle"
    # [[ "$mode" == "slurm" ]] && print_slurm_summary
    fetch_new_content
    # 2>/dev/null || true

    if [[ ${JWM_NOTEBOOK} == 1 && -z ${JWM_NOTEBOOK_start} ]]; then
        # pre_node=$(ps -eo args | grep '\-L 18889:' | grep -v grep | awk '{for(i=1;i<=NF;i++) if($i=="-L") {split($(i+1),a,":"); print a[2]}}')
        #
        # pre_host=$(ps -eo args | grep '\-L 18889:' | grep -v grep | awk '{print $NF}')

        pids=$(ps aux | grep "ssh.*-L.*:$node:18889.*$host" | grep -v grep | awk '{print $2}' || true)
        count=$(echo "$pids" | wc -w)
        if [ "$count" -gt 1 ]; then
            keep=$(echo "$pids" | head -1)
            if [ ${mode} == "remotenone" ]; then
                echo "$pids" | tail -n +2 | xargs kill
            fi
            existing=$(ps -p "$keep" -o args= | grep -oE '\-L [0-9]+' | awk '{print $2}')
            echo "use existing port $existing"
        elif [ "$count" -eq 1 ]; then
            existing=$(ps -p "$pids" -o args= | grep -oE '\-L [0-9]+' | awk '{print $2}')
            echo "use existing port $existing"
        else
            FREE_PORT=$(python3 -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')
            echo "create new forward on port ${FREE_PORT}"
            ssh -o ConnectTimeout=5 -o ExitOnForwardFailure=yes -f -N -L ${FREE_PORT}:$node:18889 $host sleep 108000
        fi
        # pgrep -fl 'ssh.*node.*berzeliusampere'
        JWM_NOTEBOOK_start=1
    fi

    # echo "run_flag, ${run_flag}"
    if [[ ${run_flag} -ne 0 ]]; then
        if [[ -f ${jobsfile} ]]; then
            sed -i '' "s|^${tmpdirname}|${tmpdirname}  finished|g" ${jobsfile}
        fi
        echo "DONE: Remote job finished (id: ${job_id})."
        break
    fi
done
