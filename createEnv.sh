if [ "$#" -ne 1 ]; then
    echo "error"
    exit
fi

env_path=${cur_dir}/aaaMjw_TMP

if [ ! -d $env_path ]; then
    mkdir -p $env_path
fi

cd $env_path

if [ ! -f ${jwCondaBin}"/conda" ]; then
    if [ -f ${jwCondaBin}"/python" ]; then
        cd /home/maojingwei/jw_pyenv
        if [ ! -d "pyenv" ]; then
            echo "create pyenv"
            ${jwCondaBin}/python -m virtualenv pyenv
        fi
        source pyenv/bin/activate
    else
        echo "pass"
    fi
else
    if [ ! -d "condaenv" ]; then
        if [ ! -f "condaenv.tar.gz" ]; then
            echo "create condaenv"
            ${jwCondaBin}/conda create -p condaenv python=$1
        else
            echo "create condaenv from pack"
            tar -xzvf condaenv.tar.gz -C condaenv
        fi
    fi
    source ${jwCondaBin}/activate ./condaenv
    #    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
    pip config set global.index-url https://pypi.mirrors.ustc.edu.cn/simple
fi

echo "using python env:"
which python
echo "
"
