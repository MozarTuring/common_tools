#!/bin/bash

early_warning() {
    echo "2 minutes left — saving checkpoint..."
    # save_checkpoint
    # optionally keep running, or exit gracefully
}

final_cleanup() {
    echo "Being killed — last-resort cleanup..."
}

trap early_warning SIGUSR1 # 120s before limit — your warning

trap final_cleanup SIGTERM # 0s — SLURM is killing you

module --force purge
module load ${PKQ_MODULES}

conda activate ${PKQ_CONDAENV}${PKQ_ARCH}

which python
which pip
pip list >pkq_configs/packages.txt

bash ${RUN_DIR_HOME}/project_remote_pkq/common_tools_pikaq/resource_usage.sh >pkqlogs/${PKQ_RUN_START_TIME}/resource_usage.log &

echo "TORCH_CUDA_ARCH_LIST ${TORCH_CUDA_ARCH_LIST}"

if [[ -n ${JWM_build_flashattn} ]]; then
    MAX_JOBS=${CPUS_PER_TASK} FLASH_ATTENTION_FORCE_BUILD=TRUE pip install ${PKQ_CONDAENV}/flash_attn_src/flash_attn*.tar.gz --no-build-isolation --no-cache-dir
    echo "flash attn build done"
    exit
fi
