#!/bin/bash
line="$1"
file="$2"

/Users/jinma63/miniconda3/bin/nvr --servername /tmp/nvim_vimtex +"$line" "$file"

osascript -e 'tell application "kitty" to activate'
