if [ -d "/content/drive/MyDrive/maojingwei" ]; then
rm /usr/local/bin/jw* /usr/local/bin/ngrok
    jwHomePath=/content/drive/MyDrive/maojingwei/project
    jwCondaBin="none"
    jwPlatform="Colab"
    mkdir -p /root/.ssh
    cp $jwHomePath/common_tools/id_rsa /root/.ssh/id_rsa
    ssh-keyscan -t rsa github.com >>/root/.ssh/known_hosts

    chmod +x $jwHomePath/ngrok-v3-stable-linux-amd64/ngrok
    ln -s $jwHomePath/ngrok-v3-stable-linux-amd64/ngrok /usr/local/bin/ngrok
    ngrok config add-authtoken 2iLwxn3OMhW45CT4SNOIPlXMYPX_3MgeK1rdZdyckMMrLh4xX
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
fi

tmpRun=$jwHomePath/common_tools/jwrun.sh
chmod +x $tmpRun

tmpKill=$jwHomePath/common_tools/jwkill.sh
chmod +x $tmpKill

tmpRuncpu=$jwHomePath/common_tools/jwruncpu.sh
chmod +x $tmpRuncpu

if [ $jwPlatform == "Colab" ]; then

    ln -s $tmpRun /usr/local/bin/jwrun
    ln -s $tmpKill /usr/local/bin/jwkill
    ln -s $tmpRuncpu /usr/local/bin/jwruncpu
else
    export jwrun=$tmpRun
    export jwkill=$tmpKill
    export jwruncpu=$tmpRuncpu
fi

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
