# Copy LIBRARY_PATH to LD_LIBRARY_PATH, but strip stubs dirs —
# CUDA module's stubs/lib64 has fake libnvidia-ml.so/libcuda.so
# that shadow the real driver and break GPU init.
_lib_path_no_stubs=$(echo "${LIBRARY_PATH:-}" | tr ':' '\n' | grep -v '/stubs/' | paste -sd ':')
export LD_LIBRARY_PATH=${_lib_path_no_stubs:+${_lib_path_no_stubs}:}${LD_LIBRARY_PATH:-}
# The pip NVIDIA libs torch was built against (cudnn, cuda_nvrtc, cublas, ...) go first,
# so a module's CUDA (e.g. buildenv-gcccuda/12.4.1 on berzeliusampere) can't shadow them:
# cudnn's runtime-compiled engines fail to load against an older libnvrtc.
_nv_libs=$(ls -d ${PKQ_CONDAENV}${PKQ_ARCH}/lib/python${PKQ_PYTHON}/site-packages/nvidia/*/lib 2>/dev/null | paste -sd ':')
export LD_LIBRARY_PATH=${_nv_libs:+${_nv_libs}:}${LD_LIBRARY_PATH:-}
echo "LD_LIBRARY_PATH, ${LD_LIBRARY_PATH}"
echo "PWD, ${PWD}"
echo "PKQ_RUN_COMMAND, ${PKQ_RUN_COMMAND}"
if [[ -z ${PKQ_RUN_COMMAND} ]]; then
    exit_code=0
else
    srun --ntasks=1 ${PKQ_RUN_COMMAND} &
    wait $!
    exit_code=$?
fi
remote_dir=${PWD}
echo "slurm remote dir, ${remote_dir}"

if [ $exit_code -eq 0 ]; then
    echo "Command succeeded."
    mkdir -p "${RUN_DIR_HOME}/project_remote_pkq/remote_data/${RUN_PROJ_NAME}/backup/${PKQ_RUN_START_TIME}" && rsync -a ./ "${RUN_DIR_HOME}/project_remote_pkq/remote_data/${RUN_PROJ_NAME}/backup/${PKQ_RUN_START_TIME}/" 2>&1 && touch ./pkq_run_succeed.flag

else
    echo "Command failed with exit code $exit_code."
fi
