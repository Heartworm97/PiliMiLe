import 'package:PiliMiLe/common/assets.dart';
import 'package:PiliMiLe/common/style.dart';
import 'package:PiliMiLe/common/widgets/button/icon_button.dart';
import 'package:PiliMiLe/models/douban/douban_detail.dart';
import 'package:PiliMiLe/utils/extension/num_ext.dart';
import 'package:flutter/material.dart';

class EpisodeSelector extends StatefulWidget {
  const EpisodeSelector({
    super.key,
    required this.episodes,
    required this.selectedIndex,
    required this.onSelected,
    this.maxPanelHeight,
  });

  final List<DoubanEpisodeModel> episodes;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double? maxPanelHeight;

  @override
  State<EpisodeSelector> createState() => _EpisodeSelectorState();
}

class _EpisodeSelectorState extends State<EpisodeSelector> {
  late final ScrollController _scrollCtr;

  @override
  void initState() {
    super.initState();
    _scrollCtr = ScrollController(
      initialScrollOffset: widget.selectedIndex * 140.0,
    );
  }

  @override
  void didUpdateWidget(covariant EpisodeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _scrollTo(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _scrollCtr.dispose();
    super.dispose();
  }

  void _scrollTo(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtr.hasClients) return;
      final viewport = _scrollCtr.position.viewportDimension;
      final offset = (index * 140.0) - (viewport - 130) / 2;
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

  void _showEpisodePanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DoubanEpisodePanel(
        episodes: widget.episodes,
        selectedIndex: widget.selectedIndex,
        maxPanelHeight: widget.maxPanelHeight,
        onSelected: (index) {
          _scrollTo(index);
          widget.onSelected(index);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.episodes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '选集 ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '正在播放：第${widget.episodes[widget.selectedIndex].nid}集',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 34,
                    child: TextButton(
                      style: const ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.zero),
                      ),
                      onPressed: _showEpisodePanel,
                      child: Text(
                        '共${widget.episodes.length}集',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              controller: _scrollCtr,
              itemCount: widget.episodes.length,
              itemBuilder: (context, index) {
                final ep = widget.episodes[index];
                final isSelected = index == widget.selectedIndex;

                return Container(
                  width: 130,
                  height: 48,
                  margin: index != widget.episodes.length - 1
                      ? const EdgeInsets.only(right: 10)
                      : null,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Material(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.08)
                        : theme.colorScheme.onInverseSurface,
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                    child: InkWell(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(6)),
                      onTap: () {
                        _scrollTo(index);
                        widget.onSelected(index);
                      },
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
                                      padding:
                                          const EdgeInsets.only(right: 6),
                                      child: Image.asset(
                                        Assets.livingChart,
                                        color: theme.colorScheme.primary,
                                        height: 16,
                                        cacheHeight:
                                            16.cacheSize(context),
                                      ),
                                    ),
                                  ),
                                TextSpan(
                                  text: '第${ep.nid}集',
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

/// 全集列表，对齐番剧 EpisodePanel 风格：固定 70% 屏高 + toolbar + 竖向列表
class _DoubanEpisodePanel extends StatefulWidget {
  const _DoubanEpisodePanel({
    required this.episodes,
    required this.selectedIndex,
    required this.onSelected,
    this.maxPanelHeight,
  });

  final List<DoubanEpisodeModel> episodes;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double? maxPanelHeight;

  @override
  State<_DoubanEpisodePanel> createState() => _DoubanEpisodePanelState();
}

class _DoubanEpisodePanelState extends State<_DoubanEpisodePanel> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrent();
    });
  }

  void _scrollToCurrent() {
    if (!_scrollController.hasClients) return;
    final offset = widget.selectedIndex * 60.0;
    final maxScroll = _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo(offset.clamp(0.0, maxScroll));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;
    final maxHeight =
        widget.maxPanelHeight ?? MediaQuery.of(context).size.height * 0.55;
    final panelHeight = maxHeight.clamp(150.0, maxHeight);

    final content = SizedBox(
      height: panelHeight,
      child: Column(
        children: [
          // toolbar — 对齐 EpisodePanel._buildToolbar
          Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '选集',
                  style: theme.textTheme.titleMedium,
                ),
                iconButton(
                  iconSize: 22,
                  tooltip: '跳至当前',
                  icon: const Icon(Icons.my_location),
                  onPressed: _scrollToCurrent,
                ),
                const Spacer(),
                Text(
                  '共${widget.episodes.length}集',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                iconButton(
                  iconSize: 22,
                  tooltip: '关闭',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                Style.safeSpace,
                8,
                Style.safeSpace,
                bottomPadding + 100,
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(widget.episodes.length, (index) {
                  final ep = widget.episodes[index];
                  final isCurrent = index == widget.selectedIndex;
                  final primary = theme.colorScheme.primary;

                  return SizedBox(
                    width: 90,
                    height: 36,
                    child: Material(
                      color: isCurrent
                          ? primary.withValues(alpha: 0.12)
                          : theme.colorScheme.onInverseSurface,
                      borderRadius: BorderRadius.circular(6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onSelected(index);
                        },
                        child: Center(
                          child: Text(
                            '第${ep.nid}集',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isCurrent ? FontWeight.bold : null,
                              color: isCurrent ? primary : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );

    return Material(
      color: theme.colorScheme.surface,
      child: content,
    );
  }
}
