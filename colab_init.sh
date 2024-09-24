alias rm='DIR=~/mjw_tmp_jwm/trash/`date +%F%T`;mkdir -p $DIR;mv -t $DIR'

if [ -d /content/drive/MyDrive/maojingwei ]; then
    rm /usr/local/bin/jw* /usr/local/bin/ngrok
    jwHomePath=/content/drive/MyDrive/maojingwei/project
    jwCondaBin="none"
    jwPlatform="Colab"
    mkdir -p /root/.ssh
    cp $jwHomePath/common_tools/id_rsa /root/.ssh/id_rsa
    ssh-keyscan -t rsa github.com >>/root/.ssh/known_hosts

elif [ -d /mntcephfs/lab_data/maojingwei ]; then
    export jwCondaBin=/cm/shared/apps/anaconda3/bin

    export jwHomePath="/mntcephfs/lab_data/maojingwei/project"
    alias jwshow="scontrol show"
    export jwPlatform="sribdGC"

elif [ -d /mnt/data/project ]; then
    export jwCondaBin=/root/anaconda3/bin

    export jwHomePath=/mnt/data/project
    export jwPlatform="cmhk"

else
    export jwCondaBin=/home/maojingwei/mjw_tmp_jwm/installed/anaconda3/bin
    export jwPlatform="local"
    export jwHomePath=~/project
    rm $jwHomePath/.vscode/launch.json
    ln -s $jwHomePath/common_tools/.vscode/launch.json $jwHomePath/.vscode/launch.json
    rm $jwHomePath/.vscode/tasks.json
    ln -s $jwHomePath/common_tools/.vscode/tasks.json $jwHomePath/.vscode/tasks.json
    rm $jwHomePath/.vscode/settings.json
    ln -s $jwHomePath/common_tools/.vscode/settings.json $jwHomePath/.vscode/settings.json
fi

export PATH="/usr/local/cuda/bin:/usr/local/MATLAB/R2022b/bin:~/mjw_tmp_jwm/TensorRT-8.2.5.1/bin:$jwHomePath/zzzresources/software/nvim/bin/:~/mjw_tmp_jwm/cmake/bin/:~/mjw_tmp_jwm/jwbin:$PATH"
# nvim in resources because it may add packages which should be saved
export LD_LIBRARY_PATH="~/mjw_tmp_jwm/TensorRT-8.2.5.1/lib:/usr/local/cuda-11.4/extras/CUPTI/lib64:$LD_LIBRARY_PATH"
export LD_INCLUDE_PATH="~/mjw_tmp_jwm/TensorRT-8.2.5.1/include:$LD_INCLUDE_PATH"




rm ~/.config/nvim

# ln -s $jwHomePath/common_tools/lazy_nvim ~/.config/nvim
mkdir -p ~/.config/nvim/
ln -s $jwHomePath/common_tools/init_nvim.lua ~/.config/nvim/init.lua

ln -s $jwHomePath/common_tools/tmux.conf ~/.tmux.conf


# jwBin=~/mjw_tmp_jwm/jwbin
# mkdir -p $jwBin this way will not treat ~ as the home dir
mkdir -p ~/mjw_tmp_jwm/jwbin

rm ~/mjw_tmp_jwm/jwbin/*

export TERM=xterm-256color
chmod +x $jwHomePath/zzzresources/ngrok
ln -s $jwHomePath/zzzresources/ngrok ~/mjw_tmp_jwm/jwbin/ngrok
ngrok config add-authtoken 2iLwxn3OMhW45CT4SNOIPlXMYPX_3MgeK1rdZdyckMMrLh4xX

export jwrun=$jwHomePath/common_tools/jwrun.sh
chmod +x $jwrun

export jwkill=$jwHomePath/common_tools/jwkill.sh
chmod +x $jwkill

export jwruncpu=$jwHomePath/common_tools/jwruncpu.sh
chmod +x $jwruncpu

export jwclone=$jwHomePath/common_tools/jwclone.sh
chmod +x $jwclone

set -x
ln -s $jwrun ~/mjw_tmp_jwm/jwbin/jwrun
ln -s $jwkill ~/mjw_tmp_jwm/jwbin/jwkill
ln -s $jwruncpu ~/mjw_tmp_jwm/jwbin/jwruncpu
ln -s $jwclone ~/mjw_tmp_jwm/jwbin/jwclone
set +x

 

cd $jwHomePath

ps aux --sort=-rss | head

# 在colab上直接编辑文件，输入以上内容似乎不能正常运行。可能和colab编辑器采用的换行符不对有关。在本地编辑好再上传是ok的
