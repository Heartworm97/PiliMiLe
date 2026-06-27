import 'package:PiliMiLe/models/douban/douban_detail.dart';
import 'package:flutter/material.dart';

class SourceSelector extends StatefulWidget {
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
  State<SourceSelector> createState() => _SourceSelectorState();
}

class _SourceSelectorState extends State<SourceSelector> {
  late final ScrollController _scrollCtr;
  late List<int> _sortedIndices;

  @override
  void initState() {
    super.initState();
    _sortedIndices = _buildSortedIndices();
    final selectedDisplayIndex = _sortedIndices.indexOf(widget.selectedIndex);
    _scrollCtr = ScrollController(
      initialScrollOffset: (selectedDisplayIndex >= 0 ? selectedDisplayIndex : 0) * 110.0,
    );
  }

  @override
  void didUpdateWidget(covariant SourceSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      final displayIndex = _sortedIndices.indexOf(widget.selectedIndex);
      if (displayIndex >= 0) _scrollTo(displayIndex);
    }
  }

  @override
  void dispose() {
    _scrollCtr.dispose();
    super.dispose();
  }

  List<int> _buildSortedIndices() {
    final indices = List.generate(widget.sources.length, (i) => i);
    indices.sort((a, b) {
      final aAvailable = widget.sources[a].decodeStatus != '2' &&
          widget.sources[a].key != 'JD4K' &&
          widget.sources[a].key != 'NBY';
      final bAvailable = widget.sources[b].decodeStatus != '2' &&
          widget.sources[b].key != 'JD4K' &&
          widget.sources[b].key != 'NBY';
      if (aAvailable == bAvailable) return 0;
      return aAvailable ? -1 : 1;
    });
    return indices;
  }

  void _scrollTo(int displayIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtr.hasClients) return;
      final viewport = _scrollCtr.position.viewportDimension;
      final offset = (displayIndex * 110.0) - (viewport - 100) / 2;
      _scrollCtr.animateTo(
        offset.clamp(
          _scrollCtr.position.minScrollExtent,
          _scrollCtr.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedIndices = _sortedIndices;
    final available = _sortedIndices
        .where((i) => widget.sources[i].decodeStatus != '2' && widget.sources[i].key != 'JD4K' && widget.sources[i].key != 'NBY')
        .length;
    final total = widget.sources.length;

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
              controller: _scrollCtr,
              itemCount: _sortedIndices.length,
              itemBuilder: (context, displayIndex) {
                final originalIndex = _sortedIndices[displayIndex];
                final src = widget.sources[originalIndex];
                final isSelected = originalIndex == widget.selectedIndex;
                final isAvailable = src.decodeStatus != '2' && src.key != 'JD4K' && src.key != 'NBY';
                final isBuiltin = !src.key.startsWith('site_');
                final isBBBlueRay = src.name == 'BB蓝光';
                final indicatorColor = !isAvailable
                    ? Colors.red
                    : isBBBlueRay
                        ? Colors.blueAccent
                        : isBuiltin
                            ? Colors.green
                            : Colors.orange;

                final textColor = !isAvailable
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                    : isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface;

                return Container(
                  width: 100,
                  height: 48,
                  margin: displayIndex != _sortedIndices.length - 1
                      ? const EdgeInsets.only(right: 10)
                      : null,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                    border: Border.all(
                      color: isSelected && isAvailable
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Material(
                    color: isSelected && isAvailable
                        ? theme.colorScheme.primary.withValues(alpha: 0.08)
                        : theme.colorScheme.onInverseSurface,
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                    child: InkWell(
                      borderRadius: const BorderRadius.all(Radius.circular(6)),
                      onTap: isAvailable
                          ? () {
                              _scrollTo(displayIndex);
                              widget.onSelected(originalIndex);
                            }
                          : null,
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
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: indicatorColor,
                                  shape: BoxShape.circle,
                                  boxShadow: isBBBlueRay && isAvailable
                                      ? [
                                          BoxShadow(
                                            color: Colors.amber.withValues(alpha: 0.7),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
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
