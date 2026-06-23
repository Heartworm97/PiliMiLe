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
          final buf = StringBuffer();
          buf.writeln('========== 获取追剧详情 ==========');
          buf.writeln('vodId: ${item.vodId}');
          buf.writeln('vodName: ${item.vodName}');

          final result = await DoubanHttp.getVodDetail(item.vodId);
          if (result['status'] == true) {
            final detail = result['data'];
            buf.writeln('状态: 成功');
            buf.writeln('影片名: ${detail.vodName}');
            buf.writeln('年份: ${detail.vodYear}');
            buf.writeln('地区: ${detail.vodArea}');
            buf.writeln('语言: ${detail.vodLang}');
            buf.writeln('演员: ${detail.vodActor}');
            buf.writeln('导演: ${detail.vodDirector}');
            buf.writeln('简介: ${detail.vodContent}');
            buf.writeln('线路数: ${detail.sources.length}');
            for (final src in detail.sources) {
              buf.writeln('  ── 线路: ${src.name}  key=${src.key}  '
                  'sort=${src.sort}  decodeStatus=${src.decodeStatus}  '
                  '集数=${src.episodeCount}');
              for (final ep in src.episodes) {
                buf.writeln('       ${ep.nid}: ${ep.title}  videoId=${ep.videoId}');
              }
            }
          } else {
            buf.writeln('状态: 失败, msg=${result['msg']}');
          }
          buf.writeln('========== 追剧详情结束 ==========');
          // ignore: avoid_print — 临时验证，一次性输出多行
          print(buf.toString());
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
