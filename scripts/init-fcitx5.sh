#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/fcitx5"
THEME_DIR="$HOME/.local/share/fcitx5/themes"
ZSHRC="$HOME/.zshrc"

echo "========================================="
echo "  Fcitx5 Input Method Installer"
echo "========================================="

# Step 1: Install fcitx5 and dependencies
echo "[1/5] Installing fcitx5..."
sudo apt-get update -qq
sudo apt-get install -y -qq fcitx5 fcitx5-chinese-addons fcitx5-frontend-gtk3 fcitx5-frontend-gtk4 fcitx5-frontend-qt5 im-config unzip
echo "  Installed."

# Step 2: Install candlelight theme
echo "[2/5] Installing candlelight theme..."
mkdir -p "$THEME_DIR"
if [ -d "$THEME_DIR/winter" ]; then
    echo "  Theme already installed, skipping."
else
    curl -fSL "https://ghfast.top/https://github.com/thep0y/fcitx5-themes-candlelight/archive/refs/heads/main.zip" -o /tmp/fcitx5-theme-candlelight.zip
    unzip -q /tmp/fcitx5-theme-candlelight.zip -d /tmp/fcitx5-theme-candlelight
    cp -r /tmp/fcitx5-theme-candlelight/fcitx5-themes-candlelight-main/winter "$THEME_DIR/"
    rm -rf /tmp/fcitx5-theme-candlelight /tmp/fcitx5-theme-candlelight.zip
    echo "  Theme installed."
fi

# Step 3: Sync config files
echo "[3/5] Syncing config files..."
mkdir -p "$CONFIG_DIR/conf"
cp "$SCRIPT_DIR/../include/fcitx5/profile" "$CONFIG_DIR/profile"
cp "$SCRIPT_DIR/../include/fcitx5/conf/"*.conf "$CONFIG_DIR/conf/"
echo "  Config applied: $CONFIG_DIR"

# Step 4: Set fcitx5 as default input method
echo "[4/5] Setting fcitx5 as default input method..."
im-config -n fcitx5 2>/dev/null || true
echo "  Set via im-config."

# Step 5: Configure environment variables
echo "[5/5] Configuring environment variables..."
if grep -q "fcitx5" "$ZSHRC" 2>/dev/null; then
    echo "  zshrc already configured, skipping."
else
    cat >> "$ZSHRC" << 'ZSHRC_EOF'

# Fcitx5 input method
export INPUT_METHOD=fcitx
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
ZSHRC_EOF
    echo "  Environment variables added to zshrc."
fi

echo ""
echo "========================================="
echo "  Installation complete!"
echo ""
echo "  Config:    $CONFIG_DIR"
echo "  Theme:     winter"
echo "  Input:     Pinyin (双拼自然码)"
echo ""
echo "  Please log out and back in, then run:"
echo "    fcitx5 &"
echo "========================================="
