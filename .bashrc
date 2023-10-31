# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions

export PATH="/usr/local/cuda-11.4/bin:/usr/local/MATLAB/R2022b/bin:$MJWHOME/software/TensorRT-8.2.5.1/bin:$MJWHOME/installed/git/bin:$MJWHOME/installed/python3.8.16/lib:$MJWHOME/software/nvim/bin/:$PATH"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/cuda-11.4/lib64:$MJWHOME/software/TensorRT-8.2.5.1/lib:$MJWHOME/installed/python3.8.16/lib"
export LD_INCLUDE_PATH="$MJWHOME/software/TensorRT-8.2.5.1/include:$LD_INCLUDE_PATH"

alias rm='DIR=/home/maojingwei/mjwtrash/`date +%F%T`;mkdir $DIR;mv -t $DIR'
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
#source $MJWHOME/python3.8.16env/base/bin/activate
#export VIMINIT='source $MJWHOME/project/common_tools_for_centos/vimrc'
# export XDG_CONFIG_HOME=$MJWHOME/project/common_tools_for_centos/
mkdir -p $MJWHOME/.config/nvim/
if [ ! -L $MJWHOME/.config/nvim/init.vim ]
then
    echo "create $MJWHOME/.config/nvim/init.vim"
    ln -s $MJWHOME/project/common_tools_for_centos/nvim/init.vim $MJWHOME/.config/nvim/init.vim
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



