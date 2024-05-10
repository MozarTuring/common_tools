condabin=/home/maojingwei/mjw_tmp_jwm/installed/anaconda3/bin/


cur_dir=$2
env_path=${cur_dir/project/mjw_tmp_jwm\/project}

if [ ! -d $env_path ]; then
    mkdir -p $env_path
fi

cd $env_path

if [ "$1" == "pyenv" ]; then
    cd /home/maojingwei/jw_pyenv
    if [ ! -d "$2" ]; then
        echo "create pyenv $2"
        /home/maojingwei/installed/python$3/bin/python3 -m virtualenv $2
    fi
    source $2/bin/activate
elif [ "$1" == "condaenv" ]; then
    if [ ! -d condaenv ]; then
        if [ ! -f "condaenv.tar.gz" ]; then
            echo "create condaenv"
            $condabin/conda create -p condaenv python=$3
        else
            echo "create condaenv from pack"
            tar -xzvf condaenv.tar.gz -C condaenv
        fi
    fi
    source $condabin/activate ./condaenv
#    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
    pip config set global.index-url https://pypi.mirrors.ustc.edu.cn/simple 
fi

echo "using python env:"
which python
echo "
"

