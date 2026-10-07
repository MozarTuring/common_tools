#!/usr/bin/env bash
set -euo pipefail
trap 'echo "ERROR: remote_monitor failed at line $LINENO (exit code $?)" >&2' ERR
# Unified remote job monitor.
#
# Usage:
#   remote_monitor.sh slurm  <host> <job_id>        <remote_dir> <local_dir> <run_dir_pre> <run_id> <proj_name>
#   remote_monitor.sh docker <host> <container_id>   <remote_dir> <local_dir>
#   remote_monitor.sh pid    <host> <remote_pid>     <remote_dir> <local_dir> [port_forward <ports_before_file>]

if [[ $# -ne 8 ]]; then
    echo "ERROR: expected 8 args <mode> <host> <job_id> <run_dir_home> <project_name> <git_branch> <local_dir> <run_start_time>, got $#: $*"
    exit 1
fi
mode="$1"
case "$mode" in
remoteslurm | remotedocker | remotenone) ;;
*)
    echo "ERROR: unknown mode '$mode', expected remoteslurm | remotedocker | remotenone"
    exit 1
    ;;
esac
shift
host="$1"
shift
job_id="$1"
shift # slurm job id, docker container id, OR remote pid
run_dir_home="$1"
shift
_project_name="$1"
shift
_git_branch="$1"
shift
local_dir="$1"
shift
PKQ_RUN_START_TIME="$1"

remote_dir="${run_dir_home}/project_remote_pkq/${_project_name}_${_git_branch}"

port_forward=false
ports_before_file=""
mkdir -p "$local_dir/pkqlogs"

print_slurm_summary() {
    ssh "$host" "squeue --job=${job_id} -h -o '%T' 2>/dev/null" |
        sort | uniq -c | awk '{printf "  %s=%s", $2, $1} END {print ""}' ||
        true
}

# Clean raw job output (stdin) for display:
#   1. tr '\r' '\n'         - split carriage-return progress updates (tqdm etc.) into separate lines
#   2. tr -cd '\n\t -~'     - keep only newline, tab and printable ASCII (drops ANSI ESC bytes, binary junk)
#   3. awk                  - collapse runs of consecutive tqdm-style lines ("NN%|") into the last one,
#                             so only the latest progress state is shown; other lines pass through unchanged
# Filtering disabled: raw output is passed through unchanged.
_clean_log() {
    cat
    # LC_ALL=C tr '\r' '\n' | LC_ALL=C tr -cd '\n\t -~' |
    #     awk 'NF && /[0-9]+%\|/ { last=$0; next } { if (last) { print last; last="" } print } END { if (last) print last }'
}

fetch_new_content() {
    local tmppath="${local_dir}/pkqlogs/${PKQ_RUN_START_TIME}/"
    if [[ -d ${tmppath} ]]; then
        cd "${local_dir}/pkqlogs/${PKQ_RUN_START_TIME}/"
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
            # Only hold back the last line if it is still being written (no trailing newline).
            # Holding back a complete line caused it to be printed twice: once via the
            # "preview" branch below, then again when the next line arrived.
            if [[ -n "${_job_finished}" || -z "$(tail -c1 "${fname}")" ]]; then
                safe_lines=$cur_lines
            else
                safe_lines=$((cur_lines > 0 ? cur_lines - 1 : 0))
            fi
            # [[ "$safe_lines" -lt "$prev_lines" ]] && prev_lines=0 # in case file is overwritten, wich shall never happen
            if [[ "$safe_lines" -gt "$prev_lines" ]]; then
                local new_start=$((prev_lines + 1))
                LC_ALL=C sed -n "${new_start},${safe_lines}p" "${fname}" | _clean_log
                if grep -q "^${fname} " "$_log_state_file" 2>/dev/null; then
                    sed -i '' "s/^${fname} .*/${fname} ${safe_lines}/" "$_log_state_file"
                else
                    echo "${fname} ${safe_lines}" >>"$_log_state_file"
                fi
            elif [[ "$safe_lines" == "$prev_lines" && "$safe_lines" != "$cur_lines" ]]; then
                # No new complete lines: preview the unfinished last line (e.g. a progress bar) once
                if [[ "$safe_lines" != "$_final_lines" ]]; then
                    _final_lines="$safe_lines"
                    LC_ALL=C sed -n "${cur_lines}p" "${fname}" | _clean_log
                fi
            fi
            break
        fi
    done
}

is_job_running() {
    if [[ "$mode" == "remotenone" ]]; then
        ssh -o ConnectTimeout=10 -o BatchMode=yes "$host" "kill -0 ${job_id} 2>/dev/null" 2>/dev/null
    elif [[ "$mode" == "remoteslurm" ]]; then
        ssh -o ConnectTimeout=10 -o BatchMode=yes "$host" "squeue -j ${job_id} -h -o '%T' 2>/dev/null | grep -qiE 'PENDING|CONFIGURING|RUNNING|COMPLETING|REQUEUED|SUSPENDED'" 2>/dev/null
    elif [[ "$mode" == "remotedocker" ]]; then
        ssh -o ConnectTimeout=10 -o BatchMode=yes "$host" "docker inspect -f '{{.State.Running}}' ${job_id} 2>/dev/null | grep -q true" 2>/dev/null
    else
        return 0
    fi
}

_project_name=$(basename "$(dirname "$local_dir")")
saved_ts="$HOME/project/${_project_name}/pkq_configs/.last_remote_ts"
ts=$(cat "$saved_ts")
echo "remote time ${ts}"

sync_remote() {
    local _rsync_out _rsync_rc=0
    # ssh "$host" "cd '${remote_dir}' && find . -newer .submit_marker -type f -size -10M" 2>/dev/null |
    #     rsync -a --files-from=- "$host":"${remote_dir}/" "$local_dir/" 2>&1

    rsync -a --timeout=60 -e 'ssh -o ConnectTimeout=10' --delete --include='*.ipynb' --exclude='*' "$host":"${remote_dir}/pkq_configs/" "$local_dir/pkq_configs/"

    rsync -a --timeout=60 -e 'ssh -o ConnectTimeout=10' "$host":"${remote_dir}/pkqlogs/${PKQ_RUN_START_TIME}" "$local_dir/pkqlogs/"

    # using $() will produce a child process, which will show the same commnd as parent in ps -ef output
    tmppath="$local_dir/pkq_configs"
    if [[ -d ${tmppath} ]]; then
        rsync -a --delete --include='*.ipynb' --exclude='*' ${tmppath}/ "$HOME/project/${_project_name}/pkq_configs/"
    fi
}

tmpdirname=$(basename "$local_dir")

jobsfile=$HOME/project/${_project_name}/pkq_configs/docs/jobs.txt

# --- main monitoring loop ---
_check_count=0
_final_lines="-1"
_job_finished=""
PKQ_NOTEBOOK=$(sed -n 's/^export PKQ_NOTEBOOK=//p' "$HOME/project/${_project_name}/pkq_configs/remote/remote_tmps/remote.sh" | tail -1)
PKQ_NOTEBOOK_start=""

if [[ ${PKQ_NOTEBOOK} != 1 ]]; then

    grep -qxF ${tmpdirname} ${jobsfile} || echo "${tmpdirname}" >>${jobsfile}
fi

node="localhost"

slurm_job_status_checked=""

if [[ ${mode} == "remoteslurm" ]]; then
    echo "slrum job status checking"
    source "$(dirname "$0")/slurm_job_status.sh" "ssh ${host}" ${job_id}
fi

while true; do
    source ${HOME}/project/common_tools/wait_for_ssh.sh

    _check_count=$((_check_count + 1))
    _capped=$((_check_count < 24 ? _check_count : 23))
    _interval=$((((_capped - 1) / 5 + 1) * 5))
    echo "
=== $(date '+%Y-%m-%d %H:%M:%S') - checking job (check #${_check_count}, next in ${_interval}s) ===
"

    is_job_running && run_flag=0 || run_flag=$?
    # 255 = ssh itself failed (network drop), not an answer from squeue/kill/docker: wait for ssh again
    if [[ ${run_flag} -eq 255 ]]; then
        echo "$(date '+%H:%M:%S') - ssh failed while checking job state, waiting for ssh"
        continue
    fi

    sleep ${_interval}

    sync_remote || echo "WARNING: rsync failed, will retry next cycle"
    # [[ "$mode" == "slurm" ]] && print_slurm_summary
    [[ ${run_flag} -ne 0 ]] && _job_finished=1
    fetch_new_content

    if [[ -f ${jobsfile} && ${slurm_job_status_checked} == "failed" ]]; then
        echo "done"
        break
    fi

    if [[ ${PKQ_NOTEBOOK} == 1 && -z ${PKQ_NOTEBOOK_start} ]]; then
        # pre_node=$(ps -eo args | grep '\-L 18889:' | grep -v grep | awk '{for(i=1;i<=NF;i++) if($i=="-L") {split($(i+1),a,":"); print a[2]}}')
        #
        # pre_host=$(ps -eo args | grep '\-L 18889:' | grep -v grep | awk '{print $NF}')

        node=$(ssh -o ConnectTimeout=10 -o BatchMode=yes ${host} squeue -j ${job_id} -o "%N" --noheader) || true
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
        PKQ_NOTEBOOK_start=1
    fi

    # echo "run_flag, ${run_flag}"
    if [[ ${run_flag} -ne 0 ]]; then
        # Second sync after a delay — HPC parallel filesystems may not have
        # flushed the final error messages (e.g. OOM) by the first rsync.
        sleep 10
        sync_remote || true
        # back up all files changed since submission to a per-run dir on remote (relative paths preserved)
        # ssh -o ConnectTimeout=10 "$host" "cd '${remote_dir}' && mkdir -p '${remote_dir}_backup/${PKQ_RUN_START_TIME}' &&
        #     find . -newermt '$ts' -type f | rsync -a --files-from=- ./ '${remote_dir}_backup/${PKQ_RUN_START_TIME}/'" 2>&1 ||

        fetch_new_content
        mkdir -p "$local_dir/../backup/${host}/${PKQ_RUN_START_TIME}"
        rsync -a --timeout=60 -e 'ssh -o ConnectTimeout=10' "$host":"${remote_dir}/" "$local_dir/../backup/${host}/${PKQ_RUN_START_TIME}/" && echo "backup done" && ssh $host "rm -rf ${remote_dir}" && echo "remote delete done"
        echo "DONE: Remote job finished (id: ${job_id})."
        break
    fi
done

if [[ -f ${jobsfile} ]]; then
    sed -i '' "s|^${tmpdirname}|${tmpdirname}  finished|g" ${jobsfile}
fi
