remoteName=googleDrive # 填写 rclone config 的时候设置的名称

googleDrive_path=$(echo "$1" | sed 's/\/home//g')
googleDrive_path=$(dirname $googleDrive_path)/

rclone sync $1 ${remoteName}:$googleDrive_path