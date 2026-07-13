// 鉴权拦截器。负责在请求时注入登录态，在会话失效时统一处理认证相关后续动作。

import 'package:dio/dio.dart';
import 'package:millet_kyai_apps/core/di/injector.dart';
import 'package:millet_kyai_apps/core/network/auth_session_store.dart';
import 'package:millet_kyai_apps/core/network/dio_client.dart';
import 'package:millet_kyai_apps/core/router/app_router.dart';
import 'package:millet_kyai_apps/core/utils/logger.dart';
import 'package:millet_kyai_apps/features/auth/data/models/auth_session_model.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/auth_session_entity.dart';

class _RefreshAttemptResult {
  const _RefreshAttemptResult._({
    required this.refreshed,
    required this.terminalFailure,
  });

  const _RefreshAttemptResult.success()
    : this._(refreshed: true, terminalFailure: false);

  const _RefreshAttemptResult.failure()
    : this._(refreshed: false, terminalFailure: false);

  const _RefreshAttemptResult.terminalFailure()
    : this._(refreshed: false, terminalFailure: true);

  final bool refreshed;
  final bool terminalFailure;
}

class AuthInterceptor extends Interceptor {
  static const _retryAfterRefreshKey = 'retry_after_token_refresh';
  static const _skipTokenRefreshKey = 'skip_token_refresh';
  static const _proactiveRefreshThreshold = Duration(minutes: 1);
  static const _retryableMethods = <String>{'GET', 'HEAD', 'OPTIONS'};

  Future<_RefreshAttemptResult>? _refreshFuture;

  bool _isAuthPath(RequestOptions options) {
    return options.path.contains('/api/v1/saas/mobile/auth/');
  }

  bool _canRetryAfterRefresh(RequestOptions options) {
    if (options.extra[DioClient.allowUnsafeRetryAfterTokenRefreshExtraKey] ==
        true) {
      return true;
    }
    return _retryableMethods.contains(options.method.toUpperCase());
  }

  bool _isAuthFailureResponse(Response<dynamic>? response) {
    final statusCode = response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      return true;
    }

    final data = response?.data;
    final envelope = data is Map<String, dynamic>
        ? data
        : data is Map
        ? Map<String, dynamic>.from(data)
        : null;
    if (envelope == null) {
      return false;
    }

    final businessCode = (envelope['code'] as num?)?.toInt();
    if (businessCode == 401 ||
        (businessCode != null &&
            businessCode >= 40100 &&
            businessCode < 40200)) {
      return true;
    }

    final messageKey = envelope['messageKey']?.toString().trim().toUpperCase();
    if (messageKey != null &&
        messageKey.isNotEmpty &&
        messageKey.startsWith('AUTH_')) {
      return true;
    }

    final message = envelope['message']?.toString().trim().toLowerCase();
    return message == '未登录' ||
        message == '未登陆' ||
        message == 'unauthorized' ||
        message == 'not logged in' ||
        message == 'refresh token expired' ||
        message == 'access token expired' ||
        message == 'token expired';
  }

  Object? _retryData(Object? data) {
    if (data is FormData) {
      return data.clone();
    }
    return data;
  }

  bool _shouldSkipAuthorizationHeader(RequestOptions options) {
    return options.extra[DioClient.skipAuthorizationHeaderExtraKey] == true;
  }

  bool _shouldAttemptRefreshForAuthFailure(
    RequestOptions options,
    Response<dynamic>? response,
  ) {
    return _isAuthFailureResponse(response) &&
        options.extra[_skipTokenRefreshKey] != true &&
        !_shouldSkipAuthorizationHeader(options) &&
        options.extra[_retryAfterRefreshKey] != true &&
        !_isAuthPath(options) &&
        _canRetryAfterRefresh(options) &&
        getIt.isRegistered<AuthSessionStore>() &&
        getIt.isRegistered<DioClient>();
  }

  Future<_RefreshAttemptResult> _refreshSession() {
    final existingRefresh = _refreshFuture;
    if (existingRefresh != null) {
      return existingRefresh;
    }

    final refreshOperation = _performRefresh().whenComplete(() {
      _refreshFuture = null;
    });
    _refreshFuture = refreshOperation;
    return refreshOperation;
  }

  bool _isTerminalRefreshFailure(DioException error) {
    final statusCode = error.response?.statusCode;
    return statusCode == 400 || statusCode == 401 || statusCode == 403;
  }

  Future<void> _invalidateSession() async {
    if (getIt.isRegistered<AuthSessionStore>()) {
      await getIt<AuthSessionStore>().clear();
    }
    setPreviewAuthenticated(false);
  }

  DioException _sessionExpiredException(RequestOptions options) {
    return DioException(
      requestOptions: options,
      response: Response<dynamic>(
        requestOptions: options,
        statusCode: 401,
        data: const {
          'code': 401,
          'message': 'Session expired. Please log in again.',
        },
      ),
      type: DioExceptionType.badResponse,
    );
  }

  Future<_RefreshAttemptResult> _performRefresh() async {
    if (!getIt.isRegistered<AuthSessionStore>() ||
        !getIt.isRegistered<DioClient>()) {
      return const _RefreshAttemptResult.failure();
    }

    final sessionStore = getIt<AuthSessionStore>();
    final refreshToken = await sessionStore.refreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return const _RefreshAttemptResult.terminalFailure();
    }

    try {
      final dio = getIt<DioClient>().dio;
      final refreshResponse = await dio.post(
        '/api/v1/saas/mobile/auth/tokens/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {_skipTokenRefreshKey: true}),
      );

      final responseData = refreshResponse.data;
      if (responseData is! Map<String, dynamic>) {
        throw const FormatException('Invalid refresh response envelope');
      }
      final data = responseData['data'];
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Missing refresh response data');
      }

      final refreshedSession = AuthSessionModel.fromJson(data);
      await sessionStore.saveSession(
        AuthSessionEntity(
          accessToken: refreshedSession.accessToken,
          refreshToken: refreshedSession.refreshToken,
          tokenType: refreshedSession.tokenType,
          expiresIn: refreshedSession.expiresIn,
          scope: refreshedSession.scope,
        ),
      );
      return const _RefreshAttemptResult.success();
    } on DioException catch (error) {
      AppLogger.log('Token refresh failed: $error');
      if (_isTerminalRefreshFailure(error)) {
        return const _RefreshAttemptResult.terminalFailure();
      }
      return const _RefreshAttemptResult.failure();
    } on Object catch (error) {
      AppLogger.log('Token refresh failed: $error');
      return const _RefreshAttemptResult.failure();
    }
  }

  Future<Response<dynamic>?> _refreshAndRetry(RequestOptions options) async {
    final sessionStore = getIt<AuthSessionStore>();

    final refreshResult = await _refreshSession();
    if (!refreshResult.refreshed) {
      if (refreshResult.terminalFailure) {
        await _invalidateSession();
      }
      return null;
    }

    final authorization = await sessionStore.authorizationHeader();
    if (authorization == null) {
      await _invalidateSession();
      return null;
    }

    final retryOptions = options.copyWith(
      data: _retryData(options.data),
      headers: Map<String, dynamic>.from(options.headers)
        ..['Authorization'] = authorization,
    );
    retryOptions.extra[_retryAfterRefreshKey] = true;

    final dio = getIt<DioClient>().dio;
    final retryResponse = await dio.fetch<dynamic>(retryOptions);
    if (_isAuthFailureResponse(retryResponse)) {
      await _invalidateSession();
    }
    return retryResponse;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_shouldSkipAuthorizationHeader(options)) {
      options.headers.remove('Authorization');
      handler.next(options);
      return;
    }

    if (!getIt.isRegistered<AuthSessionStore>()) {
      handler.next(options);
      return;
    }

    if (!_isAuthPath(options)) {
      final sessionStore = getIt<AuthSessionStore>();
      final shouldRefresh =
          options.extra[_skipTokenRefreshKey] != true &&
          await sessionStore.shouldRefreshAccessToken(
            threshold: _proactiveRefreshThreshold,
          );

      if (shouldRefresh) {
        final refreshResult = await _refreshSession();
        if (!refreshResult.refreshed) {
          if (refreshResult.terminalFailure) {
            await _invalidateSession();
            handler.reject(_sessionExpiredException(options));
            return;
          }
          AppLogger.log(
            'Proactive token refresh failed before ${options.path}; using existing access token if available.',
          );
        }
      }

      final authorization = await sessionStore.authorizationHeader();
      if (authorization != null) {
        options.headers['Authorization'] = authorization;
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final requestOptions = response.requestOptions;
    if (!_shouldAttemptRefreshForAuthFailure(requestOptions, response)) {
      handler.next(response);
      return;
    }

    try {
      final retryResponse = await _refreshAndRetry(requestOptions);
      if (retryResponse == null) {
        handler.next(response);
        return;
      }
      handler.resolve(retryResponse);
    } on DioException catch (retryError) {
      if (_isAuthFailureResponse(retryError.response)) {
        await _invalidateSession();
      }
      handler.reject(retryError);
    } on Object catch (error) {
      AppLogger.log(
        'Retried request failed after token refresh for ${requestOptions.path}: $error',
      );
      handler.next(response);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    if (!_shouldAttemptRefreshForAuthFailure(requestOptions, err.response)) {
      handler.next(err);
      return;
    }

    try {
      final retryResponse = await _refreshAndRetry(requestOptions);
      if (retryResponse == null) {
        handler.next(err);
        return;
      }
      handler.resolve(retryResponse);
    } on DioException catch (retryError) {
      if (_isAuthFailureResponse(retryError.response)) {
        await _invalidateSession();
      }
      handler.next(retryError);
    } on Object catch (error) {
      AppLogger.log(
        'Retried request failed after token refresh for ${requestOptions.path}: $error',
      );
      handler.next(err);
    }
  }
}
