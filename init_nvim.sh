if false; then
# use it when need
cd ~/jwSoftware/; rm vim_pack.tar.gz;
tar -czf vim_pack.tar.gz vim_pack
scp alvis2:~/jwSoftware/vim_pack.tar.gz ~/baidu/

cd ~/baidu; tar -czf nvim_linux.tar.gz nvim
fi

# on local; inside neovim, visual select lines want to run, then press :, then w !bash
remoteName=custodian2greatrawr # set it in .ssh/config
cd ~/project/; rm common_tools.tar.gz; tar -czf common_tools.tar.gz common_tools
if [ remoteName == 'goodleColab' ]; then
    echo 'googleColab'
# manually upload from local to google drive first
else
    scp common_tools.tar.gz $remoteName:~/
    scp ~/baidu/nvim_linux.tar.gz $remoteName:~/
    scp ~/baidu/vim_pack.tar.gz $remoteName:~/
fi


if false; then

# copy the following to terminal on remote
mkdir -p ~/project
mkdir -p ~/jwSoftware

if [ -d /content/drive/MyDrive/ ]; then
    cp /content/drive/MyDrive/nvim_linux.tar.gz ~/jwSoftware/
    cp /content/drive/MyDrive/common_tools.tar.gz ~/project/
else
    mv ~/nvim_linux.tar.gz ~/jwSoftware/
    cd ~/jwSoftware
    tar -xzf nvim_linux.tar.gz

    mv ~/vim_pack.tar.gz ~/jwSoftware/; cd ~/jwSoftware/; rm -rf vim_pack;
    tar -xzf vim_pack.tar.gz

    mv ~/common_tools.tar.gz ~/project/
    cd ~/project/
    tar -xzf common_tools.tar.gz
fi

DIR=~/.config/nvim
# if using "~/.config/nvim" if will create under folder named "~" rather than home directory
if [ -d $DIR ]; then
    rm -rf $DIR
fi
mkdir -p $DIR

if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "macOS"
    echo "source ~/project/common_tools/bash_profile" >> ~/.bash_profile
    ln -s /Users/maojingwei/baidu/project/common_tools/init_nvim_mac.lua $DIR/init.lua
else
    echo "source ~/project/common_tools/bash_profile" >> ~/.profile
    ln -s /Users/maojingwei/baidu/project/common_tools/init_nvim_linux.lua $DIR/init.lua
fi
exit

fi
