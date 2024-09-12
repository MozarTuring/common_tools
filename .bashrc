
# Put all the commands here that should run regardless of whether
# this is an interactive or non-interactive shell.



# test if the prompt var is not set and also to prevent failures
# when `$PS1` is unset and `set -u` is used 
if [ -z "${PS1:-}" ]; then
    # prompt var is not set, so this is *not* an interactive shell
    return
fi

# If we reach this line of code, then the prompt var is set, so
# this is an interactive shell.

# Put all the commands here that should run only if this is an
# interactive shell.





# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

if [ -f ~/.fzf.bash ]; then
    source ~/.fzf.bash
fi


export PATH="/usr/local/cuda/bin:/usr/local/MATLAB/R2022b/bin:$MJWHOME/mjw_tmp_jwm/TensorRT-8.2.5.1/bin:$MJWHOME/mjw_tmp_jwm/installed/git/bin:$MJWHOME/installed/python3.8.16/lib:$MJWHOME/mjw_tmp_jwm/nvim/bin/:$MJWHOME/mjw_tmp_jwm/cmake/bin/:$PATH"
export LD_LIBRARY_PATH="/home/maojingwei/mjw_tmp_jwm/TensorRT-8.2.5.1/lib:/usr/local/cuda-11.4/extras/CUPTI/lib64"
export LD_INCLUDE_PATH="$MJWHOME/mjw_tmp_jwm/TensorRT-8.2.5.1/include:$LD_INCLUDE_PATH"

alias rm='DIR=/home/maojingwei/mjw_tmp_jwm/trash/`date +%F%T`;mkdir -p $DIR;mv -t $DIR' 
# mv src dst, move src to dst; mv -t dst src, mv src to dst

#source $MJWHOME/python3.8.16env/base/bin/activate
#export VIMINIT='source $MJWHOME/project/common_tools_for_centos/vimrc'
# export XDG_CONFIG_HOME=$MJWHOME/project/common_tools_for_centos/
if [ ! -L $MJWHOME/.config/nvim/init.lua ]
then
    echo "create $MJWHOME/.config/nvim/init.lua"
    mkdir -p $MJWHOME/.config/nvim/
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

# conda activate
source /home/maojingwei/project/common_tools/colab_init.sh
