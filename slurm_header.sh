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
echo "JWM_RUN_COMMAND, ${JWM_RUN_COMMAND}"
srun ${JWM_RUN_COMMAND} &
SRUN_PID=$!

bash ${RUN_DIR_HOME}/project_remote_jwm/common_tools_jingwei/resource_usage.sh "$SRUN_PID"  >jwmlogs/${JWM_RUN_START_TIME}/resource_usage.log  &

wait $SRUN_PID
