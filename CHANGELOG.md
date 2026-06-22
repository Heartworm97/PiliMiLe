## 变更记录

### 新增功能
- 搜索面板"追剧"Tab 接入上游镜像站搜索API，支持关键词搜索影视资源
- 上游搜索4线路自动容灾切换，单线路故障自动轮询下一条

### 修复
- 修复删除Linux平台支持后 geetest_webview_dialog.dart 残留的 desktop_webview_window 引用导致iOS编译失败
- 修复搜索面板追剧Tab卡片RenderFlex溢出问题

### 优化
- 移除 Linux 平台支持（linux/、assets/linux/、CI工作流、release.sh、pubspec.yaml、patch.ps1、CLAUDE.md）
- 追剧搜索结果卡片布局对齐番剧/影视Tab风格，支持关键词高亮与长按保存封面

