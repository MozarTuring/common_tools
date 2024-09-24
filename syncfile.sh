# set -e

echo $1

if [ -d "/content/drive/MyDrive/maojingwei" ]; then
    home_path="/content/drive/MyDrive/maojingwei/project"
else
    home_path="/home/maojingwei/project"
fi
# source $home_path"/common_tools/common_func.sh" $1

if test -d "$1"; then
    echo "error:dir"
    exit
fi

if [[ "$1" == "/home/maojingwei/project/vllm"* ]]; then
    bash /home/maojingwei/project/common_tools/jwclone.sh $1 43
elif [[ "$1" == "/home/maojingwei/project/cmhk"* ]]; then
    bash /home/maojingwei/project/common_tools/jwclone.sh $1 42
elif [[ "$1" == "/home/maojingwei/project/common_tools"* ]]; then
    bash /home/maojingwei/project/common_tools/jwclone.sh $1 43
    bash /home/maojingwei/project/common_tools/jwclone.sh $1 42
fi

# if [[ "$1" == *".py" ]]; then
#     env_path=$cur_dir"/"$cur_name_pre"_jwenv.sh"

#     py_ver=$(head -n 1 $1)
#     if [[ $py_ver =~ ^[0-9]+([.][0-9]+)?$ ]]; then
#         cur_dir=$(dirname $1)
#         # cur_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
#         if [ -f $env_path ]; then
#             echo "already exists"
#         else
#             echo"
# set -e
# if [ -d '/content/drive/MyDrive/maojingwei' ]; then
#    python -m pip install
# else
#    home_path='/home/maojingwei/project'
#    source $home_path/common_tools/myhead.sh condaenv $cur_dir $py_ver
# cd $cur_dir
# python -m pip install
# python -m pip list > $cur_dir/jwmaoRpip.txt

# python -m pip install conda-pack
# conda pack -p $cur_dir/aaaMjw_TMP/condaenv
# fi

# echo 'jw done'
# " > $env_path

#         fi
#     fi
# fi
