// 全局 Dio 客户端构建入口。统一挂载应用标识、鉴权和日志拦截器，避免各模块各自拼网络配置。

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../platform/app_identity.dart';
import 'interceptors/app_identity_interceptor.dart';
import 'interceptors/log_interceptor.dart';
import 'interceptors/auth_interceptor.dart';

class DioClient {
  static const String _defaultBaseUrl = 'https://saas-api.dev51.permillet.com';
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');
  static const String skipPlatformHeadersExtraKey = 'skip_platform_headers';
  static const String skipAuthorizationHeaderExtraKey =
      'skip_authorization_header';
  static const String allowUnsafeRetryAfterTokenRefreshExtraKey =
      'allow_unsafe_retry_after_token_refresh';
  static const String appId = AppIdentity.fallbackAppId;
  static const String wechatMiniProgramAppId = String.fromEnvironment(
    'WECHAT_MINI_PROGRAM_APP_ID',
    defaultValue: appId,
  );
  static const String _platformOverride = String.fromEnvironment('X_PLATFORM');

  static String get platform {
    if (_platformOverride.isNotEmpty) {
      return _platformOverride;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'IOS',
      TargetPlatform.android => 'ANDROID',
      _ => 'ANDROID',
    };
  }

  static String get baseUrl {
    return resolveBaseUrl(
      baseUrlOverride: _baseUrlOverride,
      isWeb: kIsWeb,
      currentUri: kIsWeb ? Uri.base : null,
    );
  }

  @visibleForTesting
  static String resolveBaseUrl({
    String baseUrlOverride = '',
    required bool isWeb,
    Uri? currentUri,
  }) {
    if (baseUrlOverride.isNotEmpty) {
      if (isWeb) {
        _assertSecureWebBaseUrl(baseUrlOverride, currentUri ?? Uri.base);
      }
      return baseUrlOverride;
    }
    return _defaultBaseUrl;
  }

  static void _assertSecureWebBaseUrl(String baseUrl, Uri currentUri) {
    final parsedUri = Uri.parse(baseUrl);
    final effectiveUri = parsedUri.hasScheme
        ? parsedUri
        : currentUri.resolveUri(parsedUri);
    _ensureSecureWebUri(effectiveUri);
  }

  static void _ensureSecureWebUri(Uri uri) {
    final host = uri.host.toLowerCase();
    final isLoopbackHost =
        host == 'localhost' || host == '127.0.0.1' || host == '::1';
    final isSecureOrigin = uri.scheme == 'https';

    if (!isLoopbackHost && !isSecureOrigin) {
      throw StateError(
        'Refusing to send auth traffic from a non-HTTPS web origin.',
      );
    }
  }

  late final Dio dio;

  DioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        headers: {
          'X-App-Id': AppIdentity.currentAppId,
          'X-Platform': platform,
          'X-Dev-Host-IP': '192.168.110.7',
        },
      ),
    );
    debugPrint('[API_BASE_URL] ${DioClient.baseUrl}');
    dio.interceptors.add(AppIdentityInterceptor());
    dio.interceptors.add(AuthInterceptor());
    dio.interceptors.add(AppLogInterceptor());
  }
}
