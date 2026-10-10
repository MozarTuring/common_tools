# Copy LIBRARY_PATH to LD_LIBRARY_PATH, but strip stubs dirs —
# CUDA module's stubs/lib64 has fake libnvidia-ml.so/libcuda.so
# that shadow the real driver and break GPU init.
_lib_path_no_stubs=$(echo "${LIBRARY_PATH:-}" | tr ':' '\n' | grep -v '/stubs/' | paste -sd ':')
export LD_LIBRARY_PATH=${_lib_path_no_stubs:+${_lib_path_no_stubs}:}${LD_LIBRARY_PATH:-}
echo "PWD, ${PWD}"
echo "PKQ_RUN_COMMAND, ${PKQ_RUN_COMMAND}"
srun --ntasks=1 ${PKQ_RUN_COMMAND} &

wait $!

remote_dir=${PWD}
echo "slurm remote dir, ${remote_dir}"

# ts=$(cat "${RUN_DIR_HOME}/project_remote_pkq/last_remote_ts/${PKQ_RUN_START_TIME}.txt")
# echo "slurm ts, ${ts}, ${PKQ_RUN_START_TIME}"

mkdir -p "${RUN_DIR_HOME}/project_remote_pkq/remote_data/${RUN_PROJ_NAME}/backup/${PKQ_SERVER_NAME}/${PKQ_RUN_START_TIME}" && rsync -a ./  "${RUN_DIR_HOME}/project_remote_pkq/remote_data/${RUN_PROJ_NAME}/backup/${PKQ_SERVER_NAME}/${PKQ_RUN_START_TIME}/" 2>&1

# rm ${RUN_DIR_HOME}/project_remote_pkq/last_remote_ts/${PKQ_RUN_START_TIME}.txt
