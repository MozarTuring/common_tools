#!/bin/bash

early_warning() {
    echo "2 minutes left — saving checkpoint..."
    # save_checkpoint
    # optionally keep running, or exit gracefully
}

final_cleanup() {
    echo "Being killed — last-resort cleanup..."
}

trap early_warning SIGUSR1    # 120s before limit — your warning

trap final_cleanup SIGTERM    # 0s — SLURM is killing you
(
  sleep_time=5
  step=5
  max_sleep=300
  while true; do
    echo ""
    echo "CPU Usage: $(vmstat 1 2 | tail -1 | awk '{print 100 - $15}')% | Total CPUs: $(nproc)"
    nvidia-smi
    echo ""
    sleep "$sleep_time"
    if [ "$sleep_time" -lt "$max_sleep" ]; then
      sleep_time=$((sleep_time + step))
      if [ "$sleep_time" -gt "$max_sleep" ]; then
        sleep_time=$max_sleep
      fi
    fi
  done
) > jwmlogs/${JWM_RUN_START_TIME}/resource_usage.log 2>&1 &

module --force purge
if [[ -n "${JWM_MODULES}" ]]; then
    echo ${JWM_MODULES}
    module load ${JWM_MODULES}
fi

if [[ -n "${JWM_CONDAENV}" ]]; then
    echo ${JWM_CONDAENV}
    conda activate ${JWM_CONDAENV}
fi
which python

if [[ -n ${JWM_build_flashattn} ]]; then
    MAX_JOBS=${CPUS_PER_TASK} FLASH_ATTENTION_FORCE_BUILD=TRUE pip install ${JWM_CONDAENV}/flash_attn_src/flash_attn*.tar.gz --no-build-isolation --no-cache-dir
    echo "flash attn build done"
    exit
fi

export LD_LIBRARY_PATH=${LIBRARY_PATH}:${LD_LIBRARY_PATH:-}

srun torchrun --nproc_per_node=${JWM_GPU_NUM} --nnodes=${JWM_NODES_NUM} ${JWM_RUN_COMMAND} &
wait \$!
