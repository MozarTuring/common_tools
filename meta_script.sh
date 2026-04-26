set -e
sync_and_commit_repo() {
    local repo_path="$1"
    cd "$repo_path"
    while IFS= read -r pattern; do
        grep -qxF "$pattern" .gitignore 2>/dev/null || echo "$pattern" >>.gitignore
    done </Users/maojingwei/baidu/project/common_tools/common_gitignore.txt
    git submodule foreach 'git add -A && (git commit -m "v" || true)'
    git add -A
    (
        _staged=$(git diff --cached --name-only)
        _non_config=$(echo "$_staged" | grep -v "^jwm_configs/" || true)
        if [[ -n "$_staged" && -n "$_non_config" ]]; then
            git commit -m "v"
            git push origin
        fi
    )
    last_commit=$(git rev-parse HEAD)
    if [[ -n "$SERVER_NAME" ]]; then
        _git_branch=$(git -C ./ rev-parse --abbrev-ref HEAD 2>/dev/null)
        _remote_proj="${repo_path}_${_git_branch}"
        echo "remote dir: ${_remote_proj}"
        echo "${run_dir_pre}"
        run_dir_remote="${run_dir_pre}/${_remote_proj}"
        rsync -av --exclude-from='/Users/maojingwei/baidu/project/common_tools/rsync_exclude.txt' ./ "$SERVER_NAME":${run_dir_remote}/
    fi
    local _sync_rc=$?
    cd - >/dev/null
    return $_sync_rc
}

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

_remote_setup() {
    echo "$1, $2, $3, $4"
    export RUN_DIR_PRE="$4"
    export RUN_PROJ="$2"
    export JWM_COMMIT_ID_L="$3"
    export SERVER_NAME="${5##*@}"
    _manual_file="${6:-remote_manual.sh}"
    cd "$4"/"$2"
    remote_job_id_file=${RUN_DIR_PRE}/${RUN_PROJ}/"remote_job_id.txt"
    rm ${remote_job_id_file} 2>/dev/null || true
    export HUGGING_FACE_HUB_TOKEN="${HUGGING_FACE_HUB_TOKEN:-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}"
    export HF_TOKEN="${HF_TOKEN:-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}"

    echo """
set -e
export JWM_DATA_DIR=\${RUN_DIR_PRE}/remote_data/\${RUN_PROJ}
export PYTHONUNBUFFERED=1

""" >jwm_configs/remote.sh
    cat jwm_configs/${_manual_file} >>jwm_configs/remote.sh
}

if [[ $# -eq 1 && "$1" != "remote"* ]]; then
    _abspath="$1"
    _filename=$(basename "$_abspath")
    _project_dir=$(dirname "$(dirname "$_abspath")")
    _project_name=$(basename "$_project_dir")
    _stem="${_filename%.sh}"
    _server="${_stem%%_*}"
    _rest="${_stem#*_}"
    _mode="${_rest%%_*}"

    case "$_mode" in
        remoteslurm|remotedocker|remotedockercompose|remote) ;;
        *) echo "ERROR: unknown mode '$_mode' from filename '$_filename'"; exit 1 ;;
    esac

    export SERVER_NAME="$_server"
    _manual_file="$_filename"
    if [[ "${SERVER_NAME}" == "juwels" || "${SERVER_NAME}" == "jusuf" ]]; then
        export run_dir_pre=/p/project1/trustllm-eu/mao4
    elif [[ ${SERVER_NAME} == "custodian@"* ]]; then
        export run_dir_pre=/home/custodian/project_remote_jwm
    elif [[ ${SERVER_NAME} == "ferragon" || ${SERVER_NAME} == "greatrawr" ]]; then
        export run_dir_pre=/home/jinma/project_remote_jwm
    elif [[ ${SERVER_NAME} == "alvis"* ]]; then
        export run_dir_pre=/cephyr/users/shuyir/Alvis/project_remote_jwm
    elif [[ ${SERVER_NAME} == "berzelius"* ]]; then
        export run_dir_pre=/home/x_jinma/project_remote_jwm
    else
        echo "ERROR: unknown server '$SERVER_NAME'"
        exit 1
    fi

    cd /Users/maojingwei/baidu/project/
    ssh -o ConnectTimeout=10 -o BatchMode=yes "$SERVER_NAME" true

    sync_and_commit_repo "common_tools"
    sync_and_commit_repo "$_project_name"

    { [[ -f "$_project_name/jwm_configs/local_pre.sh" ]] && source "$_project_name/jwm_configs/local_pre.sh" || true; }

    echo ${last_commit}
    local_dir="/Users/maojingwei/baidu/project/zzzjwmoutput/${_remote_proj}"
    if [[ "$_mode" == "remoteslurm" ]]; then
        run_timestamp="$(date +%Y%m%d_%H%M%S)"
        run_id="${run_timestamp}_${last_commit}"
        local_dir="${local_dir}/${run_id}"
    fi
    mkdir -p "$local_dir"
    if [[ "$_mode" == "remotedockercompose" ]]; then
        ports_before="${local_dir}/ports_before.txt"
        ssh "$SERVER_NAME" "ss -tlnp 2>/dev/null" | grep -oE '0\.0\.0\.0:[0-9]+' | awk -F: '{print $2}' | sort -un >"$ports_before" || true
    fi

    nohup_log="${local_dir}/nohup_monitor.log"

    echo "Running remote setup... (output: $nohup_log)"
    ssh "$SERVER_NAME" "mkdir -p ${run_dir_remote} && bash --login ${run_dir_pre}/common_tools_master/meta_script.sh ${_mode} ${run_dir_remote#${run_dir_pre}/} ${last_commit} ${run_dir_pre} $SERVER_NAME ${_manual_file}" 2>&1 | tee "$nohup_log"

    if [[ "$_mode" == "remotedockercompose" ]]; then
        echo "local dir: ${local_dir}"
        pkill -f "ssh.*ControlPath=none.*-N.*$SERVER_NAME" 2>/dev/null && echo "Killed existing SSH tunnel to $SERVER_NAME" || true
        ports_after=$(
            ssh "$SERVER_NAME" "ss -tlnp 2>/dev/null" |
                { grep -oE '0\.0\.0\.0:[0-9]+' || true; } |
                awk -F: '$2 >= 1024 {print $2}' |
                sort -un
        )
        ports=()
        while IFS= read -r p; do
            [[ -n "$p" ]] && ports+=("$p")
        done < <(comm -23 <(echo "$ports_after") <(cat "$ports_before" 2>/dev/null || true))
        if [[ ${#ports[@]} -gt 0 ]]; then
            ssh_args=(-o ControlPath=none -N -f)
            for p in "${ports[@]}"; do
                ssh_args+=(-L "${p}:localhost:${p}")
            done
            echo "New ports from this run: ${ports[*]}"
            echo "ssh ${ssh_args[*]} $SERVER_NAME"
            ssh "${ssh_args[@]}" "$SERVER_NAME" || echo "WARNING: SSH tunnel failed (port conflict?)"
        else
            echo "No new ports detected from this run."
        fi
        exit 0
    fi

    if [[ "$_mode" == "remote" ]]; then
        echo "local dir: ${local_dir}"
        exit 0
    fi

    remote_job_id=$(ssh "$SERVER_NAME" "cat ${run_dir_remote}/remote_job_id.txt" 2>/dev/null)

    if [ -n "${remote_job_id}" ]; then
        echo "Remote job ID: $remote_job_id"
        echo "local dir: ${local_dir}"

        if [[ "$_mode" == "remoteslurm" ]]; then
            monitor_args=(slurm "$SERVER_NAME" "$remote_job_id" "$run_dir_remote" "$local_dir" "$run_dir_pre" "$run_id" "${_remote_proj}")
        elif [[ "$_mode" == "remotedocker" ]]; then
            monitor_args=(docker "$SERVER_NAME" "$remote_job_id" "$run_dir_remote" "$local_dir")
        else
            monitor_args=(pid "$SERVER_NAME" "$remote_job_id" "$run_dir_remote" "$local_dir")
            if [[ "$_mode" == "remotedockercompose" ]]; then
                monitor_args+=(port_forward "$ports_before")
            fi
        fi

        echo "Launching background monitor for $remote_job_id (log: $nohup_log)"
        nohup bash /Users/maojingwei/baidu/project/common_tools/remote_monitor.sh "${monitor_args[@]}" >>"$nohup_log" 2>&1 &
        monitor_pid=$!
        echo "Background monitor PID: $monitor_pid"

        if [[ -f "$_project_name/jwm_configs/local_after.sh" ]]; then
            source "$_project_name/jwm_configs/local_after.sh" "$SERVER_NAME"
        fi

        echo "datetime_seconds: $(date +%Y%m%d_%H%M%S)"
        tail -f "$nohup_log" &
        tail_pid=$!
        while kill -0 "$monitor_pid" 2>/dev/null; do
            sleep 1
        done
        kill "$tail_pid" 2>/dev/null
        wait "$tail_pid" 2>/dev/null || true
        echo "remote_monitor (PID $monitor_pid) exited, stopping log tail."
    else
        echo "FAILED: remote setup on $SERVER_NAME failed."
    fi

elif [[ "$1" == "remoteslurm" ]]; then
    _remote_setup "$@"
    touch ".slurm_submit_marker"
    cat >>jwm_configs/remote.sh <<'EOF'

if [[ -z "${SBATCH_OUT:-}" ]]; then
if [[ -z ${JWM_SLURM_FILE} || -z ${JWM_RUN_TIME} || -z ${JWM_NODES_NUM} ]]; then
    echo "not defined"
    exit
fi
sbatch_args="--time=${JWM_RUN_TIME} --nodes=${JWM_NODES_NUM} --output=slurm-%j.out --error=slurm-%j.out"&&
EOF
    # EOF has to be at the start of a line, without anything before it, not even white characters
    if [[ "${5}" == "berzeliusAmpere" ]]; then
        cat >>jwm_configs/remote.sh <<'EOF'
sbatch_args="${sbatch_args} --gpus=${JWM_GPU_NUM} --cpus-per-task=${CPUS_PER_TASK} --mem=${MEM_PER_TASK} --signal=TERM@90 -A berzelius-2026-50 --partition=berzelius"
EOF

    elif [[ "${5}" == "jusuf" ]]; then
        cat >>jwm_configs/remote.sh <<'EOF'
sbatch_args="${sbatch_args} --cpus-per-task=${CPUS_PER_TASK} --mem=${MEM_PER_TASK} --partition=batch -A trustllm-eu"
EOF
    else
        cat >>jwm_configs/remote.sh <<'EOF'
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

        if (("${JWM_GPU_NUM}" == "0")); then
            GPU_FLAG="--constraint=NOGPU"
        else
            GPU_FLAG="--gpus-per-node=${JWM_GPU_TYPE}:${JWM_GPU_NUM}"
        fi
        if [[ "${SERVER_NAME}" == "juwelscluster" ]]; then
            GPU_FLAG="--gres=gpu:${JWM_GPU_NUM}"
            CPUS_PER_TASK_FLAG="--cpus-per-task=${CPUS_PER_TASK}"
        fi
        sbatch_args="${sbatch_args} ${GPU_FLAG} ${CPUS_PER_TASK_FLAG}"
EOF

    fi
    cat >>jwm_configs/remote.sh <<'EOF'

echo ${sbatch_args} ${JWM_SLURM_FILE}
SBATCH_OUT=$(sbatch ${sbatch_args} ${JWM_SLURM_FILE}) || {
    return 1 2>/dev/null
    exit 1
}
fi
EOF

    echo "start run remote.sh"
    source jwm_configs/remote.sh
    SLURM_JOB_ID=$(echo "${SBATCH_OUT}" | awk '{print $NF}')
    echo "${PWD}, ${SLURM_JOB_ID}"
    echo "$SLURM_JOB_ID" >${remote_job_id_file}

elif [[ "$1" == "remotedockercompose" ]]; then
    _remote_setup "$@"
    source jwm_configs/remote.sh
    cd - >/dev/null
    _compose_dir="${COMPOSE_DIR:-${RUN_DIR_PRE}/${RUN_PROJ}}"
    trap 'echo "Cancelled — stopping containers..."; docker compose -f "${_compose_dir}/docker-compose.yml" down 2>/dev/null && echo "Containers stopped and removed." || echo "Warning: failed to stop containers."; exit 1' SIGTERM SIGINT
    _docker_since=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    _has_rebuilt=false

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
            _cfailed_logs=$(docker logs --since "$_docker_since" --tail 300 "$_failed_container" 2>&1)
            if ! $_has_rebuilt && echo "$_cfailed_logs" | grep -qE "No supported CUDA architectures found|ModuleNotFoundError|ImportError|AttributeError"; then
                echo "Recoverable error detected in '${_failed_container}' — rebuilding image..."
                docker rm -f "$_failed_container" 2>/dev/null || true
                docker compose -f "${_compose_dir}/docker-compose.yml" build --no-cache 2>&1 && docker compose -f "${_compose_dir}/docker-compose.yml" up --force-recreate -d 2>&1
                _has_rebuilt=true
                _docker_since=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
                sleep 5
                continue
            fi
            echo "ERROR: Container '${_failed_container}' is in a bad state. Logs:"
            echo "$_cfailed_logs"
            break
        fi

        if ! $_any_failed; then
            for _cname in "${_containers[@]}"; do
                _crestart=$(docker inspect --format='{{.RestartCount}}' "$_cname" 2>/dev/null) || _crestart=0
                if [[ "$_crestart" -ge 3 ]]; then
                    _any_failed=true
                    _failed_container="$_cname"
                    echo "Container '${_cname}' has restarted ${_crestart} times — treating as failed."
                    _cfailed_logs=$(docker logs --since "$_docker_since" --tail 300 "$_failed_container" 2>&1)
                    if ! $_has_rebuilt && echo "$_cfailed_logs" | grep -qE "No supported CUDA architectures found|ModuleNotFoundError|ImportError|AttributeError"; then
                        echo "Recoverable error detected in '${_failed_container}' — rebuilding image..."
                        docker rm -f "$_failed_container" 2>/dev/null || true
                        docker compose -f "${_compose_dir}/docker-compose.yml" build --no-cache 2>&1 && docker compose -f "${_compose_dir}/docker-compose.yml" up --force-recreate -d 2>&1
                        _has_rebuilt=true
                        _docker_since=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
                        sleep 5
                        break
                    fi
                    echo "ERROR: Container '${_failed_container}' is crash-looping. Logs:"
                    echo "$_cfailed_logs"
                    break 2
                fi
            done
            if $_any_failed; then continue; fi
        fi

        if $_all_healthy; then
            echo ""
            echo "All services are ready!"
            _after_hook="jwm_configs/remote_after.sh"
            if [[ -f "$_after_hook" ]]; then
                source "$_after_hook"
            fi
            break
        fi

        echo "Waiting for all services to become healthy..."
        sleep 10
    done

elif [[ "$1" == "remotedocker" ]]; then
    _remote_setup "$@"
    source jwm_configs/remote.sh
    echo "$JWM_CONTAINER_ID" >"remote_job_id.txt"
    echo "docker_container_started"

elif [[ "$1" == "remote" ]]; then
    _remote_setup "$@"
    source jwm_configs/remote.sh
    echo "remote.sh completed — agent deployed"

else
    echo "ERROR: unrecognized arguments. Usage:"
    echo "  meta_script.sh /path/to/project/jwm_configs/<server>_<mode>.sh"
    echo "  (remote-side call is handled internally)"
    exit 1
fi
