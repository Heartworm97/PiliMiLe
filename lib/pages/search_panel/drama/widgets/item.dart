import 'package:PiliMiLe/common/style.dart';
import 'package:PiliMiLe/common/widgets/badge.dart';
import 'package:PiliMiLe/common/widgets/image/image_save.dart';
import 'package:PiliMiLe/common/widgets/image/network_img_layer.dart';
import 'package:PiliMiLe/http/douban.dart';
import 'package:PiliMiLe/models/search/result.dart';
import 'package:PiliMiLe/utils/platform_utils.dart';
import 'package:flutter/material.dart';

class SearchDramaItem extends StatelessWidget {
  const SearchDramaItem({
    super.key,
    required this.item,
    required this.keyword,
  });

  final SearchDramaItemModel item;
  final String keyword;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const TextStyle style = TextStyle(fontSize: 13);
    void onLongPress() => imageSaveDialog(
      title: item.vodName,
      cover: item.vodPic,
    );
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () async {
          debugPrint('========== 追剧详情: ${item.vodName}(${item.vodId}) ==========');

          final result = await DoubanHttp.getVodDetail(item.vodId);
          if (result['status'] == true) {
            final detail = result['data'];
            debugPrint('成功 | 线路:${detail.sources.length}');
            for (final src in detail.sources) {
              final sample = src.episodes.isNotEmpty
                  ? src.episodes.first.videoId
                  : '无';
              debugPrint('  ${src.name}(${src.key}) '
                  '集数:${src.episodeCount} decode:${src.decodeStatus} '
                  '样本: $sample');
            }
          } else {
            debugPrint('失败, msg=${result['msg']}');
          }
        },
        onLongPress: onLongPress,
        onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Style.safeSpace,
            vertical: Style.cardSpace,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  NetworkImgLayer(
                    width: 111,
                    height: 148,
                    src: item.vodPic,
                    skipThumbnail: true,
                  ),
                  if (item.vodYear.isNotEmpty)
                    PBadge(
                      text: item.vodYear,
                      top: 6,
                      right: 4,
                      bottom: null,
                      left: null,
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    _buildTitle(theme),
                    const SizedBox(height: 12),
                    if (item.typeName.isNotEmpty || item.vodArea.isNotEmpty)
                      Text(
                        [item.typeName, item.vodArea]
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                        style: style,
                      ),
                    if (item.vodRemarks.isNotEmpty)
                      Text(item.vodRemarks, maxLines: 1, style: style),
                    if (item.vodActor.isNotEmpty)
                      Text(
                        '演员：${item.vodActor}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: style,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    final title = item.vodName;
    final kw = keyword.trim();
    if (kw.isEmpty || !title.contains(kw)) {
      return Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final idx = title.indexOf(kw, start);
      if (idx == -1) {
        spans.add(TextSpan(text: title.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: title.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: kw,
        style: TextStyle(color: theme.colorScheme.primary),
      ));
      start = idx + kw.length;
    }

    return Text.rich(
      TextSpan(
        children: spans,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
