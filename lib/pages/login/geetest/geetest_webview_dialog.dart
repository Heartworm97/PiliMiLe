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
        // 转义 </ 防止 HTML 解析时提前关闭 script 标签
        _jsSource = jsSrc.replaceAll('</', '<\\/');
      });
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

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 获取失败：短暂显示错误后关闭
    if (_errorMsg != null) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) Get.back();
      });
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '验证码加载失败',
            style: TextStyle(color: ColorScheme.of(context).error),
          ),
        ),
      );
    }

    // 数据未就绪：显示加载指示器
    if (_configJson == null || _jsSource == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // 构建内联 JS 的 HTML（不再依赖外部 URL）
    final html =
        '<!DOCTYPE html><html><head>'
        '<meta name="viewport" content="width=device-width">'
        '</head><body>'
        '<script>$_jsSource</script>'
        '<script>R=flutter_inappwebview.callHandler</script>'
        '</body></html>';

    return Stack(
      children: [
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
          initialData: InAppWebViewInitialData(data: html),
          onWebViewCreated: (ctr) {
            debugPrint('[geetest] WebView 已创建');
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
          },
          onLoadStop: (ctr, _) {
            debugPrint('[geetest] onLoadStop 触发, 注入初始化 JS');
            ctr.evaluateJavascript(source: _showJs(_configJson!));
          },
          onConsoleMessage: (ctr, msg) {
            debugPrint('[geetest] JS [${msg.messageLevel}]: ${msg.message}');
          },
        ),
        Positioned(
          left: 8,
          top: 8,
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: Get.back,
            tooltip: '关闭',
          ),
        ),
      ],
    );
  }
}
