cd $2
pwd

version=3.8.16

if [ $# -eq 3 ];then
    verion=$3
fi

if [ "$1" == "pyenv" ]; then
    if [ ! -d "pyenv" ]; then
        echo "create pyenv"
        /home/maojingwei/installed/python$version/bin/python3 -m virtualenv pyenv
    fi
    source pyenv/bin/activate
elif [ "$1" == "condaenv" ]; then
    if [ ! -d "condaenv" ]; then
        echo "create condaenv"
        /home/maojingwei/installed/anaconda3/bin/conda create -p condaenv python=$version
    fi
    source /home/maojingwei/installed/anaconda3/bin/activate $2/condaenv
fi

which python

