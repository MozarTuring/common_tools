#!/bin/bash

set -e

if false; then
    sudo chmod -R a+rwX /data/huggingface_cache
    sudo setfacl -R -m u:jinma63:rwx,u:custodian:rwx /data/huggingface_cache
    sudo setfacl -R -d -m u:jinma63:rwx,u:custodian:rwx /data/huggingface_cache
fi

if false; then
    rsync -aP berzeliusampere:/home/x_jinma63/project_remote_pkq/llm2vec_pkq/output/mntp/Meta-Llama-3.1-8B-msmarco ./
    rsync -aP greatrawr:/home/jinma63/project_remote_pkq/remote_data/llm2vec/reranker_parts /Users/jinma63/project/tmp_data/cache/
fi

slurm_job_status() {
    bash "$(dirname "${BASH_SOURCE[0]}")/slurm_job_status.sh" "$@"
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
    source ${RUN_DIR_HOME}/project_remote_pkq/project_nogit/common_tools/common_tokens.sh

    mkdir -p ${RUN_DIR_HOME}/project_remote_pkq/${RUN_PROJ}/pkq_configs/remote/remote_tmps
    mkdir -p ${PKQ_DATA_DIR}

    if [[ -d /data && ${PKQ_MODE} == "remotedocker"* ]]; then
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
    mkdir -p pkqlogs/${PKQ_RUN_START_TIME}
    mkdir -p pkq_configs/remote/remote_tmps
    sleep 1
    # echo "" > pkq_configs/${PKQ_MODE}/remote_tmps/remote.sh # init in nvim
    #     cat >>pkq_configs/${PKQ_MODE}/remote_tmps/remote.sh <<'EOF'
    #
    # require_env() {
    # for var in "$@"; do
    #     if [ -z "${!var}" ]; then
    #         echo "Error: $var is not set" >&2
    #         exit 1
    #     fi
    # done
    # }
    #
    # EOF

    export PYTHONUNBUFFERED=1
    export RUN_BACKGROUND_PKQ=1

    if [ -n ${PKQ_PYTHON} ]; then
        if [[ ${PKQ_MODE} == "remotenone" ]]; then
            cat >pkq_configs/remote/remote_tmps/remote2.sh <<'EOF'
eval "$(${RUN_DIR_HOME}/miniconda3/bin/conda shell.bash hook)"
EOF

        elif [[ ${PKQ_MODE} == "remoteslurm" ]]; then
            if [[ ${PKQ_SERVER_NAME} == "berzeliusampere" ]]; then
                export PKQ_MODULES="Miniforge3 buildenv-gcccuda/12.4.1-gcc13.3.0"
                PKQ_SLURM_NODES="--nodelist=node[061-064,065,066-093]"
            elif [[ ${PKQ_SERVER_NAME} == "arrhenius" ]]; then
                cat >pkq_configs/remote/remote_tmps/remote2.sh <<EOF
export PKQ_ARCH="aarch64"
export PKQ_MODULES="Miniforge"
EOF
            fi
            #            module --force purge
            cat >>pkq_configs/remote/remote_tmps/remote2.sh <<'EOF'
module load ${PKQ_MODULES}
EOF

        fi

        cat >>pkq_configs/remote/remote_tmps/remote2.sh <<'EOF'
if [ -z ${PKQ_CONDAENV} ]; then
    export PKQ_CONDAENV=${RUN_DIR_HOME}/pkqcondaenv/${RUN_PROJ}
    export PKQ_WHEELS=${RUN_DIR_HOME}/pkqwheels/${RUN_PROJ}
fi
echo "condaenv path ${PKQ_CONDAENV}"
if [[ ! -d ${PKQ_CONDAENV}${PKQ_ARCH} ]]; then
    conda create -p ${PKQ_CONDAENV}${PKQ_ARCH} python=${PKQ_PYTHON} -y
fi
conda activate ${PKQ_CONDAENV}${PKQ_ARCH}
which python
python --version
which pip
EOF
    fi
    # no '' around EOF, it will expand vars
    #     cat >>pkq_configs/${PKQ_MODE}/remote_tmps/remote.sh <<EOF
    # # change the following based on your running preference
    # export RUN_DIR_HOME="${RUN_DIR_HOME}"
    # export RUN_PROJ="${RUN_PROJ}"
    #
    # EOF

    # echo "${PKQ_RUN_DIR_REMOTE}, ${PWD}"
    # if [[ ${PKQ_RUN_DIR_REMOTE} != "${PWD}" ]]; then
    #     cp -R . ${PKQ_RUN_DIR_REMOTE}/
    #     cd ${PKQ_RUN_DIR_REMOTE}
    # fi

    if [[ ${PKQ_MODE} == "remotedocker" ]]; then
        cat >>pkq_configs/remote/remote_tmps/remote.sh <<'EOF'
export PKQ_CACHE_DIR=${RUN_DIR_HOME}/.cache
EOF
    fi

    # ~/miniconda3/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && ~/miniconda3/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
    if [[ ${PKQ_MODE} == "remotenone" ]]; then

        cat >>pkq_configs/remote/remote_tmps/remote2.sh <<'EOF'
if [ ! -d ${RUN_DIR_HOME}/pkqcondaenv/shared_cuda ]; then
    conda create -y -p ${RUN_DIR_HOME}/pkqcondaenv/shared_cuda -c nvidia cuda-toolkit
fi
export CUDA_HOME=${RUN_DIR_HOME}/pkqcondaenv/shared_cuda
export PATH=${CUDA_HOME}/bin:${PATH}
export CPATH=${CUDA_HOME}/targets/x86_64-linux/include:${CPATH}
export LD_LIBRARY_PATH=${CUDA_HOME}/targets/x86_64-linux/lib:${LD_LIBRARY_PATH}
EOF

    fi

    # if [[ ${PKQ_MODE} == "remotedocker" ]]; then
    #     eval "$(grep '^PKQ_CONTAINERS=' "pkq_configs/${PKQ_MODE}/remote_tmps/${batch_file}" | tail -1)"
    #     clearflag=0
    #     for _ctn in "${PKQ_CONTAINERS[@]}"; do
    #         echo "removing ${_ctn}"
    #         docker rm -f "${_ctn}"
    #         clearflag=1
    #     done
    #     if [[ ${clearflag} == 1 ]]; then
    #         echo "waiting for clearing"
    #         sleep 30
    #     fi
    # fi
    # touch ".submit_marker"

    source pkq_configs/remote/remote_tmps/remote2.sh
    if [[ -f pkq_configs/remote/template.sh ]]; then
        echo "start running template.sh"
        source pkq_configs/remote/template.sh
    fi
    interactive -A naiss2026-3-658-gpu --partition gpu --gpus 1
    echo "start running common.sh"
    source pkq_configs/common.sh
    # sed -i '/^# PKQ_SERVER_NAME=/d' pkq_configs/${PKQ_MODE}/remote_tmps/remote.sh

}

if [[ $# -lt 3 ]]; then
    PKQ_RUN_START_TIME=$2
    echo "PKQ_RUN_START_TIME, ${PKQ_RUN_START_TIME}"
    trap 'echo "ERROR: command failed at line $LINENO (exit code $?)" >&2' ERR
    echo "abspath, $1"
    _project_dir=$(cd "$(dirname "$1")"/../../../ && pwd)

    echo "project_dir, ${_project_dir}"
    _project_name=$(basename "$_project_dir")
    echo "project_name, $_project_name"

    export server_name=$(sed -n 's/^export PKQ_SERVER_NAME=//p' "$1" | tail -1)

    PKQ_MODE=$(sed -n 's/^export PKQ_MODE=//p' "$1" | tail -1)
    if [[ -z ${PKQ_MODE} ]]; then
        PKQ_MODE=remotenone
    fi
    case "$server_name" in
    berzeliusampere | jusuf | juwelscluster | arrhenius)
        PKQ_MODE=remoteslurm
        ;;
    *)
        ;;
    esac

    case "$PKQ_MODE" in
    remoteslurm | remotedocker | remotedockercompose | remotenone)

        ;;
    *)
        echo "ERROR: unknown mode '$PKQ_MODE'"
        exit 1
        ;;
    esac

    case "${server_name}" in
    juwels | jusuf | juwelscluster)
        export run_dir_home=/p/project1/trustllm-eu/mao4
        ;;
    custodian@*)
        export run_dir_home=/home/custodian
        ;;
    ferragon | greatrawr | balawar)
        export run_dir_home=/home/jinma
        ;;
    alvis*)
        export run_dir_home=/cephyr/users/shuyir/Alvis
        ;;
    berzelius*)
        export run_dir_home=/home/x_jinma
        ;;
    arrhenius)
        export run_dir_home=/nobackup/proj/disk/naiss2026-3-658/personal/jinma63
        ;;
    *)
        echo "ERROR: unknown server '$server_name'"
        exit 1
        ;;
    esac

    # bash common_tools/common_port_forward.sh

    cd $HOME/project

    if [[ -z ${PKQ_RUN_START_TIME} ]]; then
        remote_ts=$(ssh -o ConnectTimeout=10 -o BatchMode=yes "$server_name" 'date +"%Y-%m-%d %H:%M:%S"')
        echo "$remote_ts" >"$HOME/project/${_project_name}/pkq_configs/.last_remote_ts"
        bash common_tools/sync_and_commit_repo.sh "common_tools"
        bash common_tools/sync_and_commit_repo.sh "$_project_name"

        tmp_path=${run_dir_home}/project_remote_pkq/remote_data/${_project_name}
        rsync -av --rsync-path="mkdir -p ${tmp_path} && rsync" ./tmp_data/cache/ "$server_name":${tmp_path}/
        [ -n "$(ls -A ./tmp_data/cache/)" ] && mv ./tmp_data/cache/* ./tmp_data/

        tmp_path=${run_dir_home}/project_remote_pkq/project_nogit/common_tools/
        rsync -a --rsync-path="mkdir -p ${tmp_path} && rsync" /Users/jinma63/Desktop/baidu/project_nogit/common_tools/ "$server_name":${tmp_path}/

        echo "rsync done"
        exit
    fi
    local_dir="$HOME/project/zzzpkqoutput/${_project_name}"
    { [[ -f "$_project_name/pkq_configs/local_pre.sh" ]] && source "$_project_name/pkq_configs/local_pre.sh" || true; }
    cd ${_project_name}
    _git_branch=$(git -C ./ rev-parse --abbrev-ref HEAD 2>/dev/null)
    last_commit=$(git rev-parse HEAD)
    cd -

    run_dir_remote="${run_dir_home}/project_remote_pkq/${_project_name}_${_git_branch}"
    local_dir="${local_dir}/${PKQ_RUN_START_TIME}"

    mkdir -p "$local_dir"
    nohup_log="${local_dir}/nohup_monitor.log"
    #     ssh "$server_name" "ss -tlnp 2>/dev/null" | grep -oE '0\.0\.0\.0:[0-9]+' | awk -F: '{print $2}' | sort -un >"$ports_before" || true
    # fi

    info_before_remote="${local_dir}/info_before_remote.txt"
    echo "branch: ${_git_branch} , commit_hash: ${last_commit}" >${info_before_remote}

    # || keeps set -e from aborting so we can rsync then check $_ssh_rc below
    _ssh_rc=0
    echo "ssh start"
    ssh -o ConnectTimeout=10 -t "$server_name" "bash --login ${run_dir_home}/project_remote_pkq/common_tools_pikaq/meta_script.sh ${PKQ_MODE} ${run_dir_home} ${last_commit} ${_project_name}_${_git_branch} $server_name ${run_dir_remote} ${PKQ_RUN_START_TIME}" # >>"$nohup_log" 2>&1 &
    _ssh_pid=$!
    (sleep "3600" && kill -TERM "$_ssh_pid" 2>/dev/null && echo "ERROR: SSH timed out" >>"$nohup_log") &
    _timer_pid=$!
    wait "$_ssh_pid" 2>/dev/null || _ssh_rc=$?
    kill "$_timer_pid" 2>/dev/null
    wait "$_timer_pid" 2>/dev/null || true
    # SSH/docker output is appended only to nohup_monitor.log (not also to stdout)
    mkdir -p ./${_project_name}/pkq_configs/remote/remote_tmps
    rsync -a "$server_name":"${run_dir_remote}/pkq_configs/remote/remote_tmps/" "./${_project_name}/pkq_configs/remote/remote_tmps/"

    if [[ $_ssh_rc -ne 0 ]]; then
        echo "ERROR: remote setup on $server_name failed (exit code $_ssh_rc)"
        exit $_ssh_rc
    fi

    if [[ -f "$_project_name/pkq_configs/local_after.sh" ]]; then
        source "$_project_name/pkq_configs/local_after.sh"
    fi

    if [[ "$PKQ_MODE" == "remotedockercompose" ]]; then
        echo " local done"
        exit 0
    fi

    rsync -a --remove-source-files "$server_name":"${run_dir_remote}/remote_job_id.txt" "${local_dir}/"

    remote_job_id=$(cat "${local_dir}/remote_job_id.txt" 2>/dev/null)

    echo "Remote job ID: $remote_job_id"
    if [ -n "${remote_job_id}" ]; then
        echo "local dir: ${local_dir}"

        monitor_args=(${PKQ_MODE} "$server_name" "$remote_job_id" "$run_dir_remote" "$local_dir" "${PKQ_RUN_START_TIME}")

        echo """nohup bash ~/project/common_tools/remote_monitor.sh ${monitor_args[@]} >> $nohup_log 2>&1 &""" >>$nohup_log

        nohup bash ~/project/common_tools/remote_monitor.sh "${monitor_args[@]}" >>"$nohup_log" 2>&1 &
        monitor_pid=$!
        echo "Background monitor PID:
        ps -ef |grep $monitor_pid"

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
    export PKQ_MODE=$1
    shift
    export RUN_DIR_HOME="$1"
    shift
    export PKQ_COMMIT_ID="$1"
    shift
    export RUN_PROJ="$1"
    shift
    export PKQ_SERVER_NAME="${1##*@}"
    shift
    export PKQ_RUN_DIR_REMOTE=$1
    shift
    export PKQ_RUN_START_TIME=$1

    export PKQ_DATA_DIR=${RUN_DIR_HOME}/project_remote_pkq/remote_data/${RUN_PROJ%_*}
    cd ${RUN_DIR_HOME}/project_remote_pkq/${RUN_PROJ}
    source pkq_configs/remote/remote_tmps/local.sh
    # the following file is init on local
    cat >pkq_configs/remote/remote_tmps/remote.sh <<EOF

set -e
# change the following vars based on your preference, and then make sure this repo is cloned to ${RUN_DIR_HOME}/project_remote_pkq/${RUN_PROJ}
export RUN_DIR_HOME=${RUN_DIR_HOME}
export RUN_PROJ=${RUN_PROJ}
export PKQ_DATA_DIR=${RUN_DIR_HOME}/project_remote_pkq/remote_data/${RUN_PROJ%_*}

EOF
    echo 'cd ${RUN_DIR_HOME}/project_remote_pkq/${RUN_PROJ}' >>pkq_configs/remote/remote_tmps/remote.sh
    cat pkq_configs/remote/remote_tmps/local.sh >>pkq_configs/remote/remote_tmps/remote.sh
    echo "PKQ_PYTHON, ${PKQ_PYTHON}"
    _remote_setup
    if [[ "${PKQ_MODE}" == "remoteslurm" ]]; then
        sinfo # show partitions
        sinfo -a -o "%N %G %f %m"
        # Show all QOS policies and their limits
        sacctmgr show qos format=Name,MaxWall
        # Show your specific QOS association
        sacctmgr show assoc where user=$USER format=User,Account,QOS
        # Show detailed QOS info for a specific QOS (replace <qos_name> with yours)
        sacctmgr show qos normal format=Name,MaxWall,MaxSubmit,MaxTRES,MaxTRESPerUser

        if [[ ${PKQ_NOTEBOOK} == 1 ]]; then
            PKQ_RUN_COMMAND="jupyter lab --MappingKernelManager.cull_idle_timeout=3600 --MappingKernelManager.cull_interval=360 --MappingKernelManager.cull_connected=True --ip=0.0.0.0 --port=18889 --no-browser --allow-root --NotebookApp.token=''"
            PKQ_SLURM_RUN_ARGS=""
        fi
        cat ${RUN_DIR_HOME}/project_remote_pkq/common_tools_pkq/slurm_header.sh ${PKQ_SLURM_FILE} ${RUN_DIR_HOME}/project_remote_pkq/common_tools_pkq/slurm_tail.sh >pkq_configs/remote/remote_tmps/${PKQ_SLURM_FILE}
        sbatch_args="--signal=B:USR1@120 --time=${PKQ_RUN_TIME} --nodes=${PKQ_NODES_NUM} --output=pkqlogs/${PKQ_RUN_START_TIME}/job-%j.out --error=pkqlogs/${PKQ_RUN_START_TIME}/job-%j.out ${PKQ_SLURM_NODES}"
        # EOF has to be at the start of a line, without anything before it, not even white characters
        # berzelius-2026-50
        # berzelius-2026-243
        if [[ "${PKQ_SERVER_NAME}" == "berzeliusampere" ]]; then
            if (("${PKQ_GPU_NUM}" == "0")); then
                PKQ_PARTITION="berzelius-cpu"
                export CPUS_PER_TASK=32
                export MEM_PER_TASK="128G"

            else
                export CPUS_PER_TASK=$((8 * PKQ_GPU_NUM))
                export MEM_PER_TASK="$((24 * PKQ_GPU_NUM))G"
                PKQ_PARTITION="berzelius"
                export TORCH_CUDA_ARCH_LIST="9.0"
            fi

            sbatch_args="${sbatch_args} --gpus=${PKQ_GPU_NUM} --cpus-per-task=${CPUS_PER_TASK} --mem=${MEM_PER_TASK}  -A berzelius-2026-243  --partition=${PKQ_PARTITION}"

        elif [[ "${PKQ_SERVER_NAME}" == "arrhenius" ]]; then

            if (("${PKQ_GPU_NUM}" == "0")); then
                PKQ_PARTITION="cpu"
                export CPUS_PER_TASK=32
                export MEM_PER_TASK="128G"

            else
                export TORCH_CUDA_ARCH_LIST="9.0"
                PKQ_PARTITION="gpu"
            fi

            sbatch_args="${sbatch_args} --gpus=${PKQ_GPU_NUM} --cpus-per-task=${CPUS_PER_TASK} --mem=${MEM_PER_TASK}  -A naiss2026-3-658-gpu  --partition=${PKQ_PARTITION}"

        elif [[ "${PKQ_SERVER_NAME}" == "jusuf" ]]; then
            sinfo -o "%P %m %c %l %N" -p batch

            sbatch_args="${sbatch_args} --cpus-per-task=${CPUS_PER_TASK} --mem=${MEM_PER_TASK} --partition=batch -A trustllm-eu"
        else
            if check_gpu A40 ${PKQ_GPU_NUM} >/dev/null; then
                export PKQ_GPU_TYPE=A40
                echo "A40 available"
            elif check_gpu T4 ${PKQ_GPU_NUM} >/dev/null; then
                export PKQ_GPU_TYPE=T4
                echo "T4 available"
            else
                echo "no gpu available"
                return 2>/dev/null
                exit 1
            fi
            echo "GPU_TYPE: $PKQ_GPU_TYPE"
            echo "COMMIT:   $PKQ_COMMIT_ID"

            if (("${PKQ_GPU_NUM}" == "0")); then
                GPU_FLAG="--constraint=NOGPU"
            else
                GPU_FLAG="--gpus-per-node=${PKQ_GPU_TYPE}:${PKQ_GPU_NUM}"
            fi
            if [[ "${PKQ_SERVER_NAME}" == "juwelscluster" ]]; then
                GPU_FLAG="--gres=gpu:${PKQ_GPU_NUM}"
                CPUS_PER_TASK_FLAG="--cpus-per-task=${CPUS_PER_TASK}"
            fi
            sbatch_args="${sbatch_args} ${GPU_FLAG} ${CPUS_PER_TASK_FLAG}"

        fi

        echo "cd ${PWD} && sbatch ${sbatch_args} pkq_configs/remote/remote_tmps/${PKQ_SLURM_FILE}"
        cat pkq_configs/remote/remote_tmps/remote.sh pkq_configs/remote/remote_tmps/remote2.sh pkq_configs/common.sh >pkq_configs/remote/remote_tmps/remote_all.sh
        echo "sbatch ${sbatch_args} pkq_configs/remote/remote_tmps/${PKQ_SLURM_FILE}" >>pkq_configs/remote/remote_tmps/remote_all.sh
        SBATCH_OUT=$(sbatch ${sbatch_args} pkq_configs/remote/remote_tmps/${PKQ_SLURM_FILE}) || {
            return 1 2>/dev/null
            exit 1
        }
        while true; do
            if [[ ! -f "remote_job_id.txt" ]]; then
                cd ${RUN_DIR_HOME}/project_remote_pkq/${RUN_PROJ}
                PKQ_JOB_ID=$(echo "${SBATCH_OUT}" | awk '{print $NF}')
                echo "$PKQ_JOB_ID" >"remote_job_id.txt"
                break
            fi
            sleep 2
            echo "wait for remote_job_id.txt to be deleted"
        done

        # export -f slurm_job_status
        # nohup bash -c "slurm_job_status ${PKQ_JOB_ID}" >pkqlogs/${PKQ_RUN_START_TIME}/job_out.log 2>&1 & # if using stdout rather than redirct, the ssh will hold even using disown
        # disown
        # echo "1" >"${PKQ_RUN_START_TIME}".pkq

        # sbatch -A berzelius-2026-50 --partition=berzelius-cpu --cpus-per-task=1 --dependency=afterany:${PKQ_JOB_ID} -t 5 -o /dev/null -e /dev/null --wrap="rm -f ${PKQ_JOB_ID}.txt"
    elif [[ "${PKQ_MODE}" == "remotedockercompose" ]]; then
        cat >>pkq_configs/remote/remote_tmps/remote.sh <<'EOF'
docker compose ${DOCKER_ARGS} up --force-recreate -d 2>&1
EOF
        # Without -d, the docker compose up process would stay in the foreground, streaming container logs until you hit Ctrl+C or the containers stop.
        if [[ -n ${PKQ_COMPOSE_PRE} ]]; then
            eval "${PKQ_COMPOSE_PRE}"
        fi
        sleep 1
        PKQ_JOB_ID=$(docker compose ps -q)
        echo "docker rm -f ${PKQ_JOB_ID}"

        cd "${RUN_DIR_HOME}/project_remote_pkq"/"${RUN_PROJ}"
        # echo "current dir ${PWD}"
        # # cd - >/dev/null
        # export COMPOSE_DIR="llm_services/${MODEL_DIR}"
        # if [[ ! -d ${COMPOSE_DIR} ]]; then
        #     export COMPOSE_DIR="./"
        # fi

        # _compose_dir="${COMPOSE_DIR:-${RUN_DIR_HOME}/project_remote_pkq/${RUN_PROJ}}"
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
        #         _after_hook="pkq_configs/remote_after.sh"
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

        _after_hook="pkq_configs/remote_after.sh"
        if [[ -f "$_after_hook" ]]; then
            source "$_after_hook"
            echo "after hook finished"
        fi

    elif [[ "${PKQ_MODE}" == "remotedocker" ]]; then
        cat >>pkq_configs/remote/remote_tmps/remote.sh <<'EOF'
if [[ ${PKQ_NOTEBOOK} == 1 ]]; then
    echo "ARGS_AFTER_ENTRY:"
    echo "${ARGS_AFTER_ENTRY[@]}"
    docker rm -f pkq_notebook
    sleep 5
#    DOCKER_RUN_ARGS=(--name "pkq_notebook" -p 18889:18889 --entrypoint /bin/bash -v $PWD:/app "${DOCKER_RUN_ARGS[@]}" -c "jupyter labextension disable '@jupyterlab/apputils-extension:announcements' && jupyter lab --ip=0.0.0.0 --port=18889 --no-browser --allow-root --NotebookApp.token=''")
else
    DOCKER_RUN_ARGS=("${DOCKER_RUN_ARGS[@]}" "${ARGS_AFTER_ENTRY[@]}")
fi
echo "docker run args, ${DOCKER_RUN_ARGS[@]}"
if [ -z ${RUN_BACKGROUND_PKQ} ]; then
    docker run "${DOCKER_RUN_ARGS[@]}"
else
    export PKQ_JOB_ID=$(docker run -d "${DOCKER_RUN_ARGS[@]}")
fi
EOF

        cd ${RUN_DIR_HOME}/project_remote_pkq/${RUN_PROJ}

        echo "docker rm -f ${PKQ_JOB_ID}"
        while true; do
            if [[ ! -f "remote_job_id.txt" ]]; then
                echo "$PKQ_JOB_ID" >"remote_job_id.txt"
                break
            fi
            sleep 2
            echo "wait for remote_job_id.txt to be deleted"
        done

        # echo "1" >"${PKQ_RUN_START_TIME}".pkq

        nohup bash -c "cd pkqlogs/${PKQ_RUN_START_TIME}/ && docker logs -f $PKQ_JOB_ID >job_out.log.raw 2>&1 & _lp=\$!; while kill -0 \$_lp 2>/dev/null; do tr '\r' '\n' <job_out.log.raw >job_out.log.tmp && mv -f job_out.log.tmp job_out.log; sleep 10; done; wait \$_lp; tr '\r' '\n' <job_out.log.raw >job_out.log.tmp && mv -f job_out.log.tmp job_out.log; docker ps >> job_out.log; rm -f job_out.log.raw job_out.log.tmp " >/dev/null 2>&1 &
        disown
        echo "docker_container_started"

    elif [[ "${PKQ_MODE}" == "remotenone" ]]; then
        echo ${PWD}
        PKQ_RUN_COMMAND="${PKQ_RUN_COMMAND_PRE} ${PKQ_RUN_COMMAND}"

        kill $(pgrep -f "port=18889") || echo "18889 port free"
        sleep 5

        if [[ ${PKQ_NOTEBOOK} == 1 ]]; then
            PKQ_RUN_COMMAND="jupyter labextension disable '@jupyterlab/apputils-extension:announcements' && CUDA_VISIBLE_DEVICES='${CUDA_VISIBLE_DEVICES}' jupyter lab --MappingKernelManager.cull_idle_timeout=3600 --MappingKernelManager.cull_interval=360 --MappingKernelManager.cull_connected=True --ip=0.0.0.0 --port=18889 --no-browser --allow-root --NotebookApp.token=''"
        fi

        echo "PKQ_RUN_COMMAND, ${PKQ_RUN_COMMAND}"

        CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES}" nohup ${PKQ_RUN_COMMAND} >pkqlogs/${PKQ_RUN_START_TIME}/job_out.log 2>&1 &
        export PKQ_JOB_ID=$!
        disown ${PKQ_JOB_ID}
        cd ${RUN_DIR_HOME}/project_remote_pkq/${RUN_PROJ}

        while true; do
            if [[ ! -f "remote_job_id.txt" ]]; then
                echo "$PKQ_JOB_ID" >"remote_job_id.txt"
                break
            fi
            sleep 2
            echo "wait for remote_job_id.txt to be deleted"
        done
        # echo "1" >"${PKQ_RUN_START_TIME}".pkq

        nohup bash ${RUN_DIR_HOME}/project_remote_pkq/common_tools_pkq/resource_usage.sh ${PKQ_JOB_ID} >pkqlogs/${PKQ_RUN_START_TIME}/resource_usage.log 2>&1 &
        disown
        echo "ps -ef|grep ${PKQ_JOB_ID}"
        echo "pkill -TERM -P ${PKQ_JOB_ID}"
    fi
    echo "PWD: ${PWD}"
    echo "PKQ_JOB_ID: ${PKQ_JOB_ID}"
    echo "ssh done"

else
    echo "ERROR: unrecognized arguments. Usage:"
    echo "  meta_script.sh /path/to/project/pkq_configs/<mode>.sh  (last line of file: # <server>)"
    echo "  (remote-side call is handled internally)"
    exit 1
fi
