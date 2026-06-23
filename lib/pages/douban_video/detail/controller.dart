import 'package:PiliMiLe/http/douban.dart';
import 'package:PiliMiLe/models/douban/douban_detail.dart';
import 'package:PiliMiLe/plugin/pl_player/controller.dart';
import 'package:PiliMiLe/plugin/pl_player/models/data_source.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';

class DoubanVideoDetailController extends GetxController {
  // 路由参数
  late final dynamic vodId;
  final vodName = ''.obs;
  final vodPic = ''.obs;

  // 详情（预加载传入）
  final detail = Rxn<DoubanVodDetailModel>();
  final isLoading = false.obs;
  final errorMsg = Rxn<String>();

  // 选中状态
  final selectedSourceIndex = 0.obs;
  final selectedEpisodeIndex = 0.obs;

  // 解码/播放
  final isDecoding = false.obs;
  final m3u8Url = Rxn<String>();

  // 播放器
  final plPlayerController = PlPlayerController.getInstance(isLive: true);
  final playerReady = false.obs;

  // 计算属性
  DoubanSourceModel? get selectedSource =>
      detail.value?.sources.elementAtOrNull(selectedSourceIndex.value);
  DoubanEpisodeModel? get selectedEpisode =>
      selectedSource?.episodes.elementAtOrNull(selectedEpisodeIndex.value);
  List<DoubanSourceModel> get sources => detail.value?.sources ?? [];
  List<DoubanEpisodeModel> get currentEpisodes =>
      selectedSource?.episodes ?? [];

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    vodId = args?['vodId'];
    vodName.value = args?['vodName'] ?? '';
    vodPic.value = args?['vodPic'] ?? '';

    // 接收预加载数据
    if (args?['preloadedDetail'] case final DoubanVodDetailModel d) {
      detail.value = d;
      vodName.value = d.vodName;
      vodPic.value = d.vodPic;
      selectedSourceIndex.value =
          (args?['preloadedSourceIndex'] as int?) ?? 0;
      selectedEpisodeIndex.value =
          (args?['preloadedEpisodeIndex'] as int?) ?? 0;
      if (args?['preloadedM3u8'] case final String url) {
        m3u8Url.value = url;
      }
    }
  }

  @override
  void onClose() {
    plPlayerController.dispose();
    super.onClose();
  }

  /// 手动播放
  Future<void> play() async {
    if (isDecoding.value) return;

    // 已有 M3U8，直接播
    if (m3u8Url.value != null && m3u8Url.value!.isNotEmpty) {
      await _playM3u8(m3u8Url.value!);
      return;
    }

    // 没 URL，需要解码 — 先显示播放器加载态
    playerReady.value = true;
    await _doDecode();
  }

  Future<void> _doDecode() async {
    final src = selectedSource;
    final ep = selectedEpisode;
    if (src == null || ep == null) return;

    isDecoding.value = true;
    errorMsg.value = null;
    SmartDialog.showLoading(msg: '资源获取中...');
    try {
      final resp = await DoubanHttp.decodeVod(
        vodId: vodId,
        sid: src.key,
        nid: ep.nid,
        videoId: ep.videoId,
      );
      if (resp['status'] == true && resp['data'] != null) {
        final result = resp['data'] as DoubanDecodeResultModel;
        if (result.url.isNotEmpty) {
          m3u8Url.value = result.url;
          await _playM3u8(result.url);
          SmartDialog.dismiss();
        } else {
          errorMsg.value = '解码结果为空';
          SmartDialog.dismiss();
          SmartDialog.showToast('解码失败，请稍后重试');
        }
      } else {
        debugPrint('[追剧详情] 解码失败: ${resp['msg']}');
        errorMsg.value = resp['msg'] ?? '解码失败';
        SmartDialog.dismiss();
        SmartDialog.showToast('解码失败，请稍后重试');
      }
    } catch (e) {
      debugPrint('[追剧详情] 解码异常: $e');
      errorMsg.value = '解码错误: $e';
      SmartDialog.dismiss();
      SmartDialog.showToast('解码失败，请稍后重试');
    } finally {
      isDecoding.value = false;
    }
  }

  Future<void> _playM3u8(String url) async {
    await plPlayerController.setDataSource(
      NetworkSource(videoSource: url, audioSource: null),
      isLive: true,
      autoplay: false,
    );
    playerReady.value = true;
    // 显式调用 play 确保不须二次点击
    await plPlayerController.play();
  }

  void onSelectSource(int index) {
    if (index == selectedSourceIndex.value) return;

    final currentEp = selectedEpisode;
    selectedSourceIndex.value = index;

    // 新线路优先匹配相同集号，找不到则第0集
    final newEpisodes = selectedSource?.episodes ?? [];
    int matchedIndex = 0;
    if (currentEp != null) {
      final matchIdx = newEpisodes.indexWhere(
        (e) => e.nid == currentEp.nid || e.title == currentEp.title,
      );
      if (matchIdx >= 0) matchedIndex = matchIdx;
    }
    selectedEpisodeIndex.value = matchedIndex;

    m3u8Url.value = null;
    playerReady.value = false;
  }

  void onSelectEpisode(int index) {
    if (index == selectedEpisodeIndex.value) return;
    selectedEpisodeIndex.value = index;
    m3u8Url.value = null;
    playerReady.value = false;
  }
}
