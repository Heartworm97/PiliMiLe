import 'dart:async';
import 'dart:io';

import 'package:PiliMiLe/build_config.dart';
import 'package:PiliMiLe/common/assets.dart';
import 'package:PiliMiLe/common/constants.dart';
import 'package:PiliMiLe/common/style.dart';
import 'package:PiliMiLe/common/widgets/dialog/dialog.dart';
import 'package:PiliMiLe/common/widgets/dialog/export_import.dart';
import 'package:PiliMiLe/common/widgets/dialog/feedback.dart';
import 'package:PiliMiLe/common/widgets/flutter/list_tile.dart';
import 'package:PiliMiLe/pages/mine/controller.dart';
import 'package:PiliMiLe/services/logger.dart';
import 'package:PiliMiLe/utils/accounts.dart';
import 'package:PiliMiLe/utils/accounts/account.dart';
import 'package:PiliMiLe/utils/android/android_helper.dart';
import 'package:PiliMiLe/utils/cache_manager.dart';
import 'package:PiliMiLe/utils/date_utils.dart';
import 'package:PiliMiLe/utils/device_utils.dart';
import 'package:PiliMiLe/utils/extension/num_ext.dart';
import 'package:PiliMiLe/utils/login_utils.dart';
import 'package:PiliMiLe/utils/page_utils.dart';
import 'package:PiliMiLe/utils/platform_utils.dart';
import 'package:PiliMiLe/utils/storage.dart';
import 'package:PiliMiLe/utils/update.dart';
import 'package:PiliMiLe/utils/utils.dart';
import 'package:flutter/material.dart' hide ListTile;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.child,
    this.onPressed,
    this.primary = false,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: primary
          ? colorScheme.primary.withAlpha(25)
          : colorScheme.onSurface.withAlpha(12),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 13,
              fontWeight: primary ? FontWeight.w600 : FontWeight.w500,
              color: primary ? colorScheme.primary : colorScheme.outline,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AboutPage extends StatefulWidget {
  const AboutPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final currentVersion =
      '${BuildConfig.versionName}+${BuildConfig.versionCode}';
  RxString cacheSize = ''.obs;

  late int _pressCount = 0;

  @override
  void initState() {
    super.initState();
    getCacheSize();
  }

  @override
  void dispose() {
    cacheSize.close();
    super.dispose();
  }

  void getCacheSize() {
    CacheManager.loadApplicationCache().then((res) {
      if (mounted) {
        cacheSize.value = CacheManager.formatSize(res);
      }
    });
  }

  void _showSourceCodeDialog() => showDialog(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final outline = colorScheme.outline;
      return AlertDialog(
        title: Row(
          children: [
            Icon(MdiIcons.codeTags, size: 24, color: colorScheme.primary),
            const SizedBox(width: 10),
            const Text('开源致谢'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(height: 1, color: outline.withAlpha(30)),
            const SizedBox(height: 16),
            _buildCreditCard(
              label: '原作者',
              name: 'guozhigq / pilipala',
              url: 'https://github.com/guozhigq/pilipala',
              colorScheme: colorScheme,
              theme: theme,
            ),
            const SizedBox(height: 6),
            Icon(Icons.arrow_downward, size: 18, color: colorScheme.primary.withAlpha(60)),
            const SizedBox(height: 6),
            _buildCreditCard(
              label: '上游作者',
              name: 'orz12 / PiliPalaX',
              url: 'https://github.com/orz12/PiliPalaX',
              colorScheme: colorScheme,
              theme: theme,
            ),
            const SizedBox(height: 6),
            Icon(Icons.arrow_downward, size: 18, color: colorScheme.primary.withAlpha(60)),
            const SizedBox(height: 6),
            _buildCreditCard(
              label: '上游作者',
              name: 'bggRGjQaUbCoE / PiliMiLe',
              url: 'https://github.com/bggRGjQaUbCoE/PiliMiLe',
              colorScheme: colorScheme,
              theme: theme,
            ),
            const SizedBox(height: 6),
            Icon(Icons.arrow_downward, size: 18, color: colorScheme.primary.withAlpha(60)),
            const SizedBox(height: 6),
            _buildCreditCard(
              label: '本仓库',
              name: 'Heartworm97 / PiliMiLe',
              url: Constants.sourceCodeUrl,
              colorScheme: colorScheme,
              theme: theme,
              highlighted: true,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text.rich(
                TextSpan(
                  text: '感谢所有作者 ',
                  children: [
                    TextSpan(
                      text: '开源精神',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary.withAlpha(180),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _SmallButton(
                onPressed: Get.back,
                child: const Text('关闭'),
              ),
              const SizedBox(width: 8),
              _SmallButton(
                onPressed: () {
                  Utils.copyText(Constants.sourceCodeUrl);
                  SmartDialog.showToast('已复制链接');
                },
                primary: true,
                child: const Text('复制链接'),
              ),
            ],
          ),
        ],
      );
    },
  );

  Widget _buildCreditCard({
    required String label,
    required String name,
    required String url,
    required ColorScheme colorScheme,
    required ThemeData theme,
    bool highlighted = false,
  }) {
    final outline = colorScheme.outline;
    final bgColor = highlighted
        ? colorScheme.primaryContainer.withAlpha(60)
        : colorScheme.surfaceContainerHighest.withAlpha(80);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted
              ? colorScheme.primary.withAlpha(40)
              : outline.withAlpha(20),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: highlighted ? colorScheme.primary : outline,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: highlighted ? colorScheme.primary : colorScheme.onSurface,
              fontSize: highlighted ? 16 : 14,
              fontWeight: highlighted ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              Utils.copyText(url);
              SmartDialog.showToast('已复制 $label 链接');
            },
            child: SelectableText(
              url,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withAlpha(highlighted ? 180 : 140),
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDialog() => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      constraints: Style.dialogFixedConstraints,
      content: TextField(
        autofocus: true,
        onSubmitted: (value) {
          Get.back();
          if (value.isNotEmpty) {
            PageUtils.handleWebview(value, inApp: true);
          }
        },
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const style = TextStyle(fontSize: 15);
    final outline = theme.colorScheme.outline;
    final subTitleStyle = TextStyle(fontSize: 13, color: outline);
    final showAppBar = widget.showAppBar;
    final padding = MediaQuery.viewPaddingOf(context);
    return Scaffold(
      appBar: showAppBar ? AppBar(title: const Text('关于')) : null,
      resizeToAvoidBottomInset: false,
      body: ListView(
        padding: EdgeInsets.only(
          left: showAppBar ? padding.left : 0,
          right: showAppBar ? padding.right : 0,
          bottom: padding.bottom + 100,
        ),
        children: [
          GestureDetector(
            onTap: () {
              if (++_pressCount == 5) {
                _pressCount = 0;
                _showDialog();
              }
            },
            onSecondaryTap: PlatformUtils.isDesktop ? _showDialog : null,
            child: Image.asset(
              width: 150,
              height: 150,
              excludeFromSemantics: true,
              cacheWidth: 150.cacheSize(context),
              Assets.logo,
            ),
          ),
          ListTile(
            title: Text(
              Constants.appName,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium!.copyWith(height: 2),
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '基于 Flutter 开发的影视聚合客户端',
                  style: TextStyle(color: outline),
                  semanticsLabel: '与你一起，发现不一样的世界',
                ),
                const Icon(
                  Icons.accessibility_new,
                  semanticLabel: "无障碍适配",
                  size: 18,
                ),
              ],
            ),
          ),
          ListTile(
            onTap: () => Update.checkUpdate(false),
            onLongPress: () => Utils.copyText(currentVersion),
            onSecondaryTap: PlatformUtils.isMobile
                ? null
                : () => Utils.copyText(currentVersion),
            title: const Text('当前版本'),
            leading: const Icon(Icons.commit_outlined),
            trailing: Text(
              currentVersion,
              style: subTitleStyle,
            ),
          ),
          ListTile(
            title: Text(
              'Build Time: ${DateFormatUtils.format(BuildConfig.buildTime, format: DateFormatUtils.longFormatDs)}',
              style: const TextStyle(fontSize: 14),
            ),
            leading: const Icon(Icons.info_outline),
          ),
          ListTile(
            title: Text(
              'Commit Hash: ${BuildConfig.commitHash}',
              style: const TextStyle(fontSize: 14),
            ),
            leading: const SizedBox(width: 24),
            onTap: () {},
            onLongPress: () => Utils.copyText(BuildConfig.commitHash),
            onSecondaryTap: PlatformUtils.isMobile
                ? null
                : () => Utils.copyText(BuildConfig.commitHash),
          ),
          Divider(
            thickness: 1,
            height: 30,
            color: theme.colorScheme.outlineVariant,
          ),
          ListTile(
            onTap: _showSourceCodeDialog,
            leading: const Icon(MdiIcons.codeTags),
            title: const Text('开源代码'),
            subtitle: Text('因为开源，所以信赖', style: subTitleStyle),
          ),
          if (Platform.isAndroid)
            ListTile(
              onTap: PiliAndroidHelper.openLinkVerifySettings,
              leading: const Icon(MdiIcons.linkBoxOutline),
              title: const Text('打开受支持的链接'),
              trailing: Icon(Icons.arrow_forward, size: 16, color: outline),
            ),
          ListTile(
            onTap: () => showFeedbackDialog(context),
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('问题反馈'),
            subtitle: Text('帮助我们变得更好', style: subTitleStyle),
            trailing: Icon(Icons.arrow_forward, size: 16, color: outline),
          ),
          ListTile(
            onTap: () => Get.toNamed('/logs'),
            onLongPress: LoggerUtils.clearLogs,
            onSecondaryTap: PlatformUtils.isMobile
                ? null
                : LoggerUtils.clearLogs,
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('错误日志'),
            subtitle: Text('长按清除日志', style: subTitleStyle),
            trailing: Icon(Icons.arrow_forward, size: 16, color: outline),
          ),
          ListTile(
            onTap: () {
              if (cacheSize.value.isNotEmpty) {
                showConfirmDialog(
                  context: context,
                  title: const Text('提示'),
                  content: const Text('该操作将清除图片及网络请求缓存数据，确认清除？'),
                  onConfirm: () async {
                    SmartDialog.showLoading(msg: '正在清除...');
                    try {
                      await CacheManager.clearLibraryCache();
                      SmartDialog.showToast('清除成功');
                    } catch (err) {
                      SmartDialog.showToast(err.toString());
                    } finally {
                      SmartDialog.dismiss();
                    }
                    getCacheSize();
                  },
                );
              }
            },
            leading: const Icon(Icons.delete_outline),
            title: const Text('清除缓存'),
            subtitle: Obx(
              () => Text(
                '图片及网络缓存 ${cacheSize.value}',
                style: subTitleStyle,
              ),
            ),
          ),
          ListTile(
            title: const Text('导入/导出登录信息'),
            leading: const Icon(Icons.import_export_outlined),
            onTap: () => showImportExportDialog<Map>(
              context,
              title: '登录信息',
              localFileName: () => 'account',
              onExport: () =>
                  Utils.jsonEncoder.convert(Accounts.account.toMap()),
              onImport: (json) async {
                final res = json.map(
                  (key, value) => MapEntry(key, LoginAccount.fromJson(value)),
                );
                await Accounts.account.putAll(res);
                await Accounts.refresh();
                MineController.anonymity.value = !Accounts.heartbeat.isLogin;
                if (Accounts.main.isLogin) {
                  await LoginUtils.onLoginMain();
                }
              },
            ),
          ),
          ListTile(
            title: const Text('导入/导出设置'),
            dense: false,
            leading: const Icon(Icons.import_export_outlined),
            onTap: () => showImportExportDialog<Map<String, dynamic>>(
              context,
              title: '设置',
              localFileName: () => 'setting_${DeviceUtils.platformName}',
              onExport: GStorage.exportAllSettings,
              onImport: GStorage.importAllJsonSettings,
            ),
          ),
          ListTile(
            title: const Text('重置所有设置'),
            leading: const Icon(Icons.settings_backup_restore_outlined),
            onTap: () => showDialog(
              context: context,
              builder: (context) {
                return SimpleDialog(
                  clipBehavior: Clip.hardEdge,
                  title: const Text('是否重置所有设置？'),
                  children: [
                    ListTile(
                      dense: true,
                      onTap: () async {
                        Get.back();
                        await Future.wait([
                          GStorage.setting.clear(),
                          GStorage.video.clear(),
                        ]);
                        SmartDialog.showToast('重置成功');
                      },
                      title: const Text('重置可导出的设置', style: style),
                    ),
                    ListTile(
                      dense: true,
                      onTap: () async {
                        Get.back();
                        await GStorage.clear();
                        SmartDialog.showToast('重置成功');
                      },
                      title: const Text('重置所有数据（含登录信息）', style: style),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
