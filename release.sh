#!/usr/bin/env bash

# ============================================================
# PiliMiLe 一键发版脚本
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
err()   { echo -e "${RED}[✗]${NC} $1"; }
title() { echo -e "\n${GREEN}$1${NC}"; }

REPO="Heartworm97/PiliMiLe"

# AI 分析代码变更生成 CHANGELOG 条目，插入文件顶部保留历史
generate_changelog() {
    local last_tag new_tag today
    new_tag="v$1"
    today=$(date +%Y-%m-%d)

    last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    local new_section=""

    if [ -n "$last_tag" ]; then
        info "上次发布: $last_tag → 本次: $new_tag"

        # 收集代码变更上下文（提交记录 + 文件变更统计）
        local diff_stat diff_log
        diff_stat=$(git diff "$last_tag..HEAD" --stat -- '*.dart' 2>/dev/null | head -80)
        diff_log=$(git log "$last_tag..HEAD" --no-merges --pretty=format:"[%h] %s" 2>/dev/null)

        if [ -n "$diff_log" ] && command -v claude &> /dev/null; then
            info "AI 正在分析代码变更..."
            local prompt="根据以下 git 提交记录和文件变更统计，分析实际代码改动，生成一份简洁的中文 CHANGELOG 条目。
请严格按以下格式输出，不要加任何额外说明：

## [$1] - $today

### Added
- (确实没有新增功能则写「(无)」)

### Changed
- (确实没有行为变更/优化则写「(无)」)

### Fixed
- (确实没有修复则写「(无)」)

分类规则：
- Added: 新功能、新特性、新接口
- Changed: 现有行为变更、优化、重构、UI调整
- Fixed: Bug 修复、崩溃修复
- chore: 前缀的提交通常是杂务，只有涉及到具体功能变更时才纳入
- 每条用简短的中文描述（不超过一行），根据文件变更内容推断实际改动，不要照搬 commit message
- 排除以下提交：chore: 发布、chore: 发版前自动提交、chore: 会话自动提交、chore: 重置
- 只输出格式内容，不要多写任何话

文件变更统计：
$diff_stat

提交记录：
$diff_log"

            new_section=$(claude -p "$prompt" --output-format text 2>/dev/null) || true

            # 校验：AI 输出为空或没有实际条目则生成待填写模板
            local meaningful_lines
            meaningful_lines=$(echo "$new_section" | grep -cE '^- [^(无]' 2>/dev/null || echo 0)
            if [ -z "$new_section" ] || [ "$meaningful_lines" -eq 0 ]; then
                warn "AI 生成内容为空，生成待填写模板"
                new_section="## [$1] - $today

### Added
- (待填写)

### Changed
- (待填写)

### Fixed
- (待填写)"
            fi
        else
            warn "AI 不可用，生成待填写模板"
            new_section="## [$1] - $today

### Added
- (待填写)

### Changed
- (待填写)

### Fixed
- (待填写)"
        fi
    else
        warn "未找到历史 tag，生成首次发布"
        new_section="## [$1] - $today

### Added
- 初始版本 $new_tag"
    fi

    # 插入到文件顶部，保留已有历史内容
    if [ -f CHANGELOG.md ] && [ -s CHANGELOG.md ]; then
        printf '%s\n\n%s\n' "$new_section" "$(cat CHANGELOG.md)" > CHANGELOG.md
    else
        printf '%s\n\n' "$new_section" > CHANGELOG.md
    fi

    info "CHANGELOG.md 已更新（新版本已插入顶部，历史版本保留）"
}

# ---- 入口 ----
main() {
    cd "$(dirname "$0")"

    title "PiliMiLe 一键发版"

    # 1. 检查 gh CLI 是否可用
    if ! command -v gh &> /dev/null; then
        err "未找到 GitHub CLI (gh)，请先安装: brew install gh"
        exit 1
    fi

    if ! gh auth status &> /dev/null; then
        err "gh 未登录，请先执行: gh auth login"
        exit 1
    fi

    # 2. 检查是否有未提交的改动，自动提交
    if ! git diff --quiet || ! git diff --cached --quiet; then
        warn "检测到未提交的改动，自动提交..."
        git add -A
        local dirs
        dirs=$(git diff --cached --stat -- 'lib/**' 2>/dev/null | grep -oE '\S+/' | tr -d '/' | sort -u | head -5 | paste -sd, - | sed 's/,/, /g')
        git commit -m "chore: 发版前提交 (${dirs:-杂项})"
        git push
        info "已自动提交并推送"
    fi

    # 3. 确保本地代码最新
    title "拉取最新代码..."
    git pull --ff-only 2>/dev/null || true

    # 4. 获取当前版本号（仅匹配严格格式 version: X.Y.Z+N，防止损坏文件导致恶性循环）
    local version_line
    version_line=$(grep -E '^version: [0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$' pubspec.yaml)
    if [ -z "$version_line" ]; then
        err "pubspec.yaml 版本行格式异常，请检查: $(head -n1 <<< "$(grep '^version:' pubspec.yaml)")"
        exit 1
    fi
    current_version=$(echo "$version_line" | sed -E 's/^version: ([0-9.]+)\+.*/\1/')
    current_code=$(echo "$version_line" | sed -E 's/^version:.*\+([0-9]+)/\1/')
    info "当前版本: $current_version+$current_code"

    # 5. 根据代码变更量自动判断版本递增级别
    IFS='.' read -r major minor patch <<< "$current_version"

    # 找到上一个 tag，统计变更
    last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    if [ -n "$last_tag" ]; then
        feat_count=$(git log "$last_tag..HEAD" --no-merges --oneline 2>/dev/null | grep -iEc "feat|新增|添加" || echo 0)
        fix_count=$(git log "$last_tag..HEAD" --no-merges --oneline 2>/dev/null | grep -iEc "fix|bug|修复|修正" || echo 0)
        total_count=$(git log "$last_tag..HEAD" --no-merges --oneline 2>/dev/null | wc -l | tr -d ' ')
        breaking_count=$(git log "$last_tag..HEAD" --no-merges --oneline 2>/dev/null | grep -iEc "BREAKING|break|不兼容|重构.*架构" || echo 0)

        # 自动判断
        if [ "$breaking_count" -gt 0 ]; then
            auto_level="major"
            suggested_version="$((major + 1)).0.0"
            reason="检测到 BREAKING CHANGE / 架构重构，建议 major"
        elif [ "$feat_count" -gt 0 ]; then
            auto_level="minor"
            suggested_version="$major.$((minor + 1)).0"
            reason="检测到 $feat_count 个新功能，建议 minor"
        else
            auto_level="patch"
            suggested_version="$major.$minor.$((patch + 1))"
            reason="共 $total_count 个提交，均为修复/优化，建议 patch"
        fi

        info "代码分析: $reason"
        info "提交: 总计$total_count / 新功能$feat_count / 修复$fix_count / 破坏性$breaking_count"
    else
        auto_level="patch"
        suggested_version="$major.$minor.$((patch + 1))"
        reason="首次发版"
    fi

    echo ""
    read -rp "新版本名 (回车使用建议 $suggested_version, 或输入 m=M/major p=patch): " new_version

    # 解析快捷输入
    case "$(echo "$new_version" | tr '[:upper:]' '[:lower:]')" in
        m|major)
            suggested_version="$((major + 1)).0.0"
            new_version="$suggested_version"
            ;;
        p|patch)
            suggested_version="$major.$minor.$((patch + 1))"
            new_version="$suggested_version"
            ;;
    esac
    new_version="${new_version:-$suggested_version}"

    # 自动递增构建号
    new_code=$((current_code + 1))
    info "构建号自动递增: $current_code → $new_code"
    info "新版本: $new_version+$new_code"

    # 6. 生成更新内容
    title "生成更新内容..."
    generate_changelog "$new_version"

    # 显示并让用户确认
    echo ""
    echo -e "${GREEN}──────── 更新内容预览 ────────${NC}"
    awk '/^## \[/ { if (h++) exit } { print }' CHANGELOG.md
    echo -e "${GREEN}────────────────────────────────${NC}"
    echo ""
    read -rp "是否编辑更新内容? (将用编辑器打开，不需要编辑则按 n) [y/N] " edit_ans
    if [[ "$edit_ans" == "y" || "$edit_ans" == "Y" ]]; then
        ${EDITOR:-code} --wait CHANGELOG.md
    fi

    # 7. 确认平台
    echo ""
    echo "选择要构建的平台 (输入数字，多选用空格分隔，如: 1 3):"
    echo "  1) macOS"
    echo "  2) Windows"
    echo "  3) Android (无签名)"
    echo "  4) iOS (无签名)"
    echo "  5) 全部"
    read -rp "请选择: " platform_choice

    build_mac=false
    build_win=false
    build_android=false
    build_ios=false

    for choice in $platform_choice; do
        case "$choice" in
            1) build_mac=true ;;
            2) build_win=true ;;
            3) build_android=true ;;
            4) build_ios=true ;;
            5) build_mac=true; build_win=true; build_android=true; build_ios=true; break ;;
            *) warn "无效选择: $choice" ;;
        esac
    done

    # 都没选则默认全部
    if ! $build_mac && ! $build_win && ! $build_android && ! $build_ios; then
        warn "未有效选择，默认构建全部"
        build_mac=true; build_win=true; build_android=true; build_ios=true
    fi

    # 8. 最终确认
    echo ""
    echo -e "══════════════════════════════════"
    echo "  仓库:      $REPO"
    echo "  旧版本:    $current_version+$current_code"
    echo "  新版本:    $new_version+$new_code"
    echo "  tag:       v$new_version"
    echo "  macOS:     $build_mac"
    echo "  Windows:   $build_win"
    echo "  Android:   $build_android"
    echo "  iOS:       $build_ios"
    echo -e "══════════════════════════════════"
    read -rp "确认发版? [y/N] " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        info "已取消"
        exit 0
    fi

    # 9. 修改版本号
    title "更新版本号..."
    sed -i '' -E "s/^version: .*/version: $new_version+$new_code/" pubspec.yaml
    info "pubspec.yaml 已更新"

    # 10. 提交推送
    title "提交并推送..."
    git add pubspec.yaml CHANGELOG.md
    git commit -m "chore: 发布 $new_version" || true
    if ! git push; then
        err "推送失败，请检查网络或权限后重试"
        exit 1
    fi
    info "已推送"

    # 11. 触发 CI
    title "触发 CI 构建..."
    gh workflow run build.yml \
        --repo "$REPO" \
        -f build_android="$build_android" \
        -f build_ios="$build_ios" \
        -f build_mac="$build_mac" \
        -f build_win_x64="$build_win" \
        -f tag="v$new_version"

    info "CI 已触发！查看进度: https://github.com/$REPO/actions"
    info "构建完成后 Release 地址: https://github.com/$REPO/releases/tag/v$new_version"
}

main "$@"
