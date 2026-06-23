import 'package:PiliMiLe/common/style.dart';
import 'package:PiliMiLe/common/widgets/badge.dart';
import 'package:PiliMiLe/common/widgets/image/image_save.dart';
import 'package:PiliMiLe/common/widgets/image/network_img_layer.dart';
import 'package:PiliMiLe/http/douban.dart';
import 'package:PiliMiLe/models/douban/douban_detail.dart';
import 'package:PiliMiLe/models/search/result.dart';
import 'package:PiliMiLe/utils/platform_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class SearchDramaItem extends StatelessWidget {
  const SearchDramaItem({
    super.key,
    required this.item,
    required this.keyword,
  });

  final SearchDramaItemModel item;
  final String keyword;

  Future<void> _onTap() async {
    SmartDialog.showLoading(msg: '资源获取中...');

    // 1. 获取详情
    final detailResp = await DoubanHttp.getVodDetail(item.vodId);
    if (detailResp['status'] != true || detailResp['data'] == null) {
      SmartDialog.dismiss();
      SmartDialog.showToast(detailResp['msg'] ?? '加载失败');
      return;
    }
    final detail = detailResp['data'] as DoubanVodDetailModel;

    // 2. 自动选第一个可用线路
    DoubanSourceModel? selectedSource;
    for (final src in detail.sources) {
      if (src.decodeStatus == '1') {
        selectedSource = src;
        break;
      }
    }
    selectedSource ??=
        detail.sources.isNotEmpty ? detail.sources.first : null;

    // 3. 解码第一集
    String? m3u8Url;
    if (selectedSource != null && selectedSource.episodes.isNotEmpty) {
      final ep = selectedSource.episodes.first;
      try {
        final decodeResp = await DoubanHttp.decodeVod(
          vodId: item.vodId,
          sid: selectedSource.key,
          nid: ep.nid,
          videoId: ep.videoId,
        );
        if (decodeResp['status'] == true && decodeResp['data'] != null) {
          final result = decodeResp['data'] as DoubanDecodeResultModel;
          if (result.url.isNotEmpty) {
            m3u8Url = result.url;
          }
        }
      } catch (_) {}
    }

    SmartDialog.dismiss();

    if (!Get.context!.mounted) return;

    Get.toNamed('/doubanVideo', arguments: {
      'vodId': item.vodId,
      'vodName': item.vodName,
      'vodPic': item.vodPic,
      'preloadedDetail': detail,
      'preloadedM3u8': m3u8Url,
      'preloadedSourceIndex': selectedSource != null
          ? detail.sources.indexOf(selectedSource)
          : 0,
      'preloadedEpisodeIndex': 0,
    });
  }

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
        onTap: _onTap,
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
