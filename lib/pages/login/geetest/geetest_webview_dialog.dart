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

  late final Future<LoadingState<String>> _future;

  static String _showJs(String response) =>
      't=Geetest($response).onSuccess(()=>R("success",t.getValidate())).onError(o=>R("error",o)).onClose(o=>R("close",o));t.onReady(()=>t.verify())';

  @override
  void initState() {
    super.initState();
    debugPrint('[geetest] initState, gt=${widget.gt}, challenge=${widget.challenge.substring(0, 16)}...');
    _future = _getConfig(widget.gt, widget.challenge);
  }

  static Future<LoadingState<String>> _getConfig(
    String gt,
    String challenge,
  ) async {
    debugPrint('[geetest] _getConfig 开始, gt=$gt, challenge=${challenge.substring(0, 16)}...');
    try {
      final res = await Request().get<String>(
        'https://api.geetest.com/gettype.php',
        queryParameters: {'gt': gt},
        options: Options(
          responseType: ResponseType.plain,
          extra: {'account': const NoAccount()},
        ),
      );
      debugPrint('[geetest] _getConfig 响应 statusCode=${res.statusCode}, data=${res.data?.toString().substring(0, 100)}');
      if (res.data case final String data) {
        if (data.startsWith('(') && data.endsWith(')')) {
          final Map<String, dynamic> config;
          try {
            config = jsonDecode(data.substring(1, data.length - 1));
          } catch (e) {
            debugPrint('[geetest] _getConfig JSON解析失败: $e');
            return Error(e.toString());
          }
          if (config['status'] == 'success') {
            debugPrint('[geetest] _getConfig 成功');
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
            debugPrint('[geetest] _getConfig 返回status!=success: $data');
            return Error(data);
          }
        }
      }
      debugPrint('[geetest] _getConfig 返回格式不匹配, data=${res.data}');
      return Error(res.data['message']);
    } catch (e, s) {
      debugPrint('[geetest] _getConfig 网络异常: $e\n$s');
      return Error(e.toString());
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          initialData: InAppWebViewInitialData(
            data:
                '<!DOCTYPE html><html><head><meta name="viewport" content="width=device-width"></head><body><script src="$_geetestJsUri"></script><script>R=flutter_inappwebview.callHandler</script></body></html>',
          ),
          onWebViewCreated: (ctr) {
            debugPrint('[geetest] WebView 已创建');
            ctr
              ..addJavaScriptHandler(
                handlerName: 'success',
                callback: (args) {
                  debugPrint('[geetest] JS success 回调: $args');
                  if (args.isNotEmpty) {
                    if (args[0] case Map<String, dynamic> data) {
                      Get.back(result: data);
                      return;
                    }
                  }
                  debugPrint('[geetest] 无效的验证结果: $args');
                },
              )
              ..addJavaScriptHandler(
                handlerName: 'error',
                callback: (args) {
                  debugPrint('[geetest] JS error 回调: $args');
                },
              )
              ..addJavaScriptHandler(
                handlerName: 'close',
                callback: (args) {
                  debugPrint('[geetest] JS close 回调: $args');
                  Get.back();
                },
              );
          },
          onLoadStop: (ctr, _) async {
            debugPrint('[geetest] onLoadStop 触发, 等待 _future...');
            final config = await _future;
            debugPrint('[geetest] _future 完成, mounted=$mounted, isSuccess=${config.isSuccess}');
            if (!mounted) return;
            if (config case Success(:final response)) {
              debugPrint('[geetest] 注入 JS: ${_showJs(response).substring(0, 80)}...');
              ctr.evaluateJavascript(source: _showJs(response));
            } else {
              debugPrint('[geetest] 配置获取失败, 即将关闭弹窗: $config');
              config.toast();
              Get.back();
            }
          },
          onConsoleMessage: (ctr, msg) {
            debugPrint('[geetest] JS Console [${msg.messageLevel}]: ${msg.message}');
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
