# crowforkotlin.skills

AI 技能（Skills）管理仓库 — 收集、安装、部署技能到各 AI 编码工具。

## 仓库结构

```
.
├── skills.sh                 # 部署管理器（复制 + 软链接）
├── skills/                   # 技能目录
│   ├── git-commit-en/SKILL.md
│   ├── git-commit-zh/SKILL.md
│   ├── git-branch-governance/SKILL.md
│   ├── gh-commit-pr/
│   │   ├── SKILL.md
│   │   └── agents/openai.yaml
│   ├── gh-create-pr/
│   │   ├── SKILL.md
│   │   ├── agents/openai.yaml
│   │   └── scripts/
│   └── input-optimizer/SKILL.md
└── scripts/
    ├── install-skill.sh      # 从 GitHub/本地安装技能
    └── skills-links.sh       # 原始链接脚本（已整合到 skills.sh）
```

## Quick Start

```bash
chmod +x skills.sh

# 一键部署（复制 skills 到 ~/.agents/skills/ + 软链接到各工具）
./skills.sh

# 仅复制
./skills.sh cp

# 仅链接
./skills.sh link

# 取消链接
./skills.sh unlink

# 删除指定的受管理技能及其软链接
./skills.sh remove-skill git-commit

# 强制删除同名的符号链接（不删除同名目录）
./skills.sh remove-skill git-commit --force

# 查看状态
./skills.sh status

# 仅检查仓库技能是否已同步到 ~/.agents/skills/，不修改文件
./skills.sh check
```

## 更新技能

拉取仓库更新后，先检查本地部署状态，再执行部署：

```bash
git pull
./skills.sh check
./skills.sh deploy
```

`deploy` 会逐个比较仓库与 `~/.agents/skills/` 中的技能内容，并明确报告“新增”、“已更新”和“已是最新”。
后续显示的“链接已就绪”表示软链接已经指向该源目录，不需要重建；源目录内容更新后，各 AI 工具会自动使用更新后的内容。

## 安装开源技能

```bash
# 从 GitHub 仓库安装
./scripts/install-skill.sh https://github.com/user/awesome-skill

# 从多技能仓库中安装指定技能
./scripts/install-skill.sh https://github.com/user/skills-repo skill-name

# 安装后自动部署
./scripts/install-skill.sh https://github.com/user/awesome-skill --deploy

# 从本地路径安装
./scripts/install-skill.sh /path/to/skill-dir
```

## 部署目标

| Tool     | Path                 |
| -------- | -------------------- |
| Claude   | `~/.claude/skills/`  |
| OpenCode | `~/.opencode/skills/`|
| Qoder    | `~/.qoder/skills/`   |
| Copilot  | `~/.copilot/skills/` |

## 自定义路径

通过环境变量覆盖默认配置：

```bash
SKILLS_SOURCE=~/.my-skills ./skills.sh deploy
SKILLS_CLAUDE_DIR=~/.config/claude/skills ./skills.sh link
```

| Variable              | Default              |
| --------------------- | -------------------- |
| `SKILLS_SOURCE`       | `~/.agents/skills`   |
| `SKILLS_CLAUDE_DIR`   | `~/.claude/skills`   |
| `SKILLS_OPENCODE_DIR` | `~/.opencode/skills` |
| `SKILLS_QODER_DIR`    | `~/.qoder/skills`    |
| `SKILLS_COPILOT_DIR`  | `~/.copilot/skills`  |

## Requirements

- Bash 4+（关联数组支持）
- Git（install-skill.sh 需要）
- diff（用于比较技能内容，macOS / Linux 系统通常自带）
- Linux / macOS
