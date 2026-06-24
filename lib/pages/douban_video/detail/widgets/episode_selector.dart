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
  });

  final List<DoubanEpisodeModel> episodes;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

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
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final playerHeight = mediaQuery.size.width * 9 / 16;
    final maxHeight = screenHeight - playerHeight - mediaQuery.padding.top;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DoubanEpisodePanel(
        episodes: widget.episodes,
        selectedIndex: widget.selectedIndex,
        maxHeight: maxHeight,
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

/// 全集列表，对齐 [EpisodePanel] 风格：toolbar + 竖向列表
class _DoubanEpisodePanel extends StatefulWidget {
  const _DoubanEpisodePanel({
    required this.episodes,
    required this.selectedIndex,
    required this.maxHeight,
    required this.onSelected,
  });

  final List<DoubanEpisodeModel> episodes;
  final int selectedIndex;
  final double maxHeight;
  final ValueChanged<int> onSelected;

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
    final content = SizedBox(
      height: widget.maxHeight,
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
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              Style.safeSpace,
              8,
              Style.safeSpace,
              bottomPadding + 100,
            ),
            itemCount: widget.episodes.length,
            itemBuilder: (_, index) {
              final ep = widget.episodes[index];
              final isCurrent = index == widget.selectedIndex;
              final primary = theme.colorScheme.primary;

              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: SizedBox(
                  height: 60,
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onSelected(index);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Style.safeSpace,
                          vertical: 5,
                        ),
                        child: Row(
                          spacing: 10,
                          children: [
                            if (isCurrent)
                              Image.asset(
                                Assets.livingStatic,
                                color: primary,
                                height: 12,
                                cacheHeight: 12.cacheSize(context),
                                semanticLabel: "正在播放：",
                              ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '第${ep.nid}集',
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                        fontSize: theme
                                            .textTheme.bodyMedium!
                                            .fontSize,
                                        height: 1.42,
                                        letterSpacing: 0.3,
                                        fontWeight:
                                            isCurrent ? FontWeight.bold : null,
                                        color:
                                            isCurrent ? primary : null,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (ep.title.isNotEmpty &&
                                      ep.title != '第${ep.nid}集')
                                    Text(
                                      ep.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1,
                                        color: theme.colorScheme.outline,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
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

    return SafeArea(
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Style.imgRadius),
        child: content,
      ),
    );
  }
}
