import 'package:PiliMiLe/common/style.dart';
import 'package:PiliMiLe/common/widgets/badge.dart';
import 'package:PiliMiLe/common/widgets/image/image_save.dart';
import 'package:PiliMiLe/common/widgets/image/network_img_layer.dart';
import 'package:PiliMiLe/models/common/badge_type.dart';
import 'package:PiliMiLe/models_new/fav/fav_pgc/list.dart';
import 'package:PiliMiLe/utils/page_utils.dart';
import 'package:PiliMiLe/utils/platform_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 将进度文本中的时间补零为两位数（"5:16" → "05:16", "1:05:16" → "01:05:16"）
String _padProgressTime(String text) {
  // 先处理 H:MM:SS 三段格式
  text = text.replaceAllMapped(
    RegExp(r'\b(\d+):(\d{2}):(\d{2})\b'),
    (m) => '${m[1]!.padLeft(2, '0')}:${m[2]}:${m[3]}',
  );
  // 再处理 M:SS 两段格式（排除三段中的 M:SS 部分）
  return text.replaceAllMapped(
    RegExp(r'\b(\d+):(\d{2})\b(?!:\d)'),
    (m) => '${m[1]!.padLeft(2, '0')}:${m[2]}',
  );
}

// 视频卡片 - 垂直布局
class PgcCardV extends StatelessWidget {
  const PgcCardV({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
  });

  final FavPgcItemModel item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    void defaultLongPress() => imageSaveDialog(
      title: item.title,
      cover: item.cover,
    );
    return Card(
      shape: const RoundedRectangleBorder(borderRadius: Style.mdRadius),
      child: InkWell(
        borderRadius: Style.mdRadius,
        onLongPress: onLongPress ?? defaultLongPress,
        onSecondaryTap: PlatformUtils.isMobile ? null : (onLongPress ?? defaultLongPress),
        onTap: onTap ??
            (item.vodId != null
                ? () => Get.toNamed('/doubanVideo', arguments: {'vodId': item.vodId})
                : () => PageUtils.viewPgc(seasonId: item.seasonId)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 0.75,
              child: LayoutBuilder(
                builder: (context, boxConstraints) {
                  final double maxWidth = boxConstraints.maxWidth;
                  final double maxHeight = boxConstraints.maxHeight;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      NetworkImgLayer(
                        src: item.cover,
                        width: maxWidth,
                        height: maxHeight,
                      ),
                      PBadge(
                        text: item.badge,
                        top: 6,
                        right: 6,
                        bottom: null,
                        left: null,
                      ),
                      if (item.isFinish == 0 &&
                          item.renewalTime?.isNotEmpty == true)
                        Positioned(
                          bottom: 6,
                          left: 6,
                          right: 6,
                          child: PBadge(
                            text: item.renewalTime,
                            type: PBadgeType.gray,
                            isStack: false,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            content(context),
          ],
        ),
      ),
    );
  }

  Widget content(BuildContext context) {
    final theme = Theme.of(context);
    final style = TextStyle(
      fontSize: theme.textTheme.labelMedium!.fontSize,
      color: theme.colorScheme.outline,
    );
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 5, 0, 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title!,
              textAlign: TextAlign.start,
              style: const TextStyle(
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            if (item.progress != null)
              Text(
                _padProgressTime(
                  [
                    item.progress!.startsWith('看到')
                        ? item.progress!
                        : '看到${item.progress!}',
                    if (item.progressTime != null) item.progressTime!,
                  ].join(' '),
                ),
                maxLines: 1,
                style: style,
              )
            else if (item.newEp?.indexShow != null)
              Text(
                item.newEp!.indexShow!,
                maxLines: 1,
                style: style,
              ),
          ],
        ),
      ),
    );
  }
}
