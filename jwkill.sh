if [ "$#" -eq 0 ]; then
    echo "error"
    exit
fi

func() {
    if [[ "$2" =~ python ]] || [ "$2" == "ffmpeg" ] || [ "$2" == "bash" ] || [ "$2" == "TCP" ]; then
        kill -9 $1
        echo "$2 $1 is killed"
    else
        echo "$2 $1 not killed"
    fi
}

line="$@"
echo $line
if [ ${line:0:4} == "lsof" ]; then
    # echo "1"
    $line | awk '{print $2,$8}' | while read pid_command; do
        func $pid_command # $pid_command has space, so 2 params and here if change ' to ", will error
    done
elif [[ $line == *".py" ]]; then
    # echo "2"
    line=${jwHomePath}/$line
    ps -ww -eo pid,cmd | grep "$line" | grep "python" | awk '{print $1,$2}' | while read pid_command; do
        func $pid_command
    done
elif [[ $line == *".sh" ]]; then
    # echo "3"
    ps -ww -eo pid,cmd | grep "$line" | grep "bash" | grep -v "kill_pid.sh" | awk '{print $1,$2}' | while read pid_command; do
        func $pid_command
    done
else
    # echo "4"
    ps -ww -eo pid,cmd | grep "$line" | grep -v "kill_pid.sh" | awk '{print $1,$2}' | while read pid_command; do
        func $pid_command
    done
fi

# 使用 ps -ef 在colab上显示出来的 cmd 不完整
