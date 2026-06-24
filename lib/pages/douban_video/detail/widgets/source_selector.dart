import 'package:PiliMiLe/models/douban/douban_detail.dart';
import 'package:flutter/material.dart';

class SourceSelector extends StatelessWidget {
  const SourceSelector({
    super.key,
    required this.sources,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<DoubanSourceModel> sources;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 可用在前，被禁止在后
    final sortedIndices = List.generate(sources.length, (i) => i);
    sortedIndices.sort((a, b) {
      final aAvailable =
          sources[a].decodeStatus != '2' && sources[a].key != 'JD4K' && sources[a].key != 'NBY';
      final bAvailable =
          sources[b].decodeStatus != '2' && sources[b].key != 'JD4K' && sources[b].key != 'NBY';
      if (aAvailable == bAvailable) return 0;
      return aAvailable ? -1 : 1;
    });
    final available = sortedIndices
        .where((i) => sources[i].decodeStatus != '2' && sources[i].key != 'JD4K' && sources[i].key != 'NBY')
        .length;
    final total = sources.length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: '换源',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: '（$available/$total 可用）',
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
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sortedIndices.length,
              itemBuilder: (context, displayIndex) {
                final originalIndex = sortedIndices[displayIndex];
                final src = sources[originalIndex];
                final isSelected = originalIndex == selectedIndex;
                final isAvailable = src.decodeStatus != '2' && src.key != 'JD4K' && src.key != 'NBY';
                final isBuiltin = !src.key.startsWith('site_');
                final indicatorColor = !isAvailable
                    ? Colors.red
                    : isBuiltin
                        ? Colors.green
                        : Colors.orange;

                final textColor = isAvailable
                    ? isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withValues(alpha: 0.38);

                return Container(
                  width: 130,
                  height: 48,
                  margin: displayIndex != sortedIndices.length - 1
                      ? const EdgeInsets.only(right: 10)
                      : null,
                  decoration: isSelected && isAvailable
                      ? BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(6)),
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          ),
                        )
                      : null,
                  child: Material(
                    color: isSelected && isAvailable
                        ? theme.colorScheme.primary.withValues(alpha: 0.08)
                        : theme.colorScheme.onInverseSurface,
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                    child: InkWell(
                      borderRadius: const BorderRadius.all(Radius.circular(6)),
                      onTap: isAvailable ? () => onSelected(originalIndex) : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 10,
                        ),
                        child: Stack(
                          children: [
                            Align(
                              child: Text(
                                src.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textColor,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: indicatorColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
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
