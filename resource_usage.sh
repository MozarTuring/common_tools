#!/bin/bash

# Mode: PID-specific monitoring or machine-wide status
if [ -z "$1" ]; then
    MODE="machine"
else
    MODE="pid"
    PID=$1
fi

# Intervals (seconds) — switch to slower pace after count threshold
GPU_INTERVAL=2
GPU_SLOW_INTERVAL=2
GPU_SLOW_AFTER=200

CPU_INTERVAL=2
CPU_SLOW_INTERVAL=1800
CPU_SLOW_AFTER=1000

if [ "$MODE" = "pid" ]; then
    # Ensure the text file is deleted even if the script is interrupted
    trap 'rm -f "${PID}.txt"' EXIT
fi

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

# =============================================================================
# Machine-wide status (no PID given)
# =============================================================================
machine_gpu_monitor() {
    local max_gpu_mem=0
    local count=0
    local interval=$GPU_INTERVAL
    while true; do
        sleep "$interval"
        ((count++))
        if [ "$count" -ge "$GPU_SLOW_AFTER" ]; then
            interval=$GPU_SLOW_INTERVAL
        fi

        echo "===== GPU Status ($(date '+%Y-%m-%d %H:%M:%S')) ====="
        nvidia-smi 2>/dev/null || echo "(nvidia-smi not available)"

        # Track max GPU memory
        local current_gpu_mem
        current_gpu_mem=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits 2>/dev/null | awk '{if($1>m) m=$1} END {printf "%d", m}')
        if [ "$current_gpu_mem" -gt "$max_gpu_mem" ] 2>/dev/null; then
            max_gpu_mem=$current_gpu_mem
            echo ">>> NEW MAX GPU MEM: ${max_gpu_mem} MiB <<<"
        fi
        echo ""
    done
}

machine_cpu_monitor() {
    local count=0
    local interval=$CPU_INTERVAL
    while true; do
        sleep "$interval"
        ((count++))
        if [ "$count" -ge "$CPU_SLOW_AFTER" ]; then
            interval=$CPU_SLOW_INTERVAL
        fi

        echo "===== CPU / Memory Status ($(date '+%Y-%m-%d %H:%M:%S')) ====="

        # Overall load and memory
        echo "--- Uptime & Load ---"
        uptime
        echo ""

        echo "--- Memory ---"
        free -h 2>/dev/null || vm_stat 2>/dev/null || echo "(memory info not available)"
        echo ""

        echo "--- Disk ---"
        df -h / 2>/dev/null
        echo ""

        echo "--- Top Processes (by CPU) ---"
        ps aux --sort=-%cpu 2>/dev/null | head -16 || ps aux -r 2>/dev/null | head -16
        echo ""
    done
}

# =============================================================================
# PID-specific monitoring
# =============================================================================

# --- GPU monitor (runs in background) ---
gpu_monitor() {
    local max_gpu_mem=0
    local count=0
    local interval=$GPU_INTERVAL
    while kill -0 "$PID" 2>/dev/null; do
        sleep "$interval"
        ((count++))
        if [ "$count" -ge "$GPU_SLOW_AFTER" ]; then
            interval=$GPU_SLOW_INTERVAL
        fi

        # GPU usage
        if [ -n "$SLURM_JOB_ID" ]; then
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
    done
}

# --- CPU monitor (runs in background) ---
cpu_monitor() {
    local count=0
    local interval=$CPU_INTERVAL
    while kill -0 "$PID" 2>/dev/null; do
        sleep "$interval"
        ((count++))
        if [ "$count" -ge "$CPU_SLOW_AFTER" ]; then
            interval=$CPU_SLOW_INTERVAL
        fi

        # CPU/MEM usage
        local all_pids
        all_pids=$(get_all_pids | grep -E '^[0-9]+$' | sort -un | paste -sd,)
        if [ -n "$all_pids" ]; then
            ps --forest -o pid,%cpu,%mem,rss,cmd -p "$all_pids" 2>/dev/null
        fi
        echo ""
    done
}

# --- Launch the appropriate monitors ---
if [ "$MODE" = "machine" ]; then
    echo "No PID specified — monitoring overall machine status."
    echo "Press Ctrl+C to stop."
    echo ""
    machine_gpu_monitor &
    machine_cpu_monitor &
    wait
else
    gpu_monitor &
    cpu_monitor &
    wait
fi
