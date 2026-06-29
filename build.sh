#!/usr/bin/env bash

# ============================================================
# PiliMiLe 构建脚本
# ============================================================

# ---- 颜色 ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 常用 iOS 模拟器 UDID（$FLUTTER_CMD devices 查看）
IOS_SIMULATOR_UDID="1A49CA42-2DFC-49A2-9BF9-0F1C93EBF10D"
# 常用 iPad 模拟器 UDID（$FLUTTER_CMD devices 查看，为空则弹出列表选择）
IPAD_SIMULATOR_UDID=""

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

# ---- 生成本地版本信息 JSON（--dart-define-from-file） ----
gen_release_json() {
    local version_name commit_count commit_hash build_time
    version_name=$(python3 -c "
import yaml
with open('pubspec.yaml') as f:
    print(yaml.safe_load(f)['version'])
" 2>/dev/null || echo "0.0.0")
    commit_count=$(git rev-list --count HEAD 2>/dev/null || echo 1)
    commit_hash=$(git rev-parse --short HEAD 2>/dev/null || echo "N/A")
    build_time=$(date +%s)

    python3 -c "
import json
json.dump({
    'pili.name': '${version_name}',
    'pili.code': ${commit_count},
    'pili.hash': '${commit_hash}',
    'pili.time': ${build_time},
}, open('pili_release.json', 'w'))
"
    info "已生成 pili_release.json (version: ${version_name}+${commit_count}, hash: ${commit_hash})"
}

# 全局 Flutter 命令 — check_prereq 中初始化
FLUTTER_CMD=""

# ---- 前置检查 ----
check_prereq() {
    title "前置检查..."

    local required version fvm_ver

    # 从 .fvmrc 读取要求的版本
    required=$(python3 -c "import json; print(json.load(open('.fvmrc'))['flutter'])" 2>/dev/null || echo "")

    # 确定用于后续所有操作的 flutter 命令（按优先级）
    # 1. 直接可用的 flutter 命令
    if command -v flutter &>/dev/null; then
        FLUTTER_CMD="flutter"
    # 2. FVM 全局命令
    elif command -v fvm &>/dev/null && fvm flutter --version &>/dev/null 2>&1; then
        FLUTTER_CMD="fvm flutter"
    # 3. FVM 版本缓存目录（常见于 macOS: $HOME/fvm/versions/）
    elif [ -n "$required" ] && [ -x "$HOME/fvm/versions/$required/bin/flutter" ]; then
        FLUTTER_CMD="$HOME/fvm/versions/$required/bin/flutter"
    # 4. FVM 公共安装路径
    elif [ -n "${FVM_HOME:-}" ] && [ -n "$required" ] && [ -x "$FVM_HOME/versions/$required/bin/flutter" ]; then
        FLUTTER_CMD="$FVM_HOME/versions/$required/bin/flutter"
    # 5. 项目本地 FVM 符号链接
    elif [ -n "$required" ] && [ -x ".fvm/flutter_sdk/bin/flutter" ]; then
        FLUTTER_CMD=".fvm/flutter_sdk/bin/flutter"
    # 6. 环境变量 FLUTTER_ROOT
    elif [ -n "${FLUTTER_ROOT:-}" ] && [ -x "$FLUTTER_ROOT/bin/flutter" ]; then
        FLUTTER_CMD="$FLUTTER_ROOT/bin/flutter"
    # 7. 常见手动安装路径
    elif [ -x "$HOME/flutter/bin/flutter" ]; then
        FLUTTER_CMD="$HOME/flutter/bin/flutter"
    else
        err "未找到 Flutter，请先安装 Flutter SDK"
        err "  方式 1: brew install fvm && fvm install $required && fvm use $required"
        err "  方式 2: 从 https://flutter.dev 下载后加入 PATH"
        err "  当前 PATH: $PATH"
        exit 1
    fi

    version=$($FLUTTER_CMD --version 2>/dev/null | head -n 1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")

    if [ -z "$version" ]; then
        err "无法获取 Flutter 版本"
        err "  命令: $FLUTTER_CMD --version"
        err "  输出: $($FLUTTER_CMD --version 2>&1 | head -n 1 || echo '(无输出)')"
        exit 1
    fi

    if [ -n "$required" ] && [ "$version" != "$required" ]; then
        warn "Flutter 版本不匹配：要求 $required，当前 $version"
        warn "建议: fvm use $required 或切换版本后重试"
        read -rp "是否继续? [y/N] " ans
        [[ "$ans" != "y" && "$ans" != "Y" ]] && exit 0
    else
        info "Flutter $version"
    fi

    # 依赖检查
    if [ ! -f "pubspec.lock" ] || [ "pubspec.yaml" -nt "pubspec.lock" ]; then
        warn "依赖可能存在变更，正在 pub get..."
        $FLUTTER_CMD pub get
    fi
}

# ---- 1. iOS 模拟器启动 ----
ios_simulator() {
    check_prereq
    title "iOS 模拟器"

    gen_release_json

    # 指定了 UDID 则直接使用
    if [ -n "$IOS_SIMULATOR_UDID" ]; then
        # 检查是否已启动
        if $FLUTTER_CMD devices 2>/dev/null | grep -q "$IOS_SIMULATOR_UDID"; then
            info "使用指定模拟器: $IOS_SIMULATOR_UDID"
        elif xcrun simctl list devices available 2>/dev/null | grep -q "$IOS_SIMULATOR_UDID"; then
            # 存在但未启动，先启动并等待就绪
            info "启动模拟器: $IOS_SIMULATOR_UDID ..."
            xcrun simctl boot "$IOS_SIMULATOR_UDID" 2>/dev/null || true
            info "等待模拟器就绪（可能需要 30 秒）..."
            xcrun simctl bootstatus "$IOS_SIMULATOR_UDID" -b >/dev/null 2>&1 || sleep 15
            open -a Simulator 2>/dev/null || true
            info "使用指定模拟器: $IOS_SIMULATOR_UDID"
        else
            err "指定模拟器不存在: $IOS_SIMULATOR_UDID"
            echo "请在 Xcode → Settings → Devices 中确认该设备"
            exit 1
        fi
        $FLUTTER_CMD run -d "$IOS_SIMULATOR_UDID" --dart-define-from-file=pili_release.json
        return
    fi

    # 未指定 UDID：从 xcrun simctl list 获取所有可用模拟器（含关机状态）
    local simulators device_id
    simulators=$(xcrun simctl list devices available 2>/dev/null \
        | grep -E '^[[:space:]]+[^(]+\([0-9A-Fa-f-]{36}\)' \
        | sed -E 's/^[[:space:]]+//; s/ \([0-9A-Fa-f-]{36}\).*//' \
        | head -20)

    if [ -z "$simulators" ]; then
        # 回退到 $FLUTTER_CMD devices（可能模拟器已启动）
        simulators=$($FLUTTER_CMD devices 2>/dev/null | grep -i 'ios.*simulator' || true)
    fi

    if [ -z "$simulators" ]; then
        err "未找到 iOS 模拟器设备"
        echo "请确认 Xcode 中已安装至少一个模拟器 Runtime（Settings → Platforms → iOS）"
        exit 1
    fi

    echo "可用 iOS 模拟器:"
    echo "$simulators" | nl -w2 -s') '

    local count selection
    count=$(echo "$simulators" | wc -l | tr -d ' ')

    if [ "$count" -eq 1 ]; then
        selection=1
    else
        read -rp "选择设备 [1-$count]: " selection
    fi

    # 提取完整行（含 UDID），从 xcrun 重新查
    local selected_name
    selected_name=$(echo "$simulators" | sed -n "${selection}p")
    device_id=$(xcrun simctl list devices available 2>/dev/null \
        | grep -F "$selected_name" \
        | grep -oE '[0-9A-Fa-f-]{36}' \
        | head -1)

    if [ -z "$device_id" ]; then
        err "无法解析设备 ID，请确认模拟器名称未变更"
        exit 1
    fi

    info "启动模拟器: $selected_name ($device_id) ..."
    # 如果未启动则 boot
    if ! xcrun simctl list devices available 2>/dev/null | grep "$device_id" | grep -q 'Booted'; then
        xcrun simctl boot "$device_id" 2>/dev/null || true
        xcrun simctl bootstatus "$device_id" -b >/dev/null 2>&1 || sleep 15
    fi
    open -a Simulator 2>/dev/null || true

    info "启动到 iOS 模拟器..."
    $FLUTTER_CMD run -d "$device_id" --dart-define-from-file=pili_release.json
}

# ---- 2. iPad 模拟器启动 ----
ipad_simulator() {
    check_prereq
    title "iPad 模拟器"

    gen_release_json

    # 指定了 UDID 则直接使用
    if [ -n "$IPAD_SIMULATOR_UDID" ]; then
        if $FLUTTER_CMD devices 2>/dev/null | grep -q "$IPAD_SIMULATOR_UDID"; then
            info "使用指定 iPad 模拟器: $IPAD_SIMULATOR_UDID"
        elif xcrun simctl list devices available 2>/dev/null | grep -q "$IPAD_SIMULATOR_UDID"; then
            info "启动 iPad 模拟器: $IPAD_SIMULATOR_UDID ..."
            xcrun simctl boot "$IPAD_SIMULATOR_UDID" 2>/dev/null || true
            info "等待模拟器就绪（可能需要 30 秒）..."
            xcrun simctl bootstatus "$IPAD_SIMULATOR_UDID" -b >/dev/null 2>&1 || sleep 15
            open -a Simulator 2>/dev/null || true
            info "使用指定 iPad 模拟器: $IPAD_SIMULATOR_UDID"
        else
            err "指定 iPad 模拟器不存在: $IPAD_SIMULATOR_UDID"
            echo "请在 Xcode → Settings → Devices 中确认该设备"
            exit 1
        fi
        $FLUTTER_CMD run -d "$IPAD_SIMULATOR_UDID" --dart-define-from-file=pili_release.json
        return
    fi

    # 未指定 UDID：列出所有可用 iPad 模拟器
    local simulators device_id
    simulators=$(xcrun simctl list devices available 2>/dev/null \
        | grep -i 'iPad' \
        | grep -oE '^[[:space:]]+[^(]+\([0-9A-Fa-f-]{36}\)' \
        | sed -E 's/^[[:space:]]+//; s/ \([0-9A-Fa-f-]{36}\).*//')

    if [ -z "$simulators" ]; then
        err "未找到 iPad 模拟器设备"
        echo "请确认 Xcode 中已安装至少一个 iPad 模拟器 Runtime（Settings → Platforms → iOS）"
        exit 1
    fi

    echo "可用 iPad 模拟器:"
    echo "$simulators" | nl -w2 -s') '

    local count selection
    count=$(echo "$simulators" | wc -l | tr -d ' ')

    if [ "$count" -eq 1 ]; then
        selection=1
    else
        read -rp "选择设备 [1-$count]: " selection
    fi

    local selected_name
    selected_name=$(echo "$simulators" | sed -n "${selection}p")
    device_id=$(xcrun simctl list devices available 2>/dev/null \
        | grep -F "$selected_name" \
        | grep -oE '[0-9A-Fa-f-]{36}' \
        | head -1)

    if [ -z "$device_id" ]; then
        err "无法解析设备 ID，请确认模拟器名称未变更"
        exit 1
    fi

    info "启动 iPad 模拟器: $selected_name ($device_id) ..."
    if ! xcrun simctl list devices available 2>/dev/null | grep "$device_id" | grep -q 'Booted'; then
        xcrun simctl boot "$device_id" 2>/dev/null || true
        xcrun simctl bootstatus "$device_id" -b >/dev/null 2>&1 || sleep 15
    fi
    open -a Simulator 2>/dev/null || true

    info "启动到 iPad 模拟器..."
    $FLUTTER_CMD run -d "$device_id" --dart-define-from-file=pili_release.json
}

# ---- 3. macOS 桌面端启动 ----
macos_run() {
    check_prereq
    gen_release_json
    title "macOS 桌面端"
    info "启动 macOS 应用..."
    $FLUTTER_CMD run -d macos --dart-define-from-file=pili_release.json
}

# ---- 4. 构建无签名 IPA ----
build_unsigned_ipa() {
    check_prereq
    title "构建无签名 IPA"

    local project_dir build_dir app_path payload_dir ipa_path app_name

    project_dir="$(pwd)"
    build_dir="$project_dir/build/ios/Release-iphoneos"
    ipa_path="$project_dir/build/PiliMiLe-unsigned.ipa"

    info "使用 Release 模式编译 iOS..."
    run_quiet $FLUTTER_CMD build ios --release --no-codesign

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

# ---- 5. 构建 macOS 应用 + 可选 DMG ----
build_macos_app() {
    check_prereq
    title "构建 macOS 应用"

    info "编译 macOS Release..."
    run_quiet $FLUTTER_CMD build macos --release

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

# ---- 6. 清理编译缓存 ----
clean() {
    title "清理编译缓存"
    info "清理 Flutter 缓存..."
    run_quiet $FLUTTER_CMD clean
    info "清理完成"
    echo "可考虑删除 Pods/Podfile.lock 后重新 pod install"
}

# ---- 7. 清理 Xcode DerivedData (可选) ----
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
    echo -e "${GREEN}  PiliMiLe 构建脚本${NC}"
    echo -e "${GREEN}══════════════════════════════════${NC}"
    echo ""
    echo "  1) iOS 模拟器启动 (iPhone)"
    echo "  2) iPad 模拟器启动"
    echo "  3) macOS 桌面端启动"
    echo "  4) 构建无签名 IPA"
    echo "  5) 构建 macOS 应用 + 可选 DMG"
    echo "  6) 清理编译缓存"
    echo "  7) 清理 Xcode DerivedData (可选)"
    echo "  0) 退出"
    echo ""
}

# ---- 入口 ----
main() {
    cd "$(cd "$(dirname "$0")" && pwd)"

    # 支持命令行参数直接跳转
    if [ "${1:-}" != "" ]; then
        case "$1" in
            1) ios_simulator; exit 0 ;;
            2) ipad_simulator; exit 0 ;;
            3) macos_run; exit 0 ;;
            4) build_unsigned_ipa; exit 0 ;;
            5) build_macos_app; exit 0 ;;
            6) clean; exit 0 ;;
            7) extra_clean; exit 0 ;;
            *) echo "无效选项: $1"; exit 1 ;;
        esac
    fi

    while true; do
        show_menu
        read -rp "请选择 [0-7]: " choice
        case "$choice" in
            1) ios_simulator ;;
            2) ipad_simulator ;;
            3) macos_run ;;
            4) build_unsigned_ipa ;;
            5) build_macos_app ;;
            6) clean ;;
            7) extra_clean ;;
            0) echo "再见"; exit 0 ;;
            *) echo "无效选项" ;;
        esac
    done
}

main "$@"
