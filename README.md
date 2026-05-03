# UbuntuSync

AI 驱动的 Ubuntu 系统快速重建工具。通过声明式 YAML 配置定义目标状态，由 Claude Code 作为执行 agent，配合健康检查反馈闭环，实现从全新 Ubuntu 安装到完整开发环境的自动化配置。

## 核心理念

```
安装 Ubuntu -> 运行引导脚本 -> UbuntuSync 编排执行 -> 健康检查通过 -> 完成
```

UbuntuSync 不自己造 agent，而是利用 **Claude Code 作为执行引擎**。编排脚本负责调度，Claude Code 负责具体操作。

健康检查是判断"完成"的唯一标准。每项任务执行后运行检查命令，失败则通过 `--resume` 将错误反馈给同一个 Claude Code 会话进行修复，循环直到通过。

## 工作原理

```
遍历配置项
  ├── claude -p "装 X"                    → 拿到 conversation_id
  ├── 跑 check 命令
  ├── 失败？→ claude -p "报错" --resume id → Claude Code 修复
  ├── 再跑 check
  ├── 还失败？再反馈，最多重试 3 次
  ├── 写 state.json
  └── 下一项
```

## 快速开始

```bash
# 1. 运行引导脚本（安装 Node.js + Claude Code）
bash bootstrap.sh

# 2. 应用配置
ubuntusync apply configs/example.yaml

# 3. 干跑模式（只看计划不执行）
ubuntusync apply --dry-run configs/example.yaml

# 4. 系统健康检查
ubuntusync doctor
```

## 配置示例

```yaml
packages:
  apt:
    - name: docker.io
      check: docker --version
      expect: "Docker version"       # 输出必须包含此字符串
    - name: zsh
      check: zsh --version           # 只检查返回码

  snap:
    - name: ghostty
      check: which ghostty
    - name: code
      args: --classic
      check: code --version
      expect: "code"

  npm:
    - name: "@anthropic-ai/claude-code"
      global: true
      check: claude --version

  github_deb:
    - repo: localsend/localsend
      check: which localsend

  url_deb:
    - name: QQ
      url: https://dldir1.qq.com/qqfile/qq/QQNT/Linux/QQ_3.2.12_amd64.deb
      check: which qq

  script:
    - name: starship
      url: https://starship.rs/install.sh
      check: starship --version
      expect: "starship"

shell:
  default: zsh
  plugins:
    - oh-my-zsh
    - autosuggestions

files:
  - source: files/ghostty/config
    dest: ~/.config/ghostty/config
  - source: files/starship.toml
    dest: ~/.config/starship.toml
  - source: files/fcitx5/
    dest: ~/.config/fcitx5/
```

## 配置存放

配置文件和 dotfiles 放同一个 GitHub 仓库，`source` 路径相对于 YAML 文件位置：

```
my-ubuntusync-configs/
├── base.yaml
├── dev.yaml
└── files/
    ├── ghostty/
    │   └── config
    ├── starship.toml
    └── fcitx5/
        ├── config
        └── profile/
            └── default
```

## License

MIT
