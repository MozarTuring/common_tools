#! /bin/bash
set -e


find $1 -type f -name '*' > /home/maojingwei/tmp10171837.txt
while ele= read -r line
do
disk_path=${line/home/mnt\/mydisk}
if [ ! -e "$disk_path" ]
then
echo $line
echo $disk_path
echo "not exist"
fi
done < /home/maojingwei/tmp10171837.txt


# function read_dir(){
#     num=`ls -la $1|wc -l`
#     # 第一行是总用量，然后有 . 和 .. ，所以要大于3
#     if [ $num -gt 3 ]; then
#         files=("$1"/.* "$1"/*)
#         count=0
#         for file in "${files[@]}"
#         # 如果目录下不存在和某个通配符匹配的文件，那么会输出该通配符
#         do
#             echo $file
#             let count=count+1
#             if [ $count -gt 2 ]; then

#         # num=`ls -la $1|wc -l`
#         # echo $num
#         # for(( out_i=4;out_i<=$num;out_i++)) do
#         #     echo $out_i
#         #     echo $1
#         #     file=""
#         #     for tmp_file in `ls -la $1|head -n $out_i|tail -n 1|awk '{for(i=9; i<=NF; i++) print $i}'`       #注意此处这是两个反引号，表示运行系统命令
#         #     do
#         #         if [ -z $file ]
#         #         then
#         #             file=$tmp_file
#         #         else
#         #             echo $file
#         #             file='$file $tmp_file'
#         #             echo $file
#         #         fi
#         #     done
#         #     echo $file
#                 src_path=$file
#                 if [ -d "$src_path" ]  #注意此处之间一定要加上空格，否则会报错
#                 then
#                     read_dir $src_path
#                 else
#                     disk_path=${src_path/home/mnt\/mydisk}
#                     if [ ! -e "$disk_path" ]
#                     then
#                         echo $src_path
#                         echo $disk_path
#                         echo "not exist"
#                     fi
#                 fi
#             fi
#         done
#     fi
# }

# read_dir $1

# 注意参数不能以 / 结尾


# 使用 cp -r -n 就可以实现上述功能

