# crowforkotlin.skills

Symlink `~/.agents/skills/` to multiple AI coding tools (Claude, OpenCode, Qoder, Copilot).

## Quick Start

```bash
chmod +x skills-links.sh

# Install symlinks (skip duplicates)
./skills-links.sh install

# Remove symlinks
./skills-links.sh uninstall

# Check status
./skills-links.sh status
```

## Target Directories

| Tool      | Path                  |
| --------- | --------------------- |
| Claude    | `~/.claude/skills/`   |
| OpenCode  | `~/.opencode/skills/` |
| Qoder     | `~/.qoder/skills/`    |
| Copilot   | `~/.copilot/skills/`  |

## Custom Paths

Override defaults via environment variables:

```bash
SKILLS_SOURCE=~/.my-skills ./skills-links.sh install
SKILLS_CLAUDE_DIR=~/.config/claude/skills ./skills-links.sh install
```

| Variable             | Default               |
| -------------------- | --------------------- |
| `SKILLS_SOURCE`      | `~/.agents/skills`    |
| `SKILLS_CLAUDE_DIR`  | `~/.claude/skills`    |
| `SKILLS_OPENCODE_DIR`| `~/.opencode/skills`  |
| `SKILLS_QODER_DIR`   | `~/.qoder/skills`     |
| `SKILLS_COPILOT_DIR` | `~/.copilot/skills`   |

## Requirements

- Bash 4+ (for associative arrays)
- Linux / macOS
