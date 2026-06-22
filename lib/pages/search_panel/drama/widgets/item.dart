import 'package:PiliMiLe/common/widgets/badge.dart';
import 'package:PiliMiLe/common/widgets/image/network_img_layer.dart';
import 'package:PiliMiLe/models/common/badge_type.dart';
import 'package:PiliMiLe/models/search/result.dart';
import 'package:flutter/material.dart';

class SearchDramaItem extends StatelessWidget {
  const SearchDramaItem({
    super.key,
    required this.item,
  });

  final SearchDramaItemModel item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () {
          // TODO: navigate to drama detail page
        },
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: Stack(
                children: [
                  NetworkImgLayer(
                    src: item.vodPic,
                    width: 108,
                    height: 144,
                  ),
                  if (item.vodYear.isNotEmpty)
                    PBadge(
                      text: item.vodYear,
                      top: 4,
                      right: 4,
                      bottom: null,
                      left: null,
                    ),
                  if (item.vodRemarks.isNotEmpty)
                    PBadge(
                      text: item.vodRemarks,
                      top: null,
                      right: null,
                      bottom: 4,
                      left: 4,
                      type: PBadgeType.gray,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.vodName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (item.typeName.isNotEmpty || item.vodArea.isNotEmpty)
                    Text(
                      [item.typeName, item.vodArea].where((s) => s.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: theme.textTheme.labelMedium!.fontSize,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  if (item.vodActor.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.vodActor,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: theme.textTheme.labelMedium!.fontSize,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
