
for ((i=1; i<="$#"; i++)); do
    # echo "参数 $i: ${!i}"
    tmp=${!i}
    dst=$(echo "$tmp" | sed 's/LLaMA-Factory/LLaMA-Factory-main/g')
    set -x
    cp $tmp $dst
    set +x
done










# bash /home/maojingwei/project/common_tools/git_copy.sh ~/project/LLaMA-Factory/examples/train_lora/llama3_lora_sft.yaml ~/project/LLaMA-Factory/src/llamafactory/cli.py ~/project/LLaMA-Factory/src/llamafactory/data/loader.py ~/project/LLaMA-Factory/src/llamafactory/hparams/parser.py ~/project/LLaMA-Factory/src/llamafactory/train/tuner.py