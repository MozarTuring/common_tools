
dst=$(echo "$1" | sed 's/home/mntcephfs\/lab_data/g')

# echo $dst

sshpass -p 9213 scp -r $1 maojingwei@10.26.6.81:$dst

# bash /home/maojingwei/project/common_tools/file2sribdGroup.sh /home/maojingwei/project/.resources/BAAI/bge-large-zh-v1.5