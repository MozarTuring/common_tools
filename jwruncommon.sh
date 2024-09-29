if [ "$#" -eq 0 ]; then
    echo "error"
    exit
fi

args=("$@")
last_arg=${args[-1]}

if [ $jwPlatform == "sribdGC" ]; then
    function gpus_collection() {
        for ((i = 0; i < 1000; i++)); do
            /usr/bin/sleep 1
            /usr/bin/nvidia-smi >gpu_.log
        done
    }
    gpus_collection &
fi
echo "Project path: "$jwHomePath

scriptPath=${jwHomePath}/$1


export jw_cur_dir=${scriptPath%/}
if [ -f $scriptPath ]; then
    export jw_cur_dir=${scriptPath%/*}
    file_typ=${scriptPath##*.}
    fileName=$(basename $scriptPath "."$file_typ)
elif [ -d $scriptPath ]; then
    echo "launch python"
    source $jw_cur_dir/jwmaoR.sh
    cd $jw_cur_dir
    nvim .
    exit
else
    echo "error"
    exit
fi

if [ $file_typ == "sh" ]; then
    source $scriptPath ${args[@]:1} >${scriptPath}${jwPlatform} 2>&1 & # source can not be run using nohup
    exit
fi


cur_dir_name=$(basename $jw_cur_dir)
export jwResourceDir=$jwHomePath/zzzresources/$cur_dir_name
mkdir -p $jwResourceDir

export jwtime=$(date +"%Y%m%d%H%M%S")
# export jwoutput=$jw_cur_dir/${jwtime}_jwo${jwPlatform}



# if [ -d $jwoutput ]; then
#     echo "output dir exists"
#     exit
# fi


if [ $file_typ == "py" ]; then

    source $jw_cur_dir/jwmaoR.sh
    cd $jw_cur_dir

    jwkill $1
    # mkdir -p $jwoutput
    set -x
    if [ ${jwPlatform} == "sribdGC" ]; then
        python $scriptPath ${args[@]:1} 2>&1
    else
        nohup python $scriptPath ${args[@]:1} >${scriptPath}${jwPlatform} 2>&1 &
    fi
    set +x
else
    echo "pass"
fi

STATE="FALSE"

if [ $jwPlatform == "sribdGC" ]; then
    dst=$(echo $jwoutput/log.txt | sed "s/mntcephfs\/lab_data/home/g")
    echo "
sshpass -p 9213 scp $jwoutput/log.txt maojingwei@10.20.14.42:$dst" >>$jwoutput/log.txt
fi

echo "shell exit"

