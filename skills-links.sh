#!/usr/bin/env bash
#
# skills-link.sh — 多端 AI 工具技能软链接管理器
#
# 将 ~/.agents/skills/ 下的技能文件夹软链接到各 AI 工具的技能目录
#
# 用法:
#   ./skills-link.sh install    # 安装软链接（重名跳过）
#   ./skills-link.sh uninstall  # 取消软链接（仅移除本脚本创建的链接）
#   ./skills-link.sh status     # 查看当前链接状态
#

set -euo pipefail

# ======================== 配置区 ========================

SOURCE_DIR="${SKILLS_SOURCE:-$HOME/.agents/skills}"

# 各工具的技能目录（可通过环境变量覆盖）
declare -A TARGETS=(
  [claude]="${SKILLS_CLAUDE_DIR:-$HOME/.claude/skills}"
  [opencode]="${SKILLS_OPENCODE_DIR:-$HOME/.opencode/skills}"
  [qoder]="${SKILLS_QODER_DIR:-$HOME/.qoder/skills}"
  [copilot]="${SKILLS_COPILOT_DIR:-$HOME/.copilot/skills}"
)

# ======================== 颜色 ========================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ======================== 函数 ========================

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
ok() { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[SKIP]${NC} $*"; }
err() { echo -e "${RED}[ERR]${NC} $*"; }

usage() {
  cat <<EOF
用法: $(basename "$0") <command>

命令:
  install     将 ~/.agents/skills/ 下的技能软链接到各工具目录（重名跳过）
  uninstall   取消软链接（仅移除指向源目录的符号链接）
  status      查看各工具目录的链接状态

环境变量:
  SKILLS_SOURCE        源技能目录 (默认: ~/.agents/skills)
  SKILLS_CLAUDE_DIR    Claude 技能目录 (默认: ~/.claude/skills)
  SKILLS_OPENCODE_DIR  OpenCode 技能目录 (默认: ~/.opencode/skills)
  SKILLS_QODER_DIR     Qoder 技能目录 (默认: ~/.qoder/skills)
  SKILLS_COPILOT_DIR   Copilot 技能目录 (默认: ~/.copilot/skills)

示例:
  $(basename "$0") install
  $(basename "$0") uninstall
  $(basename "$0") status
EOF
}

# 安装软链接
install_links() {
  if [[ ! -d "$SOURCE_DIR" ]]; then
    err "源目录不存在: $SOURCE_DIR"
    exit 1
  fi

  # 收集源目录下的文件夹
  local skills=()
  for skill in "$SOURCE_DIR"/*/; do
    [[ -d "$skill" ]] && skills+=("$(basename "$skill")")
  done

  if [[ ${#skills[@]} -eq 0 ]]; then
    warn "源目录中没有技能文件夹: $SOURCE_DIR"
    return
  fi

  info "源目录: $SOURCE_DIR"
  info "发现 ${#skills[@]} 个技能: ${skills[*]}"
  echo ""

  local linked=0 skipped=0

  for tool in $(echo "${!TARGETS[@]}" | tr ' ' '\n' | sort); do
    local target_dir="${TARGETS[$tool]}"
    info "处理 [$tool] → $target_dir"

    mkdir -p "$target_dir"

    for skill_name in "${skills[@]}"; do
      local src="$SOURCE_DIR/$skill_name"
      local dst="$target_dir/$skill_name"

      if [[ -L "$dst" ]]; then
        # 已存在符号链接
        local current_target
        current_target=$(readlink "$dst")
        if [[ "$current_target" == "$src" ]]; then
          warn "  $skill_name — 已链接，跳过"
        else
          warn "  $skill_name — 已存在其他链接(→ $current_target)，跳过"
        fi
        ((skipped++))
      elif [[ -e "$dst" ]]; then
        # 已存在同名文件/目录（非链接）
        warn "  $skill_name — 已存在同名目录/文件，跳过"
        ((skipped++))
      else
        ln -s "$src" "$dst"
        ok "  $skill_name → $src"
        ((linked++))
      fi
    done
    echo ""
  done

  info "完成! 新建链接: $linked, 跳过: $skipped"
}

# 取消软链接
uninstall_links() {
  if [[ ! -d "$SOURCE_DIR" ]]; then
    err "源目录不存在: $SOURCE_DIR (无法判断链接归属)"
    exit 1
  fi

  info "源目录: $SOURCE_DIR"
  info "正在移除指向源目录的软链接..."
  echo ""

  local removed=0

  for tool in $(echo "${!TARGETS[@]}" | tr ' ' '\n' | sort); do
    local target_dir="${TARGETS[$tool]}"

    if [[ ! -d "$target_dir" ]]; then
      continue
    fi

    info "处理 [$tool] ← $target_dir"

    for item in "$target_dir"/*; do
      [[ -L "$item" ]] || continue

      local link_target
      link_target=$(readlink "$item")

      # 仅移除指向源目录的链接
      if [[ "$link_target" == "$SOURCE_DIR"/* ]]; then
        rm "$item"
        ok "  已移除: $(basename "$item")"
        ((removed++))
      fi
    done
    echo ""
  done

  if [[ $removed -eq 0 ]]; then
    info "没有找到需要移除的链接"
  else
    info "完成! 已移除 $removed 个链接"
  fi
}

# 查看状态
show_status() {
  info "源目录: $SOURCE_DIR"

  if [[ ! -d "$SOURCE_DIR" ]]; then
    err "源目录不存在!"
    exit 1
  fi

  local skills=()
  for skill in "$SOURCE_DIR"/*/; do
    [[ -d "$skill" ]] && skills+=("$(basename "$skill")")
  done

  info "技能列表 (${#skills[@]}): ${skills[*]:-无}"
  echo ""

  for tool in $(echo "${!TARGETS[@]}" | tr ' ' '\n' | sort); do
    local target_dir="${TARGETS[$tool]}"
    echo -e "${BLUE}[$tool]${NC} $target_dir"

    if [[ ! -d "$target_dir" ]]; then
      echo "  目录不存在"
      echo ""
      continue
    fi

    local found=0
    for skill_name in "${skills[@]}"; do
      local dst="$target_dir/$skill_name"
      if [[ -L "$dst" ]]; then
        local link_target
        link_target=$(readlink "$dst")
        if [[ "$link_target" == "$SOURCE_DIR"/* ]]; then
          echo -e "  ${GREEN}✓${NC} $skill_name → $link_target"
        else
          echo -e "  ${YELLOW}⚠${NC} $skill_name → $link_target (非本脚本管理)"
        fi
        ((found++))
      elif [[ -e "$dst" ]]; then
        echo -e "  ${YELLOW}●${NC} $skill_name (本地目录/文件)"
        ((found++))
      fi
    done

    if [[ $found -eq 0 ]]; then
      echo "  (无链接)"
    fi
    echo ""
  done
}

# ======================== 主入口 ========================

main() {
  local cmd="${1:-}"

  case "$cmd" in
  install)
    install_links
    ;;
  uninstall | remove | rm)
    uninstall_links
    ;;
  status | list | ls)
    show_status
    ;;
  -h | --help | help | "")
    usage
    ;;
  *)
    err "未知命令: $cmd"
    echo ""
    usage
    exit 1
    ;;
  esac
}

main "$@"
