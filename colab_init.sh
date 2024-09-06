if [ -d "/content/drive/MyDrive/maojingwei" ]; then
    rm /usr/local/bin/jw* /usr/local/bin/ngrok
    jwHomePath=/content/drive/MyDrive/maojingwei/project
    jwCondaBin="none"
    jwPlatform="Colab"
    mkdir -p /root/.ssh
    cp $jwHomePath/common_tools/id_rsa /root/.ssh/id_rsa
    ssh-keyscan -t rsa github.com >>/root/.ssh/known_hosts

elif [ -d "/mntcephfs/lab_data/maojingwei" ]; then
    export jwCondaBin=/cm/shared/apps/anaconda3/bin

    export jwHomePath="/mntcephfs/lab_data/maojingwei/project"
    alias jwshow="scontrol show"
    export jwPlatform="sribdGC"

else
    export jwCondaBin=/home/maojingwei/mjw_tmp_jwm/installed/anaconda3/bin
    export jwPlatform="local"
    export jwHomePath="/home/maojingwei/project"
    rm /home/maojingwei/project/.vscode/launch.json
    ln -s /home/maojingwei/project/common_tools/.vscode/launch.json /home/maojingwei/project/.vscode/launch.json
    rm /home/maojingwei/project/.vscode/tasks.json
    ln -s /home/maojingwei/project/common_tools/.vscode/tasks.json /home/maojingwei/project/.vscode/tasks.json
    rm /home/maojingwei/project/.vscode/settings.json
    ln -s /home/maojingwei/project/common_tools/.vscode/settings.json /home/maojingwei/project/.vscode/settings.json
fi

jwBin="$jwHomePath/../mjw_tmp_jwm/jwbin"
mkdir -p $jwBin

rm $jwBin/*

export PATH="$jwBin:$PATH"

chmod +x $jwHomePath/zzzresources/ngrok
ln -s $jwHomePath/zzzresources/ngrok $jwBin/ngrok
ngrok config add-authtoken 2iLwxn3OMhW45CT4SNOIPlXMYPX_3MgeK1rdZdyckMMrLh4xX

export jwrun=$jwHomePath/common_tools/jwrun.sh
chmod +x $jwrun

export jwkill=$jwHomePath/common_tools/jwkill.sh
chmod +x $jwkill

export jwruncpu=$jwHomePath/common_tools/jwruncpu.sh
chmod +x $jwruncpu

set -x
ln -s $jwrun $jwBin/jwrun
ln -s $jwkill $jwBin/jwkill
ln -s $jwruncpu $jwBin/jwruncpu
# ln -s $jwrun /usr/local/bin/jwrun
# ln -s $jwkill /usr/local/bin/jwkill
# ln -s $jwruncpu /usr/local/bin/jwruncpu
set +x


# echo $jwrun

# chmod +x jwrun
# chmod +x jwkill

# jwbin=$jwHomePath/../jwbin

# mkdir -p $jwbin

# rm $jwbin/jwrun
# chmod +x $jwHomePath/common_tools/jwrun.sh
# ln -s $jwHomePath/common_tools/jwrun.sh $jwbin/jwrun

# export PATH="$jwbin:$PATH"

cd $jwHomePath

# 在colab上直接编辑文件，输入以上内容似乎不能正常运行。可能和colab编辑器采用的换行符不对有关。在本地编辑好再上传是ok的
