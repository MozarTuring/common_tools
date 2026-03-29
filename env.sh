# Shared environment settings — sourced by both zshrc and bash_profile

# Locale
export LANG=zh_CN.UTF-8
export LC_TIME=en_US.UTF-8

# LS colors
export LS_OPTIONS='--color=auto'
export CLICOLOR='Yes'
export LSCOLORS='CxfxcxdxbxegedabagGxGx'

# PATH
export PATH="$HOME/jwSoftware/nvim/bin:$PATH"
export PATH="/Users/maojingwei/Library/Python/3.7/bin/:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"

# HomeBrew
export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles

# Safe rm: moves files to trash instead of deleting
alias rm='f() { DIR=~/111mjw_tmp_jwm/trash/$(date +%F%T) && mkdir -p "$DIR" && mv "$@" "$DIR"; }; f'
