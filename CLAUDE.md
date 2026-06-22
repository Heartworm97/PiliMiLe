# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 语言强制规则
1. 全程使用简体中文进行所有回复、代码注释、文档、解释内容，禁止任何英文自然描述。
2. 仅代码关键字、变量名、包名、命令行工具名称保留英文，其余说明、分析、方案、报错解释全部中文。
3. 不要夹杂英文短句、英文解释，专业术语可保留单词但配套中文翻译说明。
4. 提问、复盘、代码讲解、优化建议全部输出中文。
5. 收到我的问题后，**优先先用一句话复述、主动告知我你对本次需求的理解**；
   - 复述无误，再展开正式解答、执行操作；
   - 若理解有偏差、信息不足，直接向我确认疑问点，不擅自作答。

## 项目概述

**PiliMiLe** — 使用 Flutter 开发的 BiliBili 第三方客户端，支持 Android / iOS / iPad / Windows / macOS / Linux 全平台。

核心功能：视频/直播播放、弹幕、番剧追番、动态社区、私信聊天、离线下载、DLNA 投屏、多账号管理等完整 B 站客户端体验。

上游：[orz12/PiliPalaX](https://github.com/orz12/PiliPalaX) | 上游上游：[guozhigq/pilipala](https://github.com/guozhigq/pilipala)

## 技术栈

| 类别 | 技术 | 版本 |
|------|------|------|
| 语言 | Dart | SDK >= 3.12.0 |
| 框架 | Flutter | 3.44.2 (FVM 管理) |
| 状态管理 / 路由 | GetX | 4.7.2 (自定义 fork) |
| HTTP 客户端 | Dio | 5.9.1 + Http2Adapter |
| 本地存储 | Hive CE | 2.19.3 |
| 视频播放 | media-kit + MPV | 1.1.11 (自定义 fork) |
| 弹幕渲染 | canvas_danmaku | git (自定义 fork) |
| gRPC / Protobuf | protobuf | 6.0.0 |
| 动态主题 | dynamic_color + flex_seed_scheme | 1.8.1 / 4.0.1 |
| 桌面 WebView | flutter_inappwebview | 6.1.5 (自定义 fork) |
| 桌面窗口 | window_manager | git (自定义 fork) |
| 代码生成 | build_runner + json_annotation | 2.10.3 / 4.11.0 |
| 异常捕获 | catcher_2 | git |
| 图标/启动屏 | flutter_launcher_icons / flutter_native_splash | 0.14.4 / 2.4.6 |

> 大量依赖使用自定义 Git fork，修改 pubspec.yaml 依赖版本时务必使用团队 fork 而非上游 pub.dev。

## 目录结构

```
├── lib/
│   ├── main.dart              # 应用入口，初始化 GStorage / 路径 / 网络 / Player
│   ├── build_config.dart      # 编译时注入的版本号/commit-hash（--dart-define）
│   ├── common/                # 共享层
│   │   ├── constants.dart     # App 常量、API Key、headers
│   │   ├── style.dart         # 全局样式
│   │   ├── assets.dart        # 资源路径引用
│   │   ├── skeleton/          # 骨架屏组件
│   │   └── widgets/           # 通用 Widget；其中 flutter/ 是 Flutter 框架 Widget 的本地覆盖
│   ├── pages/                 # 页面（按功能模块分目录）
│   │   ├── video/             # 视频详情页（含 intro/reply/note/related 子组件）
│   │   ├── home/              # 首页推荐
│   │   ├── live_room/         # 直播间
│   │   ├── dynamics/          # 动态列表
│   │   ├── dynamics_detail/   # 动态详情
│   │   ├── member/            # 用户主页
│   │   ├── search/            # 搜索
│   │   ├── setting/           # 设置
│   │   ├── whisper/           # 私信
│   │   ├── login/             # 登录
│   │   └── ...                # 100+ 页面模块
│   ├── models/                # REST API 数据模型（旧）
│   ├── models_new/            # gRPC API 数据模型（新）
│   ├── http/                  # HTTP 网络层（Dio）
│   │   ├── init.dart          # Request 单例，Dio 初始化 + 拦截器
│   │   ├── api.dart           # API 路径常量
│   │   ├── constants.dart     # baseUrl 常量
│   │   ├── loading_state.dart # Loading / Success / Error 密封类
│   │   ├── retry_interceptor.dart
│   │   └── *.dart             # 按业务模块拆分的请求（video/user/fav/search...）
│   ├── grpc/                  # gRPC 通信层
│   │   ├── grpc_req.dart      # gRPC 请求基础封装
│   │   ├── dm.dart            # 弹幕 gRPC
│   │   ├── view.dart          # 视频视图 gRPC
│   │   ├── im.dart            # IM 私信 gRPC
│   │   ├── dyn.dart           # 动态 gRPC
│   │   ├── reply.dart         # 评论 gRPC
│   │   └── bilibili/          # protobuf 自动生成代码（禁止手动修改）
│   ├── services/              # 后台服务
│   │   ├── account_service.dart
│   │   ├── download/          # 离线下载管理
│   │   ├── service_locator.dart     # 移动端音频服务注册
│   │   ├── audio_handler.dart
│   │   └── shutdown_timer_service.dart
│   ├── plugin/                # 自定义插件
│   │   └── pl_player/         # 视频播放器（基于 media-kit）
│   │       ├── controller.dart
│   │       ├── models/        # 播放相关数据模型
│   │       ├── view/          # 播放器 UI
│   │       └── widgets/
│   ├── router/
│   │   └── app_pages.dart     # GetX 路由表
│   ├── utils/                 # 工具函数
│   │   ├── storage.dart       # Hive Box 初始化
│   │   ├── storage_pref.dart  # 偏好设置读取（Pref 类）
│   │   ├── storage_key.dart   # SettingBoxKey 常量
│   │   ├── accounts/          # 多账号管理
│   │   ├── extension/         # Dart 扩展方法
│   │   └── ...
│   └── scripts/               # CI 构建脚本 + Flutter 框架补丁
├── assets/                    # 图片、字体、shader 资源
├── android/                   # Android 原生
├── ios/                       # iOS 原生
├── macos/                     # macOS 原生
├── windows/                   # Windows 原生
├── linux/                     # Linux 原生
├── .fvmrc                     # Flutter 版本锁定 (3.44.2)
├── pubspec.yaml               # 依赖声明
├── build.sh                   # 多目标构建脚本（iOS/macOS/IPA/DMG/清理）
├── analysis_options.yaml      # Dart 静态分析配置
├── tool/                      # 辅助工具（jnigen 等）
└── .github/workflows/         # CI/CD（Android/iOS/macOS/Win/Linux）
```

## 开发命令

> **注意**：项目通过 FVM 锁定 Flutter 3.44.2（`.fvmrc`）。以下命令直接写 `flutter`，如果你的环境未配置 FVM 全局激活，请替换为 `fvm flutter`。

```bash
# 安装依赖（首次/修改 pubspec.yaml 后）
flutter pub get

# 代码生成（修改带 @HiveType / @JsonSerializable 注解的 Model 后）
flutter pub run build_runner build --delete-conflicting-outputs

# 更新原生启动屏资源
flutter pub run flutter_native_splash:create

# 更新 App 图标
flutter pub run flutter_launcher_icons

# 静态分析
flutter analyze

# 在连接设备上运行
flutter run

# 指定设备运行
flutter run -d <device_id>

# 构建命令
flutter build apk --release --split-per-abi
flutter build ios --release --no-codesign
flutter build macos --release
flutter build windows --release
flutter build linux --release

# 清理编译缓存
flutter clean

# 运行测试（项目暂无单元测试/Wiget测试）
# flutter test
```

> 项目目前没有 `test/` 目录和测试文件，功能验证依赖实际运行和手动测试。

### 构建脚本 (build.sh)

```bash
bash build.sh 1    # iOS 模拟器启动
bash build.sh 2    # macOS 桌面端启动
bash build.sh 3    # 构建无签名 IPA
bash build.sh 4    # 构建 macOS 应用 + 可选 DMG
bash build.sh 5    # 清理编译缓存（flutter clean）
bash build.sh 6    # 清理 Xcode DerivedData（可选）
```

### 发版脚本 (release.sh)

```bash
bash release.sh    # 一键发版：自动递增版本号 → 生成 CHANGELOG → 触发全平台 CI
```

`release.sh` 根据代码变更量自动判断版本递增级别（patch/minor/major），从 Git 提交记录生成 CHANGELOG，创建 tag 并推送到 GitHub 触发 CI 构建。使用前需安装 `gh` 和 `python3` + `pyyaml`。

### Flutter 框架补丁系统

`lib/scripts/` 目录下包含 `.patch` 文件，用于在 CI 中修补 Flutter 框架的已知 bug（底部弹出框行为、滚动视图、文本选择、导航抽屉等）。各平台的修补逻辑见 `patch.ps1`。

- **禁止随意删除或重命名 `.patch` 文件**，否则对应平台的构建可能失败或出现 UI 异常
- 修改 `.patch` 文件需在 PR 描述中说明原因和关联 issue
- 本地开发不影响（补丁仅在 CI 中应用），除非在本地手动执行 `lib/scripts/patch.ps1`

### CI/CD 构建时的 dart-define

```bash
flutter build apk --release \
  --dart-define-from-file=pili_release.json \
  --dart-define=pili.code=<versionCode> \
  --dart-define=pili.name=<versionName> \
  --dart-define=pili.time=<timestamp> \
  --dart-define=pili.hash=<commitHash>
```

`pili_release.json` 不在版本控制中（已 gitignored）。

## 代码规范

### 命名规范

- **变量/方法/参数**: `lowerCamelCase`
- **类/枚举/混入/扩展**: `UpperCamelCase`
- **文件/目录**: `snake_case`（禁止大写字母）
- **常量**: `lowerCamelCase`（非 SCREAMING_CASE）
- **包导入别名**: `lowercase_with_underscores`（如 `as path`）

### 导入规范（强制）

项目 lint 规则强制要求（`analysis_options.yaml`）：

```dart
// ✅ 正确：使用 package 导入
import 'package:PiliMiLe/utils/storage.dart';
import 'package:PiliMiLe/pages/video/controller.dart';

// ❌ 禁止：相对路径导入
import '../utils/storage.dart';
import 'controller.dart';
```

导入包名始终为 `PiliMiLe`（注意大小写），对应 `pubspec.yaml` 中的 name。

### 格式化

- **尾随逗号**: `trailing_commas: preserve`（保持开发者在源文件中写的逗号）
- **保存时自动格式化**: 已配置 `.vscode/settings.json`
- **保存时自动整理导入**: `source.organizeImports: explicit`

### Lint 规则

继承 `package:flutter_lints/flutter.yaml`，额外启用：
- `always_declare_return_types` — 必须声明返回类型
- `always_use_package_imports` — 必须使用 package 导入
- `avoid_relative_lib_imports` — 禁止相对路径导入
- `avoid_print` — 禁止 print/debugPrint，必须使用 `logger`，详见[常见踩坑 > Logger 使用](#logger-使用)
- `prefer_const_constructors` — 优先 const 构造
- `cascade_invocations` — 优先级联调用
- `avoid_void_async` — 禁止 void 异步函数
- 其它规则见 `analysis_options.yaml`

### 代码生成

以下文件由 `build_runner` 生成，**禁止手动修改**：
- `*.g.dart` — json_serializable 生成的序列化代码
- `lib/grpc/bilibili/**/*.pb.dart` / `*.pbenum.dart` / `*.pbjson.dart` — protobuf 生成代码
- `*.freezed.dart` — (如有)

## 架构约束

### 分层规则

```
pages/          →  UI 层，只依赖 controller.dart / models / common/widgets
  controller.dart → 页面逻辑，依赖 http/ 或 grpc/ 获取数据
models/         →  纯数据结构，不依赖任何业务层
models_new/     →  同 models，但对应新版 gRPC 接口返回结构
http/           →  HTTP 请求封装，依赖 dio、models、utils/storage
grpc/           →  gRPC 请求封装，依赖 protobuf 生成代码、utils/storage
services/       →  后台服务，依赖 utils、http
utils/          →  工具层，仅依赖 models、第三方库
common/         →  共享 UI 组件，依赖 models、utils
plugin/         →  独立功能插件，高内聚低耦合
router/         →  路由定义，仅依赖 pages
```

### 页面模块标准结构

每个页面模块遵循 GetX 模式：

```
pages/<feature>/
├── view.dart              # 入口 Widget (const 构造)
├── controller.dart        # GetxController 业务逻辑
└── widgets/               # 页面专用子组件
    ├── <widget_a>.dart
    └── <widget_b>.dart
```

复杂页面（如 video）可包含子功能目录，每个子功能也有独立的 `controller.dart` + `view.dart`。

### 状态管理模式

- **全局服务**: 通过 `Get.lazyPut()` 注册，`Get.find()` 获取（AccountService、DownloadService）
- **偏好设置**: 通过 `Pref` 静态 getter（`lib/utils/storage_pref.dart`）访问 Hive Box
- **本地存储**: `GStorage` 类（`lib/utils/storage.dart`）封装 Hive Box
- **网络状态**: `LoadingState<T>` sealed class — `Loading` / `Success<T>` / `Error`

### 平台适配

```dart
// 使用 PlatformUtils 判断平台大类
PlatformUtils.isMobile     // Android || iOS
PlatformUtils.isDesktop    // Windows || macOS || Linux

// 具体平台判断直接使用 dart:io 的 Platform
Platform.isAndroid
Platform.isIOS
Platform.isWindows
Platform.isMacOS
Platform.isLinux
```

## 禁止修改的目录/文件

| 路径 | 原因 |
|------|------|
| `lib/grpc/bilibili/` | Protobuf 自动生成 |
| `*.g.dart` | build_runner 自动生成（json_annotation） |
| `.fvm/` | FVM 版本缓存 |
| `android/key.properties` / `*.jks` | 签名密钥（已 gitignore） |
| `pili_release.json` | CI 构建参数（已 gitignore） |
| `pubspec.lock` | 依赖锁定（仅通过 flutter pub get 更新） |
| `.dart_tool/` | Dart 工具缓存 |
| `build/` | 构建产物 |
| `ios/Pods/` | CocoaPods 依赖 |
| `.github/` | CI 配置（跟团队商量后修改） |

## 常见踩坑

### Flutter 版本

项目锁定 Flutter 3.44.2（`.fvmrc`），使用 FVM 管理。运行 `fvm use 3.44.2` 或确保 `flutter --version` 输出 3.44.2。版本不匹配可能导致编译失败或运行时异常。

### 依赖 forks

大量核心依赖使用自定义 Git fork（GetX、media-kit、audio_service、window_manager 等），执行 `flutter pub get` 前确保能访问对应 GitHub 仓库。不要用 pub.dev 上的官方版本替换。

### 代码生成后编译

修改任何带 `@HiveType` 注解的 model 后，必须运行：
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
否则会在运行时报 `HiveError: Cannot write, unknown type` 等错误。

### Hive Box 名称

GStorage 中注册的 Box 名称（`userInfo`、`setting`、`localCache`、`watchProgress` 等）不可随意修改，否则已安装用户的本地数据无法读取。新增 Box 要在 `lib/utils/storage.dart` 的 `GStorage.init()` 中添加，并在 `lib/utils/accounts.dart` 的 `close()` 中关闭。

### SettingsKey / Pref 一致性

添加新的设置项时，三个文件需同步修改：
1. `lib/utils/storage_key.dart` — Key 常量定义
2. `lib/utils/storage_pref.dart` — Pref getter + 默认值
3. 对应设置页面的开关/选择器逻辑

### HTTP/2 适配层

项目使用 Http2Adapter，存在 HTTP/2 → HTTP/1.1 回退机制（`_cloneHttp11Dio()`），网络相关修改需同时在两个适配器上验证。iOS 平台监听 `Connectivity().onConnectivityChanged` 做网络切换重连。

### gRPC protobuf

`lib/grpc/bilibili/` 下文件从 `.proto` 生成。需修改 gRPC 协议时，找上游 proto 文件用 `protoc` 重新生成，不要直接编辑 `.pb.dart`。

### Android 权限

Android 端涉及存储权限（下载）、悬浮窗权限（画中画）、音频焦点等，修改相关功能时注意权限声明在 `android/app/src/main/AndroidManifest.xml`。

### 主题系统

主题系统由三部分构成：

1. **品牌色种子**：`lib/models/common/theme/theme_color_type.dart` 定义了 19 种可选颜色，用户选择后通过 `flex_seed_scheme` 生成完整的 `ColorScheme`
2. **Dynamic Color**：支持 Android 12+ Material You 取色，通过 `dynamic_color` 插件获取系统壁纸颜色覆盖品牌色
3. **ThemeUtils**（`lib/utils/theme_utils.dart`）：统一管理亮/暗主题生成，`ThemeUtils.isDarkMode` 判断当前模式，`ThemeUtils.theme` 获取当前主题

修改主题相关代码时，需同时验证：用户自选颜色模式 + Dynamic Color 模式 + 亮/暗切换。

### Logger 使用

`lib/services/logger.dart` 导出全局 `logger` 实例（`package:logger/logger.dart`）。lint 规则 `avoid_print` 禁止所有 `print`/`debugPrint`，改用：

```dart
import 'package:PiliMiLe/services/logger.dart';
logger.t('trace');   // trace 级别
logger.d('debug');   // debug 级别
logger.i('info');    // info 级别
logger.w('warning'); // warning 级别
logger.e('error');   // error 级别
```

debug 模式显示 trace 及以上，release 模式仅显示 warning 及以上。

### GStorage 与 Pref 的使用区分

- **GStorage**（`lib/utils/storage.dart`）：Hive Box 的原始读写封装，用于存储用户信息、本地缓存、观看进度等结构化数据。新增 Box 要在 `GStorage.init()` 中注册、`accounts.dart` 的 `close()` 中关闭。
- **Pref**（`lib/utils/storage_pref.dart`）：偏好设置的便捷 getter/put，底层也是 Hive Box（`setting` box），但提供类型安全的静态快捷访问。仅用于开关/选择器等简单键值设置。

原则：**应用偏好设置用 Pref，业务数据用 GStorage**。不要混用——用 GStorage 读写偏好键不报错但绕过了 Pref 的默认值机制。

### lib/common/widgets/flutter/ 覆盖目录

该目录包含对 Flutter 框架 Widget 的**本地覆盖版本**（`page_view`、`scrollable`、`refresh_indicator`、`tabs` 等），用于修补框架 bug 或调整行为。修改这些文件会影响**全局所有页面**的滚动/页面切换/下拉刷新行为，务必谨慎。`analysis_options.yaml` 中已注释掉该目录的排除项（第15行），因此 lint 规则对该目录同样生效。

## Git 提交规范

### 分支策略

- `main` — 受保护分支，通过 PR 合并
- 功能分支命名: `feat/<描述>` / `fix/<描述>` / `refactor/<描述>`

### Commit Message 格式

```
<type>(<scope>): <简短描述>

<详细说明（可选）>
```

类型（type）：
- `feat` — 新功能
- `fix` — Bug 修复
- `refactor` — 重构（无功能变化）
- `perf` — 性能优化
- `style` — 代码格式（不影响逻辑）
- `docs` — 文档更新
- `chore` — 杂务（依赖更新、CI 配置等）
- `build` — 构建系统或外部依赖变更

范围（scope）：按主要影响的目录/模块，如 `video`、`player`、`live`、`dynamic`、`http`、`grpc`、`setting` 等。

### PR 要求

- CI 必须通过至少一个平台构建（`.github/workflows/build.yml`）
- 避免包含二进制文件（图片除外）
- 修改 `.patch` 文件（`lib/scripts/`）需在 PR 描述中说明原因
- 禁止提交调试用的 `print` 语句（lint 规则强制）
