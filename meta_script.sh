#!/bin/bash

set -e
sync_and_commit_repo() {
    local repo_path="$1"
    cd "$repo_path"
    git show-ref --verify --quiet refs/heads/jingwei && echo "Branch jingwei already exists, skipping rename." || (git branch -m jingwei && echo "Branch renamed to jingwei")

    while IFS= read -r pattern; do
        grep -qxF "$pattern" .gitignore 2>/dev/null || echo "$pattern" >>.gitignore
    done <~/project/common_tools/common_gitignore.txt
    git submodule foreach 'git add -A && (git commit -m "v" || true)'
    git add -A >/dev/null
    (
        _staged=$(git diff --cached --name-only)
        _non_config=$(echo "$_staged" | grep -v "^jwm_configs/" || true)
        if [[ -n "$_staged" && -n "$_non_config" ]]; then
            git commit -m "v" >/dev/null
            tmpbranch=$(git branch --show-current)
            if [[ ${tmpbranch} == "jingwei"* ]]; then
                git push origin -u ${tmpbranch} >/dev/null
            fi
        fi
    )
    last_commit=$(git rev-parse HEAD)
    if [[ -n "$server_name" ]]; then
        _git_branch=$(git -C ./ rev-parse --abbrev-ref HEAD 2>/dev/null)
        _remote_proj="${repo_path}_${_git_branch}"
        run_dir_remote="${run_dir_home}/project_remote_jwm/${_remote_proj}"
        echo "remote dir: ${run_dir_remote}"
        if [[ ${_remote_proj} == "vllm_service" ]]; then
            strings=("greatrawr" "ferragon")
            for server_name in "${strings[@]}"; do
                rsync -a --exclude-from="$HOME/project/common_tools/rsync_exclude.txt" ./ "$server_name":${run_dir_remote}/
            done
        else
            rsync -a --exclude-from="$HOME/project/common_tools/rsync_exclude.txt" ./ "$server_name":${run_dir_remote}/
        fi
    fi
    local _sync_rc=$?
    cd - >/dev/null
    return $_sync_rc
}

if false; then
    sudo chmod -R a+rwX /data/huggingface_cache
    sudo setfacl -R -m u:jinma:rwx,u:custodian:rwx /data/huggingface_cache
    sudo setfacl -R -d -m u:jinma:rwx,u:custodian:rwx /data/huggingface_cache
fi


slurm_job_status() {
    while true; do
        sleep 10

        all_states=$("$1" squeue --job="${1}" --noheader -o '%T' 2>/dev/null)
        if [[ -z "$all_states" ]]; then
            echo "Job no longer in queue (may have finished or failed instantly)."
            break
        fi

        # Format the state counts safely handling multiple lines
        state_counts=$(echo "$all_states" | sort | uniq -c | awk '{printf "%s=%s ", $2, $1} END {print ""}')

        if echo "$all_states" | grep -q "RUNNING"; then
            # Optional: Only break if NO parts of the job are left pending
            if ! echo "$all_states" | grep -q "PENDING"; then
                echo "Job is now fully RUNNING."
                echo "  $state_counts"
                break
            else
                echo "$(date '+%H:%M:%S') - Job partially running: $state_counts"
            fi
        else
            echo "$(date '+%H:%M:%S') - $state_counts"
        fi
    done
}

export -f slurm_job_status

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

dockerfile_to_def() {
    local infile="$1" outfile="$2"
    local from_image="" workdir="/app"
    local envs=() runs=()
    local continued=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ -n "$continued" ]]; then
            line="${line#"${line%%[![:space:]]*}"}"
            continued="${continued%\\}"
            continued="${continued% }"
            continued="${continued} ${line}"
            if [[ ! "$line" =~ \\[[:space:]]*$ ]]; then
                continued="${continued%\\}"
                continued="${continued% }"
                runs+=("${continued}")
                continued=""
            fi
            continue
        fi
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// /}" ]] && continue
        if [[ "$line" =~ ^FROM[[:space:]]+(.*) ]]; then
            from_image="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^ENV[[:space:]]+(.*) ]]; then
            envs+=("${BASH_REMATCH[1]}")
        elif [[ "$line" =~ ^RUN[[:space:]]+(.*) ]]; then
            local cmd="${BASH_REMATCH[1]}"
            if [[ "$cmd" =~ \\[[:space:]]*$ ]]; then
                continued="$cmd"
            else
                runs+=("$cmd")
            fi
        elif [[ "$line" =~ ^WORKDIR[[:space:]]+(.*) ]]; then
            workdir="${BASH_REMATCH[1]}"
        fi
    done <"$infile"

    {
        echo "Bootstrap: docker"
        echo "From: ${from_image}"
        echo ""
        if [[ ${#envs[@]} -gt 0 ]]; then
            echo "%environment"
            for e in "${envs[@]}"; do
                echo "    export $e"
            done
            echo ""
        fi
        echo "%post"
        for r in "${runs[@]}"; do
            echo "    $r"
        done
        echo "    mkdir -p ${workdir}"
    } >"$outfile"
    echo "Generated def file: $outfile (from $infile)"
}

_remote_setup() {
    source ${RUN_DIR_HOME}/project_remote_jwm/common_tools_jingwei/common_tokens.sh
    export JWM_DATA_DIR=${RUN_DIR_HOME}/project_remote_jwm/remote_data/"${RUN_PROJ%_*}"
    mkdir -p ${RUN_DIR_HOME}/project_remote_jwm/${RUN_PROJ}/jwm_configs/${JWM_MODE}/remote_tmps
    mkdir -p ${JWM_DATA_DIR}

    if [[ -d /data && ${JWM_MODE} == "remotedocker"* ]]; then
        # failure inside the if block will just not stop, regardless of set -e
        mkdir -p /data/huggingface_cache
        mkdir -p ${RUN_DIR_HOME}/.cache
        tmpcache=${RUN_DIR_HOME}/.cache/huggingface
        if [[ ! -L ${tmpcache} ]]; then
            echo "create link ${tmpcache}"
            false || { docker run --rm -v ${tmpcache}:/mnt alpine rm -rf /mnt && ln -s /data/docker ${tmpcache} && echo "hard remove, check"; }
            # if using () here, will create a subshell, and exit only exit subshell
        fi

        mkdir -p /data/docker
        mkdir -p ${RUN_DIR_HOME}/.local/share
        tmpcache=${RUN_DIR_HOME}/.local/share/docker
        if [[ ! -L ${tmpcache} ]]; then
            echo "create link ${tmpcache}"
            systemctl --user stop docker && rootlesskit rm -rf ~/.local/share/docker && ln -s /data/docker ${tmpcache} && systemctl --user restart docker && echo "hard remove, check"
        fi
    fi
    cd ${RUN_DIR_HOME}/project_remote_jwm/${RUN_PROJ}
    mkdir -p jwmlogs/${JWM_RUN_START_TIME}
    mkdir -p jwm_configs/${JWM_MODE}/remote_tmps
    sleep 1
    cat >jwm_configs/${JWM_MODE}/remote_tmps/remote.sh <<'EOF'
set -e

require_env() {
for var in "$@"; do
    if [ -z "${!var}" ]; then
        echo "Error: $var is not set" >&2
        exit 1
    fi
done
}


EOF

    export RUN_BACKGROUND_JWM=1
    # no '' around EOF, it will expand vars
    cat >>jwm_configs/${JWM_MODE}/remote_tmps/remote.sh <<EOF
# change the following based on your running preference
export RUN_DIR_HOME="${RUN_DIR_HOME}"
export RUN_PROJ="${RUN_PROJ}"

EOF

    # echo "${JWM_RUN_DIR_REMOTE}, ${PWD}"
    # if [[ ${JWM_RUN_DIR_REMOTE} != "${PWD}" ]]; then
    #     cp -R . ${JWM_RUN_DIR_REMOTE}/
    #     cd ${JWM_RUN_DIR_REMOTE}
    # fi

    if [[ ${JWM_MODE} == "remotedocker" ]]; then
        cat >>jwm_configs/${JWM_MODE}/remote_tmps/remote.sh <<'EOF'
export JWM_CACHE_DIR=${RUN_DIR_HOME}/.cache
export PYTHONUNBUFFERED=1
EOF
    fi

    # ~/miniconda3/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && ~/miniconda3/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
    if [[ ${JWM_MODE} == "remotenone" ]]; then
        cat >>jwm_configs/${JWM_MODE}/remote_tmps/remote.sh <<'EOF'
eval "$(${RUN_DIR_HOME}/miniconda3/bin/conda shell.bash hook)"

if [ -n ${JWM_ENVS} ]; then
    if [ ! -d ${JWM_ENVS} ]; then
        conda create -p ${JWM_ENVS} python=3.11 -y
    fi
    conda activate ${JWM_ENVS}
    which python
    which pip
    if [ ! -d ${RUN_DIR_HOME}/jwmcondaenv/shared_cuda ]; then
        conda create -y -p ${RUN_DIR_HOME}/jwmcondaenv/shared_cuda -c nvidia cuda-toolkit
    fi
    export CUDA_HOME=${RUN_DIR_HOME}/jwmcondaenv/shared_cuda
    export PATH=${CUDA_HOME}/bin:${PATH}
    export CPATH=${CUDA_HOME}/targets/x86_64-linux/include:${CPATH}
    export LD_LIBRARY_PATH=${CUDA_HOME}/targets/x86_64-linux/lib:${LD_LIBRARY_PATH}
fi


EOF
    fi

    if [[ ${JWM_MODE} == "remotedockercompose" ]]; then
        cat >>jwm_configs/${JWM_MODE}/remote_tmps/remote.sh <<'EOF'
# uncomment the following to define them based on your running preference
# export HF_TOKEN="fill in your huggingface token"

EOF
    fi
    # if [[ ${JWM_MODE} == "remotedocker" ]]; then
    #     eval "$(grep '^JWM_CONTAINERS=' "jwm_configs/${JWM_MODE}/remote_tmps/${_manual_file}" | tail -1)"
    #     clearflag=0
    #     for _ctn in "${JWM_CONTAINERS[@]}"; do
    #         echo "removing ${_ctn}"
    #         docker rm -f "${_ctn}"
    #         clearflag=1
    #     done
    #     if [[ ${clearflag} == 1 ]]; then
    #         echo "waiting for clearing"
    #         sleep 30
    #     fi
    # fi
    touch ".submit_marker"

    cat jwm_configs/${JWM_MODE}/remote_tmps/${_manual_file} >>jwm_configs/${JWM_MODE}/remote_tmps/remote.sh
    # sed -i '/^# JWM_SERVER_NAME=/d' jwm_configs/${JWM_MODE}/remote_tmps/remote.sh

}

if [[ $# -lt 3 ]]; then
    echo "JWM_RUN_START_TIME, ${JWM_RUN_START_TIME}"
    trap 'echo "ERROR: command failed at line $LINENO (exit code $?)" >&2' ERR
    echo "abspath, $1"
    _manual_file=$(basename "$1")
    echo "filename, $_manual_file"
    _project_dir=$(cd "$(dirname "$1")"/../../../ && pwd)

    _project_name=$(basename "$_project_dir")
    echo "project_name, $_project_name"
    JWM_MODE=$(echo "$1" | awk -F'/' '{print $(NF-2)}')

    _server=$(sed -n 's/^export JWM_SERVER_NAME=//p' "$1" | tail -1)

    # if [[ $# -eq 2 ]]; then
    #     _server=$2
    # fi

    case "$JWM_MODE" in
    remoteslurm | remotedocker | remotedockercompose | remotenone) ;;
    *)
        echo "ERROR: unknown mode '$JWM_MODE' from filename '$_manual_file'"
        exit 1
        ;;
    esac

    if [[ -z "$_server" ]]; then
        echo "ERROR:  must contain the server name "
        exit 1
    fi
    export server_name="$_server"
    if [[ "${server_name}" == "juwels" || "${server_name}" == "jusuf" ]]; then
        export run_dir_home=/p/project1/trustllm-eu/mao4
    elif [[ ${server_name} == "custodian@"* ]]; then
        export run_dir_home=/home/custodian
    elif [[ ${server_name} == "ferragon" || ${server_name} == "greatrawr" || ${server_name} == "balawar" ]]; then
        export run_dir_home=/home/jinma

    elif [[ ${server_name} == "alvis"* ]]; then
        export run_dir_home=/cephyr/users/shuyir/Alvis
    elif [[ ${server_name} == "berzelius"* ]]; then
        export run_dir_home=/home/x_jinma
    else
        echo "ERROR: unknown server '$server_name'"
        exit 1
    fi

    cd ~/project/
    # bash common_tools/common_port_forward.sh

    ssh -o ConnectTimeout=10 -o BatchMode=yes "$server_name" true

    local_dir="$HOME/project/zzzjwmoutput/${_project_name}"
    run_timestamp="$2"
    run_id="${run_timestamp}"
    { [[ -f "$_project_name/jwm_configs/local_pre.sh" ]] && source "$_project_name/jwm_configs/local_pre.sh" || true; }
    sync_and_commit_repo "common_tools"
    sync_and_commit_repo "$_project_name"

    tmp_path=${run_dir_home}/project_remote_jwm/remote_data/${_project_name}
    rsync -a --rsync-path="mkdir -p ${tmp_path} && rsync" ./tmp_data/ "$server_name":${tmp_path}/

    rm -rf ./tmp_data/*

    echo ${last_commit}
    local_dir="${local_dir}/${run_id}"

    if [[ ${JWM_MODE} == "remotedockercompose" ]]; then
        run_id=""
    fi

    mkdir -p "$local_dir"
    nohup_log="${local_dir}/nohup_monitor.log"
    #     ssh "$server_name" "ss -tlnp 2>/dev/null" | grep -oE '0\.0\.0\.0:[0-9]+' | awk -F: '{print $2}' | sort -un >"$ports_before" || true
    # fi

    info_before_remote="${local_dir}/info_before_remote.txt"
    echo "branch: ${_git_branch} , commit_hash: ${last_commit}" >${info_before_remote}

    # || keeps set -e from aborting so we can rsync then check $_ssh_rc below
    _ssh_rc=0
    ssh -o ConnectTimeout=10 "$server_name" "bash --login ${run_dir_home}/project_remote_jwm/common_tools_jingwei/meta_script.sh ${JWM_MODE} ${_remote_proj} ${last_commit} ${run_dir_home} $server_name ${_manual_file} ${run_dir_remote} ${JWM_RUN_START_TIME}" >>"$nohup_log" 2>&1 &
    _ssh_pid=$!
    (sleep "3600" && kill -TERM "$_ssh_pid" 2>/dev/null && echo "ERROR: SSH timed out" >>"$nohup_log") &
    _timer_pid=$!
    wait "$_ssh_pid" 2>/dev/null || _ssh_rc=$?
    kill "$_timer_pid" 2>/dev/null
    wait "$_timer_pid" 2>/dev/null || true
    # SSH/docker output is appended only to nohup_monitor.log (not also to stdout)
    mkdir -p ./${_project_name}/jwm_configs/${JWM_MODE}/remote_tmps
    rsync -a "$server_name":"${run_dir_remote}/jwm_configs/${JWM_MODE}/remote_tmps/" "./${_project_name}/jwm_configs/${JWM_MODE}/remote_tmps/"

    if [[ $_ssh_rc -ne 0 ]]; then
        echo "ERROR: remote setup on $server_name failed (exit code $_ssh_rc)"
        exit $_ssh_rc
    fi

    if [[ -f "$_project_name/jwm_configs/local_after.sh" ]]; then
        source "$_project_name/jwm_configs/local_after.sh"
    fi

    if [[ "$JWM_MODE" == "remotedockercompose" ]]; then
        echo "$JWM_MODE local done"
        exit 0
    fi

    rsync -a --remove-source-files "$server_name":"${run_dir_remote}/remote_job_id.txt" "${local_dir}/"
    remote_job_id=$(cat "${local_dir}/remote_job_id.txt" 2>/dev/null)

    echo "Remote job ID: $remote_job_id"
    if [ -n "${remote_job_id}" ]; then
        echo "local dir: ${local_dir}"

        monitor_args=(${JWM_MODE} "$server_name" "$remote_job_id" "$run_dir_remote" "$local_dir" "${JWM_RUN_START_TIME}")

        echo """nohup bash ~/project/common_tools/remote_monitor.sh ${monitor_args[@]} >> $nohup_log 2>&1 &""" >>$nohup_log

        nohup bash ~/project/common_tools/remote_monitor.sh "${monitor_args[@]}" >>"$nohup_log" 2>&1 &
        monitor_pid=$!
        echo "Background monitor PID: $monitor_pid"

        echo "see logs at ${local_dir}"

        # tail -f "$nohup_log" &
        # tail_pid=$!
        # while kill -0 "$monitor_pid" 2>/dev/null; do
        #     sleep 1
        # done
        # kill "$tail_pid" 2>/dev/null
        # wait "$tail_pid" 2>/dev/null || true
        # echo "remote_monitor (PID $monitor_pid) exited, stopping log tail."
    else
        echo "FAILED: remote setup on $server_name failed."
    fi
elif [[ "$1" == "remote"* ]]; then
    export JWM_MODE=$1
    echo "JWM_MODE, ${JWM_MODE}"
    shift
    export RUN_PROJ="$1"
    shift
    export JWM_COMMIT_ID="$1"
    shift
    export RUN_DIR_HOME="$1"
    echo "RUN_DIR_HOME, ${RUN_DIR_HOME}"
    shift
    export SERVER_NAME="${1##*@}"
    shift
    export _manual_file=$1
    shift
    export JWM_RUN_DIR_REMOTE=$1
    shift
    export JWM_RUN_START_TIME=$1

    _remote_setup
    if [[ "${JWM_MODE}" == "remoteslurm" ]]; then
        sinfo # show partitions
        sinfo -a -o "%N %G %f %m"
        # Show all QOS policies and their limits
        sacctmgr show qos format=Name,MaxWall
        # Show your specific QOS association
        sacctmgr show assoc where user=$USER format=User,Account,QOS
        # Show detailed QOS info for a specific QOS (replace <qos_name> with yours)
        sacctmgr show qos normal format=Name,MaxWall,MaxSubmit,MaxTRES,MaxTRESPerUser
        cat >>jwm_configs/${JWM_MODE}/remote_tmps/remote.sh <<'EOF'

require_env JWM_SLURM_FILE JWM_RUN_TIME JWM_NODES_NUM
if [[ ${JWM_NOTEBOOK} == 1 ]];then
    JWM_SLURM_RUN_COMMAND="jupyter lab --MappingKernelManager.cull_idle_timeout=3600 --MappingKernelManager.cull_interval=360 --MappingKernelManager.cull_connected=True --ip=0.0.0.0 --port=18889 --no-browser --allow-root --NotebookApp.token=''"
    JWM_SLURM_RUN_ARGS=""
fi
cat ${RUN_DIR_HOME}/project_remote_jwm/common_tools_jingwei/slurm_header.sh ${JWM_SLURM_FILE} > jwm_configs/${JWM_MODE}/remote_tmps/${JWM_SLURM_FILE}
echo """
rm ${RUN_DIR_HOME}/project_remote_jwm/${RUN_PROJ}/${JWM_RUN_START_TIME}.jwm
""">>jwm_configs/${JWM_MODE}/remote_tmps/${JWM_SLURM_FILE}

sbatch_args="--time=${JWM_RUN_TIME} --nodes=${JWM_NODES_NUM} --output=jwmlogs/${JWM_RUN_START_TIME}/job-%j.out --error=jwmlogs/${JWM_RUN_START_TIME}/job-%j.out ${JWM_SLURM_NODES}"
EOF
        # EOF has to be at the start of a line, without anything before it, not even white characters
        if [[ "${SERVER_NAME}" == "berzeliusampere" ]]; then
            cat >>jwm_configs/${JWM_MODE}/remote_tmps/remote.sh <<'EOF'
sbatch_args="${sbatch_args} --gpus=${JWM_GPU_NUM} --cpus-per-task=${CPUS_PER_TASK} --mem=${MEM_PER_TASK} --signal=TERM@90 -A berzelius-2026-50 --partition=berzelius"
EOF

        elif [[ "${SERVER_NAME}" == "jusuf" ]]; then
            sinfo -o "%P %m %c %l %N" -p batch

            cat >>jwm_configs/${JWM_MODE}/remote_tmps/remote.sh <<'EOF'
sbatch_args="${sbatch_args} --cpus-per-task=${CPUS_PER_TASK} --mem=${MEM_PER_TASK} --partition=batch -A trustllm-eu"
EOF
        else
            cat >>jwm_configs/${JWM_MODE}/remote_tmps/remote.sh <<'EOF'
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
        cat >>jwm_configs/${JWM_MODE}/remote_tmps/remote.sh <<'EOF'

echo ${sbatch_args} jwm_configs/${JWM_MODE}/remote_tmps/${JWM_SLURM_FILE}
SBATCH_OUT=$(sbatch ${sbatch_args} jwm_configs/${JWM_MODE}/remote_tmps/${JWM_SLURM_FILE}) || {
    return 1 2>/dev/null
    exit 1
}
EOF
        while true; do
            if [[ ! -f "remote_job_id.txt" ]]; then
                echo "start run ${JWM_MODE}/remote_tmps/remote.sh"
                source jwm_configs/${JWM_MODE}/remote_tmps/remote.sh
                cd ${RUN_DIR_HOME}/project_remote_jwm/${RUN_PROJ}

                JWM_JOB_ID=$(echo "${SBATCH_OUT}" | awk '{print $NF}')

                echo "$JWM_JOB_ID" >"remote_job_id.txt"
                break
            fi
            sleep 2
            echo "wait for remote_job_id.txt to be deleted"
        done

        # export -f slurm_job_status
        # nohup bash -c "slurm_job_status ${JWM_JOB_ID}" >jwmlogs/${JWM_RUN_START_TIME}/job_out.log 2>&1 & # if using stdout rather than redirct, the ssh will hold even using disown
        # disown
        echo "1" >"${JWM_RUN_START_TIME}".jwm

        # sbatch -A berzelius-2026-50 --partition=berzelius-cpu --cpus-per-task=1 --dependency=afterany:${JWM_JOB_ID} -t 5 -o /dev/null -e /dev/null --wrap="rm -f ${JWM_JOB_ID}.txt"
    elif [[ "${JWM_MODE}" == "remotedockercompose" ]]; then
        cat >>jwm_configs/${JWM_MODE}/remote_tmps/remote.sh <<'EOF'
if [[ -n ${JWM_COMPOSE_PRE} ]]; then
    eval "${JWM_COMPOSE_PRE}"
fi
docker compose ${DOCKER_ARGS} up --force-recreate -d 2>&1
sleep 1
JWM_JOB_ID=$(docker compose ps -q)
echo "docker rm -f ${JWM_JOB_ID}"
EOF
        # Without -d, the docker compose up process would stay in the foreground, streaming container logs until you hit Ctrl+C or the containers stop.

        echo "start run ${JWM_MODE}/remote_tmps/remote.sh"
        source jwm_configs/${JWM_MODE}/remote_tmps/remote.sh

        cd "${RUN_DIR_HOME}/project_remote_jwm"/"${RUN_PROJ}"
        # echo "current dir ${PWD}"
        # # cd - >/dev/null
        # export COMPOSE_DIR="llm_services/${MODEL_DIR}"
        # if [[ ! -d ${COMPOSE_DIR} ]]; then
        #     export COMPOSE_DIR="./"
        # fi

        # _compose_dir="${COMPOSE_DIR:-${RUN_DIR_HOME}/project_remote_jwm/${RUN_PROJ}}"
        # trap 'echo "Cancelled — stopping containers..."; docker compose -f "${_compose_dir}/docker-compose.yml" down 2>/dev/null && echo "Containers stopped and removed." || echo "Warning: failed to stop containers."; exit 1' SIGTERM SIGINT
        # _docker_since=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        # _has_rebuilt=false
        # _loop_start=$(date +%s)
        # _startup_grace=200
        #
        # while true; do
        #     mapfile -t _containers < <(docker compose -f "${_compose_dir}/docker-compose.yml" ps -a --format '{{.Name}}' 2>/dev/null)
        #     if [ ${#_containers[@]} -eq 0 ]; then
        #         echo "ERROR: No containers found for compose project in ${_compose_dir}."
        #         break
        #     fi
        #
        #     _all_healthy=true
        #     _any_failed=false
        #     _failed_container=""
        #
        #     printf "\n--- Container Status ($(date +%H:%M:%S)) ---\n"
        #     printf "%-30s %-12s %-12s\n" "CONTAINER" "STATUS" "HEALTH"
        #     printf "%-30s %-12s %-12s\n" "-----" "------" "------"
        #
        #     for _cname in "${_containers[@]}"; do
        #         _cstatus=$(docker inspect --format='{{.State.Status}}' "$_cname" 2>/dev/null) || _cstatus="not_found"
        #         _chealth=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no_healthcheck{{end}}' "$_cname" 2>/dev/null) || _chealth="unknown"
        #         _cerror=$(docker inspect --format='{{.State.Error}}' "$_cname" 2>/dev/null) || _cerror=""
        #
        #         printf "%-30s %-12s %-12s\n" "$_cname" "$_cstatus" "$_chealth"
        #
        #         _elapsed=$(($(date +%s) - _loop_start))
        #         if [[ "$_cstatus" == "exited" || "$_cstatus" == "dead" || "$_cstatus" == "restarting" ]]; then
        #             _any_failed=true
        #             _failed_container="$_cname"
        #         elif [[ "$_chealth" == "unhealthy" && $_elapsed -ge $_startup_grace ]]; then
        #             _any_failed=true
        #             _failed_container="$_cname"
        #         fi
        #
        #         if [[ "$_cstatus" == "created" && -n "$_cerror" ]]; then
        #             _any_failed=true
        #             _failed_container="$_cname"
        #         fi
        #
        #         if [[ "$_chealth" != "healthy" && "$_chealth" != "no_healthcheck" ]]; then
        #             _all_healthy=false
        #         fi
        #         if [[ "$_cstatus" != "running" ]]; then
        #             _all_healthy=false
        #         fi
        #     done
        #
        #     if $_any_failed; then
        #         echo ""
        #         _cfailed_error=$(docker inspect --format='{{.State.Error}}' "$_failed_container" 2>/dev/null)
        #         if [[ -n "$_cfailed_error" ]]; then
        #             echo "ERROR: Container '${_failed_container}' failed to start: ${_cfailed_error}"
        #             break
        #         fi
        #         _cfailed_logs=$(docker logs --since "$_docker_since" --tail 300 "$_failed_container" 2>&1)
        #         if ! $_has_rebuilt && echo "$_cfailed_logs" | grep -qE "No supported CUDA architectures found|ModuleNotFoundError|ImportError|AttributeError"; then
        #             echo "Recoverable error detected in '${_failed_container}' — rebuilding image using no-cache mode..."
        #             docker rm -f "$_failed_container" 2>/dev/null || true
        #             docker compose -f "${_compose_dir}/docker-compose.yml" build --no-cache 2>&1 && docker compose -f "${_compose_dir}/docker-compose.yml" up --force-recreate -d 2>&1
        #             _has_rebuilt=true
        #             _docker_since=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        #             sleep 5
        #             continue
        #         fi
        #         echo "ERROR: Container '${_failed_container}' is in a bad state. Logs:"
        #         echo "$_cfailed_logs"
        #         break
        #     fi
        #
        #     # rebuild for restarting too many times
        #     if ! $_any_failed; then
        #         for _cname in "${_containers[@]}"; do
        #             _crestart=$(docker inspect --format='{{.RestartCount}}' "$_cname" 2>/dev/null) || _crestart=0
        #             if [[ "$_crestart" -ge 3 ]]; then
        #                 _any_failed=true
        #                 _failed_container="$_cname"
        #                 echo "Container '${_cname}' has restarted ${_crestart} times — treating as failed."
        #                 _cfailed_logs=$(docker logs --since "$_docker_since" --tail 300 "$_failed_container" 2>&1)
        #                 if ! $_has_rebuilt && echo "$_cfailed_logs" | grep -qE "No supported CUDA architectures found|ModuleNotFoundError|ImportError|AttributeError"; then
        #                     echo "Recoverable error detected in '${_failed_container}' — rebuilding image..."
        #                     docker rm -f "$_failed_container" 2>/dev/null || true
        #                     docker compose -f "${_compose_dir}/docker-compose.yml" build --no-cache 2>&1 && docker compose -f "${_compose_dir}/docker-compose.yml" up --force-recreate -d 2>&1
        #                     _has_rebuilt=true
        #                     _docker_since=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        #                     sleep 5
        #                     break
        #                 fi
        #                 echo "ERROR: Container '${_failed_container}' is crash-looping. Logs:"
        #                 echo "$_cfailed_logs"
        #                 break 2
        #             fi
        #         done
        #         if $_any_failed; then continue; fi
        #     fi
        #
        #     if $_all_healthy; then
        #         echo ""
        #         echo "All services are ready!"
        #         echo "current dir ${PWD}"
        #         _after_hook="jwm_configs/remote_after.sh"
        #         if [[ -f "$_after_hook" ]]; then
        #             source "$_after_hook"
        #             echo "after hook finished"
        #         fi
        #         break
        #     fi
        #
        #     echo "Waiting for all services to become healthy..."
        #     sleep 10
        # done

        _after_hook="jwm_configs/remote_after.sh"
        if [[ -f "$_after_hook" ]]; then
            source "$_after_hook"
            echo "after hook finished"
        fi

    elif [[ "${JWM_MODE}" == "remotedocker" ]]; then
        cat >>jwm_configs/${JWM_MODE}/remote_tmps/remote.sh <<'EOF'
if [[ ${JWM_NOTEBOOK} == 1 ]]; then
    echo "ARGS_AFTER_ENTRY:"
    echo "${ARGS_AFTER_ENTRY[@]}"
    docker rm -f jwm_notebook
    sleep 5
#    DOCKER_RUN_ARGS=(--name "jwm_notebook" -p 18889:18889 --entrypoint /bin/bash -v $PWD:/app "${DOCKER_RUN_ARGS[@]}" -c "jupyter labextension disable '@jupyterlab/apputils-extension:announcements' && jupyter lab --ip=0.0.0.0 --port=18889 --no-browser --allow-root --NotebookApp.token=''")
else
    DOCKER_RUN_ARGS=("${DOCKER_RUN_ARGS[@]}" "${ARGS_AFTER_ENTRY[@]}")
fi
echo "docker run args, ${DOCKER_RUN_ARGS[@]}"
if [ -z ${RUN_BACKGROUND_JWM} ]; then
    docker run "${DOCKER_RUN_ARGS[@]}"
else
    export JWM_JOB_ID=$(docker run -d "${DOCKER_RUN_ARGS[@]}")
fi
EOF

        source jwm_configs/${JWM_MODE}/remote_tmps/remote.sh
        cd ${RUN_DIR_HOME}/project_remote_jwm/${RUN_PROJ}

        echo "docker rm -f ${JWM_JOB_ID}"
        while true; do
            if [[ ! -f "remote_job_id.txt" ]]; then
                echo "$JWM_JOB_ID" >"remote_job_id.txt"
                break
            fi
            sleep 2
            echo "wait for remote_job_id.txt to be deleted"
        done

        echo "1" >"${JWM_RUN_START_TIME}".jwm

        nohup bash -c "cd jwmlogs/${JWM_RUN_START_TIME}/ && docker logs -f $JWM_JOB_ID >job_out.log.raw 2>&1 & _lp=\$!; while kill -0 \$_lp 2>/dev/null; do tr '\r' '\n' <job_out.log.raw >job_out.log.tmp && mv -f job_out.log.tmp job_out.log; sleep 10; done; wait \$_lp; tr '\r' '\n' <job_out.log.raw >job_out.log.tmp && mv -f job_out.log.tmp job_out.log; docker ps >> job_out.log; rm -f job_out.log.raw job_out.log.tmp ../../${JWM_RUN_START_TIME}.jwm" >/dev/null 2>&1 &
        disown
        echo "docker_container_started"

    elif [[ "${JWM_MODE}" == "remotenone" ]]; then
        cat >>jwm_configs/${JWM_MODE}/remote_tmps/remote.sh <<'EOF'
echo ${PWD}
JWM_RUN_COMMAND="${JWM_RUN_COMMAND_PRE} ${JWM_RUN_COMMAND}"

echo "JWM_RUN_COMMAND, 
${JWM_RUN_COMMAND}
"
if [[ ${JWM_NOTEBOOK} == 1 ]]; then
    kill $(pgrep -f "port=18889") || echo "18889 port free"
    sleep 5
    JWM_RUN_COMMAND="jupyter labextension disable '@jupyterlab/apputils-extension:announcements' && jupyter lab --MappingKernelManager.cull_idle_timeout=3600 --MappingKernelManager.cull_interval=360 --MappingKernelManager.cull_connected=True --ip=0.0.0.0 --port=18889 --no-browser --allow-root --NotebookApp.token=''"
fi
nohup bash -c "${JWM_RUN_COMMAND}; rm ${RUN_DIR_HOME}/project_remote_jwm/${RUN_PROJ}/${JWM_RUN_START_TIME}.jwm"  > jwmlogs/${JWM_RUN_START_TIME}/job_out.log 2>&1 &

export JWM_JOB_ID=$!
EOF
        source jwm_configs/${JWM_MODE}/remote_tmps/remote.sh
        disown ${JWM_JOB_ID}
        cd ${RUN_DIR_HOME}/project_remote_jwm/${RUN_PROJ}

        while true; do
            if [[ ! -f "remote_job_id.txt" ]]; then
                echo "$JWM_JOB_ID" >"remote_job_id.txt"
                break
            fi
            sleep 2
            echo "wait for remote_job_id.txt to be deleted"
        done
        echo "1" >"${JWM_RUN_START_TIME}".jwm

        nohup bash ${RUN_DIR_HOME}/project_remote_jwm/common_tools_jingwei/resource_usage.sh ${JWM_JOB_ID} >jwmlogs/${JWM_RUN_START_TIME}/resource_usage.log 2>&1 &
        disown
        echo "ps -ef|grep ${JWM_JOB_ID}"
        echo "pkill -TERM -P ${JWM_JOB_ID}"
    fi
    echo "PWD: ${PWD}"
    echo "JWM_JOB_ID: ${JWM_JOB_ID}"
    echo "${JWM_MODE} remote done"

else
    echo "ERROR: unrecognized arguments. Usage:"
    echo "  meta_script.sh /path/to/project/jwm_configs/<mode>.sh  (last line of file: # <server>)"
    echo "  (remote-side call is handled internally)"
    exit 1
fi
