#!/bin/bash
line="$1"
file="$2"

nvr=/Users/jinma63/miniconda3/bin/nvr
server=/tmp/nvim_vimtex

opened=$("$nvr" --servername "$server" --remote-expr "luaeval('PkqSkimInverse(_A[1], _A[2])', ['$line', '$file'])" 2>/dev/null)
[[ "$opened" == /* ]] || "$nvr" --servername "$server" +"$line" "$file"

osascript -e 'tell application "kitty" to activate'
