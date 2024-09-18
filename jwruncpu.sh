#!/bin/bash
#SBATCH -A R20240614095217
#SBATCH -p p-A100
#SBATCH -N 1
#SBATCH --reservation=root_139
#SBATCH -c 4



source ${jwHomePath}"/common_tools/jwruncommon.sh"
