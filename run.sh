set -e # 出错则停止

var1=$1
echo $1

cur_dir=${var1%/*}
cur_name=${var1##*/}
cur_name_pre=${cur_name%.*}
cd $cur_dir
echo $cur_dir
echo $cur_name
echo $cur_name_pre



if [ -d "pyenv" ]; then
    source pyenv/bin/activate
elif [[ $cur_dir == *sribd_attendance/* ]]; then
    source /home/maojingwei/project/sribd_attendance/pyenv/bin/activate
else
    source /home/maojingwei/python3.8.16env/base/bin/activate
fi
which python

if [ "$2" = "nohup" ]; then
    if [ ! -d "jwlogs" ]; then
      mkdir "jwlogs"
      echo "jwlogs dir created"
    fi
    nohup python $1 >jwlogs/$cur_name_pre.log 2>&1 &
elif [ "$2" = "run" ]; then
    python $1
elif [ "$2" = "debug" ]; then
    if [ ! -d "debug_jwlogs" ]; then
      mkdir "debug_jwlogs"
      echo "debug_jwlogs dir created"
    fi
#    nohup python $1 --debug >debug_jwlogs/$cur_name_pre.log 2>&1 &
    python $1 --debug
else
    echo "unknown argument "$2
fi
#else
#    echo "debug or not?"
#    read -r deb_flag
#    echo $deb_flag
#    if [ deb_flag = "y" ]; then
#        python $1 --debug
#    else
#        python $1
#    fi
#fi
