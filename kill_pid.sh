set -e # 出错则停止

func() {
    if [[ "$2" =~ python ]] || [ "$2" == "ffmpeg" ] || [ "$2" == "bash" ] || [ "$2" == "TCP" ]; then
        kill -9 $1
        echo "$2 $1 is killed"
    else
        echo "$2 $1 not killed"
    fi
}

line="$@"
# echo $line
if [ ${line:0:4} == "lsof" ]; then
    # echo "1"
    $line | awk '{print $2,$8}' | while read pid_command; do
        func $pid_command # $pid_command 是带空格的，所以是2个入参
    done
elif [[ $line == *".py" ]]; then
    # echo "2"
    ps -ef | grep "$line" | grep "python" | awk '{print $2,$8}' | while read pid_command; do
        func $pid_command
    done
elif [[ $line == *".sh" ]]; then
    # echo "3"
    ps -ef | grep "$line" | grep "bash" | grep -v "kill_pid.sh" | awk '{print $2,$8}' | while read pid_command; do
        func $pid_command
    done
else
    # echo "4"
    ps -ef | grep "$line" | grep -v "kill_pid.sh" | awk '{print $2,$8}' | while read pid_command; do
        func $pid_command
    done
fi
