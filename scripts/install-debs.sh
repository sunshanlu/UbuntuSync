#!/bin/bash
set -e

TMP_DIR=$(mktemp -d)
MIHOMO_STARTED=false

# Need mihomo proxy for reliable download
PROXY_PACKAGES="chrome vscode"

start_proxy() {
    if pgrep -x mihomo > /dev/null; then
        echo "  mihomo already running."
        return
    fi

    if ! command -v mihomo &> /dev/null; then
        echo "  mihomo not installed, skipping proxy."
        return
    fi

    echo "  Starting mihomo..."
    nohup mihomo -d "$HOME/.config/mihomo" > /tmp/mihomo.log 2>&1 &
    sleep 2

    if pgrep -x mihomo > /dev/null; then
        MIHOMO_STARTED=true
        echo "  mihomo started."
    else
        echo "  mihomo failed to start, proceeding without proxy."
    fi
}

stop_proxy() {
    if [ "$MIHOMO_STARTED" = true ]; then
        pkill mihomo || true
        echo "  mihomo stopped."
    fi
}

use_proxy() {
    for pkg in $PROXY_PACKAGES; do
        [ "$pkg" = "$1" ] && return 0
    done
    return 1
}

declare -A PACKAGES=(
    [localsend]="https://d.localsend.org/LocalSend-1.17.0-linux-x86-64.deb"
    [wechat]="https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb"
    [qq]="https://dldir1v6.qq.com/qqfile/qq/QQNT/Linux/QQ_3.2.28_260429_amd64_01.deb"
    [chrome]="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    [vscode]="https://vscode.download.prss.microsoft.com/dbazure/download/stable/034f571df509819cc10b0c8129f66ef77a542f0e/code_1.118.1-1777474985_amd64.deb"
    [ccswitch]="https://ghfast.top/https://github.com/farion1231/cc-switch/releases/download/v3.14.1/CC-Switch-v3.14.1-Linux-x86_64.deb"
)

TOTAL=${#PACKAGES[@]}
echo "========================================="
echo "  Deb Package Installer"
echo "========================================="

echo "Checking proxy..."
start_proxy
echo

i=0
for name in localsend wechat qq chrome vscode ccswitch; do
    i=$((i + 1))
    url="${PACKAGES[$name]}"
    deb_file="$TMP_DIR/${name}.deb"

    if dpkg -l "$name" &>/dev/null; then
        echo "[$i/$TOTAL] $name already installed, skipping."
        continue
    fi

    echo "[$i/$TOTAL] Installing $name..."
    if use_proxy "$name"; then
        echo "  Using proxy..."
        if ! curl -x http://127.0.0.1:7890 -fSL "$url" -o "$deb_file"; then
            echo "  Download failed, skipping."
            continue
        fi
    else
        if ! curl -fSL "$url" -o "$deb_file"; then
            echo "  Download failed, skipping."
            continue
        fi
    fi

    if sudo dpkg -i "$deb_file" 2>/dev/null; then
        echo "  Installed."
    else
        echo "  Fixing dependencies..."
        sudo apt-get install -f -y -qq
        echo "  Installed."
    fi
done

rm -rf "$TMP_DIR"
stop_proxy

echo
echo "========================================="
echo "  Installation complete!"
echo "========================================="
