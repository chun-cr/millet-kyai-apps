// 认证模块状态提供层：`CaptchaResolverProvider`。通过 Riverpod 向页面暴露查询、写操作和异步状态。

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'aliyun_captcha_web_delegate_stub.dart'
    if (dart.library.html) 'aliyun_captcha_web_delegate.dart'
    as aliyun_captcha_web;

const _aliyunCaptchaProvider = 'ALIYUN';

abstract class CaptchaResolver {
  Future<Map<String, String>?> resolve({
    required BuildContext context,
    required String challengeId,
    required String provider,
    Map<String, dynamic>? initPayload,
  });
}

final captchaResolverProvider = Provider<CaptchaResolver>((ref) {
  return const SmartCaptchaResolver();
});

class SmartCaptchaResolver implements CaptchaResolver {
  const SmartCaptchaResolver({
    this.manualFallback = const ManualCaptchaResolver(),
  });

  final CaptchaResolver manualFallback;

  @override
  Future<Map<String, String>?> resolve({
    required BuildContext context,
    required String challengeId,
    required String provider,
    Map<String, dynamic>? initPayload,
  }) async {
    final normalizedProvider = provider.trim().toUpperCase();
    if (normalizedProvider != _aliyunCaptchaProvider) {
      return manualFallback.resolve(
        context: context,
        challengeId: challengeId,
        provider: provider,
        initPayload: initPayload,
      );
    }

    final config = AliyunCaptchaConfig.tryParse(
      challengeId: challengeId,
      provider: normalizedProvider,
      initPayload: initPayload,
    );
    if (config == null) {
      await _showUnsupportedDialog(context);
      return null;
    }

    if (kIsWeb) {
      final captchaVerifyParam = await aliyun_captcha_web.showAliyunCaptchaWebDialog(
        context: context,
        url: config.buildUri(),
        challengeId: challengeId,
        title: context.l10n.authCaptchaTitle,
        cancelLabel: MaterialLocalizations.of(context).cancelButtonLabel,
        loadingText: context.l10n.authCaptchaLoadingPage,
        readyText: context.l10n.authCaptchaReady,
        failedText: context.l10n.authCaptchaFailed,
        pageLoadFailedText: context.l10n.authCaptchaPageLoadFailed,
        initFailedText: context.l10n.authCaptchaInitFailed,
      );
      if (captchaVerifyParam == null || captchaVerifyParam.isEmpty) {
        return null;
      }
      return {'captchaVerifyParam': captchaVerifyParam};
    }

    if (!_supportsEmbeddedAliyunCaptcha) {
      return manualFallback.resolve(
        context: context,
        challengeId: challengeId,
        provider: provider,
        initPayload: initPayload,
      );
    }

    final captchaVerifyParam = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => AliyunCaptchaPage(config: config)),
    );
    if (captchaVerifyParam == null || captchaVerifyParam.isEmpty) {
      return null;
    }

    return {'captchaVerifyParam': captchaVerifyParam};
  }

  Future<void> _showUnsupportedDialog(BuildContext context) {
    final l10n = context.l10n;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.authCaptchaTitle),
          content: Text(l10n.authCaptchaRequiredUnsupported),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.commonConfirm),
            ),
          ],
        );
      },
    );
  }

  bool get _supportsEmbeddedAliyunCaptcha {
    if (kIsWeb) {
      return false;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => true,
      TargetPlatform.iOS => true,
      TargetPlatform.macOS => true,
      TargetPlatform.fuchsia => false,
      TargetPlatform.linux => false,
      TargetPlatform.windows => false,
    };
  }
}

class ManualCaptchaResolver implements CaptchaResolver {
  const ManualCaptchaResolver();

  @override
  Future<Map<String, String>?> resolve({
    required BuildContext context,
    required String challengeId,
    required String provider,
    Map<String, dynamic>? initPayload,
  }) async {
    final controller = TextEditingController(text: '{}');
    try {
      return await showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          String? errorText;
          final l10n = dialogContext.l10n;
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(l10n.authCaptchaTitle),
                content: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.authCaptchaManualPrompt(provider)),
                        if (initPayload != null && initPayload.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            l10n.authCaptchaInitPayloadLabel,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F4EE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SelectableText(_prettyJson(initPayload)),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          l10n.authCaptchaResultJsonLabel,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          key: const ValueKey('captcha_payload_input'),
                          controller: controller,
                          minLines: 4,
                          maxLines: 8,
                          decoration: InputDecoration(
                            hintText: l10n.authCaptchaManualResultHint,
                            errorText: errorText,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    key: const ValueKey('captcha_dialog_cancel'),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      MaterialLocalizations.of(dialogContext).cancelButtonLabel,
                    ),
                  ),
                  FilledButton(
                    key: const ValueKey('captcha_dialog_confirm'),
                    onPressed: () {
                      final payload = _parsePayload(controller.text);
                      if (payload == null) {
                        setState(() {
                          errorText = l10n.authCaptchaInvalidJson;
                        });
                        return;
                      }
                      Navigator.of(dialogContext).pop(payload);
                    },
                    child: Text(l10n.commonContinue),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  static String _prettyJson(Map<String, dynamic> payload) {
    try {
      return const JsonEncoder.withIndent('  ').convert(payload);
    } catch (_) {
      return payload.toString();
    }
  }

  static Map<String, String>? _parsePayload(String raw) {
    final input = raw.trim();
    if (input.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(input);
    if (decoded is! Map) {
      return null;
    }

    final payload = <String, String>{};
    for (final entry in decoded.entries) {
      final key = entry.key?.toString().trim() ?? '';
      if (key.isEmpty || entry.value == null) {
        return null;
      }
      payload[key] = entry.value.toString();
    }
    return payload;
  }
}

class AliyunCaptchaConfig {
  const AliyunCaptchaConfig({
    required this.challengeId,
    required this.provider,
    required this.sceneId,
    required this.region,
    required this.prefix,
    required this.userCertifyId,
    required this.h5Url,
    required this.mode,
  });

  final String challengeId;
  final String provider;
  final String sceneId;
  final String region;
  final String prefix;
  final String userCertifyId;
  final String h5Url;
  final String mode;

  static AliyunCaptchaConfig? tryParse({
    required String challengeId,
    required String provider,
    Map<String, dynamic>? initPayload,
  }) {
    final payload = initPayload;
    if (payload == null) {
      return null;
    }

    final sceneId = _trimmedString(payload['sceneId']);
    final prefix = _trimmedString(payload['prefix']);
    final userCertifyId = _trimmedString(payload['userCertifyId']);
    final h5Url = _trimmedString(payload['h5Url']);
    final h5Uri = h5Url == null ? null : Uri.tryParse(h5Url);

    if (sceneId == null ||
        prefix == null ||
        userCertifyId == null ||
        h5Url == null ||
        h5Uri == null ||
        h5Uri.scheme.toLowerCase() != 'https') {
      return null;
    }

    return AliyunCaptchaConfig(
      challengeId: challengeId,
      provider: provider,
      sceneId: sceneId,
      region: _trimmedString(payload['region']) ?? 'cn',
      prefix: prefix,
      userCertifyId: userCertifyId,
      h5Url: h5Url,
      mode: _trimmedString(payload['mode']) ?? '',
    );
  }

  Uri buildUri() {
    final uri = Uri.parse(h5Url);
    return uri.replace(
      queryParameters: <String, String>{
        ...uri.queryParameters,
        'sceneId': sceneId,
        'region': region,
        'prefix': prefix,
        'userCertifyId': userCertifyId,
        'provider': provider,
        'challengeId': challengeId,
      },
    );
  }
}

class AliyunCaptchaBridgeEvent {
  const AliyunCaptchaBridgeEvent({
    required this.type,
    this.captchaVerifyParam,
    this.message,
  });

  final String type;
  final String? captchaVerifyParam;
  final String? message;

  static AliyunCaptchaBridgeEvent? tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }

      final type = _trimmedString(decoded['type']);
      if (type == null) {
        return null;
      }

      final captchaVerifyParam = decoded['captchaVerifyParam'];
      return AliyunCaptchaBridgeEvent(
        type: type,
        captchaVerifyParam: captchaVerifyParam is String
            ? (captchaVerifyParam.isEmpty ? null : captchaVerifyParam)
            : null,
        message: _trimmedString(decoded['message']),
      );
    } catch (_) {
      return null;
    }
  }
}

enum _AliyunCaptchaStatus { loading, ready, failed, pageLoadFailed, initFailed }

class AliyunCaptchaPage extends StatefulWidget {
  const AliyunCaptchaPage({super.key, required this.config});

  final AliyunCaptchaConfig config;

  @override
  State<AliyunCaptchaPage> createState() => _AliyunCaptchaPageState();
}

class _AliyunCaptchaPageState extends State<AliyunCaptchaPage> {
  late final WebViewController _controller;
  _AliyunCaptchaStatus _status = _AliyunCaptchaStatus.loading;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _status = _AliyunCaptchaStatus.pageLoadFailed;
            });
          },
        ),
      )
      ..addJavaScriptChannel(
        'CaptchaBridge',
        onMessageReceived: _handleBridgeMessage,
      )
      ..loadRequest(widget.config.buildUri());
  }

  void _handleBridgeMessage(JavaScriptMessage message) {
    final event = AliyunCaptchaBridgeEvent.tryParse(message.message);
    if (event == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = _AliyunCaptchaStatus.initFailed;
      });
      return;
    }

    switch (event.type) {
      case 'ready':
        if (!mounted) {
          return;
        }
        setState(() {
          _status = _AliyunCaptchaStatus.ready;
        });
        return;
      case 'success':
        final captchaVerifyParam = event.captchaVerifyParam;
        if (!mounted) {
          return;
        }
        if (captchaVerifyParam == null || captchaVerifyParam.isEmpty) {
          setState(() {
            _status = _AliyunCaptchaStatus.initFailed;
          });
          return;
        }
        Navigator.of(context).pop(captchaVerifyParam);
        return;
      case 'fail':
        if (!mounted) {
          return;
        }
        setState(() {
          _status = _AliyunCaptchaStatus.failed;
        });
        return;
      case 'error':
      default:
        if (!mounted) {
          return;
        }
        setState(() {
          _status = _AliyunCaptchaStatus.initFailed;
        });
        return;
    }
  }

  String _statusText(BuildContext context) {
    final l10n = context.l10n;
    return switch (_status) {
      _AliyunCaptchaStatus.loading => l10n.authCaptchaLoadingPage,
      _AliyunCaptchaStatus.ready => l10n.authCaptchaReady,
      _AliyunCaptchaStatus.failed => l10n.authCaptchaFailed,
      _AliyunCaptchaStatus.pageLoadFailed => l10n.authCaptchaPageLoadFailed,
      _AliyunCaptchaStatus.initFailed => l10n.authCaptchaInitFailed,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.authCaptchaTitle)),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.black12,
            padding: const EdgeInsets.all(12),
            child: Text(_statusText(context)),
          ),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}

String? _trimmedString(dynamic value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return raw;
}
