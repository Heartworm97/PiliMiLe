import 'package:PiliMiLe/common/assets.dart';
import 'package:PiliMiLe/common/style.dart';
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Style.imgRadius),
      ),
      builder: (_) => _DoubanEpisodeList(
        episodes: widget.episodes,
        selectedIndex: widget.selectedIndex,
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

/// 全集列表 BottomSheet 内容
class _DoubanEpisodeList extends StatelessWidget {
  const _DoubanEpisodeList({
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
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Text(
                  '全部集数',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '共${episodes.length}集',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPadding + 8),
              itemCount: episodes.length,
              itemBuilder: (_, index) {
                final ep = episodes[index];
                final isSelected = index == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.08)
                        : theme.colorScheme.onInverseSurface,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child: InkWell(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(8)),
                      onTap: () {
                        Navigator.of(context).pop();
                        onSelected(index);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 14,
                        ),
                        child: Row(
                          children: [
                            if (isSelected)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Image.asset(
                                  Assets.livingChart,
                                  color: theme.colorScheme.primary,
                                  height: 16,
                                  cacheHeight: 16.cacheSize(context),
                                ),
                              ),
                            Text(
                              '第${ep.nid}集',
                              style: TextStyle(
                                fontSize: 15,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                                fontWeight:
                                    isSelected ? FontWeight.w600 : null,
                              ),
                            ),
                            const Spacer(),
                            if (ep.title.isNotEmpty &&
                                ep.title != '第${ep.nid}集')
                              Flexible(
                                child: Text(
                                  ep.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme
                                        .colorScheme.onSurface
                                        .withValues(alpha: 0.5),
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
