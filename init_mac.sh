# install kitty 

# zsh
rm ~/.zshrc
ln -s ${HOME}/project/common_tools/zshrc ~/.zshrc

mkdir -p ~/111mjw_tmp_jwm
alias rm='f() { DIR=~/111mjw_tmp_jwm/trash/$(date +%F%T) && mkdir -p "$DIR" && mv "$@" "$DIR"; }; f'


# nvim
mkdir -p ~/.config/nvim
ln -s ${HOME}/project/common_tools/init_nvim_mac.lua ~/.config/nvim/init.lua

# vscode
rm ${HOME}/Library/Application\ Support/Code/User/settings.json
ln -s ${HOME}/project/common_tools/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json

rm ${HOME}/Library/Application\ Support/Code/User/keybindings.json
ln -s ${HOME}/project/common_tools/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json

# cursor
rm ${HOME}/Library/Application\ Support/Cursor/User/settings.json
ln -s ${HOME}/project/common_tools/vscode/settings.json ~/Library/Application\ Support/Cursor/User/settings.json


# ssh
rm ~/.ssh/config
mkdir ~/.ssh
ln -s ${HOME}/project/common_tools/.ssh/config ~/.ssh/config

# hammerspoon
rm ~/.hammerspoon/init.lua
mkdir ~/.hammerspoon
ln -s ${HOME}/project/common_tools/hamperspoon.lua ~/.hammerspoon/init.lua

# kitty
rm ~/.config/kitty/kitty.conf
mkdir -p ~/.config/kitty
ln -s ${HOME}/project/common_tools/kitty.conf ~/.config/kitty/kitty.conf

# git
ln -s ${HOME}/project/common_tools/gitconfig ~/.gitconfig

# data
ln -s ${HOME}/Desktop/baidu/zzzjwmresources ~/project/zzzjwmresources
ln -s ${HOME}/Desktop/baidu/zzzjwmoutput ~/project/zzzjwmoutput
ln -s ${HOME}/Desktop/baidu/project_nogit ~/project/project_nogit
