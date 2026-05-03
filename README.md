# UbuntuSync

一键配置 Ubuntu 开发环境。通过 curl 一条命令，自动安装常用软件、终端、输入法、字体，并同步配置文件。

## 快速开始

```bash
curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/sunshanlu/UbuntuSync/master/install.sh | bash -s -- "你的订阅地址"
```

## 安装内容

| 脚本 | 内容 |
|------|------|
| `init-zsh.sh` | Zsh + Oh My Zsh + Starship |
| `init-mihomo.sh` | Mihomo 代理 + Yacd Web UI |
| `init-maple-font.sh` | Maple Mono NF CN 字体 |
| `init-ghostty.sh` | Ghostty 终端 + 配置同步 |
| `init-fcitx5.sh` | Fcitx5 拼音输入法 + Candlelight 主题 |
| `install-debs.sh` | LocalSend、微信、QQ、Chrome、VS Code |

## 单独运行

每个脚本都可以独立运行：

```bash
bash scripts/init-zsh.sh
bash scripts/init-ghostty.sh
# ...
```

## 项目结构

```
UbuntuSync/
├── install.sh                  # 一键安装入口
├── include/                    # 配置文件
│   ├── .zshrc
│   ├── starship.toml
│   ├── ghostty-config
│   ├── gen_config.py
│   ├── mihomo-update.sh
│   └── fcitx5/
│       ├── profile
│       └── conf/
└── scripts/                    # 安装脚本
    ├── init-zsh.sh
    ├── init-mihomo.sh
    ├── init-maple-font.sh
    ├── init-ghostty.sh
    ├── init-fcitx5.sh
    └── install-debs.sh
```

## License

MIT
