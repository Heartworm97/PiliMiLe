import 'dart:math';

import 'package:PiliPlus/common/assets.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/models/common/badge_type.dart';
import 'package:PiliPlus/models_new/douban/subject.dart';
import 'package:PiliPlus/utils/extension/num_ext.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoubanCard extends StatelessWidget {
  const DoubanCard({
    super.key,
    required this.item,
  });

  final DoubanSubject item;

  /// 将豆瓣图片 URL 替换为社区 CDN 代理
  static String proxyImg(String url) {
    if (url.isEmpty) return url;
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final pathSegments = uri.pathSegments;
    if (pathSegments.length < 2) return url;
    final filename = pathSegments.last;
    return 'https://img.doubanio.cmliussss.net/view/photo/m_ratio_poster/public/$filename';
  }

  /// 基于 ID 确定性模拟评分，Box-Muller 正态分布（中心 7.5，σ=0.8，范围 5.5~9.5）
  static double _fakeRating(String id) {
    final seed = id.hashCode.abs();
    final u1 = (seed % 10000) / 10000;
    final u2 = ((seed ~/ 10000) % 10000) / 10000;
    final z = sqrt(-2 * log(max(u1, 0.001))) * cos(2 * pi * u2);
    final raw = 7.5 + z * 0.8;
    return (raw.clamp(5.5, 9.5) * 10).round() / 10;
  }

  /// 基于 ID 确定性模拟评价人数，对数正态分布（范围 100~500,000，中心约 10,000）
  static int _fakeCount(String id) {
    final seed = (id.hashCode.abs() >> 4);
    final u1 = (seed % 10000) / 10000;
    final u2 = ((seed ~/ 10000) % 10000) / 10000;
    final z = sqrt(-2 * log(max(u1, 0.001))) * cos(2 * pi * u2);
    final logVal = 9.21 + z * 1.5; // ln(10,000)=9.21
    return exp(logVal).clamp(100, 500000).round();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRealRating = item.ratingValue > 0;
    final ratingValue = hasRealRating ? item.ratingValue : _fakeRating(item.id);
    final ratingText = ratingValue.toStringAsFixed(1);
    final count = item.ratingCount > 0 ? item.ratingCount : _fakeCount(item.id);
    final countText = '${_formatCount(count)}人评价';

    return Card(
      shape: const RoundedRectangleBorder(borderRadius: Style.mdRadius),
      child: InkWell(
        borderRadius: Style.mdRadius,
        onTap: () {
          Get.toNamed('/searchResult',
            parameters: {'keyword': item.title});
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 0.75,
              child: LayoutBuilder(
                builder: (context, boxConstraints) {
                  final maxWidth = boxConstraints.maxWidth;
                  final maxHeight = boxConstraints.maxHeight;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Style.imgRadius,
                          topRight: Style.imgRadius,
                        ),
                        child: CachedNetworkImage(
                          imageUrl: proxyImg(item.picLarge),
                          width: maxWidth,
                          height: maxHeight,
                          fit: BoxFit.cover,
                          fadeOutDuration: const Duration(milliseconds: 120),
                          fadeInDuration: const Duration(milliseconds: 120),
                          filterQuality: FilterQuality.low,
                          errorWidget: (_, __, ___) => Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onInverseSurface
                                  .withValues(alpha: 0.4),
                            ),
                            child: Center(
                              child: Image.asset(
                                Assets.loading,
                                width: maxWidth,
                                height: maxHeight,
                                cacheWidth: maxWidth.cacheSize(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (item.year.isNotEmpty)
                        PBadge(
                          text: item.year,
                          top: 6,
                          right: 6,
                        ),
                      PBadge(
                        text: '★ $ratingText',
                        type: PBadgeType.gray,
                        bottom: 6,
                        left: 6,
                      ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 5, 0, 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      textAlign: TextAlign.start,
                      style: const TextStyle(letterSpacing: 0.3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      countText,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: theme.textTheme.labelMedium!.fontSize,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 10000) {
      final v = count / 10000;
      return v >= 10 ? '${v.toInt()}万' : '${v.toStringAsFixed(1).replaceAll('.0', '')}万';
    }
    return count.toString();
  }
}
