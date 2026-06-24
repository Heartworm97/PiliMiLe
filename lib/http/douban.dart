import 'package:PiliMiLe/http/browser_ua.dart';
import 'package:PiliMiLe/models/douban/douban_detail.dart';
import 'package:PiliMiLe/models/search/result.dart';
import 'package:PiliMiLe/services/logger.dart';
import 'package:PiliMiLe/services/upstream_decoder.dart';
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

  static const _publishPage = 'https://bubuzhuiju.com/js/config.js';
  static const _syncIntervalMs = 86400000; // 24小时

  /// 从 localCache 获取域名列表，无缓存时回退硬编码
  static List<String> get _cachedMirrors {
    final cached = GStorage.localCache.get('upstreamMirrors');
    if (cached is List && cached.isNotEmpty) {
      return cached.cast<String>();
    }
    return _upstreamMirrors;
  }

  /// 测速同步域名列表（启动时异步调用，不阻塞）
  static Future<void> ensureMirrors() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastSync = GStorage.localCache.get('upstreamMirrorsUpdatedAt');
    if (lastSync is int && (now - lastSync) < _syncIntervalMs) return;
    await _syncUpstreamMirrors();
  }

  static Future<void> _syncUpstreamMirrors() async {
    try {
      final resp = await _upstreamDio.get(
        _publishPage,
        options: Options(
          responseType: ResponseType.plain,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final hosts = _parseHosts(resp.data?.toString() ?? '');
      if (hosts.isEmpty) return;

      // 并发 ping 测速
      final results = await Future.wait(
        hosts.map(_pingHost),
      );
      final reachable = <MapEntry<String, int>>[];
      for (int i = 0; i < hosts.length; i++) {
        if (results[i] != null) {
          reachable.add(MapEntry(hosts[i], results[i]!));
        }
      }
      reachable.sort((a, b) => a.value.compareTo(b.value));
      final sorted = reachable.map((e) => 'https://${e.key}').toList();

      if (sorted.isNotEmpty) {
        GStorage.localCache.put('upstreamMirrors', sorted);
        GStorage.localCache.put(
          'upstreamMirrorsUpdatedAt',
          DateTime.now().millisecondsSinceEpoch,
        );
        _activeMirrorIndex = 0;
        debugPrint('[DoubanHttp] 域名同步完成: ${sorted.length}条, 最快=${sorted.first}');
      }
    } catch (_) {
      // 静默失败
    }
  }

  static List<String> _parseHosts(String jsContent) {
    final regex = RegExp(r"host:\s*'([^']+)'");
    return regex
        .allMatches(jsContent)
        .map((m) => m.group(1)!)
        .toList();
  }

  static Future<int?> _pingHost(String host) async {
    try {
      final sw = Stopwatch()..start();
      await _upstreamDio.head(
        'https://$host/favicon.ico',
        options: Options(
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      return sw.elapsedMilliseconds;
    } catch (_) {
      return null;
    }
  }

  static const String _webSign = 'f65f3a83d6d9ad6f';
  static const String _xClient = '8f3d2a1c7b6e5d4c9a0b1f2e3d4c5b6a';

  static int _activeMirrorIndex = -1;

  static String get _activeHost {
    final mirrors = _cachedMirrors;
    if (_activeMirrorIndex >= 0 && _activeMirrorIndex < mirrors.length) {
      return mirrors[_activeMirrorIndex];
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
    return mirrors[0];
  }

  static void _switchToNextHost() {
    _activeMirrorIndex++;
    if (_activeMirrorIndex >= _cachedMirrors.length) {
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
                debugPrint('剧名: ${item.vodName} | 海报: ${item.vodPic}');
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
            sort: double.tryParse((cfg['sort'] ?? '0').toString()) ?? 0,
            decodeStatus: (cfg['decode_status'] ?? '0').toString(),
            episodeCount: episodes.length,
            episodes: episodes,
          ));
        }

        // 内置线路按 sort 升序排列
        sources.sort((a, b) => a.sort.compareTo(b.sort));

        // 站外聚合线路：排在后面，内部按 sort 升序
        final aggregateSources = await _fetchAggregateSources(vodId);
        if (aggregateSources.isNotEmpty) {
          aggregateSources.sort((a, b) => a.sort.compareTo(b.sort));
          debugPrint('[追剧HTTP] 聚合线路数=${aggregateSources.length} 合并后总数=${sources.length + aggregateSources.length}');
          sources.addAll(aggregateSources);
        }

        return {
          'status': true,
          'data': DoubanVodDetailModel(
            vodId: vodId.toString(),
            vodName: vod['vod_name'] ?? '',
            vodPic: cleanVodPic(vod['vod_pic'] ?? ''),
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

  /// 获取站外聚合线路（search_aggregate 接口）
  static Future<List<DoubanSourceModel>> _fetchAggregateSources(
      dynamic vodId) async {
    try {
      final resp = await _upstreamGet(
        '/api.php/web/internal/search_aggregate',
        params: {'vod_id': vodId.toString()},
      );

      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data['code'] != 200) return [];

        final list = data['data'] as List<dynamic>? ?? [];
        final sources = <DoubanSourceModel>[];

        for (final item in list) {
          final siteKey = item['site_key'] as String? ?? '';
          final siteName = item['site_name'] as String? ?? '';
          if (siteKey.isEmpty) continue;

          final epRaw = (item['vod_play_url'] as String? ?? '')
              .split('#')
              .where((s) => s.trim().isNotEmpty)
              .toList();

          final episodes = epRaw.asMap().entries.map((entry) {
            final parts = entry.value.split('\$');
            return DoubanEpisodeModel(
              nid: entry.key + 1,
              title: parts.isNotEmpty ? parts[0] : '第${entry.key + 1}集',
              videoId: parts.length > 1 ? parts[1] : '',
            );
          }).toList();

          sources.add(DoubanSourceModel(
            key: siteKey,
            name: siteName,
            sort: (item['sort'] as num?)?.toDouble() ?? 0,
            decodeStatus: (item['decode_status'] ?? '0').toString(),
            episodeCount: episodes.length,
            episodes: episodes,
          ));
        }

        return sources;
      }
      return [];
    } catch (_) {
      // 聚合接口失败不影响主流程
      return [];
    }
  }

  /// 当前活跃线路 host（供播放器设置 Referer）
  static String get serverHost => _activeHost;

  // ============ 上游 API：解码 ============

  /// 解码视频 URL → M3U8
  static Future<Map<String, dynamic>> decodeVod({
    required dynamic vodId,
    required String sid,
    required int nid,
    String? videoId,
  }) async {
    try {
      // 如果没有传入 videoId，从详情中获取
      String targetVideoId = videoId ?? '';
      if (targetVideoId.isEmpty) {
        final detailResp = await getVodDetail(vodId);
        if (detailResp['status'] != true || detailResp['data'] == null) {
          return {'status': false, 'data': null, 'msg': '获取详情失败'};
        }
        final detail = detailResp['data'] as DoubanVodDetailModel;
        for (final source in detail.sources) {
          if (source.key == sid) {
            for (final ep in source.episodes) {
              if (ep.nid == nid && ep.videoId.isNotEmpty) {
                targetVideoId = ep.videoId;
                break;
              }
            }
            break;
          }
        }
      }

      if (targetVideoId.isEmpty) {
        return {'status': false, 'data': null, 'msg': '未找到对应的 videoId'};
      }

      // M3U8 直链：无需 WASM 解码，直接播放
      if (targetVideoId.endsWith('.m3u8')) {
        return {
          'status': true,
          'data': DoubanDecodeResultModel(
            url: targetVideoId,
            source: sid,
            episode: nid.toString(),
          ),
        };
      }

      logger.d('[追剧HTTP] WASM解码 vodId=$vodId sid=$sid nid=$nid videoId=$targetVideoId');

      // 聚合线路从 site_key 提取短码：site_xxx_qq → qq
      final siteKey = sid.startsWith('site_') ? sid.split('_').last : sid;
      final host = _activeHost.replaceFirst('https://', '');
      final decodeResult = await UpstreamDecoder.decode(
        upstreamHost: host,
        videoId: targetVideoId,
        siteKey: siteKey,
      );

      if (decodeResult['status'] == true && decodeResult['data'] != null) {
        final data = decodeResult['data'] as Map<String, dynamic>;
        return {
          'status': true,
          'data': DoubanDecodeResultModel(
            url: data['m3u8Url'] ?? '',
            source: data['source'] ?? sid,
            episode: data['episode']?.toString() ?? '',
          ),
        };
      }
      return {'status': false, 'data': null, 'msg': decodeResult['msg'] ?? '解码失败'};
    } catch (e) {
      logger.e('[追剧HTTP] 解码异常 $e');
      return {'status': false, 'data': null, 'msg': '网络错误: $e'};
    }
  }
}
