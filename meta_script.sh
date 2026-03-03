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

if [[ "$1" == "slurm" ]]; then
    export JWM_COMMIT_ID=$2
    export JWM_RUN_TAG=$4

    source remote.sh
    # Run tag: use JWM_RUN_TAG from remote.sh/env, or auto-generate from timestamp.
    # This allows multiple runs under the same commit.
    #   runs/<project>/<commit>/<run_tag>/
    export RUN_ID="${JWM_COMMIT_ID}/${JWM_RUN_TAG}"
    export RUN_DIR="../runs/${3}/${RUN_ID}/"


    if [ -z "${JWM_GPU_TYPE}" ]; then
        if check_gpu T4 ${JWM_GPU_NUM}; then
            export JWM_GPU_TYPE=T4
        elif check_gpu A40 ${JWM_GPU_NUM}; then
            export JWM_GPU_TYPE=A40
        else
            export JWM_GPU_TYPE=A40
        fi
    fi
    echo "GPU_TYPE: $JWM_GPU_TYPE"
    echo "COMMIT:   $JWM_COMMIT_ID"
    echo "RUN_TAG:  $JWM_RUN_TAG"
    echo "RUN_DIR:  $RUN_DIR"

    mkdir -p ${RUN_DIR}
    cp -R . ${RUN_DIR}
    cd ${RUN_DIR}
    sbatch --time=${JWM_RUN_TIME} --nodes=${JWM_NODES_NUM} --gpus-per-node=${JWM_GPU_TYPE}:${JWM_GPU_NUM} --job-name="${JWM_COMMIT_ID:0:8}_${JWM_RUN_TAG}" slurm.sh && while ! [ -f slurm_out.log ]; do sleep 1; done && tail -f slurm_out.log

else
    cd $2/ &&
        git submodule foreach 'git add -A && (git commit -m "v" || true)' &&
        git add -A && (git commit -m "v" || true) && last_commit=$(git rev-parse HEAD) &&
        cd .. &&
        tar --disable-copyfile --exclude='.git' --exclude='.DS_Store' -czf tmp.tar.gz "$2" common_tools/meta_script.sh && scp tmp.tar.gz "$1":~/project_remote_jwm/

    echo ${last_commit}
    jwm_run_tag="$(date +%Y%m%d_%H%M%S)"

    echo """
if false; then
    rsync -av alvis1:~/project_remote_jwm/runs/${2}/${last_commit}/${jwm_run_tag}/ /Users/maojingwei/baidu/project/zzzjwmoutput/${2}/runs/${last_commit}/${jwm_run_tag}
fi
""" >>${2}/remote.sh

    osascript - "$2" "${last_commit}" "$3" "${jwm_run_tag}" <<'EOF'
on run argv
    set p1 to item 1 of argv
    set p2 to item 2 of argv
    set p3 to item 3 of argv
    set p4 to item 4 of argv
    tell application "iTerm2"
        tell current window
            tell current session
                write text (ASCII character 3)
                delay 2
                write text "cd ~/project_remote_jwm && tar -xzf tmp.tar.gz && cd " & p1 & " && source ../common_tools/meta_script.sh " & p3 & " " & p2 & " " & p1 & " " & p4
            end tell
        end tell
    end tell
end run
EOF
fi

if false; then
    # remote
    scancel 5990391
    exit
    ssh alvis1
    ssh custodian2greatrawr
    nvidia-smi
    docker ps -a
    docker stop vllm
    docker rm vllm
    du -h --max-depth=1 ~/.cache/huggingface/hub
    curl http://ferragon.stellar.research.liu.se:8005/v1/models
    docker logs vllm_qwen3-coder-next-fp8 --tail=3000 >tmplogs.jwm && vim tmplogs.jwm
    curl http://ferragon.stellar.research.liu.se:8005/v1/models
    curl http://ferragon.stellar.research.liu.se:8005/v1/chat/completions \
        -H "Content-Type: application/json" \
        -d '{
        "model": "qwen3-coder-next-fp8",
        "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": "Who won the world series in 2020?"}
        ]
    }'
fi
