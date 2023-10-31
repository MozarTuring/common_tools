set -e

env_name=common_tools_for_centos
source /home/maojingwei/project/common_tools_for_centos/myhead.sh condaenv $env_name 3.8.16

shell_name=$0
if [ "${shell_name##*/}" == "jwmaoR.sh" ]; then
    echo "start installing requirements"

#    python -m pip install pymysql
    python -m pip install cryptography
fi
