set -e # 出错则停止

var1=$1
echo $1

cur_dir=${var1%/*}
cur_name=${var1##*/}
cur_name_pre=${cur_name%.*}

cd $cur_dir

while read line
do
    ps -ef|grep $line|awk '{print $2,$8}'|while read pid_command
    do
        arr=($pid_command)
        #kill -9 $tmp_pid
        if [ "${arr[1]}" == "python" ]; then
            kill -9 ${arr[0]}
            echo "${arr[1]} ${arr[0]} is killed"
        fi
    done
done < ztmpStopCommand_$cur_name_pre.txt

