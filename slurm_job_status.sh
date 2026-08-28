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
while true; do
    source ${HOME}/project/common_tools/wait_for_ssh.sh
    all_states=$($ssh_cmd squeue --job="${job_id}" --noheader -o '%T' 2>/dev/null)
    if [[ -z "$all_states" ]]; then
        echo "Job ${job_id} no longer in queue (may have finished or failed instantly). exit now"
        exit 1
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
