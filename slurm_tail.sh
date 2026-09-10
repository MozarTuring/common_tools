export LD_LIBRARY_PATH=${LIBRARY_PATH}:${LD_LIBRARY_PATH:-}
echo "JWM_RUN_COMMAND, ${JWM_RUN_COMMAND}"
srun --ntasks=1 ${JWM_RUN_COMMAND} &
SRUN_PID=$!

bash ${RUN_DIR_HOME}/project_remote_jwm/common_tools_jingwei/resource_usage.sh "$SRUN_PID"  >jwmlogs/${JWM_RUN_START_TIME}/resource_usage.log  &

wait $SRUN_PID
