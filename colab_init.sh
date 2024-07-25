if [ -d "/content/drive/MyDrive/maojingwei" ]; then
    export jwHomePath="/content/drive/MyDrive/maojingwei/project"
    mkdir -p /root/.ssh
    cp $jwHomePath/common_tools/id_rsa /root/.ssh/id_rsa
    ssh-keyscan -t rsa github.com >>/root/.ssh/known_hosts

    chmod +x $jwHomePath/ngrok-v3-stable-linux-amd64/ngrok
    if [ -e /usr/local/bin/ngrok ]; then
        rm /usr/local/bin/ngrok
    fi
    ln -s $jwHomePath/ngrok-v3-stable-linux-amd64/ngrok /usr/local/bin/ngrok
    ngrok config add-authtoken 2iLwxn3OMhW45CT4SNOIPlXMYPX_3MgeK1rdZdyckMMrLh4xX
elif [ -d "/mntcephfs/lab_data/maojingwei" ]; then
    export jwHomePath="/mntcephfs/lab_data/maojingwei/project"
    alias jwshow="scontrol show"
else
    export jwHomePath="/home/maojingwei/project"
    rm /home/maojingwei/project/.vscode/launch.json
    ln -s /home/maojingwei/project/common_tools/.vscode/launch.json /home/maojingwei/project/.vscode/launch.json
    rm /home/maojingwei/project/.vscode/tasks.json
    ln -s /home/maojingwei/project/common_tools/.vscode/tasks.json /home/maojingwei/project/.vscode/tasks.json
fi

tmp=$jwHomePath/common_tools/jwrun.sh
chmod +x $tmp
export jwrun=$tmp
tmp=$jwHomePath/common_tools/jwkill.sh
chmod +x $tmp
export jwkill=$tmp

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
