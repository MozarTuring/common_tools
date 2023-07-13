cd $1
if [ -d "pyenv" ]; then
    rm -rf pyenv
fi
scp -r $1 $2
