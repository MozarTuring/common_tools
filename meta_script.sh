check_gpu() {
    local GPU_TYPE="${1:-}"
    local REQ_FREE="${2:-}"
    if [[ -z "$GPU_TYPE" || -z "$REQ_FREE" ]]; then
        echo "Usage: check_gpu <GPU_TYPE> <MIN_FREE_GPUS>"
        echo "Example: check_gpu T4 4"
        return 2
    fi
    local GPU_TYPE_LC
    GPU_TYPE_LC="$(echo "$GPU_TYPE" | tr '[:upper:]' '[:lower:]')"
    printf "%-15s %-10s %-14s %-8s %-10s\n" "Node" "Total" "Allocated" "Free" "State"
    printf "%-15s %-10s %-14s %-8s %-10s\n" "-----" "-----" "---------" "----" "-----"
    scontrol show node | awk -v RS="" -v type="$GPU_TYPE" -v type_lc="$GPU_TYPE_LC" -v req="$REQ_FREE" '
BEGIN { ok=0; }
{
  node=""; state=""; total=0; alloc=0;

  if (match($0, /NodeName=([^ ]+)/, a)) node=a[1];
  if (match($0, /State=([^ ]+)/, a))    state=a[1];

  if (match($0, "Gres=.*gpu:" type ":([0-9]+)", a)) total=a[1];

  if (match($0, "AllocTRES=.*gres/gpu:" type_lc "=([0-9]+)", b))      alloc=b[1];
  else if (match($0, /AllocTRES=.*gres\/gpu=([0-9]+)/, b))            alloc=b[1];
  else alloc=0;

  if (total > 0) {
    free = total - alloc;
    if (free < 0) free = 0;

    printf "%-15s %-10d %-14d %-8d %-10s\n", node, total, alloc, free, state;

    if (free >= req && tolower(state) !~ /planned/) ok=1;
  }
}
END {
  if (ok) exit 0;
  else exit 1;
}
'
}

if [[ "$1" == "remote"* ]]; then
    export RUN_PROJ=$2
    export JWM_COMMIT_ID_L=$3
    export RUN_ID=$4
    export RUN_DIR_PRE=$5
    export SERVER_NAME=$6
    cd ${RUN_PROJ} &&
        echo "start run remote.sh" &&
        { source remote.sh || {
            echo "ERROR: remote.sh failed, aborting"
            return 1
        }; } &&
        if [[ "$1" == "remote_slurm" ]]; then
            export JWM_COMMIT_ID=${JWM_COMMIT_ID_L}
            # export JWM_COMMIT_ID=$(git rev-parse HEAD)
            # if [ "${JWM_COMMIT_ID_L}" != "${JWM_COMMIT_ID}" ]; then
            #     echo "error git commit hash differ, local:  ${JWM_COMMIT_ID_L}, remote: ${JWM_COMMIT_ID}"
            #     return
            # fi
            export RUN_DIR="${RUN_DIR_PRE}/${RUN_PROJ}_runs/${RUN_ID}/"
            mkdir -p ${RUN_DIR}
            cp -R . ${RUN_DIR}
            cd ${RUN_DIR}
            if check_gpu A40 ${JWM_GPU_NUM} >/dev/null; then
                export JWM_GPU_TYPE=A40
                echo "A40 available"
            elif check_gpu T4 ${JWM_GPU_NUM} >/dev/null; then
                export JWM_GPU_TYPE=T4
                echo "T4 available"
            else
                echo "no gpu available"
                return
            fi
            echo "GPU_TYPE: $JWM_GPU_TYPE"
            echo "COMMIT:   $JWM_COMMIT_ID"
            echo "RUN_DIR:  $RUN_DIR"

            if (("${JWM_GPU_NUM}" == "0")); then
                GPU_FLAG=""
            else
                GPU_FLAG="--gpus-per-node=${JWM_GPU_TYPE}:${JWM_GPU_NUM}"
            fi
            echo ${SERVER_NAME}
            if [[ "${SERVER_NAME}" == "juwels_cluster" ]]; then
                GPU_FLAG="--gres=gpu:${JWM_GPU_NUM}"
                CPUS_PER_TASK_FLAG="--cpus-per-task=${CPUS_PER_TASK}"
            fi
            sbatch_args="--time=${JWM_RUN_TIME} --nodes=${JWM_NODES_NUM} ${GPU_FLAG} ${CPUS_PER_TASK_FLAG} --job-name=${JWM_COMMIT_ID} --output=slurm_out.log --error=slurm_out.log slurm.sh"
            echo ${sbatch_args}
            sbatch_output=$(sbatch ${sbatch_args}) || { echo "sbatch failed"; return 1; }
            echo "$sbatch_output"
            job_id=$(echo "$sbatch_output" | grep -oP '\d+$')
            echo "Job ID: $job_id"

            while ! [ -f slurm_out.log ]; do sleep 1; done

            echo "=== Showing logs for 2 minutes ==="
            timeout 120 tail -f slurm_out.log || true

            echo ""
            echo "=== Stopped live log. Waiting for job $job_id to finish ==="
            while squeue -j "$job_id" 2>/dev/null | grep -q "$job_id"; do
                sleep 30
            done

            echo "=== Job $job_id stopped or finished! ==="
            tail -n 100 slurm_out.log

            for i in 1 2 3; do
                printf '\a'
                sleep 0.3
            done
            echo "DONE: Job $job_id completed."

        elif [[ "$1" == "remote_docker" ]]; then
            echo "done"
        elif [[ "$1" == "remote_docker_compose" ]]; then
            while true; do
                status=$(docker inspect --format='{{.State.Status}}' "$container_name" 2>/dev/null)

                if [ $? -ne 0 ]; then
                    echo "ERROR: Container '$container_name' not found."
                    break
                fi

                if [ "$status" = "exited" ] || [ "$status" = "dead" ]; then
                    echo "ERROR: Container has stopped (status: $status). Check logs:"
                    break
                fi

                if [ "$status" = "restarting" ]; then
                    echo "ERROR: Container is in a restart loop. Check logs:"
                    break
                fi

                health=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null)

                if [ "$health" = "healthy" ]; then
                    echo "vLLM is ready!"
                    break
                elif [ "$health" = "unhealthy" ]; then
                    echo "ERROR: Container is unhealthy. Check logs:"
                    break
                fi

                echo "Waiting for '${container_name}' to become healthy... (container: $status, health: $health)"
                sleep 10
            done
            docker logs $container_name >tmplogs.jwm
            echo "logs is ready"
        fi
else
    # if [[ "$3" != "remote_docker" && "$3" != "remote_slurm" && "$3" != "remote_docker_compose" ]]; then
    #     echo "ERROR: \$3 must be one of 'remote_docker', 'remote_slurm', 'remote_docker_compose', got '$3'"
    #     return 1 2>/dev/null || true
    # fi
    cd $2/ &&
        while IFS= read -r pattern; do
            grep -qxF "$pattern" .gitignore 2>/dev/null || echo "$pattern" >>.gitignore
        done </Users/maojingwei/baidu/project/common_tools/common_gitignore.txt &&
        git submodule foreach 'git add -A && (git commit -m "v" || true)' &&
        git add -A &&
        (
            _staged=$(git diff --cached --name-only)
            if [[ -n "$_staged" && "$_staged" != "remote.sh" ]]; then
                git commit -m "v"
            fi
        ) &&
        last_commit=$(git rev-parse HEAD) &&
        cd - &&
        echo ${last_commit} &&
        run_timestamp="$(date +%Y%m%d_%H%M%S)" &&
        run_id="${run_timestamp}_${last_commit}" &&
        if [[ "${1}" == "juwels_cluster" || "${1}" == "juwels_booster" ]]; then
            run_dir_pre=/p/project1/trustllm-eu/mao4
        elif [[ ${1} == "custodian"* ]]; then
            run_dir_pre=/home/custodian/project_remote_jwm
        elif [[ ${1} == "alvis"* ]]; then
            run_dir_pre=/cephyr/users/shuyir/Alvis/project_remote_jwm
        else
            exit
        fi
    echo ${run_dir_pre} &&
        rsync -av --exclude-from='common_tools/rsync_exclude.txt' $2/ "$1":${run_dir_pre}/$2/ &&
        if [[ "${3}" == "sync" ]]; then
            echo "sync done"
            return
        fi &&
        rsync -av --exclude-from='common_tools/rsync_exclude.txt' common_tools/ "$1":${run_dir_pre}/common_tools/ &&
        echo """
 if false; then
     rsync -av ${1}:${run_dir_pre}/${2}_runs/${run_id}/ /Users/maojingwei/baidu/project/zzzjwmoutput/${2}_runs/${run_id}
 fi
 """ >>${2}/remote.sh &&
        ssh -t "$1" "bash --login -c 'cd ${run_dir_pre} && source common_tools/meta_script.sh $3 $2 ${last_commit} ${run_id} ${run_dir_pre} $1'"
    for i in 1 2 3; do printf '\a'; sleep 0.3; done
    echo "DONE: remote task on $1 finished."
fi
