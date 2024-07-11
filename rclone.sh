googleDrive_path=$(echo "$1" | sed 's/\/home//g')
googleDrive_path=$(dirname $googleDrive_path)/

rclone sync $1 googleDrive:$googleDrive_path