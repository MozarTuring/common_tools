set -e

if [ $2 == "go" ]; then
    remoteName=googleDrive # 填写 rclone config 的时候设置的名称

    googleDrive_path=$(echo "$1" | sed 's/\/home//g')
    googleDrive_path=$(dirname $googleDrive_path)/

    rclone sync $1 ${remoteName}:$googleDrive_path
elif [ $2 == "43" ]; then
dst=$(dirname $1)
    set -x
    sshpass -p 9213fCOW scp -r $1 maojingwei@10.20.14.43:$dst
    set +x
else
    echo "pass"
fi


# bash /home/maojingwei/project/common_tools/rclone.sh
