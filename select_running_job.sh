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
_out_dir="$(dirname "${jobs_file}")"
_project_name=$(basename "${_out_dir}")
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

_cancel_line() {
    local _cmd _done _waited=0
    IFS=, read -r _srv _jid _rdh _br _ldir _rest <<<"${_job_lines[$1]}"
    [[ -z "${_jid}" ]] && return 0
    # the Terminal window creates this file when scancel is done
    _done=$(mktemp -u "${TMPDIR:-/tmp}/pkq_scancel_${_jid}.XXXXXX")
    _cmd="ssh -o ConnectTimeout=10 ${_srv} 'scancel ${_jid}'; touch ${_done}"
    echo "scancel ${_srv},${_jid} in a Terminal window"
    if ! osascript "${_tools_dir}/run_in_idle_terminal.applescript" "${_cmd}" >/dev/null; then
        echo "WARNING: could not open Terminal, run by hand: ssh -o ConnectTimeout=10 ${_srv} 'scancel ${_jid}'"
        return 1
    fi
    while [[ ! -e "${_done}" ]]; do
        if ((_waited >= 300)); then
            echo "WARNING: scancel ${_srv},${_jid} not done after 300 s, continuing without it"
            return 1
        fi
        # in the background + wait, as in the main loop: a USR1 is handled at once
        sleep 1 &
        wait $! || true
        _waited=$((_waited + 1))
    done
    rm -f "${_done}"
    echo "scancel ${_srv},${_jid} done"
}

# print "<pid> <args>" of the local meta_script.sh processes of the run with PKQ_RUN_START_TIME $1
_run_procs() {
    while read -r _pid _args; do
        [[ "${_args}" == *"meta_script.sh "* && " ${_args} " == *" $1 "* ]] && echo "${_pid} ${_args}"
    done < <(ps -Ao pid=,args=)
    return 0
}

# kill a local meta_script.sh: collect the children, then SIGKILL the script itself first: a child killed while the
# script lives would fire its ERR trap (_cancel_recorded_jobs), which scancels every recorded job of the group,
# the selected one too
_kill_run() {
    local _children
    _children=$(pgrep -P "$1" || true)
    kill -9 "$1" 2>/dev/null || true
    [[ -n "${_children}" ]] && kill ${_children} 2>/dev/null || true
}

# one ssh attempt to $1 (with the stale-ControlMaster reset of _wait_for_ssh), never waits: 0 reachable, 1 not
_ssh_ok() {
    refresh_ssh_auth_sock
    _with_timeout 30 ssh -o ConnectTimeout=10 -o BatchMode=yes "$1" true </dev/null 2>/dev/null && return 0
    _with_timeout 30 ssh -o ControlPath=none -o ConnectTimeout=10 -o BatchMode=yes "$1" true </dev/null 2>/dev/null || return 1
    _clear_stale_control_socket "$1"
    _with_timeout 30 ssh -o ConnectTimeout=10 -o BatchMode=yes "$1" true </dev/null 2>/dev/null
}

# PKQ_RUN_START_TIMEs of the runs handled so far (selected or cancelled); the selected one is never cancelled
_handled=" "
local_dir=""

# every run of the group except the selected one (none before a selection), reread from the jobs file:
#   job id recorded    -> scancel the remote job
#   no job id yet      -> the run is still in its local meta_script.sh (e.g. the ssh to the remote): kill it,
#                         found by its PKQ_RUN_START_TIME in the meta_script.sh args
#   no job id, no proc -> listed at the end (failed or exited before submitting)
# the local output dirs of cancelled/killed runs are removed at the end; a run whose scancel was not confirmed keeps it
_cleanup_rest() {
    local _unfound=() _found _pid _args _drop=() _t _ts_re='^[0-9]{8}_[0-9]{6}$'
    _read_jobs
    [[ ${#_job_lines[@]} -eq 0 ]] && echo "no lines in ${jobs_file}: no recorded job of ${whichgroup} to cancel"
    for _i in "${!_job_lines[@]}"; do
        IFS=, read -r _srv _jid _rdh _br _ldir _stime <<<"${_job_lines[_i]}"
        [[ -z "${_stime}" || "${_handled}" == *" ${_stime} "* ]] && continue
        if [[ -n "${_jid}" ]]; then
            echo "cancel job ${_stime} of ${whichgroup}"
            _cancel_line "${_i}" && _drop+=("${_stime}")
            _handled+="${_stime} "
            continue
        fi
        _found=""
        while read -r _pid _args; do
            _found=1
            echo "kill stuck run ${_stime} (pid ${_pid}): ${_args}"
            _kill_run "${_pid}"
        done < <(_run_procs "${_stime}")
        if [[ -z "${_found}" ]]; then
            _unfound+=("${_job_lines[_i]}")
            continue
        fi
        _drop+=("${_stime}")
    done

    for _t in "${_drop[@]}"; do
        [[ "${_t}" =~ ${_ts_re} && "${_t}" != "${PKQ_RUN_START_TIME}" ]] || continue
        [[ -d "${_out_dir}/${_t}" ]] || continue
        echo "remove ${_out_dir}/${_t}"
        rm -rf "${_out_dir:?}/${_t}"
    done

    if [[ ${#_unfound[@]} -gt 0 ]]; then
        echo "runs of ${whichgroup} with no job id and no running meta_script.sh (check them by hand):"
        printf '  %s\n' "${_unfound[@]}"
    fi
}

# killed by <leader>k in nvim (it sends SIGUSR1): cancel and kill the group's other runs, then exit non-zero
# so the nvim batch does not start the next group. kill <pid>, Ctrl-C, closed terminal just exit, with no cleanup.
_on_signal() {
    trap - USR1
    echo "
--- $(date '+%Y-%m-%d %H:%M:%S') select_running_job.sh of ${whichgroup} stopped by <leader>k, cleaning up"
    _cleanup_rest
    exit 1
}
trap _on_signal USR1

run_server=""
run_job=""
PKQ_RUN_START_TIME=""
_round=0
while [[ -z "${run_job}" ]]; do
    _round=$((_round + 1))
    echo "
--- $(date '+%Y-%m-%d %H:%M:%S') check round ${_round}"
    _read_jobs
    # runs write their line only just before their ssh, so the file stays empty for a while after the group starts:
    # just wait for the first line
    if [[ ${#_job_lines[@]} -eq 0 ]]; then
        echo "no lines in ${jobs_file} yet"
        sleep 15 &
        wait $! || true
        continue
    fi
    for _i in "${!_job_lines[@]}"; do
        IFS=, read -r _srv _jid _rdh _br _ldir _stime <<<"${_job_lines[_i]}"
        # meta_script.sh fills in the job id, or removes its line on an error or Ctrl-C: reread next round
        if [[ -z "${_jid}" ]]; then
            echo "${_srv} ${_stime}: no job id yet"
            continue
        fi
        echo "check ${_srv},${_jid}"
        # slurm_job_status.sh waits until ssh works: skip an unreachable server this round instead of blocking on it
        if ! _ssh_ok "${_srv}"; then
            echo "ssh to ${_srv} failed, skipping it this round"
            continue
        fi
        _with_timeout 60 bash "${_tools_dir}/slurm_job_status.sh" "ssh -o ConnectTimeout=10 ${_srv}" "${_jid}" once </dev/null && _st=0 || _st=$?
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
    # in the background + wait: a signal is handled at once, not only after the sleep ends.
    # the kill hits the whole process group, so sleep dies too and wait returns non-zero: without "|| true", set -e
    # (bash 3.2) exits on that status before the pending USR1 trap runs, and _on_signal never fires
    sleep 15 &
    wait $! || true
done
echo "${run_server},${run_job} is ${run_status}, cancelling the others"
_handled+="${PKQ_RUN_START_TIME} "
_cleanup_rest

nohup_log="${local_dir}/nohup_monitor.log"
echo "

local dir: ${local_dir}"

monitor_args=(${PKQ_MODE} "${run_server}" "${run_job}" "${run_dir_home}" "${_project_name}" "${_git_branch}" "${local_dir}" "${PKQ_RUN_START_TIME}")

echo """nohup bash ${_tools_dir}/remote_monitor.sh ${monitor_args[@]} >> $nohup_log 2>&1 &""" >>$nohup_log

nohup bash "${_tools_dir}/remote_monitor.sh" "${monitor_args[@]}" >>"$nohup_log" 2>&1 &
monitor_pid=$!
echo "Background monitor PID:
ps -ef |grep $monitor_pid"

echo "see logs at
${local_dir}
${PKQ_RUN_START_TIME}

"

echo "${PKQ_RUN_START_TIME}" > /Users/jinma63/project/zzzpkqoutput/${_project_name}/select_running_job/${whichgroup}_done

trap - USR1

# exit 0 tells the nvim batch that this group is cleanly done, so it starts the next group
exit 0
