# install kitty, brew, cursor 
brew install texlive
# zsh
# rm ~/.zshrc
# ln -s ${HOME}/project/common_tools/zshrc ~/.zshrc


# use bash rather than zsh
chsh -s /bin/bash

echo "source ~/project/common_tools/bashrc" >> ${HOME}/.bash_profile

mkdir -p ~/111mjw_tmp_jwm
alias rm='f() { DIR=~/111mjw_tmp_jwm/trash/$(date +%F%T) && mkdir -p "$DIR" && mv "$@" "$DIR"; }; f'


# nvim
mkdir -p ~/.config/nvim
ln -s ${HOME}/project/common_tools/init_nvim_mac.lua ~/.config/nvim/init.lua
# brew install go
# bash ${HOME}/project/common_tools/go_grip_patch.sh # if need to use go-grip for render markdown
brew install node # if using markdown preview to render md 
mv ~/.local/share/nvim/lazy/markdown-preview.nvim/app/routes.js ~/.local/share/nvim/lazy/markdown-preview.nvim/app/routes.js.bak && ln -s ~/project/common_tools/lazy_nvim/markdown-preview.nvim/app/routes.js ~/.local/share/nvim/lazy/markdown-preview.nvim/app/routes.js

brew install ripgrep

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
ln -s ${HOME}/Desktop/baidu/Education/Liu ~/project/Liu

# claude
curl -fsSL https://claude.ai/install.sh | bash
ln -s ${HOME}/project/project_nogit/claude_settings/.claude ~/.claude
ln -s ${HOME}/project/project_nogit/claude_settings/.claude.json ~/.claude.json

# latex
