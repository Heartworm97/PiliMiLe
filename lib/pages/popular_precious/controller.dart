import 'package:PiliMiLe/http/loading_state.dart';
import 'package:PiliMiLe/http/video.dart';
import 'package:PiliMiLe/models/model_hot_video_item.dart';
import 'package:PiliMiLe/models_new/popular/popular_precious/data.dart';
import 'package:PiliMiLe/pages/common/common_list_controller.dart';

class PopularPreciousController
    extends CommonListController<PopularPreciousData, HotVideoItemModel> {
  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  int? mediaId;

  @override
  List<HotVideoItemModel>? getDataList(PopularPreciousData response) {
    mediaId = response.mediaId;
    return response.list;
  }

  @override
  Future<LoadingState<PopularPreciousData>> customGetData() =>
      VideoHttp.popularPrecious(page: page);
}
