import 'package:PiliMiLe/http/douban.dart';
import 'package:PiliMiLe/models/common/home_tab_type.dart';
import 'package:PiliMiLe/models/douban/douban_detail.dart';
import 'package:PiliMiLe/pages/douban_video/detail/episode_label.dart';
import 'package:PiliMiLe/pages/pgc/controller.dart';
import 'package:PiliMiLe/plugin/pl_player/controller.dart';
import 'package:PiliMiLe/plugin/pl_player/models/data_source.dart';
import 'package:PiliMiLe/utils/storage.dart';
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

  // 续播进度（从追剧记录卡片传入）
  Duration? resumePosition;

  // 播放器
  final plPlayerController = PlPlayerController.getInstance(isLive: false);
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
      // 解析续播进度
      if (args?['progressTime'] case final String time) {
        resumePosition = _parseProgressTime(time);
      }
    } else {
      _fetchDetail();
    }
  }

  @override
  void onClose() {
    _updateDramaProgress();
    plPlayerController.dispose();
    super.onClose();
  }

  /// 请求上游 API 获取影片详情（无预加载数据时使用）
  Future<void> _fetchDetail() async {
    isLoading.value = true;
    errorMsg.value = null;
    try {
      final resp = await DoubanHttp.getVodDetail(vodId);
      if (resp['status'] == true && resp['data'] != null) {
        final d = resp['data'] as DoubanVodDetailModel;
        detail.value = d;
        vodName.value = d.vodName;
        vodPic.value = d.vodPic;
      } else {
        errorMsg.value = resp['msg'] ?? '获取详情失败';
      }
    } catch (e) {
      debugPrint('[追剧详情] 请求详情异常: $e');
      errorMsg.value = '网络错误: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// 手动播放
  Future<void> play() async {
    if (isDecoding.value) return;

    // 已有 M3U8，直接播
    if (m3u8Url.value != null && m3u8Url.value!.isNotEmpty) {
      await _playM3u8(m3u8Url.value!);
      return;
    }

    // 没 URL，需要解码
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
    // 有续播进度时传入 seekTo，初始化到对应位置
    final seekTo = resumePosition;
    resumePosition = null;
    await plPlayerController.setDataSource(
      NetworkSource(videoSource: url, audioSource: null),
      isLive: false,
      autoplay: false,
      seekTo: seekTo,
    );
    playerReady.value = true;
    // 显式调用 play 确保不须二次点击
    await plPlayerController.play();
    _saveDramaRecord();
  }

  /// 解析时间字符串为 Duration（"mm:ss" / "H:mm:ss"）
  Duration? _parseProgressTime(String time) {
    final parts = time.split(':');
    if (parts.length == 2) {
      final m = int.tryParse(parts[0]);
      final s = int.tryParse(parts[1]);
      if (m != null && s != null) return Duration(minutes: m, seconds: s);
    } else if (parts.length == 3) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final s = int.tryParse(parts[2]);
      if (h != null && m != null && s != null) return Duration(hours: h, minutes: m, seconds: s);
    }
    return null;
  }

  /// 格式化 Duration 为时间字符串（<1h: "mm:ss", >=1h: "H:mm:ss"）
  String _formatPosition(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) {
      return '$h:$m:$s';
    }
    return '$m:$s';
  }

  /// 视频开始播放后写入追剧记录
  void _saveDramaRecord() {
    final d = detail.value;
    if (d == null) return;

    final remarks = d.vodRemarks;
    // 显示当前线路名称
    final badge = selectedSource?.name ?? '追剧中';
    // 判断是否完结
    final isFinish = RegExp(r'完结|全\d+集').hasMatch(remarks) ? 1 : 0;
    // 当前剧集标题（格式化后）
    final ep = selectedEpisode;
    final epTitle = ep != null ? episodeLabel(ep) : null;
    // 当前播放进度时间
    final pos = plPlayerController.position.inSeconds > 0
        ? _formatPosition(plPlayerController.position)
        : null;

    final record = <String, dynamic>{
      'vodId': vodId.toString(),
      'title': vodName.value,
      'cover': vodPic.value,
      'badge': badge,
      'progress': epTitle,
      'progressTime': pos,
      'isFinish': isFinish,
      'playedAt': DateTime.now().millisecondsSinceEpoch,
    };

    GStorage.dramaRecord.put(vodId.toString(), record);

    // 最多保留最近 30 条，超限删除最旧记录
    final box = GStorage.dramaRecord;
    if (box.length > 30) {
      final oldest = box.values.reduce(
        (a, b) => (a['playedAt'] as int) < (b['playedAt'] as int) ? a : b,
      );
      box.delete(oldest['vodId'].toString());
    }

    // 通知追剧 Tab 刷新卡片，无需手动下拉
    try {
      Get.find<PgcController>(tag: HomeTabType.drama.name).loadDramaRecords();
    } catch (_) {}
  }

  /// 更新当前追剧记录的播放进度时间（页面关闭时调用）
  void _updateDramaProgress() {
    if (plPlayerController.position.inSeconds <= 0) return;
    if (selectedEpisode == null) return;

    final existing = GStorage.dramaRecord.get(vodId.toString());
    if (existing == null) return;

    existing['progressTime'] = _formatPosition(plPlayerController.position);
    existing['playedAt'] = DateTime.now().millisecondsSinceEpoch;
    GStorage.dramaRecord.put(vodId.toString(), existing);

    // 通知追剧 Tab 刷新卡片
    try {
      Get.find<PgcController>(tag: HomeTabType.drama.name).loadDramaRecords();
    } catch (_) {}
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
