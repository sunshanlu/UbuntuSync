# Mihomo 代理配置步骤

## Step 1: 安装 mihomo

```bash
# 有代理环境
curl -L -o /tmp/mihomo.gz https://github.com/MetaCubeX/mihomo/releases/download/v1.19.24/mihomo-linux-amd64-compatible-v1.19.24.gz

# 无代理环境，用镜像
curl -L -o /tmp/mihomo.gz "https://ghfast.top/https://github.com/MetaCubeX/mihomo/releases/download/v1.19.24/mihomo-linux-amd64-compatible-v1.19.24.gz"

# 安装
gunzip /tmp/mihomo.gz
chmod +x /tmp/mihomo
mkdir -p ~/.local/bin
mv /tmp/mihomo ~/.local/bin/mihomo
mihomo -v
```

## Step 2: 安装辅助脚本

```bash
cp files/mihomo/gen_config.py ~/.local/bin/mihomo-gen-config
cp files/mihomo/mihomo-update ~/.local/bin/mihomo-update
chmod +x ~/.local/bin/mihomo-gen-config ~/.local/bin/mihomo-update
```

## Step 3: 生成配置

```bash
mkdir -p ~/.config/mihomo
python3 ~/.local/bin/mihomo-gen-config "你的订阅链接" ~/.config/mihomo/config.yaml
```

测试配置：`mihomo -d ~/.config/mihomo -t`

如果报 GEOIP 错误，移除配置文件中的 `GEOIP,CN,DIRECT` 规则，或手动下载：
```bash
curl -L -o ~/.config/mihomo/country.mmdb "https://ghfast.top/https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country.mmdb"
```

## Step 4: 启动 mihomo

```bash
mihomo-start  # 或手动: nohup mihomo -d ~/.config/mihomo > /tmp/mihomo.log 2>&1 &
```

验证：`curl -s http://127.0.0.1:9090` 有响应即成功。

## Step 5: 配置终端代理

在 `~/.zshrc` 中添加：

```bash
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
```

```bash
source ~/.zshrc
proxy_on
curl -I https://google.com   # 测试
```

## Step 6: 配置 Chrome 代理

```bash
gsettings set org.gnome.system.proxy mode 'manual'
gsettings set org.gnome.system.proxy.http host '127.0.0.1'
gsettings set org.gnome.system.proxy.http port 7890
gsettings set org.gnome.system.proxy.https host '127.0.0.1'
gsettings set org.gnome.system.proxy.https port 7890
```

关闭：`gsettings set org.gnome.system.proxy mode 'none'`

## Step 7: 安装 Web UI（可选）

```bash
curl -sL "https://ghfast.top/https://github.com/haishanh/yacd/releases/latest/download/yacd.tar.xz" -o /tmp/yacd.tar.xz
mkdir -p ~/.config/mihomo/ui
tar xf /tmp/yacd.tar.xz -C ~/.config/mihomo/ui --strip-components=1
```

配置文件中确认有 `external-ui: "~/.config/mihomo/ui"`，重启后访问 `http://127.0.0.1:9090/ui/`

## Step 8: 更新订阅

```bash
mihomo-update "你的订阅链接"   # 首次需要传链接，之后直接 mihomo-update
```

---

## 常用命令速查

| 命令 | 作用 |
|---|---|
| `mihomo-start` | 启动 mihomo |
| `mihomo-stop` | 停止 mihomo |
| `mihomo-status` | 查看状态 |
| `mihomo-update` | 更新订阅并重启 |
| `proxy_on` | 终端开启代理 |
| `proxy_off` | 终端关闭代理 |

`mihomo-start` 启动代理服务，`proxy_on` 让终端走代理。两者都需要：先 start，再 on。

## 端口说明

| 端口 | 用途 |
|---|---|
| `127.0.0.1:7890` | HTTP + SOCKS5 混合代理 |
| `127.0.0.1:9090` | REST API / Web UI |

## 代理组说明

| 代理组 | 说明 |
|---|---|
| PROXY | 默认组，可手动选节点或选 Auto |
| Auto | 自动测速，选延迟最低的节点 |
| GLOBAL | 所有流量走代理（一般不用） |

推荐 PROXY 保持 Auto。
