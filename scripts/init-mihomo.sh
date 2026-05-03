#!/bin/bash
set -e

MIHOMO_VERSION="v1.19.24"
SUB_URL="${1:?Usage: init-mihomo.sh <subscription_url>}"
CONFIG_DIR="$HOME/.config/mihomo"
BIN_DIR="$HOME/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  MIHOMO_ARCH="amd64-compatible" ;;
    aarch64|arm64) MIHOMO_ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

MIHOMO_URL="https://ghfast.top/https://github.com/MetaCubeX/mihomo/releases/download/${MIHOMO_VERSION}/mihomo-linux-${MIHOMO_ARCH}-${MIHOMO_VERSION}.gz"
YACD_URL="https://ghfast.top/https://github.com/haishanh/yacd/releases/latest/download/yacd.tar.xz"

# ---------- Step 1: 安装依赖 ----------
install_deps() {
    echo "[1/7] Installing dependencies..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq python3 python3-pip curl xz-utils
    pip3 install --break-system-packages pyyaml 2>/dev/null || pip3 install pyyaml
}

# ---------- Step 2: 安装 mihomo ----------
install_mihomo() {
    if command -v mihomo &>/dev/null; then
        echo "[2/7] mihomo already installed: $(mihomo -v)"
        return
    fi

    echo "[2/7] Installing mihomo ${MIHOMO_VERSION}..."
    curl -L -o /tmp/mihomo.gz "$MIHOMO_URL"
    gunzip -f /tmp/mihomo.gz
    chmod +x /tmp/mihomo
    mkdir -p "$BIN_DIR"
    mv /tmp/mihomo "$BIN_DIR/mihomo"
}

# ---------- Step 3: 安装辅助脚本 ----------
install_scripts() {
    echo "[3/7] Installing helper scripts..."
    cp "$SCRIPT_DIR/../include/gen_config.py" "$BIN_DIR/mihomo-gen-config"
    cp "$SCRIPT_DIR/../include/mihomo-update.sh" "$BIN_DIR/mihomo-update"
    chmod +x "$BIN_DIR/mihomo-gen-config" "$BIN_DIR/mihomo-update"
}

# ---------- Step 4: 生成配置 ----------
generate_config() {
    mkdir -p "$CONFIG_DIR"
    echo "[4/7] Generating config..."
    python3 "$BIN_DIR/mihomo-gen-config" "$SUB_URL" "$CONFIG_DIR/config.yaml"
    echo "$SUB_URL" > "$CONFIG_DIR/sub_url"

    echo "  Testing config..."
    if ! "$BIN_DIR/mihomo" -d "$CONFIG_DIR" -t 2>&1; then
        echo "  Config test failed"
        exit 1
    fi
}

# ---------- Step 5: 安装 Web UI ----------
install_yacd() {
    if [ -f "$CONFIG_DIR/ui/index.html" ]; then
        echo "[5/7] Yacd already installed, skipping."
        return
    fi

    echo "[5/7] Installing Yacd Web UI..."
    curl -sL "$YACD_URL" -o /tmp/yacd.tar.xz
    mkdir -p "$CONFIG_DIR/ui"
    tar xf /tmp/yacd.tar.xz -C "$CONFIG_DIR/ui" --strip-components=1
    rm -f /tmp/yacd.tar.xz
}

# ---------- Step 6: 启动 mihomo ----------
start_mihomo() {
    if pgrep -x mihomo > /dev/null; then
        echo "[6/7] Stopping existing mihomo process..."
        pkill mihomo || true
        sleep 1
    fi

    echo "[6/7] Starting mihomo..."
    nohup "$BIN_DIR/mihomo" -d "$CONFIG_DIR" > /tmp/mihomo.log 2>&1 &
    sleep 2

    if pgrep -x mihomo > /dev/null; then
        echo "  mihomo started (PID: $(pgrep -x mihomo))"
    else
        echo "  mihomo failed to start, check /tmp/mihomo.log"
        exit 1
    fi
}

# ---------- Step 7: 配置 zshrc ----------
setup_zshrc() {
    local zshrc="$HOME/.zshrc"

    if grep -q "mihomo-start" "$zshrc" 2>/dev/null; then
        echo "[7/7] zshrc already configured, skipping."
        return
    fi

    echo "[7/7] Configuring zshrc..."

    cat >> "$zshrc" << 'ZSHRC_EOF'

# mihomo proxy
export PATH="$HOME/.local/bin:$PATH"

proxy_on() {
    export http_proxy=http://127.0.0.1:7890
    export https_proxy=http://127.0.0.1:7890
    export all_proxy=socks5://127.0.0.1:7891
    export no_proxy=localhost,127.0.0.1
    echo "proxy on"
}
proxy_off() {
    unset http_proxy https_proxy all_proxy no_proxy
    echo "proxy off"
}
mihomo-start() {
    pgrep -x mihomo > /dev/null && echo "mihomo is already running" && return
    nohup mihomo -d ~/.config/mihomo > /tmp/mihomo.log 2>&1 &
    echo "mihomo started (PID: $!)"
}
mihomo-stop() {
    pgrep -x mihomo > /dev/null && pkill mihomo && echo "mihomo stopped" || echo "mihomo is not running"
}
mihomo-status() {
    pgrep -x mihomo > /dev/null && echo "mihomo is running (PID: $(pgrep -x mihomo))" || echo "mihomo is not running"
}
ZSHRC_EOF
}

# ---------- 主流程 ----------
main() {
    echo "========================================="
    echo "  Mihomo Proxy Installer"
    echo "========================================="
    echo

    install_deps
    install_mihomo
    install_scripts
    install_yacd
    generate_config
    start_mihomo
    setup_zshrc

    echo ""
    echo "========================================="
    echo "  Installation complete!"
    echo ""
    echo "  测试代理:  proxy_on && curl -I https://google.com"
    echo "  Web UI:    http://127.0.0.1:9090/ui/"
    echo "  更新订阅:  mihomo-update"
    echo "========================================="
}

main "$@"
