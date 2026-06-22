import 'package:PiliMiLe/models/common/enum_with_label.dart';
import 'package:PiliMiLe/models/common/search/search_type.dart';
import 'package:PiliMiLe/pages/common/common_controller.dart';
import 'package:PiliMiLe/pages/hot/controller.dart';
import 'package:PiliMiLe/pages/hot/view.dart';
import 'package:PiliMiLe/pages/live/controller.dart';
import 'package:PiliMiLe/pages/live/view.dart';
import 'package:PiliMiLe/pages/pgc/controller.dart';
import 'package:PiliMiLe/pages/pgc/view.dart';
import 'package:PiliMiLe/pages/rank/controller.dart';
import 'package:PiliMiLe/pages/rank/view.dart';
import 'package:PiliMiLe/pages/rcmd/controller.dart';
import 'package:PiliMiLe/pages/rcmd/view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum HomeTabType implements EnumWithLabel {
  live('直播'),
  rcmd('推荐'),
  hot('热门'),
  rank('分区'),
  bangumi('番剧'),
  cinema('影视'),
  drama('追剧'),
  ;

  @override
  final String label;
  const HomeTabType(this.label);

  /// 映射到搜索结果页对应 Tab 的 [SearchType.index]
  int get searchInitIndex => switch (this) {
    HomeTabType.live => SearchType.live_room.index,
    HomeTabType.bangumi => SearchType.media_bangumi.index,
    HomeTabType.cinema => SearchType.media_ft.index,
    HomeTabType.drama => SearchType.drama.index,
    _ => SearchType.video.index,
  };

  ScrollOrRefreshMixin Function() get ctr => switch (this) {
    HomeTabType.live => Get.find<LiveController>,
    HomeTabType.rcmd => Get.find<RcmdController>,
    HomeTabType.hot => Get.find<HotController>,
    HomeTabType.rank => Get.find<RankController>,
    HomeTabType.bangumi ||
    HomeTabType.cinema ||
    HomeTabType.drama => () => Get.find<PgcController>(tag: name),
  };

  Widget get page => switch (this) {
    HomeTabType.live => const LivePage(),
    HomeTabType.rcmd => const RcmdPage(),
    HomeTabType.hot => const HotPage(),
    HomeTabType.rank => const RankPage(),
    HomeTabType.bangumi => const PgcPage(tabType: HomeTabType.bangumi),
    HomeTabType.cinema => const PgcPage(tabType: HomeTabType.cinema),
    HomeTabType.drama => const PgcPage(tabType: HomeTabType.drama),
  };
}
