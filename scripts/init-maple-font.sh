#!/bin/bash
set -e

FONT_VERSION="v7.9"
FONT_ZIP="MapleMono-NF-CN-unhinted.zip"
FONT_URL="https://ghfast.top/https://github.com/subframe7536/maple-font/releases/download/${FONT_VERSION}/${FONT_ZIP}"
FONT_DIR="$HOME/.local/share/fonts/MapleFont"
TMP_DIR=$(mktemp -d)

# Ensure unzip is available
command -v unzip &>/dev/null || apt-get install -y -qq unzip

echo "========================================="
echo "  Maple Font Installer"
echo "========================================="

# Step 1: Download zip
echo "[1/3] Downloading ${FONT_ZIP}..."
curl -fSL "$FONT_URL" -o "$TMP_DIR/$FONT_ZIP"

# Step 2: Extract to font directory
echo "[2/3] Extracting fonts..."
mkdir -p "$FONT_DIR"
unzip -o "$TMP_DIR/$FONT_ZIP" -d "$FONT_DIR"
rm -rf "$TMP_DIR"

# Step 3: Refresh font cache
echo "[3/3] Refreshing font cache..."
fc-cache -f "$FONT_DIR"

# Verify
echo ""
echo "========================================="
if fc-list | grep -qi "Maple Mono" > /dev/null 2>&1; then
    echo "  Installation complete!"
    echo ""
    echo "  Installed fonts:"
    fc-list | grep -i "Maple Mono" | head -5
else
    echo "  Warning: Font installed but not detected by fc-list."
    echo "  You may need to log out and back in."
fi
echo "========================================="
