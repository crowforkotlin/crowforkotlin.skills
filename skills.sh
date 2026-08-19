#!/usr/bin/env bash
#
# skills.sh — AI 技能安装管理器
#
# 将本仓库中的 skills 复制到 ~/.agents/skills/ 并软链接到各 AI 工具目录
#
# 用法:
#   ./skills.sh              # 默认: 复制 skills + 安装软链接
#   ./skills.sh link         # 仅安装软链接
#   ./skills.sh unlink       # 取消全部受管理的软链接
#   ./skills.sh remove-skill <name> [--force] # 删除指定技能及其软链接
#   ./skills.sh status       # 查看同步和链接状态
#   ./skills.sh check        # 仅检查仓库技能是否已同步
#   ./skills.sh cp           # 仅复制 skills 到 ~/.agents/skills/
#   ./skills.sh deploy       # 部署 skills（复制 + 链接）
#

set -euo pipefail

# ======================== 配置区 ========================

# 仓库根目录（脚本所在目录）
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 仓库内 skills 目录
REPO_SKILLS_DIR="$REPO_DIR/skills"

# 目标安装目录
SOURCE_DIR="${SKILLS_SOURCE:-$HOME/.agents/skills}"

# 各工具的技能目录（可通过环境变量覆盖）
SKILLS_CLAUDE_DIR="${SKILLS_CLAUDE_DIR:-$HOME/.claude/skills}"
SKILLS_OPENCODE_DIR="${SKILLS_OPENCODE_DIR:-$HOME/.opencode/skills}"
SKILLS_QODER_DIR="${SKILLS_QODER_DIR:-$HOME/.qoder/skills}"
SKILLS_COPILOT_DIR="${SKILLS_COPILOT_DIR:-$HOME/.copilot/skills}"

# ======================== 颜色 ========================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ======================== 函数 ========================

info() { printf '%b[INFO]%b %s\n' "$BLUE" "$NC" "$*"; }
ok() { printf '%b[OK]%b %s\n' "$GREEN" "$NC" "$*"; }
warn() { printf '%b[SKIP]%b %s\n' "$YELLOW" "$NC" "$*"; }
notice() { printf '%b[WARN]%b %s\n' "$YELLOW" "$NC" "$*"; }
err() { printf '%b[ERR]%b %s\n' "$RED" "$NC" "$*"; }

usage() {
  cat <<EOF
用法: $(basename "$0") [command]

命令:
  (无参数)      复制 skills 到 ~/.agents/skills/ 并安装软链接（默认）
  deploy        部署 skills（复制 + 链接），等同于默认行为
  cp            仅复制本仓库 skills 到 ~/.agents/skills/
  link          仅安装软链接（将 ~/.agents/skills/ 链接到各工具目录）
  unlink        取消全部受管理的软链接（仅移除指向源目录的符号链接）
  remove-skill  删除指定技能及其受管理的符号链接；--force 删除同名的其他符号链接
  status        查看仓库技能同步状态和各工具目录的链接状态
  check         仅检查仓库 skills 与目标目录是否一致，不修改文件

环境变量:
  SKILLS_SOURCE        目标技能目录 (默认: ~/.agents/skills)
  SKILLS_CLAUDE_DIR    Claude 技能目录 (默认: ~/.claude/skills)
  SKILLS_OPENCODE_DIR  OpenCode 技能目录 (默认: ~/.opencode/skills)
  SKILLS_QODER_DIR     Qoder 技能目录 (默认: ~/.qoder/skills)
  SKILLS_COPILOT_DIR   Copilot 技能目录 (默认: ~/.copilot/skills)

示例:
  $(basename "$0")              # 复制 + 链接
  $(basename "$0") cp           # 仅复制
  $(basename "$0") link         # 仅链接
  $(basename "$0") unlink       # 取消链接
  $(basename "$0") remove-skill git-commit          # 删除指定技能
  $(basename "$0") remove-skill git-commit --force  # 删除同名的所有符号链接
  $(basename "$0") status       # 查看状态
  $(basename "$0") check        # 检查是否有待部署的技能更新
EOF
}

# 比较两个技能目录的内容。diff 仅在目录内容不同或读取失败时返回非零。
skill_dirs_match() {
  diff -qr "$1" "$2" >/dev/null 2>&1
}

# 复制 skills 到 ~/.agents/skills/
copy_skills() {
  if [[ ! -d "$REPO_SKILLS_DIR" ]]; then
    err "仓库 skills 目录不存在: $REPO_SKILLS_DIR"
    exit 1
  fi

  # 收集仓库 skills 目录下的技能文件夹
  local skills=()
  for skill in "$REPO_SKILLS_DIR"/*/; do
    [[ -d "$skill" ]] && skills+=("$(basename "$skill")")
  done

  if [[ ${#skills[@]} -eq 0 ]]; then
    warn "仓库 skills 目录中没有技能文件夹: $REPO_SKILLS_DIR"
    return
  fi

  info "仓库 skills 目录: $REPO_SKILLS_DIR"
  info "目标目录: $SOURCE_DIR"
  info "发现 ${#skills[@]} 个技能: ${skills[*]}"
  echo ""

  mkdir -p "$SOURCE_DIR"

  local added=0 updated=0 current=0 skipped=0
  for skill_name in "${skills[@]}"; do
    local src="$REPO_SKILLS_DIR/$skill_name"
    local dst="$SOURCE_DIR/$skill_name"

    if [[ -e "$dst" || -L "$dst" ]]; then
      if [[ ! -d "$dst" ]]; then
        warn "  $skill_name — 目标不是目录，跳过"
        skipped=$((skipped + 1))
      elif skill_dirs_match "$src" "$dst"; then
        info "  $skill_name — 已是最新"
        current=$((current + 1))
      else
        rm -rf "$dst"
        cp -r "$src" "$dst"
        ok "  $skill_name — 已更新"
        updated=$((updated + 1))
      fi
    else
      cp -r "$src" "$dst"
      ok "  $skill_name — 已复制"
      added=$((added + 1))
    fi
  done

  echo ""
  info "同步完成! 新增: $added, 更新: $updated, 已是最新: $current, 跳过: $skipped"
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

  local linked=0 existing=0 skipped=0

  # 遍历各工具
  for tool in claude copilot opencode qoder; do
    case "$tool" in
      claude)     local target_dir="$SKILLS_CLAUDE_DIR" ;;
      copilot)    local target_dir="$SKILLS_COPILOT_DIR" ;;
      opencode)   local target_dir="$SKILLS_OPENCODE_DIR" ;;
      qoder)      local target_dir="$SKILLS_QODER_DIR" ;;
    esac

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
          ok "  $skill_name — 链接已就绪（内容来自源目录）"
          existing=$((existing + 1))
        else
          warn "  $skill_name — 已存在其他链接(→ $current_target)，跳过"
          skipped=$((skipped + 1))
        fi
      elif [[ -e "$dst" ]]; then
        # 已存在同名文件/目录（非链接）
        warn "  $skill_name — 已存在同名目录/文件，跳过"
        skipped=$((skipped + 1))
      else
        ln -s "$src" "$dst"
        ok "  $skill_name → $src"
        linked=$((linked + 1))
      fi
    done
    echo ""
  done

  info "完成! 新建链接: $linked, 已有链接: $existing, 跳过: $skipped"
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

  # 遍历各工具
  for tool in claude copilot opencode qoder; do
    case "$tool" in
      claude)     local target_dir="$SKILLS_CLAUDE_DIR" ;;
      copilot)    local target_dir="$SKILLS_COPILOT_DIR" ;;
      opencode)   local target_dir="$SKILLS_OPENCODE_DIR" ;;
      qoder)      local target_dir="$SKILLS_QODER_DIR" ;;
    esac

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
        removed=$((removed + 1))
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

# 删除指定技能的源目录以及指向该目录的受管理软链接
remove_skill() {
  local skill_name="${1:-}"
  local force="${2:-}"

  if [[ -z "$skill_name" || "$skill_name" == .* || "$skill_name" == */* ]]; then
    err "技能名称必须是不含路径分隔符的目录名"
    exit 1
  fi

  if [[ -n "$force" && "$force" != "--force" ]]; then
    err "未知选项: $force"
    exit 1
  fi

  local source_skill_dir="$SOURCE_DIR/$skill_name"
  local removed_links=0
  for tool in claude copilot opencode qoder; do
    case "$tool" in
      claude)  local target_dir="$SKILLS_CLAUDE_DIR" ;;
      copilot) local target_dir="$SKILLS_COPILOT_DIR" ;;
      opencode) local target_dir="$SKILLS_OPENCODE_DIR" ;;
      qoder)   local target_dir="$SKILLS_QODER_DIR" ;;
    esac

    local link_path="$target_dir/$skill_name"
    if [[ -L "$link_path" ]]; then
      local link_target
      link_target=$(readlink "$link_path")
      if [[ "$link_target" == "$source_skill_dir" ]]; then
        rm "$link_path"
        ok "  已移除链接: $tool/$skill_name"
        removed_links=$((removed_links + 1))
      elif [[ "$force" == "--force" ]]; then
        rm "$link_path"
        ok "  已强制移除链接: $tool/$skill_name"
        removed_links=$((removed_links + 1))
      else
        warn "  $tool/$skill_name 指向其他位置，未删除"
      fi
    elif [[ -e "$link_path" ]]; then
      warn "  $tool/$skill_name 不是受管理的链接，未删除"
    fi
  done

  if [[ -d "$source_skill_dir" ]]; then
    rm -rf "$source_skill_dir"
    ok "已删除技能源目录: $source_skill_dir"
  else
    info "技能源目录不存在，仅检查并清理残留链接"
  fi
  info "完成! 已移除链接: $removed_links"
}

# 查看仓库 skills 与目标目录的同步状态（不修改文件）
show_sync_status() {
  if [[ ! -d "$REPO_SKILLS_DIR" ]]; then
    err "仓库 skills 目录不存在: $REPO_SKILLS_DIR"
    exit 1
  fi

  info "===== 技能同步状态 ====="
  info "仓库 skills 目录: $REPO_SKILLS_DIR"
  info "目标目录: $SOURCE_DIR"

  local skills=()
  for skill in "$REPO_SKILLS_DIR"/*/; do
    [[ -d "$skill" ]] && skills+=("$(basename "$skill")")
  done

  if [[ ${#skills[@]} -eq 0 ]]; then
    notice "仓库 skills 目录中没有技能文件夹: $REPO_SKILLS_DIR"
    return
  fi

  if [[ ! -d "$SOURCE_DIR" ]]; then
    notice "目标目录不存在，${#skills[@]} 个仓库技能尚未部署"
    info "运行 './$(basename "$0") deploy' 进行部署"
    return
  fi

  local current=0 outdated=0 missing=0 invalid=0 local_only=0
  for skill_name in "${skills[@]}"; do
    local src="$REPO_SKILLS_DIR/$skill_name"
    local dst="$SOURCE_DIR/$skill_name"

    if [[ ! -e "$dst" && ! -L "$dst" ]]; then
      notice "  $skill_name — 尚未部署"
      missing=$((missing + 1))
    elif [[ ! -d "$dst" ]]; then
      notice "  $skill_name — 目标不是目录"
      invalid=$((invalid + 1))
    elif skill_dirs_match "$src" "$dst"; then
      ok "  $skill_name — 已是最新"
      current=$((current + 1))
    else
      notice "  $skill_name — 内容有更新待部署"
      outdated=$((outdated + 1))
    fi
  done

  for installed_skill in "$SOURCE_DIR"/*/; do
    [[ -d "$installed_skill" ]] || continue
    local skill_name
    skill_name=$(basename "$installed_skill")
    if [[ ! -d "$REPO_SKILLS_DIR/$skill_name" ]]; then
      info "  $skill_name — 仅存在于目标目录（未由当前仓库管理）"
      local_only=$((local_only + 1))
    fi
  done

  echo ""
  info "检查完成! 已是最新: $current, 待更新: $outdated, 未部署: $missing, 异常: $invalid, 本地独有: $local_only"
  if [[ $((outdated + missing + invalid)) -gt 0 ]]; then
    info "运行 './$(basename "$0") deploy' 同步仓库中的技能更新"
  fi
}

# 查看状态
show_status() {
  show_sync_status
  echo ""
  info "===== 软链接状态 ====="
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

  # 遍历各工具
  for tool in claude copilot opencode qoder; do
    case "$tool" in
      claude)     local target_dir="$SKILLS_CLAUDE_DIR" ;;
      copilot)    local target_dir="$SKILLS_COPILOT_DIR" ;;
      opencode)   local target_dir="$SKILLS_OPENCODE_DIR" ;;
      qoder)      local target_dir="$SKILLS_QODER_DIR" ;;
    esac

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
        found=$((found + 1))
      elif [[ -e "$dst" ]]; then
        echo -e "  ${YELLOW}●${NC} $skill_name (本地目录/文件)"
        found=$((found + 1))
      fi
    done

    if [[ $found -eq 0 ]]; then
      echo "  (无链接)"
    fi
    echo ""
  done
}

# 完整安装（复制 + 链接）
full_install() {
  info "===== 步骤 1/2: 复制 skills ====="
  echo ""
  copy_skills
  echo ""
  info "===== 步骤 2/2: 安装软链接 ====="
  echo ""
  install_links
}

# ======================== 主入口 ========================

main() {
  local cmd="${1:-}"

  case "$cmd" in
  "")
    # 默认: 复制 + 链接
    full_install
    ;;
  deploy)
    full_install
    ;;
  cp | copy)
    copy_skills
    ;;
  link)
    install_links
    ;;
  unlink | uninstall | rm)
    uninstall_links
    ;;
  remove-skill)
    remove_skill "${2:-}" "${3:-}"
    ;;
  check | verify)
    show_sync_status
    ;;
  status | list | ls)
    show_status
    ;;
  -h | --help | help)
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
