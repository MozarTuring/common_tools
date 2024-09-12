set -e

tmp=""
cat /home/maojingwei/project/$1/jwmaoRpip.txt | while read -r line; do
# aa="2"
    aa=$(echo "$line" | sed 's/-/_/g')
    tmp1=$(echo "$line" | sed 's/==/-/g')
    tmp2=$(echo "$aa" | sed 's/==/-/g')
    tmp3="${tmp1,,}"
    tmp4="${tmp2,,}"
    filename1=$(find /home/maojingwei/project/zzzresources/pip_packages -name "$tmp1*")
    filename2=$(find /home/maojingwei/project/zzzresources/pip_packages -name "$tmp2*")
    filename3=$(find /home/maojingwei/project/zzzresources/pip_packages -name "$tmp3*")
    filename4=$(find /home/maojingwei/project/zzzresources/pip_packages -name "$tmp4*")
    if [ -n "$filename1" ]; then
        bash /home/maojingwei/project/common_tools/rclone.sh $filename1 43
        echo "pass1"
    elif [ -n "$filename2" ]; then
    bash /home/maojingwei/project/common_tools/rclone.sh $filename2 43
    echo "pass2"
    elif [ -n "$filename3" ]; then
    bash /home/maojingwei/project/common_tools/rclone.sh $filename3 43
    echo "pass3"
    elif [ -n "$filename4" ]; then
    bash /home/maojingwei/project/common_tools/rclone.sh $filename4 43
    echo "pass4"
    else
        tmp="$tmp $line"
    fi
    echo "tmp $tmp"
done
echo "final"
echo $tmp
echo "hh"

# bash /home/maojingwei/project/common_tools/sendPackges.sh
