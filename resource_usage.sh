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

while kill -0 "$PID" 2>/dev/null; do
    ((count++))
    sleep 10
    if [ "$count" -gt 6 ]; then
        echo ""
        all_pids=$(
            echo "$PID"
            get_descendants "$PID"
        )
        all_pids=$(echo "$all_pids" | paste -sd,)

        # Run ps only on this specific family tree
        ps --forest -o pid,%cpu,%mem,rss,cmd -p "$all_pids"
        echo ""
        count=0
    fi
done
