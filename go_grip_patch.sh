#!/bin/bash
# Rebuild go-grip without the "Made with ♥ by chrishrb" footer.
# Prerequisites: go (brew install go), git

set -euo pipefail

BUILD_DIR=$(mktemp -d)
trap 'rm -rf "$BUILD_DIR"' EXIT

git clone --depth 1 https://github.com/chrishrb/go-grip.git "$BUILD_DIR" 2>&1

LAYOUT="$BUILD_DIR/defaults/templates/layout.html"

# Remove the footer block (3 lines: {{if}}, <footer>, {{end}})
sed -i '' '/{{if .BoundingBox}}/{N;N;/footer.*Made with/d;}' "$LAYOUT"

cd "$BUILD_DIR"
go build -o ~/go/bin/go-grip .
# Used by: common_tools/init_nvim_mac.lua (press 'm' in markdown files to preview)

pkill -f 'go-grip' 2>/dev/null || true

echo "Done. Patched go-grip installed to ~/go/bin/go-grip"
