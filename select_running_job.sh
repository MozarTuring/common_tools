#!/bin/bash
# Usage: select_running_job.sh <jobs_file> <pkq_mode>
#   jobs_file: one line per job: server,job_id,run_dir_home,git_branch,local_dir,PKQ_RUN_START_TIME
# Waits until one job is running, scancels the others and starts remote_monitor on the running one.

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
_project_name=$(basename "$(dirname "${jobs_file}")")
_tools_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_server=""
run_job=""
while [[ -z "${run_job}" ]]; do
    _alive=0
    while IFS=, read -r _srv _jid _rdh _br _ldir _stime <&3; do
        [[ -z "${_jid}" ]] && continue
        echo "check ${_srv},${_jid}"
        bash "${_tools_dir}/slurm_job_status.sh" "ssh ${_srv}" "${_jid}" once && _st=0 || _st=$?
        if [[ ${_st} -eq 0 ]]; then
            run_server=${_srv}
            run_job=${_jid}
            run_dir_home=${_rdh}
            _git_branch=${_br}
            local_dir=${_ldir}
            PKQ_RUN_START_TIME=${_stime}
            break
        elif [[ ${_st} -ne 1 ]]; then
            _alive=1
        fi
    done 3<"${jobs_file}"
    if [[ -z "${run_job}" ]]; then
        if [[ ${_alive} -eq 0 ]]; then
            echo "ERROR: no job in ${jobs_file} is pending or running"
            exit 1
        fi
        sleep 30
    fi
done
echo "${run_server},${run_job} is RUNNING, cancelling the others"
while IFS=, read -r _srv _jid _rest <&3; do
    [[ -z "${_jid}" || ("${_srv}" == "${run_server}" && "${_jid}" == "${run_job}") ]] && continue
    echo "scancel ${_srv},${_jid}"
    ssh -o ConnectTimeout=10 "${_srv}" "scancel ${_jid}" </dev/null || echo "WARNING: scancel ${_srv},${_jid} failed"
done 3<"${jobs_file}"

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
