import 'package:PiliMiLe/http/douban.dart';
import 'package:PiliMiLe/models/douban/douban_detail.dart';
import 'package:PiliMiLe/plugin/pl_player/controller.dart';
import 'package:PiliMiLe/plugin/pl_player/models/data_source.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';

class DoubanVideoDetailController extends GetxController {
  // 路由参数
  late final dynamic vodId;
  final vodName = ''.obs;
  final vodPic = ''.obs;

  // 详情
  final isLoading = true.obs;
  final errorMsg = Rxn<String>();
  final detail = Rxn<DoubanVodDetailModel>();

  // 选中状态
  final selectedSourceIndex = 0.obs;
  final selectedEpisodeIndex = 0.obs;

  // 解码/播放
  final isDecoding = false.obs;
  final m3u8Url = Rxn<String>();

  // 播放器
  final plPlayerController = PlPlayerController.getInstance(isLive: true);

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
    _fetchDetail();
  }

  @override
  void onClose() {
    plPlayerController.dispose();
    super.onClose();
  }

  Future<void> retry() => _fetchDetail();

  Future<void> _fetchDetail() async {
    isLoading.value = true;
    errorMsg.value = null;
    try {
      final resp = await DoubanHttp.getVodDetail(vodId);
      if (resp['status'] == true && resp['data'] != null) {
        detail.value = resp['data'] as DoubanVodDetailModel;
        vodName.value = detail.value!.vodName;
        vodPic.value = detail.value!.vodPic;
        _autoSelectSource();
      } else {
        errorMsg.value = resp['msg'] ?? '加载失败';
      }
    } catch (e) {
      debugPrint('[追剧详情] 获取详情失败: $e');
      errorMsg.value = '网络错误: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void _autoSelectSource() {
    final list = sources;
    for (int i = 0; i < list.length; i++) {
      if (list[i].decodeStatus == '1') {
        selectedSourceIndex.value = i;
        selectedEpisodeIndex.value = 0;
        _doDecode();
        return;
      }
    }
    // 没有可解码线路，默认选第一条
    if (list.isNotEmpty) {
      selectedSourceIndex.value = 0;
      selectedEpisodeIndex.value = 0;
    }
  }

  Future<void> _doDecode() async {
    final src = selectedSource;
    final ep = selectedEpisode;
    if (src == null || ep == null) return;

    isDecoding.value = true;
    m3u8Url.value = null;
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
          _playM3u8(result.url);
        } else {
          errorMsg.value = '解码结果为空';
        }
      } else {
        debugPrint('[追剧详情] 解码失败: ${resp['msg']}');
        errorMsg.value = resp['msg'] ?? '解码失败';
      }
    } catch (e) {
      debugPrint('[追剧详情] 解码异常: $e');
      errorMsg.value = '解码错误: $e';
    } finally {
      isDecoding.value = false;
    }
  }

  void _playM3u8(String url) {
    plPlayerController.setDataSource(
      NetworkSource(videoSource: url, audioSource: null),
      isLive: true,
      autoplay: true,
    );
  }

  void onSelectSource(int index) {
    if (index == selectedSourceIndex.value) return;
    selectedSourceIndex.value = index;
    selectedEpisodeIndex.value = 0;
    _doDecode();
  }

  void onSelectEpisode(int index) {
    if (index == selectedEpisodeIndex.value) return;
    selectedEpisodeIndex.value = index;
    _doDecode();
  }
}
