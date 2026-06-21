# v2.2.1

## 变更记录

### 新增功能
- feat: 发版脚本支持全平台构建（Android/iOS/macOS/Win/Linux）
- feat: 发版脚本根据代码量自动判断版本递增级别
- feat: 发版脚本自动建议版本号（patch +1）
- feat: Release 自动生成更新内容，发版脚本支持 CHANGELOG
- feat: 添加一键发版脚本 release.sh
- chore: 添加 GitHub Token 以支持私有仓库版本检查

### 修复
- fix: 修复 pubspec.yaml 版本行 YAML 语法错误，并加固 release.sh 防止恶性循环
- fix: 修复 pubspec.yaml 第20行 YAML 语法错误 — version 字段重复导致全平台 CI 解析失败
- fix: 修复首页标签页/底部导航栏勾选状态存储BUG，存储格式由List改为Map以分离排序和勾选状态
- fix: 修复首页标签页/底部导航栏勾选状态存储BUG，存储格式由List改为Map以分离排序和勾选状态
- fix: release.sh push 失败时不继续触发 CI

### 优化
- chore: 发布 version: 2.2.0
- chore: 发布 version: 2.1.0
- chore: 添加 GitHub Token 以支持私有仓库版本检查

### 其他
- (无)

## 全部提交

- `5f21213` fix: 修复 pubspec.yaml 版本行 YAML 语法错误，并加固 release.sh 防止恶性循环 (月光下的黑驴子)
- `5b17bc1` chore: 发布 version: 2.2.0 (月光下的黑驴子)
- `ea5f51a` fix: 修复 pubspec.yaml 第20行 YAML 语法错误 — version 字段重复导致全平台 CI 解析失败 (月光下的黑驴子)
- `65b5a86` chore: 发布 version: 2.1.0 (月光下的黑驴子)
- `b1b2666` fix: 修复首页标签页/底部导航栏勾选状态存储BUG，存储格式由List改为Map以分离排序和勾选状态 (月光下的黑驴子)
- `9a199ed` fix: 修复首页标签页/底部导航栏勾选状态存储BUG，存储格式由List改为Map以分离排序和勾选状态 (月光下的黑驴子)
- `11dbf6d` fix: release.sh push 失败时不继续触发 CI (月光下的黑驴子)
- `68c8e90` feat: 发版脚本支持全平台构建（Android/iOS/macOS/Win/Linux） (月光下的黑驴子)
- `978d9c2` feat: 发版脚本根据代码量自动判断版本递增级别 (月光下的黑驴子)
- `202cd69` feat: 发版脚本自动建议版本号（patch +1） (月光下的黑驴子)
- `455324b` feat: Release 自动生成更新内容，发版脚本支持 CHANGELOG (月光下的黑驴子)
- `9dd464e` feat: 添加一键发版脚本 release.sh (月光下的黑驴子)
- `3d04855` chore: 添加 GitHub Token 以支持私有仓库版本检查 (月光下的黑驴子)
