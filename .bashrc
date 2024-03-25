# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

if [ -f ~/.fzf.bash ]; then
    source ~/.fzf.bash
fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions

export PATH="/usr/local/cuda/bin:/usr/local/MATLAB/R2022b/bin:$MJWHOME/mjw_tmp_jwm/TensorRT-8.2.5.1/bin:$MJWHOME/mjw_tmp_jwm/installed/git/bin:$MJWHOME/installed/python3.8.16/lib:$MJWHOME/mjw_tmp_jwm/nvim/bin/:$MJWHOME/mjw_tmp_jwm/cmake/bin/:$PATH"
export LD_LIBRARY_PATH="/home/maojingwei/mjw_tmp_jwm/TensorRT-8.2.5.1/lib:/usr/local/cuda-11.4/extras/CUPTI/lib64"
export LD_INCLUDE_PATH="$MJWHOME/mjw_tmp_jwm/TensorRT-8.2.5.1/include:$LD_INCLUDE_PATH"

alias rm='DIR=/home/maojingwei/mjw_tmp_jwm/trash/`date +%F%T`;mkdir -p $DIR;mv -t $DIR' 
# mv src dst, move src to dst; mv -t dst src, mv src to dst

#source $MJWHOME/python3.8.16env/base/bin/activate
#export VIMINIT='source $MJWHOME/project/common_tools_for_centos/vimrc'
# export XDG_CONFIG_HOME=$MJWHOME/project/common_tools_for_centos/
mkdir -p $MJWHOME/.config/nvim/
if [ ! -L $MJWHOME/.config/nvim/init.lua ]
then
    echo "create $MJWHOME/.config/nvim/init.lua"
    ln -s $MJWHOME/project/common_tools_for_centos/init_nvim.lua $MJWHOME/.config/nvim/init.lua
fi

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('$MJWHOME/installed/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "$MJWHOME/installed/anaconda3/etc/profile.d/conda.sh" ]; then
        . "$MJWHOME/installed/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="$MJWHOME/installed/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

conda activate



