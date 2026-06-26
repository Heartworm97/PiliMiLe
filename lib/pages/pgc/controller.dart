import 'package:PiliMiLe/http/douban.dart';
import 'package:PiliMiLe/models/douban/douban_detail.dart';
import 'package:PiliMiLe/http/fav.dart';
import 'package:PiliMiLe/http/loading_state.dart';
import 'package:PiliMiLe/http/pgc.dart';
import 'package:PiliMiLe/models/common/home_tab_type.dart';
import 'package:PiliMiLe/models_new/douban/subject.dart';
import 'package:PiliMiLe/models_new/fav/fav_pgc/list.dart';
import 'package:PiliMiLe/models_new/pgc/pgc_index_result/list.dart';
import 'package:PiliMiLe/models_new/pgc/pgc_timeline/result.dart';
import 'package:PiliMiLe/pages/common/common_list_controller.dart';
import 'package:PiliMiLe/pages/douban_video/detail/episode_label.dart';
import 'package:PiliMiLe/services/account_service.dart';
import 'package:PiliMiLe/utils/extension/scroll_controller_ext.dart';
import 'package:PiliMiLe/utils/storage.dart';
import 'package:PiliMiLe/utils/storage_pref.dart';
import 'package:flutter/widgets.dart' show ScrollController;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class PgcController
    extends CommonListController<List<PgcIndexItem>?, PgcIndexItem>
    with AccountMixin {
  PgcController({required this.tabType})
    : indexType = tabType == HomeTabType.cinema ? 102 : null;

  final HomeTabType tabType;
  final int? indexType;

  bool get isDrama => tabType == HomeTabType.drama;

  late final showPgcTimeline =
      !isDrama && tabType == HomeTabType.bangumi && Pref.showPgcTimeline;

  /// 初始加载至少播放一整轮（4 个形态变换），避免转圈一闪而过
  late final RxInt initialMorphCount = 0.obs;

  @override
  final accountService = Get.find<AccountService>();

  @override
  void onInit() {
    super.onInit();

    if (!isDrama) {
      queryData();
      queryPgcFollow();
      if (showPgcTimeline) {
        queryPgcTimeline();
      }
    } else {
      loadingState.value = const Success(null);
      followState.value = const Success(null);
      loadDramaRecords();
      queryDramaSections();
    }
  }

  @override
  Future<void> onRefresh() {
    if (isDrama) {
      loadDramaRecords();
      return queryDramaSections();
    }
    if (accountService.isLogin.value) {
      _refreshPgcFollow();
    }
    if (showPgcTimeline) {
      queryPgcTimeline();
    }
    return super.onRefresh();
  }

  void _refreshPgcFollow() {
    followPage = 1;
    followEnd = false;
    queryPgcFollow();
  }

  // follow
  late int followPage = 1;
  late RxInt followCount = (-1).obs;
  late bool followLoading = false;
  late bool followEnd = false;
  late Rx<LoadingState<List<FavPgcItemModel>?>> followState =
      LoadingState<List<FavPgcItemModel>?>.loading().obs;
  final followController = ScrollController();

  // timeline
  late Rx<LoadingState<List<TimelineResult>?>> timelineState =
      LoadingState<List<TimelineResult>?>.loading().obs;

  Future<void> queryPgcTimeline() async {
    final res = await Future.wait([
      PgcHttp.pgcTimeline(types: 1, before: 6, after: 6),
      PgcHttp.pgcTimeline(types: 4, before: 6, after: 6),
    ]);
    final list1 = res.first.dataOrNull;
    final list2 = res[1].dataOrNull;
    if (list1 != null &&
        list2 != null &&
        list1.isNotEmpty &&
        list2.isNotEmpty) {
      for (var i = 0; i < list1.length; i++) {
        list1[i].addAll(list2[i]);
      }
    }
    timelineState.value = Success(list1 ?? list2);
  }

  // 我的订阅
  Future<void> queryPgcFollow([bool isRefresh = true]) async {
    if (!accountService.isLogin.value ||
        followLoading ||
        (!isRefresh && followEnd)) {
      return;
    }
    followLoading = true;
    final res = await FavHttp.favPgc(
      type: tabType == HomeTabType.bangumi ? 1 : 2,
      pn: followPage,
    );

    if (res case Success(:final response)) {
      final list = response.list;
      followCount.value = response.total ?? -1;

      if (list == null || list.isEmpty) {
        followEnd = true;
        if (isRefresh) {
          followState.value = Success(list);
        }
        followLoading = false;
        return;
      }

      if (isRefresh) {
        if (list.length >= followCount.value) {
          followEnd = true;
        }
        followState.value = Success(list);
        followController.jumpToTop();
      } else if (followState.value case Success(:final response)) {
        final currentList = response!..addAll(list);
        if (currentList.length >= followCount.value) {
          followEnd = true;
        }
        followState.refresh();
      }
      followPage++;
    } else if (isRefresh) {
      followState.value = res as Error;
    }
    followLoading = false;
  }

  @override
  Future<LoadingState<List<PgcIndexItem>?>> customGetData() => PgcHttp.pgcIndex(
    page: page,
    indexType: indexType,
  );

  @override
  void onClose() {
    followController.dispose();
    super.onClose();
  }

  @override
  void onChangeAccount(bool isLogin) {
    if (isLogin) {
      _refreshPgcFollow();
    } else {
      followState.value = LoadingState.loading();
    }
  }

  // 追剧 - 追剧记录
  late final Rx<LoadingState<List<FavPgcItemModel>>> dramaRecordState =
      LoadingState<List<FavPgcItemModel>>.loading().obs;

  // 追剧 - 豆瓣 4 个板块
  final dramaMovieState =
      Rx<LoadingState<List<DoubanSubject>>>(LoadingState.loading());
  final dramaTvState = Rx<LoadingState<List<DoubanSubject>>>(LoadingState.loading());
  final dramaAnimationState =
      Rx<LoadingState<List<DoubanSubject>>>(LoadingState.loading());
  final dramaShowState =
      Rx<LoadingState<List<DoubanSubject>>>(LoadingState.loading());

  Future<void> queryDramaSections() async {
    final enableSaveLastData = Pref.enableSaveLastData;
    try {
      final results = await Future.wait([
        _queryDramaHot(kind: 'movie', category: '热门', type: '全部'),
        _queryDramaHot(kind: 'tv', category: 'tv', type: 'tv'),
        _queryDramaHot(kind: 'tv', category: 'tv', type: 'tv_animation'),
        _queryDramaHot(kind: 'tv', category: 'tv', type: 'show'),
      ]);
      dramaMovieState.value = results[0];
      dramaTvState.value = results[1];
      dramaAnimationState.value = results[2];
      dramaShowState.value = results[3];
    } catch (_) {
      if (!enableSaveLastData) {
        dramaMovieState.value = const Error('连接错误，请检查网络重试');
        dramaTvState.value = const Error('连接错误，请检查网络重试');
        dramaAnimationState.value = const Error('连接错误，请检查网络重试');
        dramaShowState.value = const Error('连接错误，请检查网络重试');
        SmartDialog.showToast('网络连接错误，请检查网络重试');
      }
    }
  }

  Future<LoadingState<List<DoubanSubject>>> _queryDramaHot({
    required String kind,
    required String category,
    required String type,
  }) async {
    try {
      final res = await DoubanHttp.dio.get(
        '/rexxar/api/v2/subject/recent_hot/$kind',
        queryParameters: {
          'start': 0,
          'limit': 10,
          'category': category,
          'type': type,
        },
      );
      if (res.statusCode == 200) {
        final data = DoubanHotResponse.fromJson(
          res.data is Map<String, dynamic>
              ? res.data as Map<String, dynamic>
              : {},
        );
        return Success(data.items);
      }
      return const Error('连接错误，请检查网络重试');
    } catch (_) {
      return const Error('连接错误，请检查网络重试');
    }
  }

  /// 从本地 Box 加载追剧记录
  void loadDramaRecords() {
    final box = GStorage.dramaRecord;
    List<FavPgcItemModel> list;
    if (box.isEmpty) {
      list = [];
    } else {
      final records = box.values.toList()
        ..sort((a, b) => (b['playedAt'] as int).compareTo(a['playedAt'] as int));
      list = records.map<FavPgcItemModel>((r) {
        return FavPgcItemModel(
          seasonId: 0,
          title: r['title'] as String?,
          cover: r['cover'] as String?,
          badge: r['badge'] as String?,
          progress: r['progress'] as String?,
          isFinish: r['isFinish'] as int?,
          vodId: r['vodId'],
        );
      }).toList();
    }
    dramaRecordState.value = Success(list);
  }

  /// 点击追剧记录卡片：先请求详情再跳转，并定位到记录的线路和集数
  Future<void> onDramaCardTap(FavPgcItemModel item) async {
    if (item.vodId == null) return;
    SmartDialog.showLoading(msg: '资源加载中...');
    try {
      final resp = await DoubanHttp.getVodDetail(item.vodId);
      SmartDialog.dismiss();
      if (resp['status'] == true && resp['data'] != null) {
        final detail = resp['data'] as DoubanVodDetailModel;

        // 匹配记录的线路（优先匹配且可用，否则回退到首个可用线路）
        int sourceIndex = 0;
        if (item.badge != null) {
          final matchIdx = detail.sources.indexWhere(
            (s) => s.name == item.badge && s.decodeStatus == '1',
          );
          if (matchIdx >= 0) {
            sourceIndex = matchIdx;
          } else {
            final fallback = detail.sources.indexWhere(
              (s) => s.decodeStatus == '1',
            );
            if (fallback >= 0) sourceIndex = fallback;
          }
        }

        // 匹配记录的集数
        int episodeIndex = 0;
        if (item.progress != null && detail.sources.isNotEmpty) {
          final episodes = detail.sources[sourceIndex].episodes;
          final idx = episodes.indexWhere(
            (e) => episodeLabel(e) == item.progress,
          );
          if (idx >= 0) episodeIndex = idx;
        }

        Get.toNamed('/doubanVideo', arguments: {
          'vodId': item.vodId,
          'preloadedDetail': detail,
          'preloadedSourceIndex': sourceIndex,
          'preloadedEpisodeIndex': episodeIndex,
          'vodName': item.title,
          'vodPic': item.cover,
        });
      } else {
        SmartDialog.showToast(resp['msg'] ?? '获取详情失败');
      }
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast('网络错误，请稍后重试');
    }
  }

}
