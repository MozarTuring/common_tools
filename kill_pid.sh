ps -ef|grep $1|awk '{print $2,$8}'|while read pid_command
do
    arr=($pid_command)
    #kill -9 $tmp_pid
    if [ "${arr[1]}" == "python" ]; then
        kill -9 ${arr[0]}
        echo "${arr[1]} ${arr[0]} is killed"
    fi
done

