import 'package:PiliMiLe/http/browser_ua.dart';
import 'package:PiliMiLe/models/search/result.dart';
import 'package:PiliMiLe/services/logger.dart';
import 'package:PiliMiLe/utils/storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
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
          logger.d('GET ${options.uri}');
          handler.next(options);
        },
      ));
    }

    return d;
  }

  // ============ 上游镜像站配置 ============

  static final Dio _upstreamDio = Dio(BaseOptions(
    connectTimeout: const Duration(milliseconds: 12000),
    receiveTimeout: const Duration(milliseconds: 12000),
  ));

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
                    vodPic: item['vod_pic'] ?? '',
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
}
