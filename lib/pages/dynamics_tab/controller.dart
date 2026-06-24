import 'package:PiliMiLe/http/dynamics.dart';
import 'package:PiliMiLe/http/loading_state.dart';
import 'package:PiliMiLe/http/msg.dart';
import 'package:PiliMiLe/models/common/dynamic/dynamics_type.dart';
import 'package:PiliMiLe/models/dynamics/result.dart';
import 'package:PiliMiLe/pages/common/common_list_controller.dart';
import 'package:PiliMiLe/pages/dynamics/controller.dart';
import 'package:PiliMiLe/pages/main/controller.dart';
import 'package:PiliMiLe/services/account_service.dart';
import 'package:PiliMiLe/utils/extension/scroll_controller_ext.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class DynamicsTabController
    extends CommonListController<DynamicsDataModel, DynamicItemModel>
    with AccountMixin {
  DynamicsTabController({required this.dynamicsType});
  final DynamicsTabType dynamicsType;
  String offset = '';
  int? mid;
  late final MainController mainController = Get.find<MainController>();
  final dynamicsController = Get.find<DynamicsController>();

  @override
  void onInit() {
    super.onInit();
    if (accountService.isLogin.value) {
      queryData();
    } else {
      loadingState.value = const Error(null);
    }
  }

  @override
  Future<void> onRefresh() {
    if (dynamicsType == DynamicsTabType.all) {
      mainController.setDynCount();
    }
    offset = '';
    return super.onRefresh();
  }

  @override
  List<DynamicItemModel>? getDataList(DynamicsDataModel response) {
    offset = response.offset ?? '';
    return response.items;
  }

  @override
  Future<LoadingState<DynamicsDataModel>> customGetData() =>
      DynamicsHttp.followDynamic(
        type: dynamicsType,
        offset: offset,
        mid: mid,
        tempBannedList: dynamicsController.tempBannedList,
      );

  Future<void> onRemove(int index, dynamic dynamicId) async {
    final res = await MsgHttp.removeDynamic(dynIdStr: dynamicId);
    if (res.isSuccess) {
      loadingState
        ..value.data!.removeAt(index)
        ..refresh();
      SmartDialog.showToast('删除成功');
    } else {
      res.toast();
    }
  }

  @override
  Future<void> onReload() {
    scrollController.jumpToTop();
    return super.onReload();
  }

  void onBlock(int index) {
    if (dynamicsType != DynamicsTabType.up) {
      loadingState
        ..value.data!.removeAt(index)
        ..refresh();
    }
  }

  void onUnfold(DynamicItemModel item, int index) {
    try {
      final list = loadingState.value.data!;
      final ids = item.modules.moduleFold!.ids!;
      final flag = index + ids.length + 1;
      for (int i = index + 1; i < flag; i++) {
        list[i].visible = true;
      }
      item.modules.moduleFold = null;
      loadingState.refresh();
    } catch (_) {}
  }

  @override
  void onChangeAccount(bool isLogin) => onReload();

  @override
  bool handleError(String? errMsg) {
    if (!accountService.isLogin.value) return true;
    return super.handleError(errMsg);
  }
}
