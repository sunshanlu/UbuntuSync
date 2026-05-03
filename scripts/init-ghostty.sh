#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GHOSTTY_CONFIG_DIR="$HOME/.config/ghostty"

echo "========================================="
echo "  Ghostty Terminal Installer"
echo "========================================="

# Step 1: Install Ghostty via snap
echo "[1/3] Installing Ghostty..."
if command -v ghostty &> /dev/null; then
    echo "  Ghostty already installed: $(ghostty --version 2>&1 | head -1)"
else
    sudo snap install ghostty --classic
fi

# Step 2: Sync config
echo "[2/3] Syncing Ghostty config..."
mkdir -p "$GHOSTTY_CONFIG_DIR"
cp "$SCRIPT_DIR/../include/ghostty-config" "$GHOSTTY_CONFIG_DIR/config"
echo "  Config applied: $GHOSTTY_CONFIG_DIR/config"

# Step 3: Set as default terminal
echo "[3/3] Setting Ghostty as default terminal..."

# Register in update-alternatives
if command -v update-alternatives &> /dev/null; then
    sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /snap/bin/ghostty 50 2>/dev/null || true
    sudo update-alternatives --set x-terminal-emulator /snap/bin/ghostty 2>/dev/null || true
    echo "  Set via update-alternatives"
fi

# GNOME / gsettings
if command -v gsettings &> /dev/null; then
    gsettings set org.gnome.desktop.default-applications.terminal exec 'ghostty' 2>/dev/null || true
    echo "  Set via gsettings"
fi

echo ""
echo "========================================="
echo "  Installation complete!"
echo ""
echo "  Config:   $GHOSTTY_CONFIG_DIR/config"
echo "  Reload:   Ctrl+Shift+,"
echo "  Quick:    Ctrl+\`  (dropdown terminal)"
echo ""
echo "  Please log out and back in for"
echo "  default terminal to take effect."
echo "========================================="
