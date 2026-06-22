import 'package:PiliMiLe/http/dynamics.dart';
import 'package:PiliMiLe/http/loading_state.dart';
import 'package:PiliMiLe/models_new/dynamic/dyn_topic_top/topic_item.dart';
import 'package:PiliMiLe/pages/common/common_list_controller.dart';

class DynTopicRcmdController
    extends CommonListController<List<TopicItem>?, TopicItem> {
  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  Future<LoadingState<List<TopicItem>?>> customGetData() =>
      DynamicsHttp.dynTopicRcmd();
}
