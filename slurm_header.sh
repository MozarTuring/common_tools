#!/bin/bash

early_warning() {
    echo "2 minutes left — saving checkpoint..."
    # save_checkpoint
    # optionally keep running, or exit gracefully
}

final_cleanup() {
    echo "Being killed — last-resort cleanup..."
    rm ${RUN_DIR_HOME}/project_remote_jwm/${RUN_PROJ}/${JWM_RUN_START_TIME}.jwm
}

trap early_warning SIGUSR1    # 120s before limit — your warning

trap final_cleanup SIGTERM    # 0s — SLURM is killing you


(while true; do
    echo ""
    echo "CPU Usage: $(vmstat 1 2 | tail -1 | awk '{print 100 - $15}')% | Total CPUs: $(nproc)"
    nvidia-smi
    echo ""
    sleep 300
done) >jwmlogs/${JWM_RUN_START_TIME}/resource_usage.log 2>&1 &

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

