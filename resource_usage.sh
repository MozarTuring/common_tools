#!/bin/bash

# Ensure a PID was provided
if [ -z "$1" ]; then
    echo "Error: Please provide a PID." >&2
    exit 1
fi

PID=$1
count=7

# Ensure the text file is deleted even if the script is interrupted
trap 'rm -f "${PID}.txt"' EXIT

get_descendants() {
    local children
    children=$(pgrep -P "$1" 2>/dev/null)
    for child in $children; do
        echo "$child"
        get_descendants "$child"
    done
}

get_all_pids() {
    if [ -n "$SLURM_JOB_ID" ]; then
        # Inside a Slurm job: srun's children live under slurmstepd,
        # not under the srun PID, so walk the Slurm job instead.
        scontrol listpids "$SLURM_JOB_ID" 2>/dev/null | awk 'NR>1 && $1!="" {print $1}'
    else
        echo "$PID"
        get_descendants "$PID"
    fi
}

while kill -0 "$PID" 2>/dev/null; do
    ((count++))
    sleep 5

    if [ -n "$SLURM_JOB_ID" ]; then
        # Slurm: show all GPU processes on this node (they're all ours)
        nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv
    else
        gpu_pids=$(get_all_pids)
        gpu_grep_pattern=$(echo "$gpu_pids" | paste -sd'|')
        nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv | head -1
        nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv | grep -E "$gpu_grep_pattern"
    fi

    if [ "$count" -gt 1 ]; then
        echo ""
        all_pids=$(get_all_pids | paste -sd,)

        # Run ps only on this specific family tree
        ps --forest -o pid,%cpu,%mem,rss,cmd -p "$all_pids"
        echo ""
        count=0
    fi
done
