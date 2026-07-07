import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/core/network/dio_client.dart';
import 'package:millet_kyai_apps/core/platform/app_identity.dart';
import 'package:millet_kyai_apps/features/report/data/sources/report_remote_source.dart';

import 'report_test_data.dart';

typedef _AdapterHandler = ResponseBody Function(RequestOptions options);

class _CaptureAdapter implements HttpClientAdapter {
  _CaptureAdapter(this._handler);

  final _AdapterHandler _handler;

  late RequestOptions lastRequestOptions;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = options;
    return _handler(options);
  }
}

ResponseBody _jsonResponse(Object? data) {
  return ResponseBody.fromString(
    jsonEncode(data),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('app/info');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getAppId');
      return 'com.permillet.myapp.dev';
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    AppIdentity.resetForTest();
  });

  test('getReportShareQrCode hits report share endpoint', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': {
          'imageUrl': 'https://example.com/report-share.png',
          'shareUrl': 'https://example.com/report?reportId=report-1',
        },
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ReportRemoteSource(dioClient);

    final result = await remoteSource.getReportShareQrCode('report-1');

    expect(
      adapter.lastRequestOptions.path,
      '/api/v1/saas/mobile/physique/ai/diagnosis/report/report-1/share/qrcode',
    );
    expect(adapter.lastRequestOptions.method, 'GET');
    expect(result.imageUrl, 'https://example.com/report-share.png');
    expect(result.shareUrl, 'https://example.com/report?reportId=report-1');
  });

  test('getReportShareQrCode accepts scalar url payloads', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': 'https://example.com/report-share.png',
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ReportRemoteSource(dioClient);

    final result = await remoteSource.getReportShareQrCode('report-2');

    expect(result.imageUrl, 'https://example.com/report-share.png');
    expect(result.shareUrl, 'https://example.com/report-share.png');
  });

  test('getPhysiqueProductDetail unwraps nested product payloads', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': {
          'product': {'id': 123, 'name': '艾灸温养包', 'description': '详情接口返回的商品说明'},
        },
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ReportRemoteSource(dioClient);

    final result = await remoteSource.getPhysiqueProductDetail('123');

    expect(
      adapter.lastRequestOptions.path,
      '/api/v1/saas/mobile/physique/product/123',
    );
    expect(adapter.lastRequestOptions.method, 'GET');
    expect(result, isNotNull);
    expect(result!['id'], 123);
    expect(result['name'], '艾灸温养包');
    expect(result['description'], '详情接口返回的商品说明');
  });

  test(
    'getPhysiqueProjects uses by-token endpoint when token is present',
    () async {
      final dioClient = DioClient();
      final adapter = _CaptureAdapter((options) {
        return _jsonResponse({
          'code': 0,
          'message': 'ok',
          'data': {
            'projects': [
              {'id': 9, 'name': 'Meridian Care'},
            ],
          },
        });
      });
      dioClient.dio.httpClientAdapter = adapter;
      final remoteSource = ReportRemoteSource(dioClient);

      final result = await remoteSource.getPhysiqueProjects(
        token: 'report-token',
        topOrgId: 'tenant-1',
        age: 28,
        sex: 'F',
        physiqueIds: const [11, 12, 12],
      );

      expect(
        adapter.lastRequestOptions.path,
        '/api/v1/saas/mobile/physique/project/by/token',
      );
      expect(adapter.lastRequestOptions.method, 'GET');
      expect(
        adapter.lastRequestOptions.queryParameters,
        containsPair('token', 'report-token'),
      );
      expect(
        adapter.lastRequestOptions.queryParameters,
        containsPair('topOrgId', 'tenant-1'),
      );
      expect(
        adapter.lastRequestOptions.queryParameters,
        containsPair('tenantId', 'tenant-1'),
      );
      expect(
        adapter.lastRequestOptions.queryParameters,
        containsPair('age', 28),
      );
      expect(
        adapter.lastRequestOptions.queryParameters,
        containsPair('sex', 'F'),
      );
      expect(
        adapter.lastRequestOptions.queryParameters,
        containsPair('physiqueIds', [11, 12]),
      );
      expect(result, hasLength(1));
      expect(result.first['id'], 9);
    },
  );

  test('getPhysiqueProjects uses plain endpoint without token', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': [
          {'id': 'project-1', 'name': 'Warm Care'},
        ],
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ReportRemoteSource(dioClient);

    final result = await remoteSource.getPhysiqueProjects(
      topOrgId: 'tenant-2',
      age: 35,
      sex: 'M',
      physiqueIds: const [8],
    );

    expect(
      adapter.lastRequestOptions.path,
      '/api/v1/saas/mobile/physique/project',
    );
    expect(adapter.lastRequestOptions.method, 'GET');
    expect(
      adapter.lastRequestOptions.queryParameters.containsKey('token'),
      isFalse,
    );
    expect(result, hasLength(1));
    expect(result.first['id'], 'project-1');
  });

  test(
    'getPhysiqueProjects keeps explicit empty project payloads empty',
    () async {
      final dioClient = DioClient();
      final adapter = _CaptureAdapter((options) {
        return _jsonResponse({
          'code': 0,
          'message': 'ok',
          'data': {'projects': <Map<String, dynamic>>[], 'totalCount': 0},
        });
      });
      dioClient.dio.httpClientAdapter = adapter;
      final remoteSource = ReportRemoteSource(dioClient);

      final result = await remoteSource.getPhysiqueProjects(
        topOrgId: 'tenant-empty',
        age: 31,
        sex: 'F',
      );

      expect(result, isEmpty);
    },
  );

  test(
    'getPhysiqueProjects skips request when token and topOrgId are both missing',
    () async {
      final dioClient = DioClient();
      var requestCount = 0;
      final adapter = _CaptureAdapter((options) {
        requestCount += 1;
        throw StateError('request should not be sent');
      });
      dioClient.dio.httpClientAdapter = adapter;
      final remoteSource = ReportRemoteSource(dioClient);

      final result = await remoteSource.getPhysiqueProjects(
        age: 23,
        sex: 'F',
        physiqueIds: const [1, 2],
      );

      expect(result, isEmpty);
      expect(requestCount, 0);
    },
  );

  test(
    'getAllReports resolves face images from detail when summary payload omits them',
    () async {
      final requestPaths = <String>[];
      final detail = buildDiagnosisReportDetail(
        id: 'report-1',
        imageUrl: 'https://example.com/tongue.png',
        faceImageUrl: 'https://example.com/face.png',
      );
      final dioClient = DioClient();
      final adapter = _CaptureAdapter((options) {
        requestPaths.add(options.path);
        if (options.path == '/api/v1/saas/mobile/physique/report') {
          return _jsonResponse({
            'code': 0,
            'message': 'ok',
            'data': {
              'datas': [
                {
                  'id': 'report-1',
                  'testTime': '2026-04-17 10:30',
                  'healthScore': 82,
                  'physiqueName': 'Balanced',
                  'imageUrl': 'https://example.com/tongue.png',
                  'lockedStatus': '1',
                  'deepPredicts': const <String, Object>{},
                },
              ],
              'totalCount': 1,
            },
          });
        }

        if (options.path ==
            '/api/v1/saas/mobile/ai/diagnosis/report/report-1') {
          return _jsonResponse({
            'code': 0,
            'message': 'ok',
            'data': detail.raw,
          });
        }

        throw StateError('Unexpected path: ${options.path}');
      });
      dioClient.dio.httpClientAdapter = adapter;
      final remoteSource = ReportRemoteSource(dioClient);

      final result = await remoteSource.getAllReports(resolveFaceImages: true);

      expect(result, hasLength(1));
      expect(result.first.imageUrl, 'https://example.com/tongue.png');
      expect(result.first.faceImageUrl, 'https://example.com/face.png');
      expect(
        requestPaths,
        equals([
          '/api/v1/saas/mobile/physique/report',
          '/api/v1/saas/mobile/ai/diagnosis/report/report-1',
        ]),
      );
    },
  );

  test(
    'getAllReports does not resolve face images from detail by default',
    () async {
      final requestPaths = <String>[];
      final dioClient = DioClient();
      final adapter = _CaptureAdapter((options) {
        requestPaths.add(options.path);
        if (options.path == '/api/v1/saas/mobile/physique/report') {
          return _jsonResponse({
            'code': 0,
            'message': 'ok',
            'data': {
              'datas': [
                {
                  'id': 'report-1',
                  'testTime': '2026-04-17 10:30',
                  'healthScore': 82,
                  'physiqueName': 'Balanced',
                  'imageUrl': 'https://example.com/tongue.png',
                  'lockedStatus': '1',
                  'deepPredicts': const <String, Object>{},
                },
              ],
              'totalCount': 1,
            },
          });
        }

        throw StateError('Unexpected path: ${options.path}');
      });
      dioClient.dio.httpClientAdapter = adapter;
      final remoteSource = ReportRemoteSource(dioClient);

      final result = await remoteSource.getAllReports();

      expect(result, hasLength(1));
      expect(result.first.faceImageUrl, isEmpty);
      expect(requestPaths, equals(['/api/v1/saas/mobile/physique/report']));
    },
  );
}
