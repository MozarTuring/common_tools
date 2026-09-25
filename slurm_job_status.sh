#!/bin/bash
# Usage: slurm_job_status.sh <ssh_cmd> <job_id>
#   ssh_cmd: 'ssh myhost' for remote, '' for local

ssh_cmd="$1"
job_id="$2"
if [[ -z "$job_id" ]]; then
    echo "Usage: slurm_job_status.sh <ssh_cmd> <job_id>"
    echo "  ssh_cmd: 'ssh myhost' for remote, '' for local"
    exit 1
fi
count=0
slurm_job_status_checked=1
while true; do
    source ${HOME}/project/common_tools/wait_for_ssh.sh
    all_states=$($ssh_cmd squeue --job="${job_id}" --noheader -o '%T' 2>/dev/null) && rc=0 || rc=$?
    # 255 = ssh itself failed (connection dropped), not an answer from squeue
    if [[ $rc -eq 255 ]]; then
        echo "$(date '+%H:%M:%S') - ssh failed during squeue, retrying"
        sleep 30
        continue
    fi
    if [[ -z "$all_states" ]]; then
        # double-check with sacct before declaring the job gone
        sacct_state=$($ssh_cmd sacct -j "${job_id}" -X -n -o State 2>/dev/null | head -1 | awk '{print $1}') || true
        if [[ "$sacct_state" =~ ^(PENDING|RUNNING|CONFIGURING|REQUEUED|SUSPENDED)$ ]]; then
            echo "$(date '+%H:%M:%S') - squeue empty but sacct says ${sacct_state}, retrying"
            sleep 30
            continue
        fi
        echo "Job ${job_id} no longer in queue (may have finished or failed instantly), sacct state: ${sacct_state:-unknown}"
        slurm_job_status_checked="failed"
        break
    fi

    state_counts=$(echo "$all_states" | sort | uniq -c | awk '{printf "%s=%s ", $2, $1} END {print ""}')

    if echo "$all_states" | grep -q "RUNNING"; then
        if ! echo "$all_states" | grep -q "PENDING"; then
            echo "Job ${job_id} is now fully RUNNING."
            echo "  $state_counts"
            break
        else
            echo "$(date '+%H:%M:%S') - Job partially running: $state_counts"
        fi
    else
        if ((count % 10 == 0)); then
            echo "$(date '+%H:%M:%S') - $state_counts"
        fi
    fi
    sleep 10
    ((count++))
done

