import 'package:PiliMiLe/http/browser_ua.dart';
import 'package:PiliMiLe/services/logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class DoubanHttp {
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
}
