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

# 从 Git 提交记录自动生成更新内容
generate_changelog() {
    local last_tag new_tag
    new_tag="v$1"

    # 找到上一个 tag
    last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

    echo "# $new_tag" > CHANGELOG.md
    echo "" >> CHANGELOG.md

    if [ -n "$last_tag" ]; then
        info "上次发布: $last_tag → 本次: $new_tag"
        echo "## 变更记录" >> CHANGELOG.md
        echo "" >> CHANGELOG.md

        # 按类型分类汇总
        {
            echo "### 新增功能"
            git log "$last_tag..HEAD" --no-merges --pretty=format:"- %s" 2>/dev/null | grep -iE "feat|add|new|新增|添加" || echo "- (无)"
            echo ""
            echo "### 修复"
            git log "$last_tag..HEAD" --no-merges --pretty=format:"- %s" 2>/dev/null | grep -iE "fix|bug|修复|修正" || echo "- (无)"
            echo ""
            echo "### 优化"
            git log "$last_tag..HEAD" --no-merges --pretty=format:"- %s" 2>/dev/null | grep -iE "refactor|perf|optimize|优化|重构|改进|chore" || echo "- (无)"
            echo ""
            echo "### 其他"
            git log "$last_tag..HEAD" --no-merges --pretty=format:"- %s" 2>/dev/null | grep -ivE "feat|add|new|fix|bug|refactor|perf|optimize|chore|Merge|合并|新增|添加|修复|修正|优化|重构|改进" || echo "- (无)"
        } >> CHANGELOG.md

        echo "" >> CHANGELOG.md
        echo "## 全部提交" >> CHANGELOG.md
        echo "" >> CHANGELOG.md
        git log "$last_tag..HEAD" --no-merges --pretty=format:"- \`%h\` %s (%an)" >> CHANGELOG.md
    else
        warn "未找到历史 tag，生成首次发布的更新内容"
        echo "## 首次发布" >> CHANGELOG.md
        echo "" >> CHANGELOG.md
        echo "初始版本 $new_tag" >> CHANGELOG.md
    fi

    echo "" >> CHANGELOG.md
    info "更新内容已生成: CHANGELOG.md"
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

    # 2. 检查是否有未提交的改动
    if ! git diff --quiet || ! git diff --cached --quiet; then
        warn "检测到未提交的改动"
        read -rp "是否先提交这些改动? [y/N] " ans
        if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
            read -rp "输入提交信息: " commit_msg
            git add -A
            git commit -m "$commit_msg"
            git push
            info "已提交并推送"
        fi
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
    cat CHANGELOG.md
    echo -e "${GREEN}────────────────────────────────${NC}"
    echo ""
    read -rp "是否编辑更新内容? (将用 vim 打开，不需要编辑则按 n) [y/N] " edit_ans
    if [[ "$edit_ans" == "y" || "$edit_ans" == "Y" ]]; then
        ${EDITOR:-vim} CHANGELOG.md
    fi

    # 7. 确认平台
    echo ""
    echo "选择要构建的平台 (输入数字，多选用空格分隔，如: 1 3):"
    echo "  1) macOS"
    echo "  2) Windows"
    echo "  3) Linux"
    echo "  4) Android (无签名)"
    echo "  5) iOS (无签名)"
    echo "  6) 全部"
    read -rp "请选择: " platform_choice

    build_mac=false
    build_win=false
    build_linux=false
    build_android=false
    build_ios=false

    for choice in $platform_choice; do
        case "$choice" in
            1) build_mac=true ;;
            2) build_win=true ;;
            3) build_linux=true ;;
            4) build_android=true ;;
            5) build_ios=true ;;
            6) build_mac=true; build_win=true; build_linux=true; build_android=true; build_ios=true; break ;;
            *) warn "无效选择: $choice" ;;
        esac
    done

    # 都没选则默认全部
    if ! $build_mac && ! $build_win && ! $build_linux && ! $build_android && ! $build_ios; then
        warn "未有效选择，默认构建全部"
        build_mac=true; build_win=true; build_linux=true; build_android=true; build_ios=true
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
    echo "  Linux:     $build_linux"
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

    # 10. 提交推送（包含 CHANGELOG.md）
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
        -f build_linux_x64="$build_linux" \
        -f tag="v$new_version"

    info "CI 已触发！查看进度: https://github.com/$REPO/actions"
    info "构建完成后 Release 地址: https://github.com/$REPO/releases/tag/v$new_version"
}

main "$@"
