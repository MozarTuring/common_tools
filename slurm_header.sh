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
# On Arrhenius, GPU (GH200) nodes are aarch64 and need GPU/-prefixed modules
if [[ "$(uname -m)" == "aarch64" ]]; then
    JWM_MODULES=$(echo "${JWM_MODULES}" | sed 's|Miniforge|GPU/Miniforge|g')
fi
if [[ -n "${JWM_MODULES}" ]]; then
    echo ${JWM_MODULES}
    module load ${JWM_MODULES}
fi

echo "JWM_CONDAENV, ${JWM_CONDAENV}"
echo "JWM_ARCH, ${JWM_ARCH}"
if [[ ! -d "${JWM_CONDAENV}${JWM_ARCH}" ]]; then
    echo "error, exit"
    exit
else
    conda activate ${JWM_CONDAENV}${JWM_ARCH}
fi

which python

if [[ -n ${JWM_build_flashattn} ]]; then
    MAX_JOBS=${CPUS_PER_TASK} FLASH_ATTENTION_FORCE_BUILD=TRUE pip install ${JWM_CONDAENV}/flash_attn_src/flash_attn*.tar.gz --no-build-isolation --no-cache-dir
    echo "flash attn build done"
    exit
fi


