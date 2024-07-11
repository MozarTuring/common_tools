python -m pip install -U huggingface_hub


org="meta-llama"
model="Meta-Llama-3-8B-Instruct"

# huggingface-cli login
# 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

huggingface-cli download --resume-download ${org}/${model} --local-dir ${jwHomePath}/.resources/${org}/${model}

cd ${jwHomePath}/.resources
zip -q -r ${org}"_"${model}.zip ${org}"/"${model}


# bash /home/maojingwei/project/common_tools/run.sh /home/maojingwei/project/common_tools/download_llm.sh