aaa=$(grep "/home/maojingwei/project/common_tools_for_centos/run.sh $1" $1)

if [ -z "$aaa" ]; then
    echo "not exists"
    if [[ $1 == *".py" ]]; then
        echo "
'''
/home/maojingwei/project/common_tools_for_centos/run.sh $1
'''" >>$1
    elif [[ $1 == *".sh" ]]; then
        echo "
# /home/maojingwei/project/common_tools_for_centos/run.sh $1
" >>$1
    fi
else
    echo "exists"

fi
