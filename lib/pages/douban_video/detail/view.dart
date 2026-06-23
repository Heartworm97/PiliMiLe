import 'package:PiliMiLe/common/style.dart';
import 'package:PiliMiLe/pages/douban_video/detail/controller.dart';
import 'package:PiliMiLe/pages/douban_video/detail/widgets/episode_selector.dart';
import 'package:PiliMiLe/pages/douban_video/detail/widgets/header_control.dart';
import 'package:PiliMiLe/pages/douban_video/detail/widgets/source_selector.dart';
import 'package:PiliMiLe/plugin/pl_player/view/view.dart';
import 'package:flutter/material.dart';
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
    // M3U8 就绪 → 播放器
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

    // 加载中 / 解码中 / 出错 → 海报 + 加载指示
    return Stack(
      fit: StackFit.expand,
      children: [
        if (controller.vodPic.value.isNotEmpty)
          Image.network(
            controller.vodPic.value,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: Colors.black),
          )
        else
          Container(color: Colors.black),
        // 半透明遮罩
        Container(color: Colors.black.withValues(alpha: 0.4)),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                controller.isDecoding.value ? '解码中...' : '加载中...',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              if (controller.errorMsg.value != null) ...[
                const SizedBox(height: 8),
                Text(
                  controller.errorMsg.value!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    // 加载中
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    // 错误（尚未加载成功，且无 detail）
    if (controller.errorMsg.value != null && controller.detail.value == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              controller.errorMsg.value!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => controller.retry,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

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
