#!/bin/bash

set -e

if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: select_running_job.sh <jobs_file> <pkq_mode>"
    exit 1
fi
if [[ ! -s "$1" ]]; then
    echo "ERROR: jobs_file '$1' does not exist or is empty"
    exit 1
fi
if [[ "$2" != "remoteslurm" ]]; then
    echo "ERROR: unsupported pkq_mode '$2', only remoteslurm is supported"
    exit 1
fi
# resolve "..", the project name is taken from the parent dir
jobs_file="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
PKQ_MODE="$2"
whichgroup=$3
_project_name=$(basename "$(dirname "${jobs_file}")")
_tools_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_tools_dir}/retry_ssh.sh"

# snapshot the jobs file once, so later modifications of it don't affect the selection loop
_job_lines=()
while IFS= read -r _line || [[ -n "${_line}" ]]; do
    _job_lines+=("${_line}")
done <"${jobs_file}"

run_server=""
run_job=""
while [[ -z "${run_job}" ]]; do
    for _i in "${!_job_lines[@]}"; do
        IFS=, read -r _srv _jid _rdh _br _ldir _stime <<<"${_job_lines[_i]}"
        [[ -z "${_jid}" ]] && continue
        echo "check ${_srv},${_jid}"
        bash "${_tools_dir}/slurm_job_status.sh" "ssh ${_srv}" "${_jid}" once && _st=0 || _st=$?
        # 0 running, 1 no longer in queue (finished/failed): monitor this one
        if [[ ${_st} -eq 0 || ${_st} -eq 1 ]]; then
            run_idx=${_i}
            run_server=${_srv}
            run_job=${_jid}
            run_dir_home=${_rdh}
            _git_branch=${_br}
            local_dir=${_ldir}
            PKQ_RUN_START_TIME=${_stime}
            run_status=$([[ ${_st} -eq 0 ]] && echo "RUNNING" || echo "no longer in queue")
            break
        fi
    done
    sleep 15
done
echo "${run_server},${run_job} is ${run_status}, cancelling the others"
for _i in "${!_job_lines[@]}"; do
    [[ ${_i} -eq ${run_idx} ]] && continue
    IFS=, read -r _srv _jid _rdh _br _ldir _rest <<<"${_job_lines[_i]}"
    [[ -z "${_jid}" ]] && continue
    echo "scancel ${_srv},${_jid}"
    if _retry_ssh "${_srv}" ssh -o ConnectTimeout=10 -o BatchMode=yes "${_srv}" "scancel ${_jid}" </dev/null; then
        # the cancelled job's local output dir is no longer needed
        if [[ -n "${_ldir}" && -d "${_ldir}" && "${_ldir}" != "${local_dir}" ]]; then
            echo "rm -rf ${_ldir}"
            rm -rf "${_ldir}"
        fi
    else
        echo "WARNING: scancel ${_srv},${_jid} failed, keeping ${_ldir}"
    fi
done

nohup_log="${local_dir}/nohup_monitor.log"
echo "local dir: ${local_dir}"

monitor_args=(${PKQ_MODE} "${run_server}" "${run_job}" "${run_dir_home}" "${_project_name}" "${_git_branch}" "${local_dir}" "${PKQ_RUN_START_TIME}")

echo """nohup bash ${_tools_dir}/remote_monitor.sh ${monitor_args[@]} >> $nohup_log 2>&1 &""" >>$nohup_log

nohup bash "${_tools_dir}/remote_monitor.sh" "${monitor_args[@]}" >>"$nohup_log" 2>&1 &
monitor_pid=$!
echo "Background monitor PID:
ps -ef |grep $monitor_pid"

echo "see logs at
${local_dir}
${PKQ_RUN_START_TIME}"

echo "${PKQ_RUN_START_TIME}" > /Users/jinma63/project/zzzpkqoutput/${_project_name}/select_running_job/${whichgroup}_done
