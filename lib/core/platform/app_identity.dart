// 平台应用标识读取器。负责向 Flutter 层暴露包名、应用标识等原生信息，供网络和支付链路复用。

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppIdentity {
  AppIdentity._();

  static const MethodChannel _channel = MethodChannel('app/info');
  static const String fallbackAppId = String.fromEnvironment(
    'X_APP_ID',
    defaultValue: 'com.permillet.myapp.dev',
  );

  static String _currentAppId = fallbackAppId;
  static Future<String>? _loadingFuture;

  static String get currentAppId => _currentAppId;

  static Future<String> initialize() {
    return _loadingFuture ??= _loadFromPlatform();
  }

  static Future<String> _loadFromPlatform() async {
    if (kIsWeb) {
      return _currentAppId;
    }

    try {
      final appId = await _channel.invokeMethod<String>('getAppId');
      final normalizedAppId = appId?.trim();
      if (normalizedAppId != null && normalizedAppId.isNotEmpty) {
        _currentAppId = normalizedAppId;
        return _currentAppId;
      }
    } on MissingPluginException {
      _loadingFuture = null;
      return _currentAppId;
    } on PlatformException {
      _loadingFuture = null;
      return _currentAppId;
    }

    _loadingFuture = null;
    return _currentAppId;
  }

  @visibleForTesting
  static void resetForTest() {
    _currentAppId = fallbackAppId;
    _loadingFuture = null;
  }
}
