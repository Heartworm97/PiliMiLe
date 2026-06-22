import 'package:PiliMiLe/common/style.dart';
import 'package:PiliMiLe/common/widgets/badge.dart';
import 'package:PiliMiLe/common/widgets/image/network_img_layer.dart';
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
    const TextStyle style = TextStyle(fontSize: 13);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () {
          // TODO: navigate to drama detail page
        },
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
                    Text(
                      item.vodName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (item.typeName.isNotEmpty || item.vodArea.isNotEmpty)
                      Text(
                        [item.typeName, item.vodArea]
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                        style: style,
                      ),
                    if (item.vodActor.isNotEmpty)
                      Text(item.vodActor, maxLines: 2, style: style),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
