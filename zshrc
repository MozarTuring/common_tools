alias claude='cd ~/project && command claude'

# Source shared environment
source ~/baidu/project/common_tools/env.sh

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Added by OrbStack: command-line tools and integration
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
setopt interactivecomments


# export ANTHROPIC_API_KEY="your-key-here"  # Set via `export` in terminal or use a secrets manager

# OpenClaw Completion
autoload -Uz compinit && compinit
source "/Users/maojingwei/.openclaw/completions/openclaw.zsh"
