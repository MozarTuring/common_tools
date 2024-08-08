


# echo $dst
if [ ${1:1:4}  == "home" ]; then
dst=$(echo "$1" | sed 's/home/mntcephfs\/lab_data/g')
set -x
sshpass -p 9213 scp -r $1 maojingwei@10.26.6.81:$dst
set +x
else
dst=$(echo "$1" | sed 's/mntcephfs\/lab_data/home/g')
set -x
sshpass -p 9213 scp -r $1 maojingwei@10.20.14.42:$dst
set +x
fi





# bash /home/maojingwei/project/common_tools/file2sribdGroup.sh /mntcephfs/lab_data/maojingwei/project/common_tools/file2sribdGroup.sh