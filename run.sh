# set -e 这会导致 grep 没找到的时候停止

#!/bin/bash
#SBATCH -A R20240614095217
#SBATCH -p p-A100
#SBATCH -N 1
#SBATCH -W pgpu16
#SBATCH --reservation=root_139
#SBATCH -c 15
#SBATCH --gres=gpu:1
if [ -d "/content/drive/MyDrive/maojingwei" ]; then
   export jwHomePath="/content/drive/MyDrive/maojingwei/project"
   log_suffix=Colab
   jwCondaBin=none
elif [ -d "/mntcephfs/lab_data/maojingwei" ]; then
   export jwHomePath="/mntcephfs/lab_data/maojingwei/project"
   jwCondaBin=/cm/shared/apps/anaconda3/bin
else
   export jwHomePath="/home/maojingwei/project"
   log_suffix=Local
   jwCondaBin=/home/maojingwei/mjw_tmp_jwm/installed/anaconda3/bin
fi
scriptPath=$1
cur_dir=${scriptPath%/*}
file_typ=${scriptPath##*.}
log_name=${scriptPath}_log${log_suffix}

cd $cur_dir

if [ $file_typ == "sh" ]; then
   source $1
elif [ $file_typ == "py" ]; then
   source $cur_dir/jwmaoR.sh
   bash ${jwHomePath}/common_tools/kill_pid.sh $1
   nohup python $1 $2 >$log_name 2>&1 &
else
   echo "pass"
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
