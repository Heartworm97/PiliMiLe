import 'package:PiliMiLe/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliMiLe/common/widgets/loading_widget/http_error.dart';
import 'package:PiliMiLe/http/loading_state.dart';
import 'package:PiliMiLe/models/common/member/search_type.dart';
import 'package:PiliMiLe/pages/dynamics/widgets/dynamic_panel.dart';
import 'package:PiliMiLe/pages/member_search/child/controller.dart';
import 'package:PiliMiLe/pages/member_search/child/widgets/search_archive_grpc.dart';
import 'package:PiliMiLe/utils/global_data.dart';
import 'package:PiliMiLe/utils/grid.dart';
import 'package:PiliMiLe/utils/waterfall.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:waterfall_flow/waterfall_flow.dart'
    hide SliverWaterfallFlowDelegateWithMaxCrossAxisExtent;

class MemberSearchChildPage extends StatefulWidget {
  const MemberSearchChildPage({
    super.key,
    required this.controller,
    required this.searchType,
  });

  final MemberSearchChildController controller;
  final MemberSearchType searchType;

  @override
  State<MemberSearchChildPage> createState() => _MemberSearchChildPageState();
}

class _MemberSearchChildPageState extends State<MemberSearchChildPage>
    with AutomaticKeepAliveClientMixin, DynMixin, GridMixin {
  MemberSearchChildController get _controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return refreshIndicator(
      onRefresh: _controller.onRefresh,
      child: CustomScrollView(
        controller: _controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              top: widget.searchType == MemberSearchType.archive ? 7 : 0,
              bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
            ),
            sliver: switch (widget.searchType) {
              MemberSearchType.archive => Obx(
                () => _buildBody(_controller.loadingState.value),
              ),
              MemberSearchType.dynamic => buildPage(
                Obx(() => _buildBody(_controller.loadingState.value)),
              ),
            },
          ),
        ],
      ),
    );
  }

  Widget get _buildLoading {
    return switch (widget.searchType) {
      MemberSearchType.archive => gridSkeleton,
      MemberSearchType.dynamic => dynSkeleton,
    };
  }

  Widget _buildBody(LoadingState<List?> loadingState) {
    return switch (loadingState) {
      Loading() => _buildLoading,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? switch (widget.searchType) {
                MemberSearchType.archive => SliverGrid.builder(
                  gridDelegate: gridDelegate,
                  itemBuilder: (context, index) {
                    if (index == response.length - 1) {
                      _controller.onLoadMore();
                    }
                    return SearchArchiveGrpc(item: response[index]);
                  },
                  itemCount: response.length,
                ),
                MemberSearchType.dynamic =>
                  GlobalData().dynamicsWaterfallFlow
                      ? SliverWaterfallFlow(
                          gridDelegate: dynGridDelegate,
                          delegate: SliverChildBuilderDelegate(
                            (_, index) {
                              if (index == response.length - 1) {
                                _controller.onLoadMore();
                              }
                              return DynamicPanel(item: response[index]);
                            },
                            childCount: response.length,
                          ),
                        )
                      : SliverList.builder(
                          itemBuilder: (context, index) {
                            if (index == response.length - 1) {
                              _controller.onLoadMore();
                            }
                            return DynamicPanel(item: response[index]);
                          },
                          itemCount: response.length,
                        ),
              }
            : HttpError(onReload: _controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _controller.onReload,
      ),
    };
  }

  @override
  bool get wantKeepAlive => true;
}
