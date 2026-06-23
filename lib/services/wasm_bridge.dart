import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:PiliMiLe/services/logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';

/// 上游解码结果
class DecodeResult {
  final int code;
  final int errorCode;
  final String msg;
  final String data;

  const DecodeResult({
    required this.code,
    required this.errorCode,
    required this.msg,
    required this.data,
  });
}

/// WASM 桥接层 — 用隐藏 HeadlessInAppWebView 运行上游 WASM 模块
class WasmBridge {
  static final WasmBridge _instance = WasmBridge._();
  factory WasmBridge() => _instance;
  WasmBridge._();

  InAppWebViewController? _controller;
  HeadlessInAppWebView? _headlessWebView;
  final Completer<bool> _readyCompleter = Completer<bool>();
  bool _initialized = false;

  bool get isReady => _initialized;
  Future<bool> get ready => _readyCompleter.future;

  /// 初始化并启动 HeadlessInAppWebView
  Future<void> init(String upstreamHost) async {
    if (_initialized) return;

    final loadCompleter = Completer<void>();

    _headlessWebView = HeadlessInAppWebView(
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: true,
      ),
      onWebViewCreated: (controller) {
        _controller = controller;
      },
      onLoadStop: (controller, url) {
        if (!loadCompleter.isCompleted) {
          loadCompleter.complete();
        }
      },
      onConsoleMessage: (controller, consoleMessage) {
        logger.d('[WasmBridge] JS: ${consoleMessage.message}');
      },
    );

    await _headlessWebView!.run();

    // 准备 HTML 并加载
    final html = await _buildHtml(upstreamHost);
    await _controller!.loadData(
      data: html,
      mimeType: 'text/html',
      encoding: 'utf-8',
      baseUrl: WebUri('https://$upstreamHost/'),
    );

    // 等待 onLoadStop
    await loadCompleter.future;

    // 轮询 WASM 就绪
    await _waitForWasm();
  }

  Future<String> _callJs(String js) async {
    if (_controller == null) throw StateError('WasmBridge 未初始化');
    final result = await _controller!.evaluateJavascript(source: js);
    if (result is String) return result;
    if (result is num) return result.toString();
    return '';
  }

  /// 创建解码请求 → protobuf 字节
  Future<Uint8List> createDecodeRequest(String videoId, String siteKey) async {
    final base64 = await _callJs(
      'wasmCreateDecodeRequest("${_escapeJs(videoId)}", "${_escapeJs(siteKey)}")',
    );
    if (base64.isEmpty) {
      throw Exception('WASM 编码返回空');
    }
    if (base64.startsWith('ERROR:')) {
      throw Exception('WASM 编码失败: ${base64.substring(6)}');
    }
    return base64Decode(base64);
  }

  /// 解析解码响应 → M3U8 URL
  Future<DecodeResult> parseDecodeResponse(Uint8List bytes) async {
    final base64Input = base64Encode(bytes);
    final json = await _callJs('wasmParseDecodeResponse("$base64Input")');
    if (json.isEmpty) {
      throw Exception('WASM 解码返回空');
    }
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return DecodeResult(
        code: (map['code'] as num?)?.toInt() ?? -1,
        errorCode: (map['errorCode'] as num?)?.toInt() ?? 0,
        msg: map['msg'] as String? ?? '',
        data: map['data'] as String? ?? '',
      );
    } catch (e) {
      throw Exception('WASM 解码 JSON 解析失败: ${json.substring(0, 200)}');
    }
  }

  static String _escapeJs(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
  }

  /// 轮询等待 WASM 就绪（间隔 100ms，最多等 20 秒）
  Future<void> _waitForWasm() async {
    int attempts = 0;
    while (attempts < 200) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
      try {
        final result = await _controller!.evaluateJavascript(source: 'wasmReady');
        if (result is bool && result) {
          _initialized = true;
          if (!_readyCompleter.isCompleted) {
            _readyCompleter.complete(true);
          }
          return;
        }
      } catch (_) {}
    }
    logger.w('[WasmBridge] WASM 初始化超时');
  }

  /// 下载 WASM → base64 → 嵌入 HTML
  Future<String> _buildHtml(String upstreamHost) async {
    final dir = await getApplicationDocumentsDirectory();
    final wasmDir = Directory('${dir.path}/wasm_bridge');
    if (!await wasmDir.exists()) {
      await wasmDir.create(recursive: true);
    }

    final wasmFile = File('${wasmDir.path}/web_app.wasm');
    final wasmUrl = await _resolveWasmUrl(upstreamHost);
    final urlCacheFile = File('${wasmDir.path}/wasm_url.txt');

    bool needDownload = !await wasmFile.exists();
    if (!needDownload && await urlCacheFile.exists()) {
      final cachedUrl = await urlCacheFile.readAsString();
      if (cachedUrl.trim() != wasmUrl) needDownload = true;
    }

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    if (needDownload) {
      await dio.download(
        'https://$upstreamHost$wasmUrl',
        wasmFile.path,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
            'Referer': 'https://$upstreamHost/',
          },
        ),
      );
      await urlCacheFile.writeAsString(wasmUrl);
    }

    final wasmBytes = await wasmFile.readAsBytes();
    final wasmBase64 = base64Encode(wasmBytes);
    return _buildWasmHtml(wasmBase64);
  }

  /// 动态解析 WASM URL
  Future<String> _resolveWasmUrl(String upstreamHost) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final htmlResp = await dio.get(
        'https://$upstreamHost/',
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
            'Accept': 'text/html',
          },
        ),
      );
      final html = htmlResp.data as String;
      final jsMatch = RegExp(
        r'<script[^>]*type="module"[^>]*src="(/assets/index-[^"]+\.js)"',
      ).firstMatch(html);

      if (jsMatch != null) {
        final jsContent = await dio.get(
          'https://$upstreamHost${jsMatch.group(1)!}',
          options: Options(headers: {'Accept': 'application/javascript'}),
        );
        final wasmMatch = RegExp(
          r'(web_app_wasm_bg-[a-zA-Z0-9_-]+\.wasm)',
        ).firstMatch(jsContent.data as String);

        if (wasmMatch != null) {
          return '/assets/${wasmMatch.group(1)!}';
        }
      }
    } catch (_) {}
    return '/assets/web_app_wasm_bg-DaFtKBCq.wasm';
  }

  /// 释放资源
  Future<void> dispose() async {
    if (_headlessWebView != null) {
      await _headlessWebView!.dispose();
      _headlessWebView = null;
      _controller = null;
      _initialized = false;
    }
  }

  /// 构建嵌入 WASM base64 的 HTML
  static String _buildWasmHtml(String wasmBase64) {
    return '''
<!DOCTYPE html>
<html><head><meta charset="utf-8"></head><body>
<script>
var wasmReady = false;
var wasmExports = null;
var externrefTable = [];
var nextExternref = 1;

function externrefAlloc(obj) { var idx=nextExternref++; externrefTable[idx]=obj; return idx; }
function externrefGet(idx) { return externrefTable[idx]||null; }
function _cleanupExternrefs() {
  if (nextExternref > 20) {
    externrefTable = externrefTable.slice(0, 2);
    nextExternref = 2;
  }
}

async function initWasm() {
  try {
    var binaryStr = atob('$wasmBase64');
    var bytes = new Uint8Array(binaryStr.length);
    for (var i = 0; i < binaryStr.length; i++) bytes[i] = binaryStr.charCodeAt(i);

    var imports = {
      './web_app_wasm_bg.js': {
        __wbg_crypto_86f2631e91b51511: function() { return externrefAlloc(window.crypto||{}); },
        __wbg_msCrypto_d562bbe83e0d4b91: function() { return externrefAlloc(null); },
        __wbg_getRandomValues_b3f15fcbfabb0f8b: function() {},
        __wbg_randomFillSync_f8c153b79f285817: function() {},
        __wbg_now_a3af9a2f4bbaa4d1: function() { return Date.now(); },
        __wbg_new_with_length_a2c39cbe88fd8ff1: function(t) { return externrefAlloc(new Uint8Array(t>>>0)); },
        __wbg_length_32ed9a279acd054c: function(t) { var o=externrefGet(t); return o?o.length:0; },
        __wbg_subarray_a96e1fef17ed23cb: function(t,r,n) { return externrefAlloc(externrefGet(t).subarray(r>>>0,n>>>0)); },
        __wbg_prototypesetcall_bdcdcc5842e4d77d: function(t,r) { externrefGet(t).set(externrefGet(r)); },
        __wbg___wbindgen_is_function_0095a73b8b156f76: function() { return 0; },
        __wbg___wbindgen_is_object_5ae8e5880f2c1fbd: function(t) { return (t&&typeof t==='object')?1:0; },
        __wbg___wbindgen_is_string_cd444516edc5b180: function(t) { return typeof t==='string'?1:0; },
        __wbg___wbindgen_is_undefined_9e4d92534c42d778: function(t) { return t===undefined?1:0; },
        __wbg_call_389efe28435a9388: function() { return externrefAlloc(function(){}); },
        __wbg_call_4708e0c13bdc8e95: function() { return externrefAlloc(function(){}); },
        __wbg_new_no_args_1c7c842f08d00ebb: function() { return externrefAlloc(function(){}); },
        __wbg_static_accessor_GLOBAL_12837167ad935116: function() { return externrefAlloc(self); },
        __wbg_static_accessor_GLOBAL_THIS_e628e89ab3b1c95f: function() { return externrefAlloc(globalThis); },
        __wbg_static_accessor_SELF_a621d3dfbb60d0ce: function() { return externrefAlloc(globalThis); },
        __wbg_static_accessor_WINDOW_f8727f0cf888e0bd: function() { return externrefAlloc(null); },
        __wbg_process_3975fd6c72f520aa: function() { return externrefAlloc({versions:{node:'0.0.0'}}); },
        __wbg_versions_4e31226f5e8dc909: function() { return externrefAlloc({node:'0.0.0'}); },
        __wbg_node_e1f24f89a7336c2e: function() { return externrefAlloc(null); },
        __wbg_require_b74f47fc2d022fd6: function() { return externrefAlloc(function(){}); },
        __wbg___wbindgen_throw_be289d5034ed271b: function(t,r) {
          var mem=new Uint8Array(wasmExports.memory.buffer);
          throw new Error(new TextDecoder('utf-8').decode(mem.slice(t,t+r)));
        },
        __wbindgen_cast_0000000000000001: function(t,r) {
          var mem=new Uint8Array(wasmExports.memory.buffer);
          return externrefAlloc(new Uint8Array(mem.slice(t,t+r)));
        },
        __wbindgen_cast_0000000000000002: function(t,r) {
          var mem=new Uint8Array(wasmExports.memory.buffer);
          return new TextDecoder('utf-8').decode(mem.slice(t,t+r));
        },
        __wbindgen_init_externref_table: function() {},
      }
    };

    var mod = await WebAssembly.instantiate(bytes, imports);
    wasmExports = mod.instance.exports;
    wasmReady = true;
  } catch(e) { console.error('WASM init error:', e); }
}
initWasm();

// ======== 导出函数 ========
var encoder = new TextEncoder();
var decoder = new TextDecoder('utf-8');

function encodeWasmString(str) {
  var e=encoder.encode(str);
  var p=wasmExports.__wbindgen_malloc(e.length,1);
  new Uint8Array(wasmExports.memory.buffer).set(e,p);
  return {ptr:p, len:e.length};
}
function readBytes(p,l) { return new Uint8Array(wasmExports.memory.buffer.slice(p,p+l)); }
function writeBytes(buf) {
  var p=wasmExports.__wbindgen_malloc(buf.length,1);
  new Uint8Array(wasmExports.memory.buffer).set(new Uint8Array(buf),p);
  return {ptr:p, len:buf.length};
}

function wasmCreateDecodeRequest(videoId, siteKey) {
  try {
    if(!wasmReady) return 'ERROR:wasm not ready';
    var vid=encodeWasmString(videoId);
    var sk=encodeWasmString(siteKey);
    var r=wasmExports.create_decode_request(vid.ptr,vid.len,sk.ptr,sk.len);
    var bytes=readBytes(r[0],r[1]);
    wasmExports.__wbindgen_free(r[0],r[1],1);
    _cleanupExternrefs();
    var bin='';
    for(var i=0;i<bytes.length;i++) bin+=String.fromCharCode(bytes[i]);
    return btoa(bin);
  } catch(e) { return 'ERROR:'+e.message; }
}

function wasmParseDecodeResponse(base64Input) {
  try {
    if(!wasmReady) return JSON.stringify({code:-1,msg:'wasm not ready',data:''});
    var bin=atob(base64Input);
    var buf=new Uint8Array(bin.length);
    for(var i=0;i<bin.length;i++) buf[i]=bin.charCodeAt(i);
    var wb=writeBytes(buf);
    var r=wasmExports.parse_decode_response(wb.ptr,wb.len);
    var code=wasmExports.decoderesult_code(r[0]);
    var errorCode=wasmExports.decoderesult_error_code(r[0]);
    var m=wasmExports.decoderesult_msg(r[0]);
    var d=wasmExports.decoderesult_data(r[0]);
    var msg=m?decoder.decode(readBytes(m[0],m[1])):'';
    var data=d?decoder.decode(readBytes(d[0],d[1])):'';
    wasmExports.__wbg_decoderesult_free(r[0],0);
    _cleanupExternrefs();
    return JSON.stringify({code:code,errorCode:errorCode,msg:msg,data:data});
  } catch(e) { return JSON.stringify({code:-1,msg:e.message,data:''}); }
}
</script></body></html>
''';
  }
}
