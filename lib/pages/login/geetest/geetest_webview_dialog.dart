import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:io' show Platform;

import 'package:PiliMiLe/http/browser_ua.dart';
import 'package:PiliMiLe/http/init.dart';
import 'package:PiliMiLe/http/loading_state.dart';
import 'package:PiliMiLe/main.dart';
import 'package:PiliMiLe/utils/accounts/account.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

class GeetestWebviewDialog extends StatefulWidget {
  const GeetestWebviewDialog(this.gt, this.challenge, {super.key});

  final String gt;
  final String challenge;

  @override
  State<GeetestWebviewDialog> createState() => _GeetestWebviewDialogState();

  static Future geetest(String gt, String challenge) {
    return showDialog(
      context: Get.context!,
      builder: (context) => GeetestWebviewDialog(gt, challenge),
    );
  }
}

class _GeetestWebviewDialogState extends State<GeetestWebviewDialog> {
  static const _geetestJsUri =
      'https://static.geetest.com/static/js/fullpage.0.0.0.js';

  /// 极验配置 JSON 字符串
  String? _configJson;

  /// 极验 JS 库源码（内联用）
  String? _jsSource;

  /// 获取失败时的错误信息
  String? _errorMsg;

  /// WebView 控制器，数据就绪后用于 loadData
  InAppWebViewController? _controller;

  static String _showJs(String response) =>
      't=Geetest($response).onSuccess(()=>R("success",t.getValidate())).onError(o=>R("error",o)).onClose(o=>R("close",o));t.onReady(()=>t.verify())';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  /// 并行获取极验配置和 JS 库源码
  Future<void> _fetchData() async {
    debugPrint(
      '[geetest] 开始并行获取, gt=${widget.gt}, challenge=${widget.challenge.substring(0, 16)}...',
    );
    final results = await Future.wait([
      _getConfig(widget.gt, widget.challenge),
      _fetchGeetestJs(),
    ]);
    if (!mounted) return;
    if (results[0].isSuccess && results[1].isSuccess) {
      final jsSrc = results[1].dataOrNull!;
      debugPrint('[geetest] 数据获取成功, JS长度=${jsSrc.length}');
      setState(() {
        _configJson = results[0].dataOrNull;
        _jsSource = jsSrc;
      });
      // 数据就绪，如果 WebView 已创建则立即加载完整 HTML
      _tryLoadCaptcha();
    } else {
      final err = results[0].dataOrNull == null
          ? (results[0] as Error).errMsg
          : results[1].dataOrNull == null
              ? (results[1] as Error).errMsg
              : '未知错误';
      debugPrint('[geetest] 数据获取失败: $err');
      setState(() { _errorMsg = err; });
    }
  }

  /// 获取极验配置（通过 HTTP API）
  static Future<LoadingState<String>> _getConfig(
    String gt,
    String challenge,
  ) async {
    try {
      final res = await Request().get<String>(
        'https://api.geetest.com/gettype.php',
        queryParameters: {'gt': gt},
        options: Options(
          responseType: ResponseType.plain,
          extra: {'account': const NoAccount()},
        ),
      );
      if (res.data case final String data) {
        if (data.startsWith('(') && data.endsWith(')')) {
          final Map<String, dynamic> config;
          try {
            config = jsonDecode(data.substring(1, data.length - 1));
          } catch (e) {
            return Error('极验配置解析失败: $e');
          }
          if (config['status'] == 'success') {
            return Success(
              jsonEncode(
                config['data'] as Map<String, dynamic>..addAll({
                  "gt": gt,
                  "challenge": challenge,
                  "offline": false,
                  "new_captcha": true,
                  "product": "bind",
                  "width": "100%",
                  "https": true,
                  "protocol": "https://",
                }),
              ),
            );
          } else {
            return Error(data);
          }
        }
      }
      return Error(res.data['message'] ?? '未知错误');
    } catch (e) {
      return Error('获取极验配置异常: $e');
    }
  }

  /// 获取极验 JS 库源码（通过 HTTP，与 WebView 无关）
  static Future<LoadingState<String>> _fetchGeetestJs() async {
    try {
      final res = await Request().get<String>(
        _geetestJsUri,
        options: Options(
          responseType: ResponseType.plain,
          extra: {'account': const NoAccount()},
        ),
      );
      if (res.data case final String data) {
        if (data.isNotEmpty) {
          return Success(data);
        }
        return const Error('极验JS响应为空');
      }
      return const Error('极验JS响应格式异常');
    } catch (e) {
      return Error('获取极验JS异常: $e');
    }
  }

  /// 构建包含内联 JS 的完整 HTML
  String _buildHtml() {
    // 检查 JS 中是否包含 </script>（极验 JS 通常不含此序列）
    if (_jsSource!.contains('</script>')) {
      debugPrint('[geetest] 警告: JS源码包含</script>，可能导致HTML解析异常');
    }
    return '<!DOCTYPE html><html><head>'
        '<meta name="viewport" content="width=device-width">'
        '</head><body>'
        '<script>$_jsSource</script>'
        '<script>R=flutter_inappwebview.callHandler</script>'
        '</body></html>';
  }

  /// 如果 WebView 和数据都已就绪，加载完整验证码 HTML
  void _tryLoadCaptcha() {
    if (_controller != null && _configJson != null && _jsSource != null) {
      final html = _buildHtml();
      debugPrint('[geetest] loadData 加载完整 HTML, 长度=${html.length}');
      _controller!.loadData(data: html, mimeType: 'text/html');
    }
  }

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorMsg != null;
    final ready = _configJson != null && _jsSource != null;

    if (hasError) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Get.back();
      });
    }

    return Stack(
      children: [
        // WebView 始终构建，数据就绪前用空白 HTML
        InAppWebView(
          webViewEnvironment: webViewEnvironment,
          initialSettings: InAppWebViewSettings(
            clearCache: true,
            javaScriptEnabled: true,
            forceDark: ForceDark.AUTO,
            useHybridComposition: false,
            algorithmicDarkeningAllowed: true,
            useShouldOverrideUrlLoading: true,
            userAgent: BrowserUa.mob,
            mixedContentMode: .MIXED_CONTENT_ALWAYS_ALLOW,

            incognito: true,
            allowFileAccess: false,
            allowsLinkPreview: false,
            allowContentAccess: false,
            useOnDownloadStart: false,
            geolocationEnabled: false,
            thirdPartyCookiesEnabled: false,
            enterpriseAuthenticationAppLinkPolicyEnabled: false,
            saveFormData: false,
            safeBrowsingEnabled: false,
            isFraudulentWebsiteWarningEnabled: false,
            domStorageEnabled: false,
            databaseEnabled: false,
            cacheEnabled: false,
            cacheMode: .LOAD_NO_CACHE,

            horizontalScrollBarEnabled: false,
            verticalScrollBarEnabled: false,
            overScrollMode: .NEVER,

            pageZoom: Platform.isIOS ? 3 : 1,
          ),
          initialData: InAppWebViewInitialData(
            data: '<!DOCTYPE html><html><head></head><body></body></html>',
          ),
          onWebViewCreated: (ctr) {
            debugPrint('[geetest] WebView 已创建');
            _controller = ctr;
            ctr
              ..addJavaScriptHandler(
                handlerName: 'success',
                callback: (args) {
                  debugPrint('[geetest] 验证成功: $args');
                  if (args.isNotEmpty) {
                    if (args[0] case Map<String, dynamic> data) {
                      Get.back(result: data);
                      return;
                    }
                  }
                },
              )
              ..addJavaScriptHandler(
                handlerName: 'error',
                callback: (args) {
                  debugPrint('[geetest] 验证出错: $args');
                },
              )
              ..addJavaScriptHandler(
                handlerName: 'close',
                callback: (args) {
                  debugPrint('[geetest] 用户关闭验证');
                  Get.back();
                },
              );
            // 如果数据已在 WebView 创建前就绪，直接加载完整 HTML
            _tryLoadCaptcha();
          },
          onLoadStop: (ctr, _) {
            debugPrint('[geetest] onLoadStop 触发, ready=${_configJson != null}');
            if (_configJson != null) {
              debugPrint('[geetest] 注入初始化 JS');
              ctr.evaluateJavascript(source: _showJs(_configJson!));
            }
          },
          onConsoleMessage: (ctr, msg) {
            debugPrint('[geetest] JS [${msg.messageLevel}]: ${msg.message}');
          },
        ),
        // 关闭按钮
        Positioned(
          left: 8,
          top: 8,
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: Get.back,
            tooltip: '关闭',
          ),
        ),
        // 加载指示器遮罩
        if (!ready && !hasError)
          const Center(child: CircularProgressIndicator()),
        // 错误提示
        if (hasError)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '验证码加载失败',
                style: TextStyle(color: ColorScheme.of(context).error),
              ),
            ),
          ),
      ],
    );
  }
}
