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

    # 3. 获取当前版本号
    current_version=$(grep '^version:' pubspec.yaml | sed -E 's/^version:\s*([0-9.]+)\+.*/\1/')
    current_code=$(grep '^version:' pubspec.yaml | sed -E 's/^version:.*\+([0-9]+).*/\1/')
    info "当前版本: $current_version+$current_code"

    # 4. 输入新版本号
    echo ""
    read -rp "新版本名 (如 2.1.0): " new_version
    if [ -z "$new_version" ]; then
        err "版本名不能为空"
        exit 1
    fi

    # 自动递增构建号
    new_code=$((current_code + 1))
    info "构建号自动递增: $current_code → $new_code"
    info "新版本: $new_version+$new_code"

    # 5. 确认平台
    echo ""
    echo "选择要构建的平台 (多选用空格分隔, 如: 1 3):"
    echo "  1) macOS"
    echo "  2) Windows"
    echo "  3) 全部（macOS + Windows）"
    read -rp "请选择 [1-3]: " platform_choice

    build_mac=false
    build_win=false

    case "$platform_choice" in
        1) build_mac=true ;;
        2) build_win=true ;;
        3) build_mac=true; build_win=true ;;
        *) warn "无效选择，默认构建全部"; build_mac=true; build_win=true ;;
    esac

    # 6. 最终确认
    echo ""
    echo -e "══════════════════════════════════"
    echo "  仓库:    $REPO"
    echo "  旧版本:  $current_version+$current_code"
    echo "  新版本:  $new_version+$new_code"
    echo "  tag:     v$new_version"
    echo "  macOS:   $build_mac"
    echo "  Windows: $build_win"
    echo -e "══════════════════════════════════"
    read -rp "确认发版? [y/N] " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        info "已取消"
        exit 0
    fi

    # 7. 修改版本号
    title "更新版本号..."
    sed -i '' -E "s/^version: .*/version: $new_version+$new_code/" pubspec.yaml
    info "pubspec.yaml 已更新"

    # 8. 提交推送
    title "提交并推送..."
    git add pubspec.yaml
    git commit -m "chore: 升级版本到 $new_version" || true
    git push
    info "已推送"

    # 9. 触发 CI
    title "触发 CI 构建..."
    gh workflow run build.yml \
        --repo "$REPO" \
        -f build_android=false \
        -f build_ios=false \
        -f build_mac="$build_mac" \
        -f build_win_x64="$build_win" \
        -f build_linux_x64=false \
        -f tag="v$new_version"

    info "CI 已触发！查看进度: https://github.com/$REPO/actions"
    info "构建完成后 Release 地址: https://github.com/$REPO/releases/tag/v$new_version"
}

main "$@"
