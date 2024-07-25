python -m pip install -U huggingface_hub


org="meta-llama"
model="Meta-Llama-3-8B-Instruct"

org="facebook"
model="opt-6.7b"

org="dunzhang"
model="stella_en_400M_v5"

huggingface-cli download --resume-download ${org}/${model} $@ --local-dir ${jwHomePath}/.resources/${org}/${model}

# huggingface-cli login
# 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



# cd ${jwHomePath}/.resources
# zip -q -r ${org}"_"${model}.zip ${org}"/"${model}


# $jwrun common_tools/download_llm.sh aa bb