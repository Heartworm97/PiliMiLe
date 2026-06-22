import 'package:PiliMiLe/common/skeleton/media_bangumi.dart';
import 'package:PiliMiLe/common/style.dart';
import 'package:PiliMiLe/models/search/result.dart';
import 'package:PiliMiLe/pages/search_panel/controller.dart';
import 'package:PiliMiLe/pages/search_panel/drama/widgets/item.dart';
import 'package:PiliMiLe/pages/search_panel/view.dart';
import 'package:PiliMiLe/utils/grid.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchDramaPanel extends CommonSearchPanel {
  const SearchDramaPanel({
    super.key,
    required super.keyword,
    required super.tag,
    required super.searchType,
  });

  @override
  State<SearchDramaPanel> createState() => _SearchDramaPanelState();
}

class _SearchDramaPanelState
    extends CommonSearchPanelState<
        SearchDramaPanel,
        SearchDramaData,
        SearchDramaItemModel> {
  @override
  late final SearchPanelController<SearchDramaData, SearchDramaItemModel>
  controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      SearchPanelController<SearchDramaData, SearchDramaItemModel>(
        keyword: widget.keyword,
        searchType: widget.searchType,
        tag: widget.tag,
      ),
      tag: widget.searchType.name + widget.tag,
    );
  }

  @override
  Widget buildList(ThemeData theme, List<SearchDramaItemModel> list) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        Style.safeSpace,
        4,
        Style.safeSpace,
        0,
      ),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          mainAxisSpacing: Style.cardSpace - 2,
          crossAxisSpacing: Style.cardSpace,
          crossAxisCount: 3,
          childAspectRatio: 0.50,
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            if (index == list.length - 1) {
              controller.onLoadMore();
            }
            return SearchDramaItem(item: list[index]);
          },
          childCount: list.length,
        ),
      ),
    );
  }

  @override
  Widget get buildLoading => SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithExtentAndRatio(
          mainAxisSpacing: 2,
          maxCrossAxisExtent: Grid.smallCardWidth * 2,
          childAspectRatio: Style.aspectRatio * 1.5,
          minHeight: MediaQuery.textScalerOf(context).scale(155),
        ),
        itemBuilder: (context, index) => const MediaPgcSkeleton(),
        itemCount: 10,
      );
}
