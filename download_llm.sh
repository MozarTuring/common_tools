python -m pip install -U huggingface_hub


org="meta-llama"
model="Meta-Llama-3-8B-Instruct"

org="facebook"
model="opt-6.7b"

org="dunzhang"
model="stella_en_400M_v5"

org="hustvl"
model="yolos-tiny"

org="hustvl"
model="yolos-base"

org="THUDM"
model="chatglm2-6b-int4"

org="openbmb"
model="MiniCPM-2B-dpo-bf16"

huggingface-cli download --resume-download ${org}/${model} ${args[@]:1} --local-dir ${jwHomePath}/zzzresources/${org}/${model}

# huggingface-cli login
# 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



# cd ${jwHomePath}/.resources
# zip -q -r ${org}"_"${model}.zip ${org}"/"${model}


# $jwrun common_tools/download_llm.sh aa bb
