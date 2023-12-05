set -e # 出错则停止



while read line
do
    ps -ef|grep $line|awk '{print $2,$8}'|while read pid_command
    do
        arr=($pid_command)
        #kill -9 $tmp_pid
        if [ "${arr[1]}" == "python" ] || [ "${arr[1]}" == "bash" ]; then
            kill -9 ${arr[0]}
            echo "${arr[1]} ${arr[0]} is killed"
        fi
    done
done < $1

