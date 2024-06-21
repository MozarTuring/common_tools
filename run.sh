echo "

"

var1=$1

cur_dir=${var1%/*}
cur_name=${var1##*/}
cur_name_pre=${cur_name%.*}
file_typ=${cur_name##*.}

# env_path=`echo "$cur_dir" | sed 's/project/project\/zzzMjw_TMP/g'`

cd $cur_dir

if [ $file_typ = "sh" ]; then
   exeProgrm=bash
   startFlag="^:<<EOF"
   endFlag="^EOF"
elif [ $file_typ = "py" ]; then
   line1=$(head -n 1 $1)

   if [ ${line1:0:2} == "#!" ]; then
      exeProgrm=${line1:2}
   else
      exeProgrm=$cur_dir/aaaMjw_TMP/condaenv/bin/python
   fi
   echo $exeProgrm
   startFlag='"""run_mjw'
   endFlag='run_jwm"""'
fi

line_start=$(grep -n $startFlag $1)
# echo $line_start
line_start=$(echo $line_start | grep -o '^[0-9]*')
line_end=$(grep -n $endFlag $1)
# echo $line_end
line_end=$(echo $line_end | grep -o '^[0-9]*')

newCommand=("")
stopArg=$1
if [ ! -z $line_start ]; then

   ((line_start++))
   tmp_text=$(sed -n ${line_start}p $1)
   ccc=$(echo "$tmp_text" | cut -d',' -f1 --output-delimiter='')
   # echo $ccc
   if [[ $ccc == "stop" ]]; then
      ccc=$(echo "$tmp_text" | cut -d',' -f2 --output-delimiter='')
      # echo $ccc
      stopArg=$ccc
      ((line_start++))
   fi
   while [ $line_start -le $line_end ]; do
      tmp_text=$(sed -n ${line_start}p $1)
      ccc=$(echo "$tmp_text" | cut -d',' -f1 --output-delimiter='')
      if [[ $ccc == "line" ]]; then
         ccc=$(echo "$tmp_text" | cut -d',' -f2 --output-delimiter='')
         ele=1

         while [ $ele -le $ccc ]; do
            ((line_start++))
            tmp_text=$(sed -n ${line_start}p $1)

            if [[ ${newCommand[0]} == "" ]]; then
               newCommand=("$tmp_text")
            else
               newCommand+=("$tmp_text")
            fi

            ((ele++))
         done
      else
         ((line_start++))
      fi
   done

fi

count=1
echo "

"

/home/maojingwei/project/common_tools_for_centos/kill_pid.sh $stopArg

for element in "${newCommand[@]}"; do
   set -x
   nohup $exeProgrm $1 $element >${cur_name}_log"$count" 2>&1 &
   set +x
   ((count++))
done
