if [[ "$1" == remote ]]; then
    export JWM_GPU_NUM=1 && export JWM_COMMIT_ID=debug
    scancel --name=debug && sleep 5 && rm -rf ../debug
    if bash check_gpu.sh T4 $2; then
        export JWM_GPU_TYPE=T4
    elif bash check_gpu.sh A40 $2; then
        export JWM_GPU_TYPE=A40
    else
        export JWM_GPU_TYPE=A40
    fi
    echo "$JWM_GPU_TYPE"

    mkdir -p "../${JWM_COMMIT_ID}"
    cp -R . "../${JWM_COMMIT_ID}/"
    cd "../${JWM_COMMIT_ID}"
    sbatch --time=1-00:00:00 --nodes=1 --gpus-per-node=${JWM_GPU_TYPE}:${JWM_GPU_NUM} --job-name="${JWM_COMMIT_ID}" slurm.sh
    while ! [ -f slurm_out.log ]; do sleep 1; done && tail -f slurm_out.log
else
    rm tmp.tar.gz
    cp common_tools/meta_script.sh $2/
    tar --disable-copyfile --exclude='.git' --exclude='.DS_Store' -czf tmp.tar.gz "$2" && scp tmp.tar.gz "$1":~/project_remote_jwm/


osascript - "$2" <<'EOF'
on run argv
    set p to item 1 of argv
    tell application "iTerm2"
        tell current window
            tell current session
                write text (ASCII character 3)
                delay 2
                write text "cd ~/project_remote_jwm && tar -xzf tmp.tar.gz && cd " & p & " && source meta_script.sh remote"
            end tell
        end tell
    end tell
end run
EOF
fi

if false; then
    # local
    cd /Users/maojingwei/baidu/project/ && source common_tools/meta_script.sh alvis1 DeMuon

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
