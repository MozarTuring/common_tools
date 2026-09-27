#!/bin/bash
# GPU monitor. CPU/memory monitoring lives in cpu_usage.sh.

# Mode: PID-specific monitoring or machine-wide status
# if [ -z "$1" ]; then
#     MODE="machine"
# else
#     MODE="pid"
#     PID=$1
# fi

MODE="machine"
# Intervals (seconds) — switch to slower pace after count threshold
GPU_INTERVAL=2
GPU_SLOW_INTERVAL=5
GPU_SLOW_AFTER=200
# Once GPU memory is first seen above 0, sample fast and restart the count
GPU_ACTIVE_INTERVAL=0.2

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
        scontrol listpids "$SLURM_JOB_ID" 2>/dev/null | awk 'NR>1 && $1 ~ /^[0-9]+$/ {print $1}'
    fi
    echo "$PID"
    get_descendants "$PID"
}

gpu_sample() {
    if [ "$MODE" = "machine" ]; then
        echo "===== GPU Status ($(date '+%Y-%m-%d %H:%M:%S')) ====="
        nvidia-smi 2>/dev/null || echo "(nvidia-smi not available)"
    elif [ -n "$SLURM_JOB_ID" ]; then
        nvidia-smi
    else
        local gpu_pids
        gpu_pids=$(get_all_pids)
        local gpu_grep_pattern
        gpu_grep_pattern=$(echo "$gpu_pids" | paste -sd'|')
        nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv | head -1
        nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv | grep -E "$gpu_grep_pattern"
    fi

    # Track max GPU memory (max across all GPUs)
    local current_gpu_mem
    current_gpu_mem=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits 2>/dev/null | awk '{if($1>m) m=$1} END {printf "%d", m}')
    if [ "$current_gpu_mem" -gt "$max_gpu_mem" ] 2>/dev/null; then
        max_gpu_mem=$current_gpu_mem
        echo ">>> NEW MAX GPU MEM: ${max_gpu_mem} MiB <<<"
    fi
    echo ""
}

keep_running() {
    [ "$MODE" = "machine" ] || kill -0 "$PID" 2>/dev/null
}

if [ "$MODE" = "machine" ]; then
    echo "No PID specified — monitoring overall machine GPU status."
    echo "Press Ctrl+C to stop."
    echo ""
fi

max_gpu_mem=0
count=0
interval=$GPU_INTERVAL
gpu_active=0
while keep_running; do
    sleep "$interval"
    ((count++))
    if [ "$gpu_active" -eq 1 ] && [ "$count" -ge "$GPU_SLOW_AFTER" ]; then
        interval=$GPU_SLOW_INTERVAL
    fi
    gpu_sample

    # First time GPU memory is in use: switch to fast sampling, restart count
    if [ "$gpu_active" -eq 0 ] && [ "$max_gpu_mem" -gt 0 ]; then
        gpu_active=1
        interval=$GPU_ACTIVE_INTERVAL
        count=0
    fi
done
