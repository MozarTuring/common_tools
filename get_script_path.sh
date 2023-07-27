dir_name=$(cd "$(dirname "$0")";pwd)
shell_name=$(basename $0)
tmp_name=${shell_name#*_}
script_name=${tmp_name%.*}
abs_path=$dir_name/$script_name.py

