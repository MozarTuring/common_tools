# set -e

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

if [[ "$1" == "/home/maojingwei/project/common_tools/"* || "$1" == "/home/maojingwei/project/vllm/"* || "$1" == "/home/maojingwei/project/LLaMA-Factory/"* || "$1" == "/home/maojingwei/project/Telco-RAG/"* || "$1" == "/home/maojingwei/project/DroneDetectron2/"* ]]; then
    set -x
    # sshpass -p 9213fCOW scp $1 maojingwei@10.20.14.43:$1
    # sshpass -p 9213 scp $1 maojingwei@120.79.52.236:$1
    bash /home/maojingwei/project/common_tools/rclone.sh $1
    bash /home/maojingwei/project/common_tools/file2sribdGroup.sh $1
    set +x
elif [[ "$1" == "/home/maojingwei/project/attendance_backend"* || "$1" == "/home/maojingwei/project/attendance_web_front"* || "$1" == "/home/maojingwei/project/sribd_attendance/udp2hls.sh" ]]; then
    set -x
    sshpass -p 9213 scp $1 maojingwei@120.79.52.236:$1
    set +x
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
