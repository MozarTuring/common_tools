if [ "$#" -ne 1 ]; then
    echo "error"
    exit
fi

env_path=${jw_cur_dir}/111mjw_tmp_jwm
if [ ! -d $env_path ]; then
    mkdir -p $env_path
fi
cd $env_path

if [ ! -d "condaenv" ]; then
    if [ "$1" == "condaenv.tar.gz" ]; then
        echo "create condaenv from pack"
        tar -xzvf condaenv.tar.gz -C condaenv
        exit
    else
        echo "create condaenv"
        ${jwCondaBin}/conda create -y -p condaenv python=$1
        source ${jwCondaBin}/activate ./condaenv
#        conda create -y -p condaenv python=$1
#        conda activate ./condaenv
        pip config set global.index-url https://pypi.mirrors.ustc.edu.cn/simple
        rm condaenv.tar.gz
        pip install conda-pack
        pip install pynvim
        pip install jedi
        conda pack -p ./condaenv
        echo "condaenv created and exit"
        exit
    fi
fi

if [ -f ./condaenv/bin/activate ]; then
    source ./condaenv/bin/activate
else
    source ${jwCondaBin}/activate ./condaenv
#    conda init
#    conda activate ./condaenv
fi
#    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
pip config set global.index-url https://pypi.mirrors.ustc.edu.cn/simple

echo "using python env:"
which python
echo "
"

cd $jw_cur_dir

