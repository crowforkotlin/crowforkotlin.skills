#!/usr/bin/env bash
#
# install-skill.sh — 从 GitHub 等开源地址安装 AI Skill
#
# 用法:
#   ./scripts/install-skill.sh <url> [skill-name]
#   ./scripts/install-skill.sh https://github.com/user/awesome-skill
#   ./scripts/install-skill.sh https://github.com/user/skills-repo my-skill
#   ./scripts/install-skill.sh <url> --deploy    # 安装后自动部署
#
# 支持的 URL 格式:
#   - GitHub 仓库:    https://github.com/user/repo
#   - GitHub 子目录:  https://github.com/user/repo/tree/branch/path/to/skill
#   - 本地路径:       /path/to/skill-directory
#

set -euo pipefail

# ======================== 配置 ========================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$REPO_DIR/skills"

# ======================== 颜色 ========================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
ok() { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err() { echo -e "${RED}[ERR]${NC} $*"; }

usage() {
  cat <<USAGE
用法: $(basename "$0") <source> [skill-name] [--deploy]

参数:
  source        技能来源（GitHub URL 或本地路径）
  skill-name    可选，指定要安装的技能名称（用于多技能仓库）
  --deploy      安装后自动执行部署（cp + link）

支持的来源格式:
  GitHub 仓库       https://github.com/user/repo
  GitHub 子目录     https://github.com/user/repo/tree/branch/path/to/skill
  本地路径          /path/to/skill-directory

示例:
  $(basename "$0") https://github.com/user/awesome-skill
  $(basename "$0") https://github.com/user/skills-repo my-skill
  $(basename "$0") https://github.com/user/skills-repo --deploy
  $(basename "$0") /home/user/my-local-skill
USAGE
}

# ======================== 工具函数 ========================

# 清理临时目录
cleanup() {
  if [[ -n "${TMP_DIR:-}" && -d "${TMP_DIR:-}" ]]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

# 判断是否为 GitHub URL
is_github_url() {
  [[ "$1" =~ ^https?://github\.com/ ]]
}

# 解析 GitHub 子目录 URL
# 格式: https://github.com/user/repo/tree/branch/path/to/dir
parse_github_subdir_url() {
  local url="$1"
  if [[ "$url" =~ ^https?://github\.com/([^/]+)/([^/]+)/tree/([^/]+)/(.+)$ ]]; then
    GH_USER="${BASH_REMATCH[1]}"
    GH_REPO="${BASH_REMATCH[2]}"
    GH_BRANCH="${BASH_REMATCH[3]}"
    GH_SUBDIR="${BASH_REMATCH[4]}"
    return 0
  fi
  return 1
}

# 解析 GitHub 仓库 URL
parse_github_repo_url() {
  local url="$1"
  # 去除末尾 .git 和 /
  url="${url%.git}"
  url="${url%/}"
  if [[ "$url" =~ ^https?://github\.com/([^/]+)/([^/]+)$ ]]; then
    GH_USER="${BASH_REMATCH[1]}"
    GH_REPO="${BASH_REMATCH[2]}"
    GH_BRANCH=""
    GH_SUBDIR=""
    return 0
  fi
  return 1
}

# 检测目录中是否包含 skill（有 SKILL.md）
find_skills_in_dir() {
  local dir="$1"
  local -n result=$2
  result=()

  # 根目录直接有 SKILL.md → 单技能
  if [[ -f "$dir/SKILL.md" ]]; then
    result+=("$dir")
    return
  fi

  # 子目录中有 SKILL.md → 多技能
  for sub in "$dir"/*/; do
    if [[ -f "$sub/SKILL.md" ]]; then
      result+=("${sub%/}")
    fi
  done
}

# 从 SKILL.md 提取技能名称
get_skill_name() {
  local skill_dir="$1"
  local skill_md="$skill_dir/SKILL.md"

  # 尝试从 frontmatter 的 name 字段提取
  local name
  name=$(grep -m1 '^name:' "$skill_md" 2>/dev/null | sed 's/^name:[[:space:]]*//' | tr -d '"' | tr -d "'")

  if [[ -n "$name" ]]; then
    echo "$name"
  else
    # 回退到目录名
    basename "$skill_dir"
  fi
}

# 安装单个 skill 到仓库
install_single_skill() {
  local src_dir="$1"
  local override_name="${2:-}"

  local skill_name
  if [[ -n "$override_name" ]]; then
    skill_name="$override_name"
  else
    skill_name=$(get_skill_name "$src_dir")
  fi

  local dst="$SKILLS_DIR/$skill_name"

  mkdir -p "$SKILLS_DIR"

  if [[ -d "$dst" ]]; then
    warn "技能 '$skill_name' 已存在，将覆盖更新"
    rm -rf "$dst"
  fi

  cp -r "$src_dir" "$dst"
  # 清理可能带入的 .git 目录
  rm -rf "$dst/.git"

  ok "已安装: $skill_name → $dst"
}

# ======================== 安装逻辑 ========================

install_from_github() {
  local url="$1"
  local skill_filter="${2:-}"

  TMP_DIR=$(mktemp -d)
  local clone_dir="$TMP_DIR/repo"

  if [[ -n "$GH_SUBDIR" ]]; then
    # 子目录模式: sparse checkout
    info "从 GitHub 子目录安装: $GH_USER/$GH_REPO/$GH_SUBDIR (分支: $GH_BRANCH)"
    git clone --depth 1 --branch "$GH_BRANCH" --filter=blob:none --sparse \
      "https://github.com/$GH_USER/$GH_REPO.git" "$clone_dir" 2>/dev/null
    cd "$clone_dir"
    git sparse-checkout set "$GH_SUBDIR" 2>/dev/null
    cd - >/dev/null

    local target_dir="$clone_dir/$GH_SUBDIR"
    if [[ ! -d "$target_dir" ]]; then
      err "子目录不存在: $GH_SUBDIR"
      exit 1
    fi

    install_single_skill "$target_dir" "$skill_filter"
  else
    # 整仓库模式
    info "从 GitHub 仓库安装: $GH_USER/$GH_REPO"
    git clone --depth 1 "https://github.com/$GH_USER/$GH_REPO.git" "$clone_dir" 2>/dev/null

    local skills_found=()
    find_skills_in_dir "$clone_dir" skills_found

    if [[ ${#skills_found[@]} -eq 0 ]]; then
      err "仓库中未找到技能（需要 SKILL.md 文件）"
      exit 1
    fi

    if [[ -n "$skill_filter" ]]; then
      # 指定了技能名称，只安装匹配的
      local matched=0
      for s in "${skills_found[@]}"; do
        local sname
        sname=$(get_skill_name "$s")
        if [[ "$sname" == "$skill_filter" ]]; then
          install_single_skill "$s"
          matched=1
          break
        fi
      done
      if [[ $matched -eq 0 ]]; then
        err "未找到名为 '$skill_filter' 的技能"
        info "可用技能:"
        for s in "${skills_found[@]}"; do
          echo "  - $(get_skill_name "$s")"
        done
        exit 1
      fi
    else
      # 安装所有找到的技能
      info "发现 ${#skills_found[@]} 个技能"
      for s in "${skills_found[@]}"; do
        install_single_skill "$s"
      done
    fi
  fi
}

install_from_local() {
  local path="$1"
  local skill_filter="${2:-}"

  if [[ ! -d "$path" ]]; then
    err "本地路径不存在: $path"
    exit 1
  fi

  local skills_found=()
  find_skills_in_dir "$path" skills_found

  if [[ ${#skills_found[@]} -eq 0 ]]; then
    err "目录中未找到技能（需要 SKILL.md 文件）"
    exit 1
  fi

  if [[ -n "$skill_filter" ]]; then
    local matched=0
    for s in "${skills_found[@]}"; do
      local sname
      sname=$(get_skill_name "$s")
      if [[ "$sname" == "$skill_filter" ]]; then
        install_single_skill "$s"
        matched=1
        break
      fi
    done
    if [[ $matched -eq 0 ]]; then
      err "未找到名为 '$skill_filter' 的技能"
      exit 1
    fi
  else
    for s in "${skills_found[@]}"; do
      install_single_skill "$s"
    done
  fi
}

# ======================== 主入口 ========================

main() {
  local source=""
  local skill_name=""
  local do_deploy=false

  # 解析参数
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --deploy)
        do_deploy=true
        shift
        ;;
      -h | --help | help)
        usage
        exit 0
        ;;
      *)
        if [[ -z "$source" ]]; then
          source="$1"
        elif [[ -z "$skill_name" ]]; then
          skill_name="$1"
        fi
        shift
        ;;
    esac
  done

  if [[ -z "$source" ]]; then
    err "请提供技能来源 URL 或路径"
    echo ""
    usage
    exit 1
  fi

  echo ""
  info "===== 安装 Skill ====="
  echo ""

  if is_github_url "$source"; then
    # GitHub URL
    if parse_github_subdir_url "$source"; then
      install_from_github "$source" "$skill_name"
    elif parse_github_repo_url "$source"; then
      install_from_github "$source" "$skill_name"
    else
      err "无法解析 GitHub URL: $source"
      exit 1
    fi
  else
    # 本地路径
    install_from_local "$source" "$skill_name"
  fi

  echo ""

  # 自动部署
  if [[ "$do_deploy" == true ]]; then
    info "===== 自动部署 ====="
    echo ""
    bash "$REPO_DIR/setup.sh" deploy
  else
    info "提示: 运行 './setup.sh deploy' 将技能部署到各 AI 工具目录"
  fi
}

main "$@"
