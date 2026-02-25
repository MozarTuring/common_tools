# zsh
rm ~/.zshrc
ln -s /Users/maojingwei/baidu/project/common_tools/zshrc ~/.zshrc

mkdir -p ~/111mjw_tmp_jwm
alias rm='f() { DIR=~/111mjw_tmp_jwm/trash/$(date +%F%T) && mkdir -p "$DIR" && mv "$@" "$DIR"; }; f'


# nvim
ln -s /Users/maojingwei/baidu/project/common_tools/init_nvim_mac.lua ~/.config/nvim/init.lua

# vscode
rm /Users/maojingwei/Library/Application\ Support/Code/User/settings.json
ln -s /Users/maojingwei/baidu/project/common_tools/vscode/settings.json /Users/maojingwei/Library/Application\ Support/Code/User/settings.json

rm /Users/maojingwei/Library/Application\ Support/Code/User/keybindings.json
ln -s /Users/maojingwei/baidu/project/common_tools/vscode/keybindings.json /Users/maojingwei/Library/Application\ Support/Code/User/keybindings.json

# cursor
rm /Users/maojingwei/Library/Application\ Support/Cursor/User/settings.json
ln -s /Users/maojingwei/baidu/project/common_tools/vscode/settings.json /Users/maojingwei/Library/Application\ Support/Cursor/User/settings.json


# ssh
rm ~/.ssh/config
ln -s /Users/maojingwei/baidu/project/common_tools/.ssh/config ~/.ssh/config

# hammerspoon
rm ~/.hammerspoon/init.lua
ln -s /Users/maojingwei/baidu/project/common_tools/hamperspoon.lua ~/.hammerspoon/init.lua

# kitty
rm ~/.config/kitty/kitty.conf
ln -s /Users/maojingwei/baidu/project/common_tools/kitty.conf ~/.config/kitty/kitty.conf
