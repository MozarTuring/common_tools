

if [ "$1" == "pyenv" ]; then
    cd /home/maojingwei/jw_pyenv
    if [ ! -d "$2" ]; then
        echo "create pyenv $2"
        /home/maojingwei/installed/python$3/bin/python3 -m virtualenv $2
    fi
    source $2/bin/activate
elif [ "$1" == "condaenv" ]; then
    if [ ! -d "/home/maojingwei/jw_condaenv" ]; then
        mkdir -p "/home/maojingwei/jw_condaenv" 
        echo "/home/maojingwei/jw_condaenv created" 
    fi
    cd /home/maojingwei/jw_condaenv
    if [ ! -d "$2" ]; then
        if [ ! -f "$2.tar.gz" ]; then
            echo "create condaenv $2"
            /home/maojingwei/installed/anaconda3/bin/conda create -p $2 python=$3
        else
            mkdir $2
            echo "create condaenv $2 from pack"
            tar -xzvf $2.tar.gz -C $2
        fi
    fi
    source /home/maojingwei/installed/anaconda3/bin/activate ./$2
#    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
#    pip config set global.index-url https://pypi.mirrors.ustc.edu.cn/simple 
fi

echo "using python env:"
which python
echo "
"

