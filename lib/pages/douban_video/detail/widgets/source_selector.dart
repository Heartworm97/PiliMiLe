import 'package:PiliMiLe/common/style.dart';
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
      padding: const EdgeInsets.symmetric(
        horizontal: Style.safeSpace,
        vertical: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '播放源（$available/$total 可用）',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: List.generate(sources.length, (index) {
              final src = sources[index];
              final isSelected = index == selectedIndex;
              final isAvailable = src.decodeStatus != '2' && src.key != 'JD4K' && src.key != 'NBY';

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: isAvailable ? () => onSelected(index) : null,
                child: Text(
                  src.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isAvailable
                        ? isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
