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
    cd ${RUN_DIR_PRE}/${RUN_PROJ} &&
        echo "start run remote.sh" &&
        { source jwm_configs/remote.sh || {
            echo "ERROR: remote.sh failed, aborting"
            return 1 2>/dev/null
            exit 1
        }; } &&
        if [[ "$1" == "remote_slurm" ]]; then
            export RUN_DIR="${RUN_DIR_PRE}/${RUN_PROJ}/" &&
                export JWM_COMMIT_ID=${JWM_COMMIT_ID_L} &&
            if check_gpu A40 ${JWM_GPU_NUM} >/dev/null; then
                export JWM_GPU_TYPE=A40
                echo "A40 available"
            elif check_gpu T4 ${JWM_GPU_NUM} >/dev/null; then
                export JWM_GPU_TYPE=T4
                echo "T4 available"
            else
                echo "no gpu available"
                return 2>/dev/null
                exit 1
            fi
            echo "GPU_TYPE: $JWM_GPU_TYPE"
            echo "COMMIT:   $JWM_COMMIT_ID"
            echo "RUN_DIR:  $RUN_DIR"

            if (("${JWM_GPU_NUM}" == "0")); then
                GPU_FLAG="--constraint=NOGPU"
            else
                GPU_FLAG="--gpus-per-node=${JWM_GPU_TYPE}:${JWM_GPU_NUM}"
            fi
            echo ${SERVER_NAME}
            if [[ "${SERVER_NAME}" == "juwels_cluster" ]]; then
                GPU_FLAG="--gres=gpu:${JWM_GPU_NUM}"
                CPUS_PER_TASK_FLAG="--cpus-per-task=${CPUS_PER_TASK}"
            fi
            sbatch_args="--time=${JWM_RUN_TIME} --nodes=${JWM_NODES_NUM} ${GPU_FLAG} ${CPUS_PER_TASK_FLAG} --job-name=${JWM_COMMIT_ID} --output=slurm_out.log --error=slurm_out.log --open-mode=append slurm.sh"
            echo ${sbatch_args}
            SBATCH_OUT=$(sbatch ${sbatch_args}) || {
                return 1 2>/dev/null
                exit 1
            }
            echo "${SBATCH_OUT}"
            SLURM_JOB_ID=$(echo "${SBATCH_OUT}" | awk '{print $NF}')
            echo "$SLURM_JOB_ID" >"${RUN_DIR}/remote_job_id.txt"

        elif [[ "$1" == "remote_" ]]; then
            echo "remote.sh completed — agent deployed"
        elif [[ "$1" == "remote_docker" ]]; then
            echo "$JWM_CONTAINER_ID" >"${RUN_DIR_PRE}/${RUN_PROJ}/remote_job_id.txt"
            echo "docker_container_started"
        elif [[ "$1" == "remote_docker_compose" ]]; then
            _docker_since=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
            _compose_dir="${COMPOSE_DIR:-${RUN_DIR_PRE}/${RUN_PROJ}}"
            _arch_rebuilt=false

            while true; do
                mapfile -t _containers < <(docker compose -f "${_compose_dir}/docker-compose.yml" ps -a --format '{{.Name}}' 2>/dev/null)
                if [ ${#_containers[@]} -eq 0 ]; then
                    echo "ERROR: No containers found for compose project in ${_compose_dir}."
                    break
                fi

                _all_healthy=true
                _any_failed=false
                _failed_container=""

                printf "\n--- Container Status ($(date +%H:%M:%S)) ---\n"
                printf "%-30s %-12s %-12s\n" "CONTAINER" "STATUS" "HEALTH"
                printf "%-30s %-12s %-12s\n" "-----" "------" "------"

                for _cname in "${_containers[@]}"; do
                    _cstatus=$(docker inspect --format='{{.State.Status}}' "$_cname" 2>/dev/null) || _cstatus="not_found"
                    _chealth=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no_healthcheck{{end}}' "$_cname" 2>/dev/null) || _chealth="unknown"
                    _cerror=$(docker inspect --format='{{.State.Error}}' "$_cname" 2>/dev/null) || _cerror=""

                    printf "%-30s %-12s %-12s\n" "$_cname" "$_cstatus" "$_chealth"

                    if [[ "$_cstatus" == "exited" || "$_cstatus" == "dead" || "$_cstatus" == "restarting" || "$_chealth" == "unhealthy" ]]; then
                        _any_failed=true
                        _failed_container="$_cname"
                    fi

                    if [[ "$_cstatus" == "created" && -n "$_cerror" ]]; then
                        _any_failed=true
                        _failed_container="$_cname"
                    fi

                    if [[ "$_chealth" != "healthy" && "$_chealth" != "no_healthcheck" ]]; then
                        _all_healthy=false
                    fi
                    if [[ "$_cstatus" != "running" ]]; then
                        _all_healthy=false
                    fi
                done

                if $_any_failed; then
                    echo ""
                    _cfailed_error=$(docker inspect --format='{{.State.Error}}' "$_failed_container" 2>/dev/null)
                    if [[ -n "$_cfailed_error" ]]; then
                        echo "ERROR: Container '${_failed_container}' failed to start: ${_cfailed_error}"
                        break
                    fi
                    _cfailed_logs=$(docker logs --since "$_docker_since" --tail 80 "$_failed_container" 2>&1)
                    if ! $_arch_rebuilt && echo "$_cfailed_logs" | grep -q "No supported CUDA architectures found"; then
                        echo "CUDA arch error detected in '${_failed_container}' — rebuilding image..."
                        docker rm -f "$_failed_container" 2>/dev/null || true
                        docker compose -f "${_compose_dir}/docker-compose.yml" up --build -d
                        _arch_rebuilt=true
                        _docker_since=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
                        sleep 5
                        continue
                    fi
                    echo "ERROR: Container '${_failed_container}' is in a bad state. Logs:"
                    echo "$_cfailed_logs"
                    break
                fi

                if $_all_healthy; then
                    echo ""
                    echo "All services are ready!"
                    break
                fi

                echo "Waiting for all services to become healthy..."
                sleep 10
            done
        fi
else
    # if [[ "$3" != "remote_docker" && "$3" != "remote_slurm" && "$3" != "remote_docker_compose" ]]; then
    #     echo "ERROR: \$3 must be one of 'remote_docker', 'remote_slurm', 'remote_docker_compose', got '$3'"
    #     return 1 2>/dev/null || true
    # fi
    if [[ "$1" == "localmachine" ]]; then
        last_commit="local"
    else
        cd $2/ &&
            while IFS= read -r pattern; do
                grep -qxF "$pattern" .gitignore 2>/dev/null || echo "$pattern" >>.gitignore
            done </Users/maojingwei/baidu/project/common_tools/common_gitignore.txt &&
            git submodule foreach 'git add -A && (git commit -m "v" || true)' &&
            git add -A &&
            (
                _staged=$(git diff --cached --name-only)
                _non_config=$(echo "$_staged" | grep -v "^jwm_configs/")
                if [[ -n "$_staged" && -n "$_non_config" ]]; then
                    git commit -m "v"
                fi
            ) &&
            last_commit=$(git rev-parse HEAD) &&
            cd - &&
            echo ${last_commit}
    fi &&
        run_timestamp="$(date +%Y%m%d_%H%M%S)" &&
        run_id="${run_timestamp}_${last_commit}" &&
        if [[ "${1}" == "juwels_cluster" || "${1}" == "juwels_booster" ]]; then
            run_dir_pre=/p/project1/trustllm-eu/mao4
        elif [[ ${1} == "custodian"* ]]; then
            run_dir_pre=/home/custodian/project_remote_jwm
        elif [[ ${1} == "alvis"* ]]; then
            run_dir_pre=/cephyr/users/shuyir/Alvis/project_remote_jwm
        elif [[ "${1}" == "localmachine" ]]; then
            run_dir_pre=$(pwd)
        else
            exit
        fi
    # Remote dir is always <project>_<branch> so it's clear which branch is running.
    # e.g. gpu_commander on main -> gpu_commander_main, on dev -> gpu_commander_dev
    _git_branch=$(git -C $2 rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)
    _remote_proj="${2}_${_git_branch}"
    echo "Branch: ${_git_branch} → remote dir: ${_remote_proj}" &&
    echo ${run_dir_pre} &&
        { [[ "$1" == "localmachine" ]] || ssh -o ConnectTimeout=10 -o BatchMode=yes "$1" true; } &&
        { [[ -f "$2/jwm_configs/local.sh" ]] && source "$2/jwm_configs/local.sh" pre "$1" || true; } &&
    if [[ "$1" == "localmachine" ]]; then
        # No rsync — project is already local; point run_dir_remote at the source dir
        run_dir_remote="${run_dir_pre}/$2"
        local_dir="${run_dir_pre}/zzzjwmoutput/${_remote_proj}"
    elif [[ "$3" == "remote_slurm" ]]; then
        run_dir_remote="${run_dir_pre}/${_remote_proj}_runs/${run_id}"
        local_dir="/Users/maojingwei/baidu/project/zzzjwmoutput/${_remote_proj}_runs/${run_id}"
        ssh "$1" "mkdir -p ${run_dir_pre}/${_remote_proj}_runs"
    else
        run_dir_remote="${run_dir_pre}/${_remote_proj}"
        local_dir="/Users/maojingwei/baidu/project/zzzjwmoutput/${_remote_proj}"
    fi &&
    if [[ "$1" != "localmachine" ]]; then
        rsync -av --exclude-from='common_tools/rsync_exclude.txt' $2/ "$1":${run_dir_remote}/ &&
        if [[ "${3}" == "sync" ]]; then
            echo "sync done"
            return
        fi &&
        rsync -av --exclude-from='common_tools/rsync_exclude.txt' common_tools/ "$1":${run_dir_pre}/common_tools/
    fi &&
    mkdir -p "$local_dir"
    local nohup_log="${local_dir}/nohup_monitor.log"

    if [[ "$3" == "remote_slurm" ]]; then
        log_file="${run_dir_remote}/slurm_out.log"
        local_log="${local_dir}/slurm_out.log"
        echo "Running remote setup + sbatch..."
        if ! ssh "$1" "bash --login ${run_dir_pre}/common_tools/meta_script.sh $3 ${_remote_proj}_runs/${run_id} ${last_commit} ${run_id} ${run_dir_pre} $1"; then
            echo "FAILED: remote setup/sbatch on $1 failed."
        else
            remote_job_id=$(ssh "$1" "cat ${run_dir_remote}/remote_job_id.txt" 2>/dev/null)
            if [[ -z "$remote_job_id" ]]; then
                echo "FAILED: could not read remote_job_id.txt from ${run_dir_remote}."
            else
                echo ${local_dir}
                echo "Launching background monitor for job $remote_job_id (log: $nohup_log)"
                nohup bash /Users/maojingwei/baidu/project/common_tools/remote_monitor.sh slurm "$1" "$remote_job_id" "$log_file" "$local_log" "$run_dir_pre" "$run_id" "${_remote_proj}" >"$nohup_log" 2>&1 &
                echo "Background monitor PID: $!"
            fi
        fi
    else
        remote_nohup_log="${run_dir_remote}/nohup_remote.log"
        remote_pid_file="${run_dir_remote}/remote_job.pid"
        local_log="${local_dir}/nohup_remote.log"

        if [[ "$3" == "remote_docker_compose" ]]; then
            local ports_before="${local_dir}/ports_before.txt"
            if [[ "$1" == "localmachine" ]]; then
                ss -tlnp 2>/dev/null | grep -oE '0\.0\.0\.0:[0-9]+' | awk -F: '{print $2}' | sort -un >"$ports_before" || true
            else
                ssh "$1" "ss -tlnp 2>/dev/null" | grep -oE '0\.0\.0\.0:[0-9]+' | awk -F: '{print $2}' | sort -un >"$ports_before" || true
            fi
        fi

        echo "Launching task as background job..."
        if [[ "$1" == "localmachine" ]]; then
            mkdir -p "${run_dir_remote}"
            nohup bash --login -c "cd ${run_dir_pre} && source common_tools/meta_script.sh $3 $2 ${last_commit} ${run_id} ${run_dir_pre} localmachine" >"${remote_nohup_log}" 2>&1 &
            echo $! >"${remote_pid_file}"
            remote_pid=$(cat "${remote_pid_file}")
        else
            ssh "$1" "mkdir -p ${run_dir_remote} && nohup bash --login ${run_dir_pre}/common_tools/meta_script.sh $3 ${_remote_proj} ${last_commit} ${run_id} ${run_dir_pre} $1 >${remote_nohup_log} 2>&1 & echo \$! >${remote_pid_file}" &&
                remote_pid=$(ssh "$1" "cat ${remote_pid_file} 2>/dev/null")
        fi
        echo "Job PID: ${remote_pid}"
        echo "Local log: ${local_log}"

        local monitor_args=(pid "$1" "$remote_pid" "$remote_nohup_log" "$local_log")
        if [[ "$3" == "remote_docker_compose" ]]; then
            monitor_args+=(port_forward "$ports_before")
        fi
        echo ${local_dir}
        echo "Launching background monitor for PID $remote_pid (log: $nohup_log)"
        nohup bash /Users/maojingwei/baidu/project/common_tools/remote_monitor.sh "${monitor_args[@]}" >"$nohup_log" 2>&1 &
        echo "Background monitor PID: $!"
    fi

    if [[ -f "$2/jwm_configs/local.sh" ]]; then
        echo "Running $2/jwm_configs/local.sh after hook..."
        source "$2/jwm_configs/local.sh" after "$1"
    fi
fi
