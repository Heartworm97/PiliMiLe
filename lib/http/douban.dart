import 'package:PiliMiLe/http/browser_ua.dart';
import 'package:PiliMiLe/models/douban/douban_detail.dart';
import 'package:PiliMiLe/models/search/result.dart';
import 'package:PiliMiLe/services/logger.dart';
import 'package:PiliMiLe/utils/storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:hive_ce/hive.dart';

class DoubanHttp {
  // ============ 豆瓣官方API ============
  static const _baseUrl = 'https://m.douban.com';
  static final Dio dio = _createDio();

  static Dio _createDio() {
    final d = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'referer': 'https://movie.douban.com/',
        'user-agent': BrowserUa.mob,
        'accept': 'application/json, text/plain, */*',
      },
    ));

    if (kDebugMode) {
      d.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('*** Request ***');
          debugPrint('uri: ${options.uri}');
          handler.next(options);
        },
      ));
    }

    return d;
  }

  // ============ 上游镜像站配置 ============

  static final Dio _upstreamDio = _createUpstreamDio();

  static Dio _createUpstreamDio() {
    final d = Dio(BaseOptions(
      connectTimeout: const Duration(milliseconds: 12000),
      receiveTimeout: const Duration(milliseconds: 12000),
    ));

    if (kDebugMode) {
      d.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('*** Request ***');
          debugPrint('uri: ${options.uri}');
          handler.next(options);
        },
      ));
    }

    return d;
  }

  static const List<String> _upstreamMirrors = [
    'https://asd123sx23xdacsx.top',
    'https://c453sddsc451azx.top',
    'https://h234das3acx.top',
    'https://zdki6k23cdsec.top',
  ];

  static const String _webSign = 'f65f3a83d6d9ad6f';
  static const String _xClient = '8f3d2a1c7b6e5d4c9a0b1f2e3d4c5b6a';

  static int _activeMirrorIndex = -1;

  static String get _activeHost {
    if (_activeMirrorIndex >= 0 &&
        _activeMirrorIndex < _upstreamMirrors.length) {
      return _upstreamMirrors[_activeMirrorIndex];
    }
    final Box<dynamic> cache = GStorage.localCache;
    final cached = cache.get('upstreamMirrorIndex');
    if (cached != null) {
      _activeMirrorIndex = cached as int;
      if (_activeMirrorIndex >= 0 &&
          _activeMirrorIndex < _upstreamMirrors.length) {
        return _upstreamMirrors[_activeMirrorIndex];
      }
    }
    _activeMirrorIndex = 0;
    return _upstreamMirrors[0];
  }

  static void _switchToNextHost() {
    _activeMirrorIndex++;
    if (_activeMirrorIndex >= _upstreamMirrors.length) {
      _activeMirrorIndex = 0;
    }
    GStorage.localCache.put('upstreamMirrorIndex', _activeMirrorIndex);
  }

  static void _markHostAlive() {
    GStorage.localCache.put('upstreamMirrorIndex', _activeMirrorIndex);
  }

  static Map<String, String> get _upstreamHeaders => {
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        'Referer': '$_activeHost/',
        'web-sign': _webSign,
        'X-Client': _xClient,
        'Accept': 'application/json',
      };

  static Future<Response> _upstreamGet(String path,
      {Map<String, dynamic>? params}) async {
    int attempts = 0;
    while (attempts < _upstreamMirrors.length) {
      try {
        final resp = await _upstreamDio.get(
          '$_activeHost$path',
          queryParameters: params,
          options: Options(headers: _upstreamHeaders),
        );
        _markHostAlive();
        return resp;
      } on DioException {
        attempts++;
        if (attempts < _upstreamMirrors.length) {
          _switchToNextHost();
        }
      }
    }
    throw DioException(
      requestOptions: RequestOptions(path: path),
      message: '所有上游线路不可用',
    );
  }

  static Future<Response> _upstreamPost(String path,
      {dynamic data,
      Map<String, dynamic>? params,
      String contentType = 'application/json'}) async {
    int attempts = 0;
    while (attempts < _upstreamMirrors.length) {
      try {
        final resp = await _upstreamDio.post(
          '$_activeHost$path',
          data: data,
          queryParameters: params,
          options: Options(
            headers: {
              ..._upstreamHeaders,
              'Content-Type': contentType,
            },
          ),
        );
        _markHostAlive();
        return resp;
      } on DioException {
        attempts++;
        if (attempts < _upstreamMirrors.length) {
          _switchToNextHost();
        }
      }
    }
    throw DioException(
      requestOptions: RequestOptions(path: path),
      message: '所有上游线路不可用',
    );
  }

  // ============ 图片URL清洗 ============

  /// 上游返回的海报地址可能是代理 URL，提取真实豆瓣地址并替换为社区CDN
  static String cleanVodPic(String rawUrl) {
    if (rawUrl.isEmpty) return rawUrl;

    // 从代理 URL 中提取真实图片地址
    // 如: https://4k.jdyx.pro/img.php?url=https://img1.doubanio.com/... → 提取 url 参数
    String url = rawUrl;
    final uri = Uri.tryParse(rawUrl);
    if (uri != null && !uri.host.contains('doubanio')) {
      final innerUrl = uri.queryParameters['url'];
      if (innerUrl != null && innerUrl.isNotEmpty) {
        url = innerUrl;
      }
    }

    // 将豆瓣图片CDN替换为社区CDN代理
    final doubanUri = Uri.tryParse(url);
    if (doubanUri != null && doubanUri.host.contains('doubanio.com')) {
      final pathSegments = doubanUri.pathSegments;
      if (pathSegments.length >= 2) {
        final filename = pathSegments.last;
        return 'https://img.doubanio.cmliussss.net/view/photo/m_ratio_poster/public/$filename';
      }
    }

    return url;
  }

  // ============ 上游搜索 ============

  static Future<Map<String, dynamic>> searchVod({
    required String keyword,
    int page = 1,
  }) async {
    try {
      final resp = await _upstreamGet(
        '/api.php/web/search/index',
        params: {
          'wd': keyword.trim(),
          'page': page.toString(),
          'limit': '10',
        },
      );

      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data is! Map) {
          return {'status': false, 'data': null, 'msg': '数据格式异常'};
        }
        if (data['code'] != 200) {
          return {
            'status': false,
            'data': null,
            'msg': data['msg'] ?? '搜索失败',
          };
        }
        final rawList = (data['data'] as List<dynamic>?)
                ?.map((item) {
                  final typeName = item['type_name'] ?? '';
                  return SearchDramaItemModel(
                    vodId: item['vod_id'],
                    vodName: item['vod_name'] ?? '',
                    typeName: typeName == '剧集' ? '电视剧' : typeName,
                    vodPic: cleanVodPic(item['vod_pic'] ?? ''),
                    vodRemarks: item['vod_remarks'] ?? '',
                    vodYear: item['vod_year']?.toString() ?? '',
                    vodActor: item['vod_actor'] ?? '',
                    vodArea: item['vod_area'] ?? '',
                  );
                })
                .toList() ??
            [];

        final filteredList = rawList
            .where((item) => item.vodName.contains(keyword.trim()))
            .toList();

        if (kDebugMode) {
          for (final item in filteredList) {
            logger.d('剧名: ${item.vodName} | 海报: ${item.vodPic}');
          }
        }

        if (filteredList.isEmpty) {
          return {'status': false, 'data': null, 'msg': '没有相关数据'};
        }

        return {
          'status': true,
          'data': SearchDramaData(
            numResults: filteredList.length,
            list: filteredList,
          ),
          'page': page,
          'hasMore': rawList.length >= 10,
        };
      }
      return {'status': false, 'data': null, 'msg': '搜索失败'};
    } catch (e) {
      logger.e('searchVod error: $e');
      return {'status': false, 'data': null, 'msg': '网络错误: $e'};
    }
  }

  // ============ 上游详情 ============

  /// 获取影片详情（线路+集数）
  static Future<Map<String, dynamic>> getVodDetail(dynamic vodId) async {
    try {
      final resp = await _upstreamPost(
        '/api.php/web/vod/get_detail',
        data: 'vod_id=$vodId',
        contentType: 'application/x-www-form-urlencoded',
      );

      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data['code'] != 200) {
          return {
            'status': false,
            'data': null,
            'msg': data['msg'] ?? '获取详情失败',
          };
        }

        final vod = (data['data'] as List).first;
        final vodplayer = data['vodplayer'] as List<dynamic>? ?? [];

        // 构建线路元信息 map: from -> { show, sort, decode_status }
        final playerMap = <String, Map<String, dynamic>>{};
        for (final p in vodplayer) {
          playerMap[p['from'] as String] = p as Map<String, dynamic>;
        }

        // 解析线路名列表（$$$ 分隔）
        final sourceKeys = (vod['vod_play_from'] as String? ?? '')
            .split('\$\$\$')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        // 解析各线路的集数列表（$$$ 分隔线路，# 分隔集，$ 分隔标题和videoId）
        final sourceUrls = (vod['vod_play_url'] as String? ?? '')
            .split('\$\$\$')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        final sources = <DoubanSourceModel>[];
        for (int i = 0; i < sourceKeys.length; i++) {
          final key = sourceKeys[i];
          final cfg = playerMap[key] ?? <String, dynamic>{};
          final epRaw = i < sourceUrls.length
              ? sourceUrls[i]
                  .split('#')
                  .where((s) => s.isNotEmpty)
                  .toList()
              : <String>[];

          final episodes = epRaw.asMap().entries.map((entry) {
            final parts = entry.value.split('\$');
            return DoubanEpisodeModel(
              nid: entry.key + 1,
              title: parts.isNotEmpty ? parts[0] : '第${entry.key + 1}集',
              videoId: parts.length > 1 ? parts[1] : '',
            );
          }).toList();

          sources.add(DoubanSourceModel(
            key: key,
            name: (cfg['show'] as String?) ?? key,
            sort: int.tryParse((cfg['sort'] ?? '0').toString()) ?? 0,
            decodeStatus: (cfg['decode_status'] ?? '0').toString(),
            episodeCount: episodes.length,
            episodes: episodes,
          ));
        }

        // 内置线路按 sort 降序排列
        sources.sort((a, b) => b.sort.compareTo(a.sort));

        return {
          'status': true,
          'data': DoubanVodDetailModel(
            vodId: vodId.toString(),
            vodName: vod['vod_name'] ?? '',
            vodPic: vod['vod_pic'] ?? '',
            vodRemarks: vod['vod_remarks'] ?? '',
            vodYear: vod['vod_year']?.toString() ?? '',
            vodArea: vod['vod_area'] ?? '',
            vodLang: vod['vod_lang'] ?? '',
            vodActor: vod['vod_actor'] ?? '',
            vodDirector: vod['vod_director'] ?? '',
            vodContent: vod['vod_content'] ?? '',
            sources: sources,
          ),
        };
      }
      return {'status': false, 'data': null, 'msg': '获取详情失败'};
    } catch (e) {
      logger.e('getVodDetail error: $e');
      return {'status': false, 'data': null, 'msg': '网络错误: $e'};
    }
  }

  /// 当前活跃线路 host（供播放器设置 Referer）
  static String get serverHost => _activeHost;
}
