## [2.2.6] - 2026-06-23

### Added
- 首页搜索入口支持根据当前Tab自动切换搜索结果页对应分类（直播/番剧/影视/电视剧）
- 豆瓣卡片/搜索结果页支持长按（移动端）或右键（桌面端）保存海报图片
- PGC页面错误状态增加重载按钮
- 搜索面板"追剧"Tab 接入上游镜像站搜索API，支持关键词搜索影视资源
- 上游搜索4线路自动容灾切换，单线路故障自动轮询下一条

### Changed
- 豆瓣卡片海报渲染改用NetworkImgLayer组件，统一图片加载行为
- 豆瓣搜索结果海报URL自动清洗，从上游代理地址提取真实豆瓣图片链接并替换为社区CDN
- 豆瓣卡片点击跳转至搜索结果页豆瓣剧集分类
- 豆瓣搜索结果展示备注信息，演员行显示格式优化并增加溢出省略
- 网络请求失败时统一弹出Toast提示，日志页面复制/清空提示改用SmartDialog替代SnackBar
- 网络异常错误信息简化，移除冗余error code
- 移除 Linux 平台支持（linux/、assets/linux/、CI工作流、release.sh、pubspec.yaml、patch.ps1、CLAUDE.md）
- 追剧搜索结果卡片布局对齐番剧/影视Tab风格，支持关键词高亮与长按保存封面

### Fixed
- 修复豆瓣剧集页面网络异常时无捕获处理导致界面卡在加载状态的问题
- 修复删除Linux平台支持后 geetest_webview_dialog.dart 残留的 desktop_webview_window 引用导致iOS编译失败
- 修复搜索面板追剧Tab卡片RenderFlex溢出问题
