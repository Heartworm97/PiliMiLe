import 'dart:convert';
import 'dart:typed_data';

import 'package:PiliMiLe/services/logger.dart';
import 'package:PiliMiLe/services/wasm_bridge.dart';
import 'package:dio/dio.dart';

/// 上游解码服务 — 组合 WASM 编解码 + HTTP 请求
///
/// 完整流程：
/// 1. WasmBridge.createDecodeRequest(videoId, siteKey) → protobuf 字节
/// 2. POST protobuf → 上游 /api.php/web/decode/url
/// 3. WasmBridge.parseDecodeResponse(responseBytes) → M3U8 URL
class UpstreamDecoder {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  static const String _webSign = 'f65f3a83d6d9ad6f';
  static const String _xClient = '8f3d2a1c7b6e5d4c9a0b1f2e3d4c5b6a';

  /// 解码视频 → 返回 M3U8 URL
  ///
  /// [upstreamHost] 上游线路域名 (如 asd123sx23xdacsx.top)
  /// [videoId] 从 vod_play_url 解析出的视频 ID
  /// [siteKey] 线路 key (如 "co", "YYNB")
  static Future<Map<String, dynamic>> decode({
    required String upstreamHost,
    required String videoId,
    required String siteKey,
  }) async {
    // 等待 WASM 就绪
    logger.d('[UpstreamDecoder] 等待 WASM 就绪...');
    final ready = await WasmBridge().ready;
    if (!ready) {
      logger.e('[UpstreamDecoder] WASM 未就绪');
      return {'status': false, 'msg': 'WASM 模块初始化中，请稍后重试'};
    }
    logger.d('[UpstreamDecoder] WASM 已就绪');

    // 1. 创建解码请求
    Uint8List reqBytes;
    try {
      logger.d('[UpstreamDecoder] createDecodeRequest($videoId, $siteKey)');
      reqBytes = await WasmBridge().createDecodeRequest(videoId, siteKey);
      logger.d('[UpstreamDecoder] 请求 protobuf ${reqBytes.length} 字节');
    } catch (e) {
      logger.e('[UpstreamDecoder] createDecodeRequest 失败: $e');
      return {'status': false, 'msg': 'WASM 编码失败: $e'};
    }

    // 2. POST 到上游
    Response resp;
    try {
      logger.d('[UpstreamDecoder] POST https://$upstreamHost/api.php/web/decode/url');
      resp = await _dio.post(
        'https://$upstreamHost/api.php/web/decode/url',
        data: Stream.fromIterable([reqBytes]),
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
            'Referer': 'https://$upstreamHost/',
            'web-sign': _webSign,
            'X-Client': _xClient,
            'Content-Type': 'application/x-protobuf',
            'Accept': 'application/x-protobuf',
          },
          responseType: ResponseType.bytes,
        ),
      );
      logger.d('[UpstreamDecoder] HTTP ${resp.statusCode}, ${(resp.data is List ? resp.data.length : 0)} 字节');
    } on DioException catch (e) {
      logger.e('[UpstreamDecoder] HTTP 失败: ${e.type} ${e.message}');
      if (e.response != null) {
        logger.e('[UpstreamDecoder] 响应体: ${_safeString(e.response?.data)}');
      }
      return {'status': false, 'msg': '解码请求失败: ${e.message}'};
    }

    // 3. 解析解码响应
    try {
      final respBytes = Uint8List.fromList(resp.data is List<int>
          ? resp.data
          : (resp.data as List<dynamic>).cast<int>());

      final result = await WasmBridge().parseDecodeResponse(respBytes);
      logger.d('[UpstreamDecoder] 解析: code=${result.code} msg=${result.msg}');

      if (result.code != 1 || result.data.isEmpty) {
        final errMsg = result.msg.isNotEmpty
            ? '解码失败(${result.code}): ${result.msg}'
            : '解码失败(${result.code}): 上游返回空数据';
        return {'status': false, 'msg': errMsg, 'data': null};
      }

      return {
        'status': true,
        'data': {
          'm3u8Url': result.data,
          'source': siteKey,
          'episode': '',
        },
      };
    } catch (e) {
      logger.e('[UpstreamDecoder] parseDecodeResponse 失败: $e');
      logger.e('[UpstreamDecoder] 原始响应 hex: ${_safeHex(resp.data)}');
      return {'status': false, 'msg': 'WASM 解码失败: $e'};
    }
  }

  /// 安全转字符串（截断 500 字符）
  static String _safeString(dynamic data) {
    try {
      if (data is List<int>) {
        return utf8.decode(data, allowMalformed: true).substring(0, 500);
      }
      return data.toString().substring(0, 500);
    } catch (_) {
      return '<无法解码>';
    }
  }

  /// 安全转 Hex（截断 200 字节）
  static String _safeHex(dynamic data) {
    try {
      if (data is List<int>) {
        final hex = data.take(200).map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
        return '$hex${data.length > 200 ? '...(截断)' : ''}';
      }
      return '<非字节数组>';
    } catch (_) {
      return '<转换失败>';
    }
  }
}
