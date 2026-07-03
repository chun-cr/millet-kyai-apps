import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:millet_kyai_apps/core/di/injector.dart';
import 'package:millet_kyai_apps/core/network/auth_session_store.dart';
import 'package:millet_kyai_apps/core/network/dio_client.dart';
import 'package:millet_kyai_apps/core/network/interceptors/auth_interceptor.dart';
import 'package:millet_kyai_apps/core/router/app_router.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/auth_session_entity.dart';

class _AuthRefreshTestAdapter implements HttpClientAdapter {
  int protectedRequestCount = 0;
  int refreshRequestCount = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/api/v1/saas/mobile/auth/tokens/refresh') {
      refreshRequestCount++;
      expect(options.data, {'refreshToken': 'stale-refresh'});
      return ResponseBody.fromString(
        jsonEncode({
          'code': 0,
          'message': 'ok',
          'data': {
            'accessToken': 'fresh-access',
            'refreshToken': 'fresh-refresh',
            'tokenType': 'Bearer',
            'expiresIn': 7200,
            'scope': 'profile',
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (options.path == '/protected/resource') {
      protectedRequestCount++;
      final authorization = options.headers['Authorization'];
      if (authorization == 'Bearer fresh-access') {
        return ResponseBody.fromString(
          jsonEncode({'ok': true}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
      return ResponseBody.fromString(
        jsonEncode({'message': 'expired'}),
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'message': 'not found'}),
      404,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _ExpiredRefreshTokenAdapter implements HttpClientAdapter {
  int protectedRequestCount = 0;
  int refreshRequestCount = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/api/v1/saas/mobile/auth/tokens/refresh') {
      refreshRequestCount++;
      return ResponseBody.fromString(
        jsonEncode({'code': 401, 'message': 'refresh token expired'}),
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (options.path == '/protected/resource') {
      protectedRequestCount++;
      return ResponseBody.fromString(
        jsonEncode({'message': 'expired'}),
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'message': 'not found'}),
      404,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _UnsafeWrite401Adapter implements HttpClientAdapter {
  int postRequestCount = 0;
  int refreshRequestCount = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/api/v1/saas/mobile/auth/tokens/refresh') {
      refreshRequestCount++;
      return ResponseBody.fromString(
        jsonEncode({'code': 0, 'message': 'unexpected refresh'}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (options.path == '/protected/mutate') {
      postRequestCount++;
      return ResponseBody.fromString(
        jsonEncode({'message': 'expired'}),
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'message': 'not found'}),
      404,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

Future<void> _seedSession(
  AuthSessionEntity session, {
  DateTime? savedAt,
}) async {
  SharedPreferences.setMockInitialValues({});
  initInjector();
  await getIt<AuthSessionStore>().saveSession(session, savedAt: savedAt);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AuthSessionStore.debugUseMemoryBackend = true;
  });

  tearDown(() async {
    AuthSessionStore.debugUseMemoryBackend = false;
    setPreviewAuthenticated(false);
    await getIt.reset();
  });

  test('refreshes token and retries protected request after 401', () async {
    await _seedSession(
      const AuthSessionEntity(
        accessToken: 'stale-access',
        refreshToken: 'stale-refresh',
        tokenType: 'Bearer',
        expiresIn: 3600,
        scope: 'mobile',
      ),
    );
    final dioClient = getIt<DioClient>();
    dioClient.dio.interceptors.clear();
    dioClient.dio.interceptors.add(AuthInterceptor());
    final adapter = _AuthRefreshTestAdapter();
    dioClient.dio.httpClientAdapter = adapter;

    final response = await dioClient.dio.get<Map<String, dynamic>>(
      '/protected/resource',
    );

    expect(response.data, {'ok': true});
    expect(adapter.protectedRequestCount, 2);
    expect(
      await getIt<AuthSessionStore>().authorizationHeader(),
      'Bearer fresh-access',
    );
    expect(await getIt<AuthSessionStore>().refreshToken(), 'fresh-refresh');
  });

  test('proactively refreshes token one minute before expiry', () async {
    await _seedSession(
      const AuthSessionEntity(
        accessToken: 'stale-access',
        refreshToken: 'stale-refresh',
        tokenType: 'Bearer',
        expiresIn: 3600,
        scope: 'mobile',
      ),
      savedAt: DateTime.now().subtract(const Duration(seconds: 3570)),
    );

    final dioClient = getIt<DioClient>();
    dioClient.dio.interceptors.clear();
    dioClient.dio.interceptors.add(AuthInterceptor());
    final adapter = _AuthRefreshTestAdapter();
    dioClient.dio.httpClientAdapter = adapter;

    final response = await dioClient.dio.get<Map<String, dynamic>>(
      '/protected/resource',
    );

    expect(response.data, {'ok': true});
    expect(adapter.refreshRequestCount, 1);
    expect(adapter.protectedRequestCount, 1);
    expect(
      await getIt<AuthSessionStore>().authorizationHeader(),
      'Bearer fresh-access',
    );
    expect(await getIt<AuthSessionStore>().refreshToken(), 'fresh-refresh');
  });

  test(
    'forces re-login when refresh token is expired during proactive refresh',
    () async {
      await _seedSession(
        const AuthSessionEntity(
          accessToken: 'stale-access',
          refreshToken: 'expired-refresh',
          tokenType: 'Bearer',
          expiresIn: 3600,
          scope: 'mobile',
        ),
        savedAt: DateTime.now().subtract(const Duration(seconds: 3570)),
      );
      setPreviewAuthenticated(true);

      final dioClient = getIt<DioClient>();
      dioClient.dio.interceptors.clear();
      dioClient.dio.interceptors.add(AuthInterceptor());
      final adapter = _ExpiredRefreshTokenAdapter();
      dioClient.dio.httpClientAdapter = adapter;

      await expectLater(
        () => dioClient.dio.get<Map<String, dynamic>>('/protected/resource'),
        throwsA(isA<DioException>()),
      );

      expect(adapter.refreshRequestCount, 1);
      expect(adapter.protectedRequestCount, 0);
      expect(await getIt<AuthSessionStore>().authorizationHeader(), isNull);
      expect(await getIt<AuthSessionStore>().refreshToken(), isNull);
      expect(isPreviewAuthenticated, isFalse);
    },
  );

  test(
    'forces re-login when refresh token is expired after a protected request 401',
    () async {
      await _seedSession(
        const AuthSessionEntity(
          accessToken: 'stale-access',
          refreshToken: 'expired-refresh',
          tokenType: 'Bearer',
          expiresIn: 3600,
          scope: 'mobile',
        ),
      );
      setPreviewAuthenticated(true);

      final dioClient = getIt<DioClient>();
      dioClient.dio.interceptors.clear();
      dioClient.dio.interceptors.add(AuthInterceptor());
      final adapter = _ExpiredRefreshTokenAdapter();
      dioClient.dio.httpClientAdapter = adapter;

      await expectLater(
        () => dioClient.dio.get<Map<String, dynamic>>('/protected/resource'),
        throwsA(isA<DioException>()),
      );

      expect(adapter.protectedRequestCount, 1);
      expect(adapter.refreshRequestCount, 1);
      expect(await getIt<AuthSessionStore>().authorizationHeader(), isNull);
      expect(await getIt<AuthSessionStore>().refreshToken(), isNull);
      expect(isPreviewAuthenticated, isFalse);
    },
  );

  test('does not retry non-idempotent requests after a 401', () async {
    await _seedSession(
      const AuthSessionEntity(
        accessToken: 'stale-access',
        refreshToken: 'stale-refresh',
        tokenType: 'Bearer',
        expiresIn: 3600,
        scope: 'mobile',
      ),
    );

    final dioClient = getIt<DioClient>();
    dioClient.dio.interceptors.clear();
    dioClient.dio.interceptors.add(AuthInterceptor());
    final adapter = _UnsafeWrite401Adapter();
    dioClient.dio.httpClientAdapter = adapter;

    await expectLater(
      () => dioClient.dio.post<Map<String, dynamic>>('/protected/mutate'),
      throwsA(isA<DioException>()),
    );

    expect(adapter.postRequestCount, 1);
    expect(adapter.refreshRequestCount, 0);
    expect(
      await getIt<AuthSessionStore>().authorizationHeader(),
      'Bearer stale-access',
    );
    expect(await getIt<AuthSessionStore>().refreshToken(), 'stale-refresh');
  });
}
