
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


source /home/maojingwei/project/common_tools/colab_init.sh
