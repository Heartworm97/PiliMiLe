import 'package:PiliMiLe/common/assets.dart';
import 'package:PiliMiLe/common/style.dart';
import 'package:PiliMiLe/common/widgets/image/network_img_layer.dart';
import 'package:PiliMiLe/pages/douban_video/detail/controller.dart';
import 'package:PiliMiLe/pages/douban_video/detail/widgets/episode_selector.dart';
import 'package:PiliMiLe/pages/douban_video/detail/widgets/header_control.dart';
import 'package:PiliMiLe/pages/douban_video/detail/widgets/source_selector.dart';
import 'package:PiliMiLe/plugin/pl_player/view/view.dart';
import 'package:flutter/material.dart';
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 播放器区域
            SizedBox(
              width: playerWidth,
              height: playerHeight,
              child: Obx(() => _buildPlayerArea(playerWidth, playerHeight)),
            ),
            // 详情区域
            Expanded(child: Obx(_buildContent)),
          ],
        ),
      ),
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
        ),
      );
    }

    // 未播放 → 封面 + 顶栏 + 右下角播放按钮（对齐番剧/影视 manualPlayerWidget）
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        // 封面
        if (controller.vodPic.value.isNotEmpty)
          NetworkImgLayer(
            src: controller.vodPic.value,
            width: width,
            height: height,
            skipThumbnail: true,
            getPlaceHolder: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          )
        else
          Container(color: Colors.black),

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

        // 解码中
        if (controller.isDecoding.value)
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle_outline, color: Colors.white, size: 60),
                SizedBox(height: 8),
                Text(
                  '加载中...',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),

        // 错误提示
        if (controller.errorMsg.value != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 48,
            child: Text(
              controller.errorMsg.value!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              textAlign: TextAlign.center,
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: Style.safeSpace,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 剧名
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(
              detail.vodName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),

          // 基础信息行
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _infoChip(detail.vodYear),
              _infoChip(detail.vodArea),
              _infoChip(detail.vodLang),
              _infoChip(detail.vodRemarks),
            ].whereType<Widget>().toList(),
          ),

          const SizedBox(height: 12),

          // 演员
          if (detail.vodActor.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('演员：${detail.vodActor}', style: infoStyle),
            ),

          // 导演
          if (detail.vodDirector.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('导演：${detail.vodDirector}', style: infoStyle),
            ),

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

          // 简介
          if (detail.vodContent.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '简介',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail.vodContent,
              style: infoStyle,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
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
