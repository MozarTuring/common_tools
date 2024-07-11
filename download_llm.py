# import transformers
# print(transformers.__version__)


# !pip install sentence_transformers==2.2.2
# from sentence_transformers import SentenceTransformer, util
# SentenceTransformer('paraphrase-multilingual-MiniLM-L12-v2')





import os
import shutil
import huggingface_hub as hh
import pandas as pd


def format_size(bytes, precision=2):
    """
    Convert a file size in bytes to a human-readable format like KB, MB, GB, etc.
    Huggingface use 1000 not 1024
    """
    units = ["B", "KB", "MB", "GB", "TB", "PB"]
    size = float(bytes)
    index = 0

    while size >= 1000 and index < len(units) - 1:
        index += 1
        size /= 1000

    return f"{size:.{precision}f} {units[index]}"


def list_repo_files_info(repo_id):
    data_ls = []
    for file in list(hh.list_files_info(repo_id)):
        data_ls.append([file.path,format_size(file.size)])
    files = [file[0] for file in data_ls]
    data = pd.DataFrame(data_ls,columns = ['文件名','大小'])
    return data, files

# 模型下载到当前目录下的"./download"目录
def download_file(repo_id):
    data, filenames = list_repo_files_info(repo_id)
    print(filenames)
    # repo_name = repo_id.replace("/","---")
    repo_name = repo_id

    for filename in filenames:
        print(filename)
        if ".bin" in filename:
            continue
        out = hh.hf_hub_download(repo_id=repo_id,filename=filename,local_dir=f"/content/drive/MyDrive/maojingwei/project/.resources/{repo_name}",local_dir_use_symlinks=False,force_download =True)
    # out_path = f"./download/{repo_name}"
    # os.system(f"zip -q -r {repo_name}.zip ./download/{repo_name}")
    # return out_path



if __name__ == "__main__":
    download_file("")


# bash /home/maojingwei/project/common_tools/download_llm_jwenv.sh env download_llm.py
