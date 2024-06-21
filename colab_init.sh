mkdir -p /root/.ssh
ls /root/.ssh
cp /content/drive/MyDrive/maojingwei/common_tools/id_rsa /root/.ssh/id_rsa
ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts

# 在colab上直接编辑文件，输入以上内容似乎不能正常运行。可能和colab编辑器采用的换行符不对有关。在本地编辑好再上传是ok的