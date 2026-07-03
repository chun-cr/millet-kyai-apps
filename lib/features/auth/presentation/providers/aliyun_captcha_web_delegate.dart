// 认证模块状态提供层：`AliyunCaptchaWebDelegate`。通过 Riverpod 向页面暴露查询、写操作和异步状态。

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

Future<String?> showAliyunCaptchaWebDialog({
  required BuildContext context,
  required Uri url,
  required String challengeId,
  required String title,
  required String cancelLabel,
  required String loadingText,
  required String readyText,
  required String failedText,
  required String pageLoadFailedText,
  required String initFailedText,
}) {
  // HtmlElementView-backed dialogs are noticeably janky on Flutter web when the
  // route applies the default scale/fade transition to an ancestor. Keep the
  // overlay static so the iframe can mount without an animated transform.
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0x73000000),
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: Duration.zero,
    pageBuilder: (dialogContext, animation, secondaryAnimation) =>
        _AliyunCaptchaWebDialog(
          url: url,
          challengeId: challengeId,
          title: title,
          cancelLabel: cancelLabel,
          loadingText: loadingText,
          readyText: readyText,
          failedText: failedText,
          pageLoadFailedText: pageLoadFailedText,
          initFailedText: initFailedText,
        ),
    transitionBuilder: (context, animation, secondaryAnimation, child) => child,
  );
}

class _AliyunCaptchaWebDialog extends StatefulWidget {
  const _AliyunCaptchaWebDialog({
    required this.url,
    required this.challengeId,
    required this.title,
    required this.cancelLabel,
    required this.loadingText,
    required this.readyText,
    required this.failedText,
    required this.pageLoadFailedText,
    required this.initFailedText,
  });

  final Uri url;
  final String challengeId;
  final String title;
  final String cancelLabel;
  final String loadingText;
  final String readyText;
  final String failedText;
  final String pageLoadFailedText;
  final String initFailedText;

  @override
  State<_AliyunCaptchaWebDialog> createState() =>
      _AliyunCaptchaWebDialogState();
}

class _AliyunCaptchaWebDialogState extends State<_AliyunCaptchaWebDialog> {
  late final String _viewType;
  late final web.HTMLIFrameElement _iframeElement;
  late final Widget _iframeView;
  late final ValueNotifier<String> _statusText;
  StreamSubscription<web.MessageEvent>? _messageSubscription;
  StreamSubscription<web.Event>? _iframeErrorSubscription;

  @override
  void initState() {
    super.initState();
    _statusText = ValueNotifier(widget.loadingText);
    _viewType =
        'aliyun-captcha-web-${widget.challengeId}-${DateTime.now().microsecondsSinceEpoch}';
    _iframeElement = web.HTMLIFrameElement()
      ..src = widget.url.toString()
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.display = 'block'
      ..style.backgroundColor = '#FFFFFF'
      ..style.borderRadius = '16px'
      ..allow = 'clipboard-read; clipboard-write'
      ..allowFullscreen = true;

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId, {Object? params}) => _iframeElement,
    );
    _iframeView = HtmlElementView(viewType: _viewType);

    _iframeErrorSubscription = _iframeElement.onError.listen((_) {
      if (!mounted) {
        return;
      }
      _updateStatus(widget.pageLoadFailedText);
    });

    _messageSubscription = web.window.onMessage.listen(_handleMessage);
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _iframeErrorSubscription?.cancel();
    _statusText.dispose();
    _iframeElement.remove();
    super.dispose();
  }

  void _updateStatus(String nextStatus) {
    if (_statusText.value == nextStatus) {
      return;
    }
    _statusText.value = nextStatus;
  }

  void _handleMessage(web.MessageEvent event) {
    if (event.origin != widget.url.origin) {
      return;
    }

    final payload = _AliyunCaptchaWebBridgePayload.tryParse(event.data);
    if (payload == null) {
      return;
    }
    if (payload.challengeId != null &&
        payload.challengeId != widget.challengeId) {
      return;
    }

    switch (payload.type) {
      case 'ready':
        if (!mounted) {
          return;
        }
        _updateStatus(widget.readyText);
        return;
      case 'success':
        final captchaVerifyParam = payload.captchaVerifyParam;
        if (!mounted) {
          return;
        }
        if (captchaVerifyParam == null || captchaVerifyParam.isEmpty) {
          _updateStatus(widget.initFailedText);
          return;
        }
        Navigator.of(context).pop(captchaVerifyParam);
        return;
      case 'fail':
        if (!mounted) {
          return;
        }
        _updateStatus(widget.failedText);
        return;
      case 'error':
      default:
        if (!mounted) {
          return;
        }
        _updateStatus(payload.message ?? widget.initFailedText);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final dialogWidth = math.min(constraints.maxWidth, 520.0);
            final dialogHeight = math.min(constraints.maxHeight, 700.0);

            return Center(
              child: SizedBox(
                width: dialogWidth,
                height: dialogHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ValueListenableBuilder<String>(
                          valueListenable: _statusText,
                          builder: (context, statusText, child) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F4EE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: RepaintBoundary(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0x14000000),
                                ),
                              ),
                              child: _iframeView,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(widget.cancelLabel),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AliyunCaptchaWebBridgePayload {
  const _AliyunCaptchaWebBridgePayload({
    required this.type,
    this.challengeId,
    this.captchaVerifyParam,
    this.message,
  });

  final String type;
  final String? challengeId;
  final String? captchaVerifyParam;
  final String? message;

  static _AliyunCaptchaWebBridgePayload? tryParse(Object? raw) {
    final map = _asStringMap(raw);
    if (map == null) {
      return null;
    }

    final type = _trimmedString(map['type']);
    if (type == null) {
      return null;
    }

    return _AliyunCaptchaWebBridgePayload(
      type: type,
      challengeId: _trimmedString(map['challengeId']),
      captchaVerifyParam: _trimmedString(map['captchaVerifyParam']),
      message: _trimmedString(map['message']),
    );
  }

  static Map<String, dynamic>? _asStringMap(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {
        return null;
      }
      return null;
    }
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }

    try {
      final dartValue = (raw as JSAny).dartify();
      if (dartValue is Map) {
        return dartValue.map((key, value) => MapEntry(key.toString(), value));
      }
      if (dartValue is String) {
        return _asStringMap(dartValue);
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}

String? _trimmedString(dynamic value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return raw;
}
