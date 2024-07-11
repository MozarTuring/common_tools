set -e

scriptPath=$1
cur_dir=${scriptPath%/*}

if [  -f ${cur_dir}"/jwrunjw.sh" ]; then
echo "already exists"
exit
fi


cp /home/maojingwei/project/common_tools/run.sh $cur_dir/jwrunjw.sh

bash /home/maojingwei/project/common_tools/rclone.sh $cur_dir/jwrunjw.sh





