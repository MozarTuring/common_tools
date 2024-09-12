#!/bin/bash
#SBATCH -A R20240614095217
#SBATCH --reservation=root_139
#SBATCH -p p-A100
#SBATCH -N 1
#SBATCH -c 16
#SBATCH --gres=gpu:1

# the following is not ok
# aa="0"
# if [ $aa == "0" ]; then
# #SBATCH -c 16
# #SBATCH --gres=gpu:1
# echo "gpu mode"
# else
# #SBATCH -c 4
# echo "cpu mode"
# fi

source ${jwHomePath}"/common_tools/jwrunCommon.sh"
