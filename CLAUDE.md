# UbuntuSync

AI 驱动的 Ubuntu 系统快速重建工具。通过声明式 YAML 配置定义目标状态，由 Claude Code 作为执行 agent，配合健康检查反馈闭环，实现从全新 Ubuntu 安装到完整开发环境的自动化配置。

## 核心流程

```
安装 Ubuntu -> 运行引导脚本（装好 Claude Code）-> 编排脚本逐项执行 -> 健康检查通过 -> 完成
```

健康检查是判断"完成"的唯一标准。每项任务执行后运行检查，失败则通过 `--resume` 将错误反馈给同一个 Claude Code 会话进行修复，循环直到通过。

## 架构设计

**不自己造 agent，利用 Claude Code 作为执行引擎。**

UbuntuSync 本身是一个轻量 Python 编排脚本，负责：
1. 读取 YAML 配置
2. 遍历每个配置项
3. 调用 `claude -p` 让 Claude Code 执行具体操作
4. 运行健康检查命令
5. 失败时用 `--resume` 反馈错误给同一个会话
6. 更新 state.json

复杂度全在 Claude Code 侧，编排脚本只做调度。

### 单项执行流程

```
claude -p "安装 docker.io"              → 拿到 conversation_id
跑 check 命令：docker --version
失败？→ claude -p "报错信息" --resume id  → Claude Code 修复
再跑 check
还失败？再反馈，最多重试 3 次
写 state.json
下一项
```

## 技术栈

- Python 3.10+（编排脚本）
- Claude Code CLI（执行 agent，通过 `claude -p` + `--resume` 调用）
- PyYAML — 配置解析
- Click — CLI 框架（可选，也可用 argparse）
- 状态存储：~/.ubuntusync/state.json

## 配置格式

模块化 YAML，包含两大类配置：

### 软件安装

每个配置项自行定义 `check` 和可选的 `expect` 字段，检查逻辑因软件而异。

```yaml
packages:
  apt:
    - name: docker.io
      check: docker --version          # 命令能跑
      expect: "Docker version"         # 输出包含此字符串
    - name: zsh
      check: zsh --version             # 只检查返回码，无 expect
  snap:
    - name: ghostty
      check: which ghostty
```

#### 健康检查设计

- `check`：要执行的 shell 命令
- `expect`（可选）：命令输出中需要包含的字符串，不填则只检查返回码是否为 0
- 每个软件的具体检查方式由用户在配置中定义，不做通用模板
- 检查失败时，编排脚本将命令、返回码、输出反馈给 Claude Code 进行诊断修复

### 配置文件同步

采用**直接路径映射**，声明 source → dest，不依赖大模型猜测路径。

```yaml
files:
  - source: files/ghostty/config
    dest: ~/.config/ghostty/config
  - source: files/starship.toml
    dest: ~/.config/starship.toml
  - source: files/fcitx5/
    dest: ~/.config/fcitx5/
```

- `source` 相对于 YAML 配置文件所在目录
- 支持单文件和整个目录映射
- 配置文件与 YAML 存放在同一 GitHub 仓库中

仓库结构示例：

```
my-ubuntusync-configs/
├── base.yaml
├── files/
│   ├── ghostty/
│   │   └── config
│   ├── starship.toml
│   └── fcitx5/
│       ├── config
│       └── profile/
│           └── default
```

## 软件安装清单

### 安装方式分类

| 安装方式 | 软件 |
|---------|------|
| apt（含源配置） | Chrome、Zsh、Fcitx5 |
| snap | Ghostty、VS Code |
| npm | Claude Code |
| GitHub deb | LocalSend、CCSwitch、FlClash |
| GitHub zip | Maple Font |
| 直接 URL deb | QQ、微信 |
| 官方脚本 | Starship、Oh My Zsh |

### 需要配置管理的软件

- Ghostty — 终端配置文件
- Starship — prompt 配置文件
- Fcitx5 — 输入法配置文件

## CLI 命令

- `ubuntusync apply config.yaml` — 应用配置
- `ubuntusync apply --dry-run config.yaml` — 干跑模式
- `ubuntusync doctor` — 系统健康检查

## 项目结构

```
UbuntuSync/
├── CLAUDE.md
├── README.md
├── bootstrap.sh            # 引导脚本：装 Node.js + Claude Code
├── ubuntusync/
│   ├── __init__.py
│   ├── cli.py              # CLI 入口
│   ├── config.py           # YAML 配置加载与校验
│   ├── orchestrator.py     # 核心编排逻辑（调 claude CLI + 健康检查 + 重试）
│   └── state.py            # state.json 状态管理
└── configs/
    └── example.yaml        # 示例配置
```
