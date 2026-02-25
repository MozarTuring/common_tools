#!/usr/bin/env bash
set -euo pipefail

GPU_TYPE="${1:-}"
REQ_FREE="${2:-}"

if [[ -z "$GPU_TYPE" || -z "$REQ_FREE" ]]; then
  echo "Usage: $0 <GPU_TYPE> <MIN_FREE_GPUS>"
  echo "Example: $0 T4 4"
  exit 2
fi

GPU_TYPE_LC="$(echo "$GPU_TYPE" | tr '[:upper:]' '[:lower:]')"

printf "%-15s %-10s %-14s %-8s %-10s\n" "Node" "Total" "Allocated" "Free" "State"
printf "%-15s %-10s %-14s %-8s %-10s\n" "-----" "-----" "---------" "----" "-----"

# Print per-node table + return exit status:
#   0 if any node has free >= REQ_FREE
#   1 otherwise
scontrol show node | awk -v RS="" -v type="$GPU_TYPE" -v type_lc="$GPU_TYPE_LC" -v req="$REQ_FREE" '
BEGIN { ok=0; }
{
  node=""; state=""; total=0; alloc=0;

  if (match($0, /NodeName=([^ ]+)/, a)) node=a[1];
  if (match($0, /State=([^ ]+)/, a))    state=a[1];

  # Total GPUs of requested type from Gres (e.g., gpu:T4:8)
  if (match($0, "Gres=.*gpu:" type ":([0-9]+)", a)) total=a[1];

  # Allocated GPUs: prefer type-specific (gres/gpu:t4=8), else fallback to generic (gres/gpu=8)
  if (match($0, "AllocTRES=.*gres/gpu:" type_lc "=([0-9]+)", b))      alloc=b[1];
  else if (match($0, /AllocTRES=.*gres\/gpu=([0-9]+)/, b))            alloc=b[1];
  else alloc=0;

  if (total > 0) {
    free = total - alloc;
    if (free < 0) free = 0;

    printf "%-15s %-10d %-14d %-8d %-10s\n", node, total, alloc, free, state;

    if (free >= req) ok=1;
  }
}
END {
  if (ok) exit 0;
  else exit 1;
}
'

