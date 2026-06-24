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
    final available = sources.where((s) => s.decodeStatus != '2' && s.key != 'JD4K' && s.key != 'NBY').length;
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
              itemCount: sources.length,
              itemBuilder: (context, index) {
                final src = sources[index];
                final isSelected = index == selectedIndex;
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
                  margin: index != sources.length - 1
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
                      onTap: isAvailable ? () => onSelected(index) : null,
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
                              left: 0,
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
