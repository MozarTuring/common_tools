# set -e


googleDrive_path=$(echo "$1" | sed 's/\/home//g')
echo $googleDrive_path
exit

if [[ "$1" == "/home/maojingwei/project/common_tools_for_centos/"* ]]; then
    set -x
    sshpass -p 9213fCOW scp $1 maojingwei@10.20.14.43:$1
    sshpass -p 9213 scp $1 maojingwei@120.79.52.236:$1
    set +x
elif [[ "$1" == "/home/maojingwei/project/attendance_backend"* || "$1" == "/home/maojingwei/project/attendance_web_front"* || "$1" == "/home/maojingwei/project/sribd_attendance/udp2hls.sh" ]]; then
    set -x
    sshpass -p 9213 scp $1 maojingwei@120.79.52.236:$1
    set +x
fi

if [[ "$1" == *".py" ]]; then
    py_ver=$(head -n 1 $1)
    if [[ $py_ver =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        cur_dir=$(dirname $1)
        # cur_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
        if [ -f "$cur_dir/jwmaoR.sh" ]; then
            echo "already exists"
        else
            echo "set -e

source /home/maojingwei/project/common_tools_for_centos/myhead.sh condaenv $cur_dir $py_ver
cd $cur_dir


python -m pip install 
python -m pip list > $cur_dir/jwmaoRpip.txt

python -m pip install conda-pack
conda pack -p $cur_dir/aaaMjw_TMP/condaenv

echo 'jw done'

" >$cur_dir/jwmaoR.sh

        fi
    fi
fi
