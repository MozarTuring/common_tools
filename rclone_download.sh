googleDrive_path=$(echo "$1" | sed 's/\/home//g')
googleDrive_path=$(dirname $googleDrive_path)/





rclone copy googleDrive:$1 /home$(dirname $1)

# bash /home/maojingwei/project/common_tools/rclone_download.sh /maojingwei/project/.resources/meta-llama/Meta-Llama-3-8B-Instruct/README.md