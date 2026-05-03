#!/bin/bash
# 更新 mihomo 订阅配置并重启
# 用法: mihomo-update [订阅链接]
# 如果不传参数，则使用 ~/.config/mihomo/sub_url 中保存的链接

CONFIG_DIR="$HOME/.config/mihomo"
SUB_URL_FILE="$CONFIG_DIR/sub_url"
GEN_SCRIPT="$HOME/.local/bin/mihomo-gen-config"

# 获取订阅链接
if [ -n "$1" ]; then
    SUB_URL="$1"
    mkdir -p "$CONFIG_DIR"
    echo "$SUB_URL" > "$SUB_URL_FILE"
elif [ -f "$SUB_URL_FILE" ]; then
    SUB_URL=$(cat "$SUB_URL_FILE")
else
    echo "用法: mihomo-update <订阅链接>"
    echo "首次使用需要传入订阅链接，之后会自动保存"
    exit 1
fi

echo "Downloading subscription..."
python3 "$GEN_SCRIPT" "$SUB_URL" "$CONFIG_DIR/config.yaml"
if [ $? -eq 0 ]; then
    echo "Config updated. Restarting mihomo..."
    PID=$(pgrep -x mihomo)
    if [ -n "$PID" ]; then
        kill $PID 2>/dev/null
        sleep 1
    fi
    nohup ~/.local/bin/mihomo -d "$CONFIG_DIR" > /tmp/mihomo.log 2>&1 &
    echo "Done. mihomo restarted (PID: $!)"
else
    echo "Failed to generate config"
    exit 1
fi
