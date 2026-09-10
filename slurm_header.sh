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
    JWM_MODULES=$(echo "${JWM_MODULES}" | sed 's|Miniforge|GPU/Miniforge/26.3.2-2-eb|g')
fi
if [[ -n "${JWM_MODULES}" ]]; then
    echo ${JWM_MODULES}
    module load ${JWM_MODULES}
fi
# Load CUDA toolkit so LD_LIBRARY_PATH includes cublas, cudart, etc.
# (torch installed --no-deps because nvidia-cudnn-cu12 has no aarch64 wheel)
if [[ "$(uname -m)" == "aarch64" ]]; then
    module load GPU/buildtool-easybuild/5.2.1-hpca3ef7d197 CUDA/12.9.1
    echo "CUDA_HOME=$CUDA_HOME  EBROOTCUDA=$EBROOTCUDA"
    echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
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

echo "TORCH_CUDA_ARCH_LIST ${TORCH_CUDA_ARCH_LIST}"

if [[ -n ${JWM_build_flashattn} ]]; then
    MAX_JOBS=${CPUS_PER_TASK} FLASH_ATTENTION_FORCE_BUILD=TRUE pip install ${JWM_CONDAENV}/flash_attn_src/flash_attn*.tar.gz --no-build-isolation --no-cache-dir
    echo "flash attn build done"
    exit
fi


