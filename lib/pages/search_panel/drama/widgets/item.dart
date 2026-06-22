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
    return Card(
      elevation: 0,
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {
          // TODO: navigate to drama detail page
        },
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: AspectRatio(
                aspectRatio: 0.65,
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    children: [
                      NetworkImgLayer(
                        src: item.vodPic,
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                      ),
                      if (item.vodYear.isNotEmpty)
                        PBadge(
                          text: item.vodYear,
                          top: 6,
                          right: 6,
                          bottom: null,
                          left: null,
                        ),
                      if (item.vodRemarks.isNotEmpty)
                        PBadge(
                          text: item.vodRemarks,
                          top: null,
                          right: null,
                          bottom: 6,
                          left: 6,
                          type: PBadgeType.gray,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 5, 0, 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.vodName,
                      textAlign: TextAlign.start,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        if (item.typeName.isNotEmpty)
                          Flexible(
                            child: Text(
                              item.typeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: theme.textTheme.labelMedium!.fontSize,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ),
                        if (item.vodArea.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              item.vodArea,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: theme.textTheme.labelMedium!.fontSize,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ),
                        ],
                      ],
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
}
