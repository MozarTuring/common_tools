condabin=/home/maojingwei/mjw_tmp_jwm/installed/anaconda3/bin/

cd $2

if [ ! -d mjw_tmp_jwm ];then
mkdir mjw_tmp_jwm
fi

cd mjw_tmp_jwm


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

