import 'dart:math';

import 'package:PiliMiLe/common/style.dart';
import 'package:PiliMiLe/common/widgets/button/more_btn.dart';
import 'package:PiliMiLe/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliMiLe/common/widgets/loading_widget/http_error.dart';
import 'package:PiliMiLe/common/widgets/loading_widget/m3e_loading_indicator.dart';
import 'package:PiliMiLe/common/widgets/loading_widget/morphs.dart';
import 'package:PiliMiLe/common/widgets/scroll_physics.dart';
import 'package:PiliMiLe/common/widgets/view_safe_area.dart';
import 'package:PiliMiLe/http/loading_state.dart';
import 'package:PiliMiLe/models/common/fav_type.dart';
import 'package:PiliMiLe/models/common/home_tab_type.dart';
import 'package:PiliMiLe/models_new/douban/subject.dart';
import 'package:PiliMiLe/models_new/fav/fav_pgc/list.dart';
import 'package:PiliMiLe/models_new/pgc/pgc_index_result/list.dart';
import 'package:PiliMiLe/models_new/pgc/pgc_timeline/result.dart';
import 'package:PiliMiLe/pages/pgc/controller.dart';
import 'package:PiliMiLe/pages/pgc/widgets/douban_card.dart';
import 'package:PiliMiLe/pages/pgc/widgets/douban_subject_list.dart';
import 'package:PiliMiLe/pages/pgc/widgets/pgc_card_v.dart';
import 'package:PiliMiLe/pages/pgc/widgets/pgc_card_v_timeline.dart';
import 'package:PiliMiLe/pages/pgc_index/controller.dart';
import 'package:PiliMiLe/pages/pgc_index/view.dart';
import 'package:PiliMiLe/pages/pgc_index/widgets/pgc_card_v_pgc_index.dart';
import 'package:PiliMiLe/utils/extension/iterable_ext.dart';
import 'package:PiliMiLe/utils/grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class PgcPage extends StatefulWidget {
  const PgcPage({
    super.key,
    required this.tabType,
  });

  final HomeTabType tabType;

  @override
  State<PgcPage> createState() => _PgcPageState();
}

class _PgcPageState extends State<PgcPage> with AutomaticKeepAliveClientMixin {
  late final PgcController controller;
  late final _randomMorphs = Morphs.randomMorphs();

  @override
  void initState() {
    controller = Get.put(
      PgcController(tabType: widget.tabType),
      tag: widget.tabType.name,
    );
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (controller.isDrama) {
      return Obx(() {
        final morphsDone = controller.initialMorphCount.value >= 4;
        final isInitialLoading =
            !morphsDone ||
            (controller.dramaMovieState.value is Loading &&
                controller.dramaTvState.value is Loading &&
                controller.dramaAnimationState.value is Loading &&
                controller.dramaShowState.value is Loading);
        if (isInitialLoading) {
          return Center(
            child: M3ELoadingIndicator(
              morphs: _randomMorphs,
              size: const Size.square(72),
              onMorphCompleted: () => controller.initialMorphCount.value++,
            ),
          );
        }
        return _buildDramaContent(context);
      });
    }
    return Obx(() {
      final morphsDone = controller.initialMorphCount.value >= 4;
      final isInitialLoading =
          !morphsDone ||
          (controller.followState.value is Loading &&
           controller.loadingState.value is Loading &&
           (!controller.showPgcTimeline || controller.timelineState.value is Loading));
      if (isInitialLoading) {
        return Center(
          child: M3ELoadingIndicator(
            morphs: _randomMorphs,
            size: const Size.square(72),
            onMorphCompleted: () => controller.initialMorphCount.value++,
          ),
        );
      }
      return _buildContent(context);
    });
  }

  Widget _buildDramaContent(BuildContext context) {
    final theme = Theme.of(context);
    return refreshIndicator(
      onRefresh: controller.onRefresh,
      child: CustomScrollView(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
        _buildDramaRecord(theme),
        _buildDramaSection(
          theme: theme,
          title: '热门电影',
          state: controller.dramaMovieState,
          kind: 'movie',
          params: {'category': '热门', 'type': '全部'},
        ),
        _buildDramaSection(
          theme: theme,
          title: '热门剧集',
          state: controller.dramaTvState,
          kind: 'tv',
          params: {'category': 'tv', 'type': 'tv'},
        ),
        _buildDramaSection(
          theme: theme,
          title: '热门动漫',
          state: controller.dramaAnimationState,
          kind: 'tv',
          params: {'category': 'tv', 'type': 'tv_animation'},
        ),
        _buildDramaSection(
          theme: theme,
          title: '热门综艺',
          state: controller.dramaShowState,
          kind: 'tv',
          params: {'category': 'tv', 'type': 'show'},
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 24,
              bottom: 12,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.outline.withAlpha(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          TextSpan(
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                              height: 1.5,
                            ),
                            children: const [
                              TextSpan(
                                text: '本APP当前页面所有视频、影视短片、短视频等多媒体资源，均通过互联网公开网络渠道',
                              ),
                              TextSpan(
                                text: '自动抓取、采集整理而来',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              TextSpan(
                                text: '。平台仅作为内容信息展示浏览工具，',
                              ),
                              TextSpan(
                                text: '不参与原作品录制、制作、发行',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              TextSpan(
                                text: '，',
                              ),
                              TextSpan(
                                text: '不拥有任何素材的著作权、传播授权等相关版权权益',
                              ),
                              TextSpan(text: '。'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '— PiliMiLe / 月光下的黑驴子',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.primary,
                              fontSize: 12,
                            ),
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
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
      ),
    );
  }

  Widget _buildDramaRecord(ThemeData theme) {
    final cardWidth = Grid.smallCardWidth / 2;
    final cardHeight = cardWidth / 0.75;
    const textHeight = 50.0;
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 10,
              bottom: 10,
              left: 16,
              right: 10,
            ),
            child: Row(
              children: [
                Text(
                  '追剧记录',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  tooltip: '刷新',
                  onPressed: () =>
                      SmartDialog.showToast('功能开发中，敬请期待'),
                  icon: const Icon(Icons.refresh, size: 20),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: moreTextButton(
                    text: '查看全部',
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    color: theme.colorScheme.secondary,
                    onTap: () =>
                        SmartDialog.showToast('功能开发中，敬请期待'),
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            return switch (controller.dramaRecordState.value) {
              Success(:final response) when response.isNotEmpty =>
                SizedBox(
                  height: cardHeight +
                      MediaQuery.textScalerOf(context).scale(textHeight),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: response.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      return Container(
                        width: cardWidth,
                        margin: EdgeInsets.only(
                          left: Style.safeSpace,
                          right: index == response.length - 1
                              ? Style.safeSpace
                              : 0,
                        ),
                        child: PgcCardV(item: response[index]),
                      );
                    },
                  ),
                ),
              _ => const SizedBox.shrink(),
            };
          }),
        ],
      ),
    );
  }

  Widget _buildDramaSection({
    required ThemeData theme,
    required String title,
    required Rx<LoadingState<List<DoubanSubject>>> state,
    required String kind,
    required Map<String, dynamic> params,
  }) {
    final cardWidth = Grid.smallCardWidth / 2;
    final cardHeight = cardWidth / 0.75;
    const textHeight = 50.0;
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 10,
              bottom: 10,
              left: 16,
              right: 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium,
                ),
                moreTextButton(
                  text: '查看全部',
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  color: theme.colorScheme.secondary,
                  onTap: () {
                    Get.to(
                      DoubanSubjectListPage(
                        title: title,
                        kind: kind,
                        params: params,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Obx(() {
            return switch (state.value) {
              Success(:final response) when response.isNotEmpty =>
                SizedBox(
                  height: cardHeight +
                      MediaQuery.textScalerOf(context).scale(textHeight),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: response.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      return Container(
                        width: cardWidth,
                        margin: EdgeInsets.only(
                          left: Style.safeSpace,
                          right:
                              index == response.length - 1 ? Style.safeSpace : 0,
                        ),
                        child: DoubanCard(item: response[index]),
                      );
                    },
                  ),
                ),
              Error(:final errMsg) =>
                HttpError(isSliver: false, errMsg: errMsg, onReload: controller.onRefresh),
              _ => const SizedBox.shrink(),
            };
          }),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return refreshIndicator(
      onRefresh: controller.onRefresh,
      child: CustomScrollView(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildFollow(theme),
          if (controller.showPgcTimeline)
            SliverToBoxAdapter(
              child: SizedBox(
                height:
                    Grid.smallCardWidth / 2 / 0.75 +
                    MediaQuery.textScalerOf(context).scale(96),
                child: Obx(
                  () => _buildTimeline(theme, controller.timelineState.value),
                ),
              ),
            ),
          ..._buildRcmd(theme),
        ],
      ),
    );
  }

  Widget _buildTimeline(
    ThemeData theme,
    LoadingState<List<TimelineResult>?> loadingState,
  ) => switch (loadingState) {
    Loading() => const SizedBox.shrink(),
    Success(:final response) =>
      response != null && response.isNotEmpty
          ? Builder(
              builder: (context) {
                final initialIndex = max(
                  0,
                  response.indexWhere((item) => item.isToday == 1),
                );
                return DefaultTabController(
                  initialIndex: initialIndex,
                  length: response.length,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 16),
                          Text(
                            '追番时间表',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TabBar(
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              dividerHeight: 0,
                              overlayColor: const WidgetStatePropertyAll(
                                Colors.transparent,
                              ),
                              splashFactory: NoSplash.splashFactory,
                              padding: const EdgeInsets.only(right: 10),
                              indicatorPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 10,
                              ),
                              indicator: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelColor:
                                  theme.colorScheme.onSecondaryContainer,
                              labelStyle:
                                  TabBarTheme.of(
                                    context,
                                  ).labelStyle?.copyWith(fontSize: 14) ??
                                  const TextStyle(fontSize: 14),
                              dividerColor: Colors.transparent,
                              tabs: response.map(
                                (item) {
                                  return Tab(
                                    text:
                                        '${item.date} ${item.isToday == 1 ? '今天' : '周${const [
                                                '一',
                                                '二',
                                                '三',
                                                '四',
                                                '五',
                                                '六',
                                                '日',
                                              ][item.dayOfWeek! - 1]}'}',
                                  );
                                },
                              ).toList(),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          physics: const NeverScrollableScrollPhysics(),
                          children: response.map((item) {
                            if (item.episodes.isNullOrEmpty) {
                              return const SizedBox.shrink();
                            }
                            return ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              itemCount: item.episodes!.length,
                              padding: EdgeInsets.zero,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: Grid.smallCardWidth / 2,
                                  margin: EdgeInsets.only(
                                    left: Style.safeSpace,
                                    right: index == item.episodes!.length - 1
                                        ? Style.safeSpace
                                        : 0,
                                  ),
                                  child: PgcCardVTimeline(
                                    item: item.episodes![index],
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          : const SizedBox.shrink(),
    Error(:final errMsg) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: controller.queryPgcTimeline,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        child: Text(
          errMsg ?? '',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  };

  List<Widget> _buildRcmd(ThemeData theme) => [
    _buildRcmdTitle(theme),
    SliverPadding(
      padding: const EdgeInsets.only(
        left: Style.safeSpace,
        right: Style.safeSpace,
        bottom: 100,
      ),
      sliver: Obx(
        () => _buildRcmdBody(controller.loadingState.value),
      ),
    ),
  ];

  Widget _buildRcmdTitle(ThemeData theme) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.only(
        top: 10,
        bottom: 10,
        left: 16,
        right: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '推荐',
            style: theme.textTheme.titleMedium,
          ),
          moreTextButton(
            padding: const EdgeInsets.symmetric(vertical: 2),
            onTap: () {
              if (widget.tabType == HomeTabType.bangumi) {
                Get.to(const PgcIndexPage());
              } else {
                List<String> titles = const [
                  '全部',
                  '电影',
                  '电视剧',
                  '纪录片',
                  '综艺',
                ];
                List<int> types = const [102, 2, 5, 3, 7];
                Get.to(
                  Scaffold(
                    resizeToAvoidBottomInset: false,
                    appBar: AppBar(title: const Text('索引')),
                    body: DefaultTabController(
                      length: types.length,
                      child: Builder(
                        builder: (context) {
                          return Column(
                            children: [
                              ViewSafeArea(
                                child: TabBar(
                                  tabs: titles
                                      .map((title) => Tab(text: title))
                                      .toList(),
                                  onTap: (index) {
                                    try {
                                      if (!DefaultTabController.of(
                                        context,
                                      ).indexIsChanging) {
                                        Get.find<PgcIndexController>(
                                          tag: types[index].toString(),
                                        ).animateToTop();
                                      }
                                    } catch (_) {}
                                  },
                                ),
                              ),
                              Expanded(
                                child: tabBarView(
                                  children: types
                                      .map(
                                        (type) => PgcIndexPage(indexType: type),
                                      )
                                      .toList(),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                );
              }
            },
            color: theme.colorScheme.secondary,
          ),
        ],
      ),
    ),
  );

  late final gridDelegate = SliverGridDelegateWithExtentAndRatio(
    mainAxisSpacing: Style.cardSpace,
    crossAxisSpacing: Style.cardSpace,
    maxCrossAxisExtent: Grid.smallCardWidth * 0.6,
    childAspectRatio: 0.75,
    mainAxisExtent: MediaQuery.textScalerOf(context).scale(50),
  );

  Widget _buildRcmdBody(LoadingState<List<PgcIndexItem>?> loadingState) {
    return switch (loadingState) {
      Loading() => const SliverToBoxAdapter(),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    controller.onLoadMore();
                  }
                  return PgcCardVPgcIndex(item: response[index]);
                },
                itemCount: response.length,
              )
            : HttpError(onReload: controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: controller.onReload,
      ),
    };
  }

  Widget _buildFollow(ThemeData theme) => SliverToBoxAdapter(
    child: Obx(
      () => controller.accountService.isLogin.value
          ? Column(
              children: [
                _buildFollowTitle(theme),
                SizedBox(
                  height:
                      Grid.smallCardWidth / 2 / 0.75 +
                      MediaQuery.textScalerOf(context).scale(50),
                  child: Obx(
                    () => _buildFollowBody(controller.followState.value),
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    ),
  );

  Widget _buildFollowTitle(ThemeData theme) => Padding(
    padding: const EdgeInsets.only(left: 16),
    child: Row(
      children: [
        Obx(
          () => Text(
            '最近${widget.tabType == HomeTabType.bangumi ? '追番' : '追剧'}${controller.followCount.value == -1 ? '' : ' ${controller.followCount.value}'}',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: '刷新',
          onPressed: () => controller
            ..followPage = 1
            ..followEnd = false
            ..queryPgcFollow(),
          icon: const Icon(
            Icons.refresh,
            size: 20,
          ),
        ),
        Obx(
          () => controller.accountService.isLogin.value
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: moreTextButton(
                    text: '查看全部',
                    onTap: () => Get.toNamed(
                      '/fav',
                      arguments: widget.tabType == HomeTabType.bangumi
                          ? FavTabType.bangumi.index
                          : FavTabType.cinema.index,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: theme.colorScheme.secondary,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    ),
  );

  Widget _buildFollowBody(LoadingState<List<FavPgcItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => const SizedBox.shrink(),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? ListView.builder(
                controller: controller.followController,
                scrollDirection: Axis.horizontal,
                itemCount: response.length,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    controller.queryPgcFollow(false);
                  }
                  return Container(
                    width: Grid.smallCardWidth / 2,
                    margin: EdgeInsets.only(
                      left: Style.safeSpace,
                      right: index == response.length - 1 ? Style.safeSpace : 0,
                    ),
                    child: PgcCardV(item: response[index]),
                  );
                },
              )
            : Center(
                child: Text(
                  '还没有${widget.tabType == HomeTabType.bangumi ? '追番' : '追剧'}',
                ),
              ),
      Error(:final errMsg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        child: Text(
          errMsg ?? '',
          textAlign: TextAlign.center,
        ),
      ),
    };
  }
}
