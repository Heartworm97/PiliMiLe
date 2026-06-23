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
    final available = sources.where((s) => s.decodeStatus != '2' && s.key != 'JD4K').length;
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
            '播放线路（$available/$total 可用）',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sources.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final src = sources[index];
                final isSelected = index == selectedIndex;
                final isAvailable = src.decodeStatus != '2' && src.key != 'JD4K';

                return ChoiceChip(
                  label: Text(
                    src.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: isAvailable ? (_) => onSelected(index) : null,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
