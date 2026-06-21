#!/usr/bin/env bash

# ============================================================
# PiliPlus 构建脚本
# ============================================================

# ---- 颜色 ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 常用 iOS 模拟器 UDID（flutter devices 查看）
IOS_SIMULATOR_UDID="1A49CA42-2DFC-49A2-9BF9-0F1C93EBF10D"

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
err()   { echo -e "${RED}[✗]${NC} $1"; }
title() { echo -e "\n${GREEN}$1${NC}"; }

# 静默执行命令，仅失败时显示日志
run_quiet() {
    local log
    log=$(mktemp)
    if "$@" > "$log" 2>&1; then
        rm -f "$log"
        return 0
    else
        local rc=$?
        err "命令失败 (退出码: $rc): $*"
        echo "────────────────────────────────"
        cat "$log"
        echo "────────────────────────────────"
        rm -f "$log"
        return $rc
    fi
}

# ---- 前置检查 ----
check_prereq() {
    title "前置检查..."

    # Flutter 版本校验
    local required version
    required=$(python3 -c "import json; print(json.load(open('.fvmrc'))['flutter'])" 2>/dev/null || echo "")
    version=$(flutter --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")

    if [ -z "$version" ]; then
        err "未找到 Flutter，请先安装 Flutter SDK"
        exit 1
    fi

    if [ -n "$required" ] && [ "$version" != "$required" ]; then
        warn "Flutter 版本不匹配：要求 $required，当前 $version"
        warn "建议使用 fvm 或切换版本后重试"
        read -rp "是否继续? [y/N] " ans
        [[ "$ans" != "y" && "$ans" != "Y" ]] && exit 0
    else
        info "Flutter $version"
    fi

    # 依赖检查
    if [ ! -f "pubspec.lock" ] || [ "pubspec.yaml" -nt "pubspec.lock" ]; then
        warn "依赖可能存在变更，正在 flutter pub get..."
        flutter pub get -q
    fi
}

# ---- 1. iOS 模拟器启动 ----
ios_simulator() {
    check_prereq
    title "iOS 模拟器"

    open -a Simulator 2>/dev/null || true

    # 指定了 UDID 则直接使用
    if [ -n "$IOS_SIMULATOR_UDID" ]; then
        if flutter devices 2>/dev/null | grep -q "$IOS_SIMULATOR_UDID"; then
            info "使用指定模拟器: $IOS_SIMULATOR_UDID"
            flutter run -d "$IOS_SIMULATOR_UDID"
            return
        fi
        warn "指定 UDID ($IOS_SIMULATOR_UDID) 未找到，尝试自动检测..."
    fi

    local devices
    devices=$(flutter devices 2>/dev/null | grep -i 'ios.*simulator' || true)

    if [ -z "$devices" ]; then
        err "未找到 iOS 模拟器设备"
        echo "请确认 Xcode 中已安装至少一个模拟器 Runtime"
        exit 1
    fi

    echo "可用 iOS 模拟器:"
    echo "$devices" | nl -w2 -s') '

    local count selection device_id
    count=$(echo "$devices" | wc -l | tr -d ' ')

    if [ "$count" -eq 1 ]; then
        selection=1
    else
        read -rp "选择设备 [1-$count]: " selection
    fi

    device_id=$(echo "$devices" | sed -n "${selection}p" | grep -oE '[0-9A-Fa-f-]{36}')

    if [ -z "$device_id" ]; then
        err "无法解析设备 ID"
        exit 1
    fi

    info "启动到 iOS 模拟器..."
    flutter run -d "$device_id"
}

# ---- 2. macOS 桌面端启动 ----
macos_run() {
    check_prereq
    title "macOS 桌面端"
    info "启动 macOS 应用..."
    flutter run -d macos
}

# ---- 3. 构建无签名 IPA ----
build_unsigned_ipa() {
    check_prereq
    title "构建无签名 IPA"

    local project_dir build_dir app_path payload_dir ipa_path app_name

    project_dir="$(pwd)"
    build_dir="$project_dir/build/ios/Release-iphoneos"
    ipa_path="$project_dir/build/PiliPlus-unsigned.ipa"

    info "使用 Release 模式编译 iOS..."
    run_quiet flutter build ios --release --no-codesign

    # 产物自动在 build/ios/iphoneos/
    # 找到 .app
    app_path=$(find "$build_dir" -maxdepth 2 -name '*.app' -type d | head -1)
    if [ -z "$app_path" ]; then
        # 备选：Runner.app 路径
        app_path="$project_dir/build/ios/iphoneos/Runner.app"
    fi

    if [ ! -d "$app_path" ]; then
        # 终极备选：直接找
        app_path=$(find "$project_dir/build/ios" -name '*.app' -type d -maxdepth 4 | head -1)
    fi

    if [ ! -d "$app_path" ]; then
        err "未找到 .app 产物，请检查编译是否成功"
        exit 1
    fi

    info "打包 IPA..."
    app_name=$(basename "$app_path" .app)
    payload_dir="$project_dir/build/Payload"
    rm -rf "$payload_dir"
    mkdir -p "$payload_dir"
    cp -R "$app_path" "$payload_dir/"

    rm -f "$ipa_path"
    cd "$project_dir/build"
    zip -rq "$ipa_path" Payload
    rm -rf "$payload_dir"

    info "IPA 已生成: ${ipa_path}"
    local size
    size=$(du -sh "$ipa_path" | cut -f1)
    echo "  大小: $size"
}

# ---- 4. 构建 macOS 应用 + 可选 DMG ----
build_macos_app() {
    check_prereq
    title "构建 macOS 应用"

    info "编译 macOS Release..."
    run_quiet flutter build macos --release

    local app_path dmgs_dir
    app_path=$(find "$(pwd)/build/macos/Build/Products/Release" -name '*.app' -type d -maxdepth 1 | head -1)
    if [ ! -d "$app_path" ]; then
        err "未找到 .app 产物，请检查编译是否成功"
        exit 1
    fi

    local size
    size=$(du -sh "$app_path" | cut -f1)
    info "macOS 应用已生成: $app_path"
    echo "  大小: $size"

    # 询问是否制作 DMG
    echo ""
    read -rp "是否需要制作 DMG 安装包? [Y/n] " ans
    if [[ "$ans" == "n" || "$ans" == "N" ]]; then
        info "跳过 DMG 制作"
        return
    fi

    title "制作 DMG"

    local app_name dmg_name dmg_path dmg_temp
    app_name=$(basename "$app_path" .app)
    dmg_name="${app_name}.dmg"
    dmgs_dir="$(pwd)/build/dmgs"
    mkdir -p "$dmgs_dir"
    dmg_path="$dmgs_dir/$dmg_name"
    rm -f "$dmg_path"

    info "创建拖拽安装式 DMG..."

    # 创建工作目录
    dmg_temp="$dmgs_dir/.dmg_temp"
    rm -rf "$dmg_temp"
    mkdir -p "$dmg_temp"

    cp -R "$app_path" "$dmg_temp/"
    # 创建 Applications 快捷方式
    ln -s /Applications "$dmg_temp/Applications"

    # 创建 DMG
    hdiutil create -volname "$app_name" \
        -srcfolder "$dmg_temp" \
        -ov -format UDZO \
        "$dmg_path" > /dev/null

    # 设置窗口布局（图标位置排列）
    echo "
        tell application \"Finder\"
            tell disk \"$app_name\"
                open
                set current view of container window to icon view
                set toolbar visible of container window to false
                set statusbar visible of container window to false
                set the bounds of container window to {400, 200, 900, 500}
                set theViewOptions to the icon view options of container window
                set arrangement of theViewOptions to not arranged
                set icon size of theViewOptions to 96
                set position of item \"$app_name.app\" of container window to {140, 140}
                set position of item \"Applications\" of container window to {360, 140}
                update without registering applications
                delay 1
                close
            end tell
        end tell
    " | osascript - > /dev/null 2>&1 || true

    # 重新挂载以便应用布局
    hdiutil detach "/Volumes/$app_name" > /dev/null 2>&1 || true
    hdiutil convert "$dmg_path" -format UDZO -o "${dmg_path}.tmp" > /dev/null 2>&1 && \
        mv "${dmg_path}.tmp" "$dmg_path"

    # 重新应用布局到最终 DMG
    local mount_point
    mount_point=$(hdiutil attach "$dmg_path" -nobrowse -readwrite 2>&1 | grep '/Volumes/' | awk '{print $NF}')
    if [ -n "$mount_point" ]; then
        echo "
            tell application \"Finder\"
                tell disk \"$app_name\"
                    open
                    set current view of container window to icon view
                    set toolbar visible of container window to false
                    set statusbar visible of container window to false
                    set the bounds of container window to {400, 200, 900, 500}
                    set theViewOptions to the icon view options of container window
                    set arrangement of theViewOptions to not arranged
                    set icon size of theViewOptions to 96
                    set position of item \"$app_name.app\" of container window to {140, 140}
                    set position of item \"Applications\" of container window to {360, 140}
                    update without registering applications
                    delay 1
                    close
                end tell
            end tell
        " | osascript - > /dev/null 2>&1 || true
        hdiutil detach "$mount_point" > /dev/null 2>&1
    fi

    rm -rf "$dmg_temp"

    local dmg_size
    dmg_size=$(du -sh "$dmg_path" | cut -f1)
    info "DMG 已生成: $dmg_path"
    echo "  大小: $dmg_size"
}

# ---- 5. 清理编译缓存 ----
clean() {
    title "清理编译缓存"
    info "清理 Flutter 缓存..."
    run_quiet flutter clean
    info "清理完成"
    echo "可考虑删除 Pods/Podfile.lock 后重新 pod install"
}

# ---- 6. 清理 Xcode DerivedData (可选) ----
extra_clean() {
    title "清理 Xcode DerivedData"
    info "清理中..."
    rm -rf ~/Library/Developer/Xcode/DerivedData
    info "DerivedData 清理完成"
}

# ---- 菜单 ----
show_menu() {
    echo ""
    echo -e "${GREEN}══════════════════════════════════${NC}"
    echo -e "${GREEN}  PiliPlus 构建脚本${NC}"
    echo -e "${GREEN}══════════════════════════════════${NC}"
    echo ""
    echo "  1) iOS 模拟器启动"
    echo "  2) macOS 桌面端启动"
    echo "  3) 构建无签名 IPA"
    echo "  4) 构建 macOS 应用 + 可选 DMG"
    echo "  5) 清理编译缓存"
    echo "  6) 清理 Xcode DerivedData (可选)"
    echo "  0) 退出"
    echo ""
}

# ---- 入口 ----
main() {
    cd "$(dirname "$0")"

    # 支持命令行参数直接跳转
    if [ "${1:-}" != "" ]; then
        case "$1" in
            1) ios_simulator; exit 0 ;;
            2) macos_run; exit 0 ;;
            3) build_unsigned_ipa; exit 0 ;;
            4) build_macos_app; exit 0 ;;
            5) clean; exit 0 ;;
            6) extra_clean; exit 0 ;;
            *) echo "无效选项: $1"; exit 1 ;;
        esac
    fi

    while true; do
        show_menu
        read -rp "请选择 [0-6]: " choice
        case "$choice" in
            1) ios_simulator ;;
            2) macos_run ;;
            3) build_unsigned_ipa ;;
            4) build_macos_app ;;
            5) clean ;;
            6) extra_clean ;;
            0) echo "再见"; exit 0 ;;
            *) echo "无效选项" ;;
        esac
    done
}

main "$@"
