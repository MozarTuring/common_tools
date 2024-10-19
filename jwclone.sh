if [ "$#" -ne 2 ]; then
    echo "error"
    exit
fi

# tmp=$(echo "$1" | tr '\\' ' ')

if [[ $1 == 'C:'* ]] then
new_path=$(echo "$1" | awk -F'project' '{print $2}'|tr '\\' '/')
new_path=/home/maojingwei/project$new_path
else
new_path=$1
fi



if [ $2 == "go" ]; then
    remoteName=googleDrive # 填写 rclone config 的时候设置的名称

    googleDrive_path=$(echo $new_path | sed 's/\/home//g')
    googleDrive_path=$(dirname $googleDrive_path)/

    rclone sync $1 ${remoteName}:$googleDrive_path
elif [ $2 == "43" ]; then
    set -x
    scp $1 maojingwei@10.20.14.43:$(dirname $new_path)/
    set +x
elif [ $2 == "42" ]; then
    set -x
    scp $1 maojingwei@10.20.14.42:$(dirname $new_path)/
    set +x
else
    echo "pass"
fi

# jwclone /home/maojingwei/project/vllm/ 43
