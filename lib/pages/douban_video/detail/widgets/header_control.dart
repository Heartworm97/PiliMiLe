import 'dart:async';

import 'package:PiliMiLe/common/widgets/custom_icon.dart';
import 'package:PiliMiLe/pages/douban_video/detail/controller.dart';
import 'package:PiliMiLe/pages/douban_video/detail/episode_label.dart';
import 'package:PiliMiLe/pages/setting/models/play_settings.dart'
    show showPlayerVolumeDialog;
import 'package:PiliMiLe/pages/setting/widgets/popup_item.dart'
    show PopupListTile, enumItemBuilder, DescPosType;
import 'package:PiliMiLe/pages/video/introduction/ugc/widgets/menu_row.dart';
import 'package:PiliMiLe/pages/video/widgets/header_control.dart'
    show HeaderControlState;
import 'package:PiliMiLe/plugin/pl_player/controller.dart';
import 'package:PiliMiLe/plugin/pl_player/models/play_repeat.dart';
import 'package:PiliMiLe/services/shutdown_timer_service.dart'
    show shutdownTimerService;
import 'package:PiliMiLe/utils/image_utils.dart';
import 'package:PiliMiLe/utils/page_utils.dart';
import 'package:PiliMiLe/utils/platform_utils.dart';
import 'package:PiliMiLe/utils/storage_pref.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DoubanVideoHeaderControl extends StatelessWidget {
  const DoubanVideoHeaderControl({
    super.key,
    required this.plPlayerController,
    required this.title,
    required this.doubanController,
  });

  final PlPlayerController plPlayerController;
  final String title;
  final DoubanVideoDetailController doubanController;

  Widget _buildPipBtn() {
    return _buildBtn(
      tooltip: '画中画',
      icon: const Icon(
        Icons.picture_in_picture_outlined,
        size: 15,
        color: Colors.white,
      ),
      onPressed: plPlayerController.toggleDesktopPip,
    );
  }

  Widget _buildMoreBtn(BuildContext context) {
    return _buildBtn(
      tooltip: '更多设置',
      icon: const Icon(
        Icons.more_vert_outlined,
        size: 19,
        color: Colors.white,
      ),
      onPressed: () => _showMoreMenu(context),
    );
  }

  void _showMoreMenu(BuildContext context) {
    final isFullScreen = plPlayerController.isFullScreen.value;
    PageUtils.showVideoBottomSheet(
      context,
      maxWidth: 512,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Material(
          clipBehavior: Clip.hardEdge,
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 14),
            children: [
              if (doubanController.vodPic.value.isNotEmpty)
                ListTile(
                  dense: true,
                  onTap: () {
                    Get.back();
                    ImageUtils.downloadImg([doubanController.vodPic.value]);
                  },
                  leading: const Icon(Icons.image_outlined, size: 20),
                  title: const Text('保存封面'),
                ),
              ListTile(
                dense: true,
                onTap: () {
                  Get.back();
                  shutdownTimerService.showScheduleExitDialog(
                    context,
                    isFullScreen: isFullScreen,
                  );
                },
                leading: const Icon(Icons.hourglass_top_outlined, size: 20),
                title: const Text('定时关闭'),
              ),
              ListTile(
                dense: true,
                onTap: () {
                  Get.back();
                  _showEditPlayUrl(context);
                },
                leading: const Icon(Icons.link, size: 20),
                title: const Text('播放地址'),
              ),
              ListTile(
                dense: true,
                onTap: () {
                  Get.back();
                  doubanController.m3u8Url.value = null;
                  doubanController.play();
                },
                leading: const Icon(Icons.refresh_outlined, size: 20),
                title: const Text('重载视频'),
              ),
              if (PlatformUtils.isMobile)
                if (plPlayerController.videoPlayerController case final player?)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.volume_up, size: 20),
                    title: const Text('播放器音量'),
                    subtitle: Text(
                      '当前: ${Pref.playerVolume.toStringAsFixed(0)}%',
                    ),
                    onTap: () => showPlayerVolumeDialog(
                      context,
                      () => (context as Element).markNeedsBuild(),
                      onChanged: player.setVolume,
                    ),
                  ),
              PopupListTile<PlayRepeat>(
                dense: true,
                leading: const Icon(Icons.repeat, size: 20),
                title: const Text('播放顺序'),
                value: () {
                  final value = plPlayerController.playRepeat;
                  return (value, value.label);
                },
                itemBuilder: (_) => enumItemBuilder(PlayRepeat.values),
                onSelected: (value, setState) {
                  plPlayerController.setPlayRepeat(value);
                  setState();
                },
                descPosType: DescPosType.subtitle,
                descFontSize: 12,
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Obx(
                      () {
                        final flipX = plPlayerController.flipX.value;
                        return ActionRowLineItem(
                          iconData: Icons.flip,
                          onTap: () =>
                              plPlayerController.flipX.value = !flipX,
                          text: " 左右翻转 ",
                          selectStatus: flipX,
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    Obx(
                      () {
                        final flipY = plPlayerController.flipY.value;
                        return ActionRowLineItem(
                          icon: Icon(
                            CustomIcons.flip_rotate_90,
                            size: 13,
                            color: flipY
                                ? Theme.of(context).colorScheme.onSecondaryContainer
                                : Theme.of(context).colorScheme.outline,
                          ),
                          onTap: () {
                            plPlayerController.flipY.value = !flipY;
                          },
                          text: " 上下翻转 ",
                          selectStatus: flipY,
                        );
                      },
                    ),
                    if (PlatformUtils.isMobile) ...[
                      const SizedBox(width: 10),
                      Obx(
                        () => ActionRowLineItem(
                          iconData: Icons.play_circle_outline,
                          onTap:
                              plPlayerController.setContinuePlayInBackground,
                          text: " 后台播放 ",
                          selectStatus: plPlayerController
                              .continuePlayInBackground
                              .value,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (plPlayerController.videoPlayerController case final player?)
                ListTile(
                  dense: true,
                  title: const Text('播放信息'),
                  leading: const Icon(Icons.info_outline, size: 20),
                  onTap: () => HeaderControlState.showPlayerInfo(
                    context,
                    player: player,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditPlayUrl(BuildContext context) {
    String url = doubanController.m3u8Url.value ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('播放地址'),
        content: TextFormField(
          initialValue: url,
          minLines: 1,
          maxLines: 3,
          onChanged: (value) => url = value,
          decoration: const InputDecoration(
            labelText: 'M3U8 地址',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              if (url.isNotEmpty) {
                doubanController.m3u8Url.value = url;
                doubanController.play();
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 11, 8, 4),
      child: Row(
        children: [
          _buildBtn(
            tooltip: '返回',
            icon: const Icon(
              FontAwesomeIcons.arrowLeft,
              size: 15,
              color: Colors.white,
            ),
            onPressed: () {
              if (plPlayerController.isFullScreen.value) {
                plPlayerController.onPopInvokedWithResult(false, null);
              } else {
                Get.back();
              }
            },
          ),
          Obx(() {
            // 读取 isFullScreen.value 确保 Obx 能感知播放器状态变化
            plPlayerController.isFullScreen.value;
            if (!plPlayerController.isDesktopPip) {
              return _buildBtn(
                tooltip: '返回主页',
                icon: const Icon(
                  FontAwesomeIcons.house,
                  size: 15,
                  color: Colors.white,
                ),
                onPressed: plPlayerController.onCloseAll,
              );
            }
            return const SizedBox.shrink();
          }),
          _buildTitle(context),
          // 时间 + 电量（横屏/全屏时显示）
          Obx(() {
            // 读取 isFullScreen 确保 Obx 能感知播放器状态变化
            plPlayerController.isFullScreen.value;
            if (MediaQuery.of(context).orientation == Orientation.portrait) {
              return const SizedBox.shrink();
            }
            return const _TimeBatteryWidget();
          }),
          // 右侧操作按钮
          if (PlatformUtils.isDesktop)
            Obx(() {
              if (plPlayerController.isFullScreen.value) {
                return const SizedBox.shrink();
              }
              return _buildPipBtn();
            }),
          _buildMoreBtn(context),
        ],
      ),
    );
  }

  Widget _buildBtn({
    required String tooltip,
    required Widget icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 40,
      height: 34,
      child: IconButton(
        tooltip: tooltip,
        style: const ButtonStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.zero),
        ),
        onPressed: onPressed,
        icon: icon,
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Obx(() {
      final isPortrait =
          MediaQuery.of(context).orientation == Orientation.portrait;
      final isFullScreen = plPlayerController.isFullScreen.value;
      if (isFullScreen ||
          ((!plPlayerController.horizontalScreen ||
                  plPlayerController.isDesktopPip) &&
              !isPortrait)) {
        final ep = doubanController.selectedEpisode;
        final label = ep != null ? '$title ${episodeLabel(ep)}' : title;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
      return const Spacer();
    });
  }
}

class _TimeBatteryWidget extends StatefulWidget {
  const _TimeBatteryWidget();

  @override
  State<_TimeBatteryWidget> createState() => _TimeBatteryWidgetState();
}

class _TimeBatteryWidgetState extends State<_TimeBatteryWidget> {
  Timer? _clock;
  final _now = ''.obs;
  final _batteryLevel = RxnInt();
  late final _battery = Battery();

  static final _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _startClock();
    _fetchBattery();
  }

  @override
  void dispose() {
    _stopClock();
    super.dispose();
  }

  void _startClock() {
    _now.value = _timeFormat.format(DateTime.now());
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _now.value = _timeFormat.format(DateTime.now());
    });
  }

  void _stopClock() {
    _clock?.cancel();
    _clock = null;
  }

  Future<void> _fetchBattery() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) _batteryLevel.value = level;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() {
          final level = _batteryLevel.value;
          if (level == null) return const SizedBox.shrink();
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$level%',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(width: 10),
            ],
          );
        }),
        Obx(
          () => Text(
            _now.value,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
