#!/usr/bin/env bash
set -euo pipefail

# Unified remote job monitor.
#
# Usage:
#   remote_monitor.sh slurm <host> <slurm_job_id> <remote_log> <local_log> <run_dir_pre> <run_id> <proj_name>
#   remote_monitor.sh pid   <host> <remote_pid>   <remote_log> <local_log> [port_forward <ports_before_file>]

mode="$1"; shift
host="$1"; shift
job_id="$1"; shift   # slurm job id  OR  remote pid
remote_log="$1"; shift
local_log="$1"; shift

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

local_log_dir=$(dirname "$local_log")

wait_for_ssh() {
    [[ "$host" == "localmachine" ]] && return 0
    while ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$host" true 2>/dev/null; do
        echo "$(date '+%H:%M:%S') - SSH connection failed, waiting 1 minute before retry..."
        sleep 60
    done
}

is_job_running() {
    if [[ "$mode" == "slurm" ]]; then
        ssh "$host" "squeue --job=${job_id} --noheader 2>/dev/null | grep -q ." 2>/dev/null
    elif [[ "$host" == "localmachine" ]]; then
        kill -0 "${job_id}" 2>/dev/null
    else
        ssh "$host" "kill -0 ${job_id} 2>/dev/null"
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

# --- main monitoring loop ---
_check_count=0
while true; do
    _check_count=$((_check_count + 1))
    _interval=$(( ((_check_count - 1) / 10 + 1) * 30 ))
    echo "=== $(date '+%H:%M:%S') - checking job (check #${_check_count}, next in ${_interval}s) ==="
    wait_for_ssh
    if [[ "$host" != "localmachine" ]]; then
        rsync -av "$host":"$(dirname ${remote_log})/" "$local_log_dir/" \
            2>/dev/null || echo "WARNING: rsync failed, will retry next cycle"
    fi

    if ! is_job_running; then
        wait_for_ssh
        if [[ "$host" != "localmachine" ]]; then
            rsync -av "$host":"$(dirname ${remote_log})/" "$local_log_dir/" \
                || echo "WARNING: final rsync failed, results may be incomplete"
        fi

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
        echo "DONE: Remote job finished (${mode} id: ${job_id}). Log saved to: ${local_log}"
        break
    fi

    sleep $_interval
done
