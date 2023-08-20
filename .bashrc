# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions

export PATH="$PATH:/usr/local/cuda-11.4/bin:/usr/local/git/bin:/usr/local/MATLAB/R2022b/bin:/home/maojingwei/software/TensorRT-8.2.5.1/bin:/home/maojingwei/installed/vim/bin:/home/maojingwei/installed/git/bin:/home/maojingwei/installed/python3.8.16/lib:/home/maojingwei/software/nvim-linux64/bin/"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/cuda-11.4/lib64:/home/maojingwei/software/TensorRT-8.2.5.1/lib:/home/maojingwei/installed/python3.8.16/lib"
export LD_INCLUDE_PATH="/home/maojingwei/software/TensorRT-8.2.5.1/include:$LD_INCLUDE_PATH"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
#source /home/maojingwei/python3.8.16env/base/bin/activate
#export VIMINIT='source /home/maojingwei/project/common_tools_for_centos/vimrc'
export XDG_CONFIG_HOME=/home/maojingwei/project/common_tools_for_centos/

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/maojingwei/installed/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/maojingwei/installed/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/maojingwei/installed/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/maojingwei/installed/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<






