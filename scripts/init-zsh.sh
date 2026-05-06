#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================="
echo "  ZSH + Oh My Zsh + Starship Installer"
echo "========================================="

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    echo "Cannot detect OS. Exiting."
    exit 1
fi

echo "[1/4] Detected: $OS $VER"

# Install dependencies
echo "[2/4] Installing zsh and dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq zsh git curl

# Install Oh My Zsh (non-interactive)
echo "[3/4] Installing Oh My Zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "  Oh My Zsh already installed, skipping."
else
    git clone --depth=1 https://gitee.com/mirrors/oh-my-zsh.git "$HOME/.oh-my-zsh"
    cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"
fi

# Install Starship
echo "[4/4] Installing Starship..."
if command -v starship &> /dev/null; then
    echo "  Starship already installed, skipping."
else
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64) ARCH="x86_64" ;;
        aarch64|arm64) ARCH="aarch64" ;;
        *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    # Use ghproxy mirror for faster download in China
    curl -fsSL "https://ghfast.top/https://github.com/starship/starship/releases/latest/download/starship-${ARCH}-unknown-linux-gnu.tar.gz" -o /tmp/starship.tar.gz
    sudo tar -xzf /tmp/starship.tar.gz -C /usr/local/bin
    rm /tmp/starship.tar.gz
fi

# Copy config files
echo "Applying configurations..."
cp "$SCRIPT_DIR/../include/.zshrc" "$HOME/.zshrc"
mkdir -p "$HOME/.config"
cp "$SCRIPT_DIR/../include/starship.toml" "$HOME/.config/starship.toml"

# Set zsh as default shell
echo "Setting zsh as default shell..."
chsh -s $(which zsh)

echo ""
echo "========================================="
echo "  Installation complete!"
echo "  Please run: exec zsh"
echo "========================================="
