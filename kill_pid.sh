set -e # 出错则停止



func(){
#kill -9 $tmp_pid
if [ "$2" == "python" ] || [ "$2" == "ffmpeg" ] || [ "$2" == "bash" ] || [ "$2" == "TCP" ]; then
    kill -9 $1
    echo "$2 $1 is killed"
fi
}


while read line
do
    echo $line
    if [ ${line:0:4} == "lsof"  ]; then
        $line|awk '{print $2,$8}'|while read pid_command
        do
            func $pid_command
        done
    else
        ps -ef|grep "$line"|awk '{print $2,$8}'|while read pid_command
        do
            func $pid_command
        done
    fi
done < $1

