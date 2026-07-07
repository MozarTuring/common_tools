#!/bin/bash
line="$1"
file="$2"

file=$(echo "$file" | sed 's|/Users/jinma63/Desktop/baidu/project_nogit|/Users/jinma63/project/project_nogit|')

/Users/jinma63/miniconda3/bin/nvr --servername /tmp/nvim_vimtex +"$line" "$file"

osascript -e 'tell application "kitty" to activate'
