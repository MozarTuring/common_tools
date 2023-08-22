

if [ "$1" == "pyenv" ]; then
    cd /home/maojingwei/jw_pyenv
    if [ ! -d "$2" ]; then
        echo "create pyenv $2"
        /home/maojingwei/installed/python$3/bin/python3 -m virtualenv $2
    fi
    source $2/bin/activate
elif [ "$1" == "condaenv" ]; then
    cd /home/maojingwei/jw_condaenv
    if [ ! -d "$2" ]; then
        echo "create condaenv $2"
        /home/maojingwei/installed/anaconda3/bin/conda create -p $2 python=$3
    fi
    source /home/maojingwei/installed/anaconda3/bin/activate ./$2
fi

which python

