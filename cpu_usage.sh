#!/bin/bash
# CPU / memory monitor. GPU monitoring lives in resource_usage.sh.

# Mode: PID-specific monitoring or machine-wide status
# if [ -z "$1" ]; then
#     MODE="machine"
# else
#     MODE="pid"
#     PID=$1
# fi

MODE="machine"
# Intervals (seconds) — switch to slower pace after count threshold
CPU_INTERVAL=2
CPU_SLOW_INTERVAL=1800
CPU_SLOW_AFTER=1000

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

cpu_sample() {
    if [ "$MODE" = "machine" ]; then
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

        echo "--- Total CPU Usage ---"
        if [ -f /proc/stat ]; then
            grep 'cpu ' /proc/stat | awk '{used=$2+$3+$4+$6+$7+$8; total=used+$5; printf "Total CPU Usage: %.1f%%\n", used*100/total}'
        else
            top -l 1 2>/dev/null | grep 'CPU usage' || echo "(cpu usage not available)"
        fi
    else
        local all_pids
        all_pids=$(get_all_pids | grep -E '^[0-9]+$' | sort -un | paste -sd,)
        if [ -n "$all_pids" ]; then
            ps --forest -o pid,%cpu,%mem,rss,cmd -p "$all_pids" 2>/dev/null
        fi
    fi
    echo ""
}

keep_running() {
    [ "$MODE" = "machine" ] || kill -0 "$PID" 2>/dev/null
}

if [ "$MODE" = "machine" ]; then
    echo "No PID specified — monitoring overall machine CPU / memory status."
    echo "Press Ctrl+C to stop."
    echo ""
fi

count=0
interval=$CPU_INTERVAL
while keep_running; do
    sleep "$interval"
    ((count++))
    if [ "$count" -ge "$CPU_SLOW_AFTER" ]; then
        interval=$CPU_SLOW_INTERVAL
    fi
    cpu_sample
done
