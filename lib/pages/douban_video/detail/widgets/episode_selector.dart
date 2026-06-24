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

/// 全集列表弹窗：TabBar 分段 + 横排按钮网格 + 正序/倒序切换
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

class _DoubanEpisodePanelState extends State<_DoubanEpisodePanel>
    with SingleTickerProviderStateMixin {
  static const _segmentSize = 50;

  late final TabController _tabController;
  int _segmentCount = 1;
  bool _isReversed = false;

  List<DoubanEpisodeModel> get _orderedEpisodes => _isReversed
      ? widget.episodes.reversed.toList()
      : widget.episodes;

  int _globalIndex(int displayIndex, int baseIndex) =>
      _isReversed ? widget.episodes.length - 1 - (baseIndex + displayIndex) : baseIndex + displayIndex;

  @override
  void initState() {
    super.initState();
    _initTab();
  }

  void _initTab() {
    _segmentCount = (widget.episodes.length / _segmentSize).ceil();
    final initialDisplayIndex = _isReversed
        ? widget.episodes.length - 1 - widget.selectedIndex
        : widget.selectedIndex;
    final initialSegment = initialDisplayIndex ~/ _segmentSize;
    _tabController = TabController(
      length: _segmentCount,
      vsync: this,
      initialIndex: initialSegment.clamp(0, _segmentCount - 1),
    );
  }

  void _toggleOrder() {
    setState(() {
      _isReversed = !_isReversed;
      _tabController.dispose();
      _initTab();
    });
  }

  void _jumpToCurrent() {
    final displayIndex = _isReversed
        ? widget.episodes.length - 1 - widget.selectedIndex
        : widget.selectedIndex;
    final seg = displayIndex ~/ _segmentSize;
    if (seg < _segmentCount) {
      _tabController.animateTo(seg);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;
    final maxHeight =
        widget.maxPanelHeight ?? MediaQuery.of(context).size.height * 0.55;
    final panelHeight = maxHeight.clamp(150.0, maxHeight);
    final showSegments = widget.episodes.length > _segmentSize;

    final allEpisodes = _orderedEpisodes;
    final segments = <_EpisodeSegment>[];
    for (int i = 0; i < allEpisodes.length; i += _segmentSize) {
      final end = (i + _segmentSize).clamp(0, allEpisodes.length);
      segments.add(_EpisodeSegment(
        start: i + 1,
        end: end,
        episodes: allEpisodes.sublist(i, end),
        baseIndex: i,
      ));
    }

    final content = SizedBox(
      height: panelHeight,
      child: Column(
        children: [
          // toolbar
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
                Text('选集', style: theme.textTheme.titleMedium),
                const Spacer(),
                iconButton(
                  iconSize: 22,
                  tooltip: _isReversed ? '当前倒序，点击切换正序' : '当前正序，点击切换倒序',
                  icon: Icon(
                    _isReversed ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 18,
                  ),
                  onPressed: _toggleOrder,
                ),
                iconButton(
                  iconSize: 22,
                  tooltip: '跳至当前',
                  icon: const Icon(Icons.my_location),
                  onPressed: _jumpToCurrent,
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
          // 分段 TabBar
          if (showSegments)
            SizedBox(
              height: 40,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(fontSize: 13),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                tabs: segments
                    .map((s) => Tab(text: '${s.start}-${s.end}'))
                    .toList(),
              ),
            ),
          // 分隔符
          if (showSegments)
            Divider(
              height: 1,
              thickness: 1,
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: segments.map((seg) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    Style.safeSpace,
                    8,
                    Style.safeSpace,
                    bottomPadding + 100,
                  ),
                  child: _buildEpisodeGrid(theme, seg),
                );
              }).toList(),
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

  Widget _buildEpisodeGrid(ThemeData theme, _EpisodeSegment seg) {
    final primary = theme.colorScheme.primary;
    const crossAxisCount = 5;
    const spacing = 10.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
                crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: seg.episodes.asMap().entries.map((entry) {
            final globalIndex =
                _globalIndex(entry.key, seg.baseIndex);
            final isCurrent = globalIndex == widget.selectedIndex;

            return SizedBox(
              width: itemWidth,
              height: 45,
              child: Material(
                color: isCurrent
                    ? primary.withValues(alpha: 0.08)
                    : theme.colorScheme.onInverseSurface,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onSelected(globalIndex);
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: isCurrent
                          ? Border.all(color: primary, width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '第${entry.value.nid}集',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.bold : null,
                          color: isCurrent ? primary : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _EpisodeSegment {
  const _EpisodeSegment({
    required this.start,
    required this.end,
    required this.episodes,
    required this.baseIndex,
  });
  final int start;
  final int end;
  final List<DoubanEpisodeModel> episodes;
  final int baseIndex;
}
