# Copy LIBRARY_PATH to LD_LIBRARY_PATH, but strip stubs dirs —
# CUDA module's stubs/lib64 has fake libnvidia-ml.so/libcuda.so
# that shadow the real driver and break GPU init.
_lib_path_no_stubs=$(echo "${LIBRARY_PATH:-}" | tr ':' '\n' | grep -v '/stubs/' | paste -sd ':')
export LD_LIBRARY_PATH=${_lib_path_no_stubs:+${_lib_path_no_stubs}:}${LD_LIBRARY_PATH:-}
echo "PKQ_RUN_COMMAND, ${PKQ_RUN_COMMAND}"
srun --ntasks=1 ${PKQ_RUN_COMMAND} &

wait $!
