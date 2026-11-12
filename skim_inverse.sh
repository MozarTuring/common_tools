#!/bin/bash
line="$1"
file="$2"

nvr=/Users/jinma63/miniconda3/bin/nvr
map=/tmp/nvim_vimtex_servers

server=""
dir=$(dirname "$file")
while [[ -n "$dir" && "$dir" != "/" ]]; do
	key=$(printf '%s' "$dir" | tr '/' '_')
	if [[ -f "$map/$key" ]]; then
		server=$(cat "$map/$key")
		break
	fi
	dir=$(dirname "$dir")
done
if [[ -z "$server" || ! -S "$server" ]]; then
	server=$(cat "$map/last" 2>/dev/null)
fi

opened=$("$nvr" --servername "$server" --remote-expr "luaeval('PkqSkimInverse(_A[1], _A[2])', ['$line', '$file'])" 2>/dev/null)
[[ "$opened" == /* ]] || "$nvr" --servername "$server" +"$line" "$file"

osascript -e 'tell application "kitty" to activate'
