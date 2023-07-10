cd $2
pwd


if [ $1 == "pyenv" ]; then
    if [ ! -d "pyenv" ]; then
        echo "create pyenv"
        /home/maojingwei/installed/python3.8.16/bin/python3 -m virtualenv pyenv
    fi
    source pyenv/bin/activate
elif [ $1 == "condaenv" ]; then
    if [ ! -d "condaenv" ]; then
        echo "create condaenv"
        conda create -p condaenv python=3.8.16
    fi
    source /cm/shared/apps/anaconda3/bin/activate $cur_dir/condaenv
fi

which python

