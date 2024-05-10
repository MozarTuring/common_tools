


if [[ "$1" == "/home/maojingwei/project/common_tools_for_centos/"* ]]; then
set -x
    sshpass -p 9213fCOW scp $1 maojingwei@10.20.14.43:$1
    sshpass -p 9213 scp $1 maojingwei@120.79.52.236:$1
    set +x
elif [[ "$1" == "/home/maojingwei/project/attendance_backend"* ]]; then
set -x
sshpass -p 9213 scp $1 maojingwei@120.79.52.236:$1
set +x
elif [[ "$1" == "/home/maojingwei/project/attendance_web_front"* ]]; then
set -x
sshpass -p 9213 scp $1 maojingwei@120.79.52.236:$1
set +x
elif [[ "$1" == "/home/maojingwei/project/sribd_attendance/udp2hls.sh" ]]; then
set -x
sshpass -p 9213 scp $1 maojingwei@120.79.52.236:$1
set +x
fi