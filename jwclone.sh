if [ "$#" -ne 2 ]; then
    echo "error"
    exit
fi


if [ $2 == "go" ]; then
    remoteName=googleDrive # 填写 rclone config 的时候设置的名称

    googleDrive_path=$(echo "$1" | sed 's/\/home//g')
    googleDrive_path=$(dirname $googleDrive_path)/

    rclone sync $1 ${remoteName}:$googleDrive_path
elif [ $2 == "43" ]; then
    set -x
    sshpass -p 9213fCOW rsync -avz $1 maojingwei@10.20.14.43:$(dirname $1)/
    set +x
elif [ $2 == "42" ]; then
    set -x
    sshpass -p 9213 rsync -avz $1 maojingwei@10.20.14.42:$(dirname $1)/
    set +x
else
    echo "pass"
fi

# jwclone /home/maojingwei/project/vllm/ 43
