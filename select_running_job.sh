#!/bin/bash

set -e

if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: select_running_job.sh <jobs_file> <pkq_mode> <group>"
    exit 1
fi
# the jobs file may not exist yet: started at the group's end, its runs record their lines later
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

# reread the jobs file into _job_lines; the group's runs keep appending to it while this script runs
_read_jobs() {
    _job_lines=()
    [[ -f "${jobs_file}" ]] || return 0
    while IFS= read -r _line || [[ -n "${_line}" ]]; do
        [[ -n "${_line}" ]] && _job_lines+=("${_line}")
    done <"${jobs_file}"
}

# scancel the job on line _i of _job_lines and remove its local output dir
_cancel_line() {
    IFS=, read -r _srv _jid _rdh _br _ldir _rest <<<"${_job_lines[$1]}"
    [[ -z "${_jid}" ]] && return 0
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
}

# print "<pid> <args>" of the local meta_script.sh processes of the run with PKQ_RUN_START_TIME $1
_run_procs() {
    while read -r _pid _args; do
        [[ "${_args}" == *"meta_script.sh "* && " ${_args} " == *" $1 "* ]] && echo "${_pid} ${_args}"
    done < <(ps -Ao pid=,args=)
    return 0
}

run_server=""
run_job=""
_round=0
while [[ -z "${run_job}" ]]; do
    _round=$((_round + 1))
    _read_jobs
    # whether any run of the group can still give a job: a recorded job id, or a meta_script.sh still running
    _alive=""
    for _i in "${!_job_lines[@]}"; do
        IFS=, read -r _srv _jid _rdh _br _ldir _stime <<<"${_job_lines[_i]}"
        if [[ -z "${_jid}" ]]; then
            if [[ -n "$(_run_procs "${_stime}")" ]]; then
                echo "${_stime} in process, but no job id yet"
                _alive=1
            else
                echo "${_stime} not in process"
            fi
            continue
        fi
        _alive=1
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
    [[ -n "${run_job}" ]] && break
    # runs that have not recorded their line yet (before the ssh) only show up as a meta_script.sh with the group flag
    if [[ -z "${_alive}" ]] && ps -Ao args= | grep -qE "meta_script\.sh .* ${whichgroup}( |$)"; then
        echo "no job id yet, but a meta_script.sh of ${whichgroup} is still running"
        _alive=1
    fi
    # from the 2nd round on (the group's last run needs a moment to start): stop when nothing can give a job any more
    if [[ -z "${_alive}" && ${_round} -gt 1 ]]; then
        echo "ERROR: no run of ${whichgroup} has a job id or is still in process, stopping"
        exit 1
    fi
    sleep 15
done
echo "${run_server},${run_job} is ${run_status}, cancelling the others"
# PKQ_RUN_START_TIMEs of the runs handled so far (selected or cancelled)
_handled=" ${PKQ_RUN_START_TIME} "
for _i in "${!_job_lines[@]}"; do
    [[ ${_i} -eq ${run_idx} ]] && continue
    IFS=, read -r _srv _jid _rdh _br _ldir _stime <<<"${_job_lines[_i]}"
    [[ -z "${_jid}" ]] && continue
    _cancel_line "${_i}"
    _handled+="${_stime} "
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

# the group's remaining runs, reread since the selection:
#   job id recorded    -> scancel the remote job
#   no job id yet      -> the run is still in its local meta_script.sh (e.g. the ssh to the remote): kill it,
#                         found by its PKQ_RUN_START_TIME in the meta_script.sh args
#   no job id, no proc -> listed at the end (failed or exited before submitting)
_unfound=()
_killed=" "
_read_jobs
for _i in "${!_job_lines[@]}"; do
    IFS=, read -r _srv _jid _rdh _br _ldir _stime <<<"${_job_lines[_i]}"
    [[ -z "${_stime}" || "${_handled}" == *" ${_stime} "* ]] && continue
    if [[ -n "${_jid}" ]]; then
        echo "late job ${_stime} of ${whichgroup}"
        _cancel_line "${_i}"
        _handled+="${_stime} "
        continue
    fi
    _found=""
    while read -r _pid _args; do
        _found=1
        echo "kill stuck run ${_stime} (pid ${_pid}): ${_args}"
        # collect the children, then SIGKILL the script itself first: a child killed while the script lives would fire
        # its ERR trap (_cancel_recorded_jobs), which scancels every recorded job of the group, the selected one too
        _children=$(pgrep -P "${_pid}" || true)
        kill -9 "${_pid}" 2>/dev/null || true
        [[ -n "${_children}" ]] && kill ${_children} 2>/dev/null || true
    done < <(_run_procs "${_stime}")
    if [[ -z "${_found}" ]]; then
        _unfound+=("${_job_lines[_i]}")
        continue
    fi
    _killed+="${_stime} "
    # the killed run's local output dir is no longer needed
    if [[ -n "${_ldir}" && -d "${_ldir}" && "${_ldir}" != "${local_dir}" ]]; then
        echo "rm -rf ${_ldir}"
        rm -rf "${_ldir}"
    fi
done

# a killed run may have filled in its job id just before the kill: cancel those too
_read_jobs
for _i in "${!_job_lines[@]}"; do
    IFS=, read -r _srv _jid _rdh _br _ldir _stime <<<"${_job_lines[_i]}"
    [[ -n "${_jid}" && "${_killed}" == *" ${_stime} "* ]] || continue
    echo "job ${_stime} of ${whichgroup} recorded just before its kill"
    _cancel_line "${_i}"
done

if [[ ${#_unfound[@]} -gt 0 ]]; then
    echo "runs of ${whichgroup} with no job id and no running meta_script.sh (check them by hand):"
    printf '  %s\n' "${_unfound[@]}"
fi

# exit 0 tells the nvim batch that this group is cleanly done, so it starts the next group
exit 0
