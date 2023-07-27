cd $1
#conda export
if [ -d "pyenv" ]; then
    rm -rf pyenv
fi
scp -r $1 $2
