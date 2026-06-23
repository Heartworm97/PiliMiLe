import 'package:PiliMiLe/plugin/pl_player/controller.dart';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.6),
            Colors.transparent,
          ],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        left: 8,
        right: 8,
        bottom: 8,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: '返回',
            onPressed: Get.back,
            icon: const Icon(
              FontAwesomeIcons.arrowLeft,
              size: 15,
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          IconButton(
            tooltip: '返回主页',
            onPressed: plPlayerController.onCloseAll,
            icon: const Icon(
              FontAwesomeIcons.house,
              size: 15,
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          // 仅全屏时显示剧名
          Obx(
            () => plPlayerController.isFullScreen.value
                ? Expanded(
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
                  )
                : const Spacer(),
          ),
        ],
      ),
    );
  }
}
