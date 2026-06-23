import 'dart:io' show Platform;
import 'dart:ui' show ImageFilter;

import 'package:PiliMiLe/common/assets.dart';
import 'package:PiliMiLe/common/style.dart';
import 'package:PiliMiLe/common/widgets/custom_icon.dart';
import 'package:PiliMiLe/common/widgets/image/network_img_layer.dart';
import 'package:PiliMiLe/models/common/image_preview_type.dart';
import 'package:PiliMiLe/models/douban/douban_detail.dart';
import 'package:PiliMiLe/pages/douban_video/detail/controller.dart';
import 'package:PiliMiLe/pages/douban_video/detail/widgets/episode_selector.dart';
import 'package:PiliMiLe/pages/douban_video/detail/widgets/header_control.dart';
import 'package:PiliMiLe/pages/douban_video/detail/widgets/source_selector.dart';
import 'package:PiliMiLe/plugin/pl_player/view/view.dart';
import 'package:PiliMiLe/utils/page_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

class DoubanVideoDetailPage extends StatefulWidget {
  const DoubanVideoDetailPage({super.key});

  @override
  State<DoubanVideoDetailPage> createState() => _DoubanVideoDetailPageState();
}

class _DoubanVideoDetailPageState extends State<DoubanVideoDetailPage> {
  late final DoubanVideoDetailController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(DoubanVideoDetailController());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final playerWidth = size.width;
    final playerHeight = playerWidth * 9 / 16;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          backgroundColor: Colors.black,
          toolbarHeight: 0,
          systemOverlayStyle: Platform.isAndroid
              ? const SystemUiOverlayStyle(
                  statusBarIconBrightness: Brightness.light,
                  systemNavigationBarIconBrightness: Brightness.light,
                )
              : null,
        ),
      ),
      body: Obx(() {
        final isFullScreen = controller.plPlayerController.isFullScreen.value;
        final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

        // 全屏 / 横屏时播放器撑满，移除 SafeArea + 隐藏详情区域
        if (isFullScreen || !isPortrait) {
          return _buildPlayerArea(size.width, size.height);
        }

        return SafeArea(
          child: Column(
            children: [
              SizedBox(
                width: playerWidth,
                height: playerHeight,
                child: Obx(() => _buildPlayerArea(playerWidth, playerHeight)),
              ),
              Expanded(child: Obx(_buildContent)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPlayerArea(double width, double height) {
    // 已播放 → 播放器
    if (controller.playerReady.value) {
      return PLVideoPlayer(
        maxWidth: width,
        maxHeight: height,
        plPlayerController: controller.plPlayerController,
        headerControl: DoubanVideoHeaderControl(
          plPlayerController: controller.plPlayerController,
          title: controller.vodName.value,
          doubanController: controller,
        ),
      );
    }

    // 未播放 → 模糊海报背景 + 居中海报 + 顶栏 + 右下角播放按钮
    return Stack(
      clipBehavior: Clip.hardEdge,
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: ColoredBox(color: Colors.black)),

        // 背景层：同一张海报模糊拉伸铺满
        if (controller.vodPic.value.isNotEmpty)
          Positioned.fill(
            child: ClipRect(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: NetworkImgLayer(
                  src: controller.vodPic.value,
                  width: width,
                  height: height,
                  skipThumbnail: true,
                ),
              ),
            ),
          ),

        // 居中海报
        if (controller.vodPic.value.isNotEmpty)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: controller.play,
              child: Center(
                child: NetworkImgLayer(
                  src: controller.vodPic.value,
                  width: width,
                  height: height,
                  skipThumbnail: true,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

        // 顶栏（对齐 B站 manualPlayerWidget）
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AppBar(
            primary: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            foregroundColor: Colors.white,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                // 返回
                SizedBox(
                  width: 42,
                  height: 34,
                  child: IconButton(
                    tooltip: '返回',
                    icon: const Icon(
                      FontAwesomeIcons.arrowLeft,
                      size: 15,
                      color: Colors.white,
                      shadows: [
                        Shadow(blurRadius: 1.5, color: Colors.black),
                      ],
                    ),
                    onPressed: Get.back,
                  ),
                ),
                // 返回主页
                SizedBox(
                  width: 42,
                  height: 34,
                  child: IconButton(
                    tooltip: '返回主页',
                    icon: const Icon(
                      FontAwesomeIcons.house,
                      size: 15,
                      color: Colors.white,
                      shadows: [
                        Shadow(blurRadius: 1.5, color: Colors.black),
                      ],
                    ),
                    onPressed: controller.plPlayerController.onCloseAll,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 右下角播放按钮（对齐 B站）
        Positioned(
          right: 12,
          bottom: 10,
          child: IconButton(
            tooltip: '播放',
            onPressed: controller.play,
            icon: Image.asset(
              Assets.play,
              width: 60,
              height: 60,
              cacheHeight: 60,
            ),
          ),
        ),

      ],
    );
  }

  Widget _buildContent() {
    // 无数据
    if (controller.detail.value == null) {
      return const Center(child: Text('暂无数据'));
    }

    final detail = controller.detail.value!;
    final theme = Theme.of(context);
    final infoStyle = TextStyle(
      fontSize: 13,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
    );

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: SizedBox(
              height: 45,
              child: Row(
                children: [
                  Flexible(
                    flex: 1,
                    child: TabBar(
                      padding: EdgeInsets.zero,
                      labelStyle:
                          TabBarTheme.of(context).labelStyle?.copyWith(fontSize: 13) ??
                          const TextStyle(fontSize: 13),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                      dividerColor: Colors.transparent,
                      dividerHeight: 0,
                      tabs: const [
                        Tab(text: '简介'),
                        Tab(text: '待规划'),
                      ],
                    ),
                  ),
                  const Flexible(
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 32,
                            child: TextButton(
                              style: ButtonStyle(
                                padding: WidgetStatePropertyAll(EdgeInsets.zero),
                              ),
                              onPressed: null,
                              child: Text(
                                '发弹幕',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 38,
                            height: 38,
                            child: IconButton(
                              onPressed: null,
                              icon: Icon(
                                CustomIcons.dm_on,
                                size: 22,
                              ),
                            ),
                          ),
                          SizedBox(width: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // 简介 Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    Style.safeSpace,
                    Style.safeSpace,
                    Style.safeSpace,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCoverInfoRow(theme, detail, infoStyle),
                      const SizedBox(height: 12),
                      // 线路选择器
                      Obx(() => SourceSelector(
                        sources: controller.sources,
                        selectedIndex: controller.selectedSourceIndex.value,
                        onSelected: controller.onSelectSource,
                      )),
                      // 集数选择器
                      Obx(() => EpisodeSelector(
                        episodes: controller.currentEpisodes,
                        selectedIndex: controller.selectedEpisodeIndex.value,
                        onSelected: controller.onSelectEpisode,
                      )),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                // 待规划 Tab
                Center(
                  child: Text(
                    '待规划',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.38),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverInfoRow(
    ThemeData theme,
    DoubanVodDetailModel detail,
    TextStyle infoStyle,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 封面
        GestureDetector(
          onTap: () => PageUtils.imageView(
            imgList: [SourceModel(url: detail.vodPic)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: NetworkImgLayer(
              src: detail.vodPic,
              width: 115,
              height: 153,
              skipThumbnail: true,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // 右侧信息
        Expanded(
          child: SizedBox(
            height: 153,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 剧名
                Text(
                  detail.vodName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // 元数据标签
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _infoChip(detail.vodYear),
                    _infoChip(detail.vodArea),
                    _infoChip(detail.vodLang),
                  ].whereType<Widget>().toList(),
                ),
                if (detail.vodContent.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      detail.vodContent
                          .replaceAll(RegExp(r'<[^>]*>'), '')
                          .replaceAll('&nbsp;', ' ')
                          .replaceAll('&amp;', '&')
                          .replaceAll('&lt;', '<')
                          .replaceAll('&gt;', '>')
                          .replaceAll('&quot;', '"'),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: infoStyle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget? _infoChip(String text) {
    if (text.isEmpty) return null;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
