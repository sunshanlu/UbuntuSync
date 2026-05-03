#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: install.sh <mihomo_subscription_url>"
    exit 1
fi

SUB_URL="$1"
REPO_URL="https://ghfast.top/https://github.com/sunshanlu/UbuntuSync.git"
WORK_DIR=$(mktemp -d)

echo "========================================="
echo "  UbuntuSync Installer"
echo "========================================="

# Step 1: Download repo
echo "[1/7] Downloading repository..."
if git clone --depth=1 "$REPO_URL" "$WORK_DIR/UbuntuSync" 2>/dev/null; then
    SCRIPT_DIR="$WORK_DIR/UbuntuSync/scripts"
    echo "  Cloned via git."
else
    echo "  git clone failed, falling back to zip download..."
    ZIP_URL="https://ghfast.top/https://github.com/sunshanlu/UbuntuSync/archive/refs/heads/master.zip"
    curl -fSL "$ZIP_URL" -o "$WORK_DIR/master.zip"
    unzip -q "$WORK_DIR/master.zip" -d "$WORK_DIR"
    SCRIPT_DIR="$WORK_DIR/UbuntuSync-master/scripts"
    echo "  Downloaded via zip."
fi

# Step 2: ZSH + Oh My Zsh + Starship
echo ""
echo "[2/7] ZSH + Oh My Zsh + Starship"
echo "-----------------------------------------"
bash "$SCRIPT_DIR/init-zsh.sh"

# Step 3: Mihomo proxy
echo ""
echo "[3/7] Mihomo Proxy"
echo "-----------------------------------------"
bash "$SCRIPT_DIR/init-mihomo.sh" "$SUB_URL"

# Step 4: Maple Font
echo ""
echo "[4/7] Maple Font"
echo "-----------------------------------------"
bash "$SCRIPT_DIR/init-maple-font.sh"

# Step 5: Ghostty terminal
echo ""
echo "[5/7] Ghostty Terminal"
echo "-----------------------------------------"
bash "$SCRIPT_DIR/init-ghostty.sh"

# Step 6: Fcitx5 input method
echo ""
echo "[6/7] Fcitx5 Input Method"
echo "-----------------------------------------"
bash "$SCRIPT_DIR/init-fcitx5.sh"

# Step 7: Deb packages (LocalSend, WeChat, QQ, Chrome, VS Code)
echo ""
echo "[7/7] Deb Packages"
echo "-----------------------------------------"
bash "$SCRIPT_DIR/install-debs.sh"

# Cleanup
rm -rf "$WORK_DIR"

echo ""
echo "========================================="
echo "  All done! Please log out and back in."
echo "========================================="
