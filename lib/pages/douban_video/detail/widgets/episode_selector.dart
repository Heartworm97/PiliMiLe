import 'package:PiliMiLe/common/assets.dart';
import 'package:PiliMiLe/models/douban/douban_detail.dart';
import 'package:PiliMiLe/utils/extension/num_ext.dart';
import 'package:flutter/material.dart';

class EpisodeSelector extends StatelessWidget {
  const EpisodeSelector({
    super.key,
    required this.episodes,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<DoubanEpisodeModel> episodes;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: '选集',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (episodes.isNotEmpty)
                  TextSpan(
                    text: ' 正在播放：${episodes[selectedIndex].title}',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: episodes.length,
              itemBuilder: (context, index) {
                final ep = episodes[index];
                final isSelected = index == selectedIndex;

                return Container(
                  width: 150,
                  height: 60,
                  margin: index != episodes.length - 1
                      ? const EdgeInsets.only(right: 10)
                      : null,
                  child: Material(
                    color: theme.colorScheme.onInverseSurface,
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                    child: InkWell(
                      borderRadius: const BorderRadius.all(Radius.circular(6)),
                      onTap: () => onSelected(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 10,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                if (isSelected)
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: Image.asset(
                                        Assets.livingChart,
                                        color: theme.colorScheme.primary,
                                        height: 16,
                                        cacheHeight: 16.cacheSize(context),
                                      ),
                                    ),
                                  ),
                                TextSpan(
                                  text: ep.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
