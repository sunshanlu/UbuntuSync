# UbuntuSync

一键配置 Ubuntu 开发环境的 shell 脚本集合。

## 项目结构

- `install.sh` — 总入口，按顺序调用所有脚本
- `scripts/` — 各软件的安装脚本，可独立运行
- `include/` — 配置文件，脚本通过 `$SCRIPT_DIR/../include/` 引用

## 脚本执行顺序

1. `init-zsh.sh` — Zsh + Oh My Zsh + Starship
2. `init-mihomo.sh` — Mihomo 代理
3. `init-maple-font.sh` — Maple Mono 字体
4. `init-ghostty.sh` — Ghostty 终端
5. `init-fcitx5.sh` — Fcitx5 输入法
6. `install-debs.sh` — deb 包（LocalSend、微信、QQ、Chrome、VS Code）

顺序有依赖：后续脚本往 `.zshrc` 写环境变量，Ghostty 配置引用 Maple 字体，deb 下载依赖 mihomo 代理。

## 约定

- GitHub 资源通过 `ghfast.top` 代理加速下载
- 脚本输出风格统一：`[N/M]` 步骤编号 + 缩进状态信息
- 已安装的软件自动跳过，支持幂等执行
- 配置文件放 `include/`，脚本放 `scripts/`
