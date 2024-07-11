set -e

mkdir -p /root/.ssh
cp /content/drive/MyDrive/maojingwei/project/common_tools/id_rsa /root/.ssh/id_rsa
ssh-keyscan -t rsa github.com >>/root/.ssh/known_hosts

chmod +x /content/drive/MyDrive/maojingwei/project/ngrok-v3-stable-linux-amd64/ngrok
if [ -e /usr/local/bin/ngrok ]; then
    rm /usr/local/bin/ngrok
fi
ln -s /content/drive/MyDrive/maojingwei/project/ngrok-v3-stable-linux-amd64/ngrok /usr/local/bin/ngrok
ngrok config add-authtoken 2iLwxn3OMhW45CT4SNOIPlXMYPX_3MgeK1rdZdyckMMrLh4xX

# 在colab上直接编辑文件，输入以上内容似乎不能正常运行。可能和colab编辑器采用的换行符不对有关。在本地编辑好再上传是ok的
