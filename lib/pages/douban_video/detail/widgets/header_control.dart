import 'package:PiliMiLe/plugin/pl_player/controller.dart';
import 'package:PiliMiLe/utils/platform_utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

class DoubanVideoHeaderControl extends StatelessWidget {
  const DoubanVideoHeaderControl({
    super.key,
    required this.plPlayerController,
    required this.title,
  });

  final PlPlayerController plPlayerController;
  final String title;

  Widget _buildAudioOnlyBtn() {
    return Obx(() {
      final isOnlyAudio = plPlayerController.onlyPlayAudio.value;
      return _buildBtn(
        tooltip: isOnlyAudio ? '退出听视频' : '听视频',
        icon: Icon(
          isOnlyAudio ? Icons.headphones : Icons.headphones_outlined,
          size: 15,
          color: Colors.white,
        ),
        onPressed: plPlayerController.setOnlyPlayAudio,
      );
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                plPlayerController.triggerFullScreen(status: false);
              } else {
                Get.back();
              }
            },
          ),
          Obx(() {
            final isPortrait =
                MediaQuery.of(context).orientation == Orientation.portrait;
            final isFullScreen = plPlayerController.isFullScreen.value;
            if (!plPlayerController.isDesktopPip &&
                (!isFullScreen || !isPortrait)) {
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
          // 右侧操作按钮
          _buildAudioOnlyBtn(),
          if (PlatformUtils.isDesktop)
            Obx(() {
              if (plPlayerController.isFullScreen.value) {
                return const SizedBox.shrink();
              }
              return _buildPipBtn();
            }),
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
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              title,
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
