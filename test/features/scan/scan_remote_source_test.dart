import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:millet_kyai_apps/core/di/injector.dart';
import 'package:millet_kyai_apps/core/network/auth_session_store.dart';
import 'package:millet_kyai_apps/core/network/dio_client.dart';
import 'package:millet_kyai_apps/core/platform/app_identity.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/auth_session_entity.dart';
import 'package:millet_kyai_apps/features/scan/data/models/scan_upload_result.dart';
import 'package:millet_kyai_apps/features/scan/data/sources/scan_remote_source.dart';

class _StubResponse {
  const _StubResponse(this.statusCode, this.body);

  final int statusCode;
  final Map<String, dynamic> body;
}

class _QueueHttpClientAdapter implements HttpClientAdapter {
  _QueueHttpClientAdapter(this._responses);

  final List<_StubResponse> _responses;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = _responses.removeAt(0);
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  const fakeFaceUpload = ScanFaceUploadResult(<String, dynamic>{
    'faceNum': 1,
    'imageId': 'face-image-id',
    'imageUrl': 'https://example.com/face.jpg',
    'features': <int>[1, 2, 3],
    'age': 30,
    'sex': 'F',
  });

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('scan_remote_source_test');
  });

  tearDownAll(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() {
    AuthSessionStore.debugUseMemoryBackend = true;
    AppIdentity.resetForTest();
  });

  tearDown(() async {
    AuthSessionStore.debugUseMemoryBackend = false;
    await getIt.reset();
  });

  Future<File> createFile(String name) async {
    final file = File('${tempDir.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(const <int>[1, 2, 3, 4]);
    return file;
  }

  Future<void> seedSession(AuthSessionEntity session) async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    initInjector();
    await getIt<AuthSessionStore>().saveSession(session);
  }

  ScanRemoteSource createSource(
    _QueueHttpClientAdapter adapter, {
    bool keepInterceptors = false,
  }) {
    final dioClient = DioClient();
    if (!keepInterceptors) {
      dioClient.dio.interceptors.clear();
    }
    dioClient.dio.httpClientAdapter = adapter;
    return ScanRemoteSource(dioClient);
  }

  ScanRemoteSource createRegisteredSource(_QueueHttpClientAdapter adapter) {
    final dioClient = getIt<DioClient>();
    dioClient.dio.httpClientAdapter = adapter;
    return ScanRemoteSource(dioClient);
  }

  test('uploadFace posts to the face upload endpoint', () async {
    final file = await createFile('face.jpg');
    final frameFile = await createFile('face-mask.png');
    final adapter = _QueueHttpClientAdapter(<_StubResponse>[
      const _StubResponse(200, <String, dynamic>{
        'code': 0,
        'data': <String, dynamic>{},
      }),
    ]);
    final source = createSource(adapter);

    await source.uploadFace(
      faceFilePath: file.path,
      faceFrameFilePath: frameFile.path,
    );

    expect(adapter.requests, hasLength(1));
    expect(
      adapter.requests.single.path,
      '/api/v1/saas/mobile/ai/diagnosis/upload/face',
    );
    final payload = adapter.requests.single.data as FormData;
    expect(payload.fields, isEmpty);
    expect(payload.files.map((entry) => entry.key), <String>[
      'faceFile',
      'faceFrameFile',
    ]);
    expect(payload.files.map((entry) => entry.value.filename), <String>[
      'face.jpg',
      'face-mask.png',
    ]);
  });

  test(
    'uploadFace includes tenant compatibility fields when provided',
    () async {
      final file = await createFile('face-tenant.jpg');
      final adapter = _QueueHttpClientAdapter(<_StubResponse>[
        const _StubResponse(200, <String, dynamic>{
          'code': 0,
          'data': <String, dynamic>{},
        }),
      ]);
      final source = createSource(adapter);

      await source.uploadFace(
        faceFilePath: file.path,
        tenantId: 11,
        topOrgId: 12,
        storeId: 13,
        clinicId: 14,
      );

      expect(adapter.requests, hasLength(1));
      final payload = adapter.requests.single.data as FormData;
      final fields = Map<String, String>.fromEntries(payload.fields);
      expect(fields, containsPair('tenantId', '11'));
      expect(fields, containsPair('topOrgId', '12'));
      expect(fields, containsPair('storeId', '13'));
      expect(fields, containsPair('clinicId', '14'));
    },
  );

  test(
    'scan uploads keep authorization and app id but skip platform header',
    () async {
      await seedSession(
        const AuthSessionEntity(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
          tokenType: 'Bearer',
          expiresIn: 3600,
          scope: 'mobile',
        ),
      );
      final file = await createFile('scan-face.jpg');
      final adapter = _QueueHttpClientAdapter(<_StubResponse>[
        const _StubResponse(200, <String, dynamic>{
          'code': 0,
          'data': <String, dynamic>{},
        }),
      ]);
      final source = createSource(adapter, keepInterceptors: true);

      await source.uploadFace(faceFilePath: file.path);

      expect(adapter.requests, hasLength(1));
      final headers = adapter.requests.single.headers;
      expect(headers['Authorization'], 'Bearer access-token');
      expect(headers['X-App-Id'], AppIdentity.fallbackAppId);
      expect(headers.containsKey('X-Platform'), isFalse);
      expect(adapter.requests.single.sendTimeout, const Duration(seconds: 30));
      expect(
        adapter.requests.single.receiveTimeout,
        const Duration(seconds: 120),
      );
    },
  );

  test(
    'scan uploads refresh and retry once when the access token is stale',
    () async {
      await seedSession(
        const AuthSessionEntity(
          accessToken: 'stale-access',
          refreshToken: 'refresh-token',
          tokenType: 'Bearer',
          expiresIn: 3600,
          scope: 'mobile',
        ),
      );
      final file = await createFile('scan-face-retry.jpg');
      final adapter = _QueueHttpClientAdapter(<_StubResponse>[
        const _StubResponse(200, <String, dynamic>{
          'code': 40101,
          'message': '未登录',
          'messageKey': 'AUTH_ACCESS_EXPIRED',
        }),
        const _StubResponse(200, <String, dynamic>{
          'code': 0,
          'data': <String, dynamic>{
            'accessToken': 'fresh-access',
            'refreshToken': 'fresh-refresh',
            'tokenType': 'Bearer',
            'expiresIn': 7200,
            'scope': 'mobile',
          },
        }),
        const _StubResponse(200, <String, dynamic>{
          'code': 0,
          'data': <String, dynamic>{},
        }),
      ]);
      final source = createRegisteredSource(adapter);

      await source.uploadFace(faceFilePath: file.path);

      expect(adapter.requests.map((request) => request.path), <String>[
        '/api/v1/saas/mobile/ai/diagnosis/upload/face',
        '/api/v1/saas/mobile/auth/tokens/refresh',
        '/api/v1/saas/mobile/ai/diagnosis/upload/face',
      ]);
      expect(
        adapter.requests.first.headers['Authorization'],
        'Bearer stale-access',
      );
      expect(
        adapter.requests.last.headers['Authorization'],
        'Bearer fresh-access',
      );
      expect(adapter.requests.last.data, isA<FormData>());
    },
  );

  test(
    'uploadTongue throws detailed exception for business failure envelope',
    () async {
      final file = await createFile('tongue.jpg');
      final adapter = _QueueHttpClientAdapter(<_StubResponse>[
        const _StubResponse(200, <String, dynamic>{
          'code': 9001,
          'message': 'tongue upload failed',
          'messageKey': 'POINTLESS',
          'requestId': 'req-business',
        }),
      ]);
      final source = createSource(adapter);

      await expectLater(
        () => source.uploadTongue(
          imageFilePath: file.path,
          faceUpload: fakeFaceUpload,
        ),
        throwsA(
          isA<ScanUploadException>()
              .having((error) => error.stage, 'stage', 'tongue')
              .having((error) => error.businessCode, 'businessCode', 9001)
              .having(
                (error) => error.message,
                'message',
                'tongue upload failed',
              )
              .having((error) => error.messageKey, 'messageKey', 'POINTLESS')
              .having((error) => error.requestId, 'requestId', 'req-business'),
        ),
      );
    },
  );

  test(
    'uploadTongue includes tenant compatibility fields when provided',
    () async {
      final file = await createFile('tongue-tenant.jpg');
      final adapter = _QueueHttpClientAdapter(<_StubResponse>[
        const _StubResponse(200, <String, dynamic>{
          'code': 0,
          'data': <String, dynamic>{},
        }),
      ]);
      final source = createSource(adapter);

      await source.uploadTongue(
        imageFilePath: file.path,
        faceUpload: fakeFaceUpload,
        tenantId: 21,
        topOrgId: 22,
        storeId: 23,
        clinicId: 24,
      );

      expect(adapter.requests, hasLength(1));
      final payload = adapter.requests.single.data as FormData;
      final fields = Map<String, String>.fromEntries(payload.fields);
      expect(fields, containsPair('tenantId', '21'));
      expect(fields, containsPair('topOrgId', '22'));
      expect(fields, containsPair('storeId', '23'));
      expect(fields, containsPair('clinicId', '24'));
    },
  );

  test('uploadTongue keeps envelope requestId in the parsed payload', () async {
    final file = await createFile('tongue-request-id.jpg');
    final adapter = _QueueHttpClientAdapter(<_StubResponse>[
      const _StubResponse(200, <String, dynamic>{
        'code': 0,
        'requestId': 'req-success',
        'data': <String, dynamic>{
          'analysisResult': <String, dynamic>{
            'success': true,
            'hasTongue': true,
          },
          'tongueReport': <String, dynamic>{
            'success': true,
            'reportId': 'report-123',
          },
        },
      }),
    ]);
    final source = createSource(adapter);

    final result = await source.uploadTongue(
      imageFilePath: file.path,
      faceUpload: fakeFaceUpload,
    );

    expect(result.requestId, 'req-success');
    expect(result.hasGeneratedReport, isTrue);
  });

  test(
    'uploadPalm posts hand and frame files to the hand upload endpoint',
    () async {
      final file = await createFile('palm.jpg');
      final frameFile = await createFile('palm-frame.jpg');
      final adapter = _QueueHttpClientAdapter(<_StubResponse>[
        const _StubResponse(200, <String, dynamic>{
          'code': 0,
          'data': <String, dynamic>{},
        }),
      ]);
      final source = createSource(adapter);

      await source.uploadPalm(
        handFilePath: file.path,
        handFrameFilePath: frameFile.path,
        reportId: 'report-123',
      );

      expect(adapter.requests, hasLength(1));
      expect(
        adapter.requests.single.path,
        '/api/v1/saas/mobile/ai/diagnosis/upload/hand',
      );
      final payload = adapter.requests.single.data as FormData;
      final fields = Map<String, String>.fromEntries(payload.fields);
      expect(fields, containsPair('reportId', 'report-123'));
      expect(payload.files.map((entry) => entry.key), <String>[
        'handFile',
        'handFrameFile',
      ]);
      expect(payload.files.map((entry) => entry.value.filename), <String>[
        'palm.jpg',
        'palm-frame.jpg',
      ]);
    },
  );

  test('uploadPalm requires reportId before posting hand files', () async {
    final file = await createFile('palm-no-report.jpg');
    final adapter = _QueueHttpClientAdapter(<_StubResponse>[]);
    final source = createSource(adapter);

    await expectLater(
      () => source.uploadPalm(handFilePath: file.path, reportId: '  '),
      throwsA(
        isA<ScanUploadException>()
            .having((error) => error.stage, 'stage', 'palm')
            .having((error) => error.message, 'message', '报告ID缺失，无法上传手诊。'),
      ),
    );
    expect(adapter.requests, isEmpty);
  });

  test(
    'uploadPalm throws detailed exception for http failure response',
    () async {
      final file = await createFile('palm.jpg');
      final adapter = _QueueHttpClientAdapter(<_StubResponse>[
        const _StubResponse(400, <String, dynamic>{
          'code': 40101,
          'message': 'refresh token expired',
          'messageKey': 'AUTH_REFRESH_EXPIRED',
          'requestId': 'req-http',
        }),
      ]);
      final source = createSource(adapter);

      await expectLater(
        () =>
            source.uploadPalm(handFilePath: file.path, reportId: 'report-123'),
        throwsA(
          isA<ScanUploadException>()
              .having((error) => error.stage, 'stage', 'palm')
              .having((error) => error.statusCode, 'statusCode', 400)
              .having((error) => error.businessCode, 'businessCode', 40101)
              .having(
                (error) => error.message,
                'message',
                'refresh token expired',
              )
              .having(
                (error) => error.messageKey,
                'messageKey',
                'AUTH_REFRESH_EXPIRED',
              )
              .having((error) => error.requestId, 'requestId', 'req-http'),
        ),
      );
    },
  );

  test('uploadPalm accepts business success with null payload', () async {
    final file = await createFile('palm-null-payload.jpg');
    final adapter = _QueueHttpClientAdapter(<_StubResponse>[
      const _StubResponse(200, <String, dynamic>{
        'code': 0,
        'message': '请求成功',
        'data': null,
      }),
    ]);
    final source = createSource(adapter);

    final result = await source.uploadPalm(
      handFilePath: file.path,
      reportId: 'report-123',
    );

    expect(result.data, isEmpty);
  });
}
