set -e # 出错则停止

var1=$1
echo $1

cur_dir=${var1%/*}
cur_name=${var1##*/}
cur_name_pre=${cur_name%.*}
source $cur_dir/myRequirements.sh

cd $cur_dir

pwd

if [ "$2" = "nohup" ]; then
    if [ ! -d "jwlogs" ]; then
      mkdir "jwlogs"
      echo "jwlogs dir created"
    fi
    nohup python $1 >jwlogs/${cur_name_pre}.log 2>&1 &
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
