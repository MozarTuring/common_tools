
# tar -czf nvim.tar.gz nvim


mkdir -p ~/baidu/project/common_tools
if [ -d /content/drive/MyDrive ]; then
    cp /content/drive/MyDrive/nvim.tar.gz ~/baidu/
    cp /content/drive/MyDrive/project/common_tools/* ~/baidu/project/common_tools/
fi


# scp ~/Downloads/nvim.tar.gz alvis1:~/baidu/
# scp ~/baidu/project/common_tools/* alvis1:~/baidu/project/common_tools/

cd ~/baidu/
tar -xzf nvim.tar.gz
rm nvim.tar.gz
export PATH="~/baidu/nvim/bin/:$PATH"

DIR=~/.config/nvim # if using "~/.config/nvim" if will create under folder named "~" rather than home directory
if [ -d $DIR ]; then
    echo "Directory $DIR exists. Deleting..."
    rm -rf $DIR
    echo "Deleted $DIR."
fi
mkdir -p $DIR

ln -s ~/baidu/project/common_tools/init_nvim.lua $DIR/init.lua

cd project
nvim .
