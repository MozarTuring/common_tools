if [ "$#" -eq 0 ]; then
    echo "error"
    exit
fi

args=("$@")
last_arg=${args[-1]}

if [ $jwPlatform == "sribdGC" ]; then
    function gpus_collection() {
        for ((i = 0; i < 1000; i++)); do
            /usr/bin/sleep 1
            /usr/bin/nvidia-smi >gpu_.log
        done
    }
    gpus_collection &
fi
echo "Project path: "$jwHomePath
export jwResourceDir=$jwHomePath"/.resources"

scriptPath=${jwHomePath}/$1
cur_dir=${scriptPath%/*}
file_typ=${scriptPath##*.}
cd $cur_dir

# tmpTime=$(date +"%Y%m%d%H%M%S")
# echo $tmpTime
tmpTime=""
log_name=${scriptPath}${jwPlatform}$tmpTime

if [ $file_typ == "sh" ]; then
    source $scriptPath ${args[@]:1}
elif [ $file_typ == "py" ]; then
    source $cur_dir/jwmaoR.sh
    jwkill $1
    cd $cur_dir
    set -x
    if [ ${jwPlatform} == "sribdGC" ]; then
        python $scriptPath ${args[@]:1} >$log_name 2>&1
    else
        nohup python $scriptPath ${args[@]:1} >$log_name 2>&1 &
    fi
    set +x
else
    echo "pass"
fi
STATE="FALSE"

if [ $jwPlatform == "sribdGC" ]; then
    dst=$(echo $log_name | sed 's/mntcephfs\/lab_data/home/g')
    echo "
sshpass -p 9213 scp $log_name maojingwei@10.20.14.42:$dst" >>$log_name
fi

# line_start=$(grep -n $startFlag $scriptPath)
# # echo $line_start
# line_start=$(echo $line_start | grep -o '^[0-9]*')
# line_end=$(grep -n $endFlag $scriptPath)
# # echo $line_end
# line_end=$(echo $line_end | grep -o '^[0-9]*')

# newCommand=("")
# stopArg=$scriptPath
# if [ ! -z $line_start ]; then

#    ((line_start++))
#    tmp_text=$(sed -n ${line_start}p $scriptPath)
#    ccc=$(echo "$tmp_text" | cut -d',' -f1 --output-delimiter='')
#    # echo $ccc
#    if [[ $ccc == "stop" ]]; then
#       ccc=$(echo "$tmp_text" | cut -d',' -f2 --output-delimiter='')
#       # echo $ccc
#       stopArg=$ccc
#       ((line_start++))
#    fi
#    while [ $line_start -le $line_end ]; do
#       tmp_text=$(sed -n ${line_start}p $scriptPath)
#       ccc=$(echo "$tmp_text" | cut -d',' -f1 --output-delimiter='')
#       if [[ $ccc == "line" ]]; then
#          ccc=$(echo "$tmp_text" | cut -d',' -f2 --output-delimiter='')
#          ele=1

#          while [ $ele -le $ccc ]; do
#             ((line_start++))
#             tmp_text=$(sed -n ${line_start}p $scriptPath)

#             if [[ ${newCommand[0]} == "" ]]; then
#                newCommand=("$tmp_text")
#             else
#                newCommand+=("$tmp_text")
#             fi

#             ((ele++))
#          done
#       else
#          ((line_start++))
#       fi
#    done

# fi

# count=1
# echo "

# "

# bash $home_path"/common_tools/kill_pid.sh" $stopArg

# for element in "${newCommand[@]}"; do
#    set -x
#    nohup $exeProgrm $scriptPath $element >$log_name"$count" 2>&1 &
#    set +x
#    ((count++))
# done

# set -e 这会导致 grep 没找到的时候停止

# scontrol show node pgpu16
# scontrol show job
