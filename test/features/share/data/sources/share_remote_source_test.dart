import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/core/platform/app_identity.dart';
import 'package:millet_kyai_apps/core/network/dio_client.dart';
import 'package:millet_kyai_apps/features/share/data/sources/share_remote_source.dart';

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

  test('createShareTouch posts guest invite payload', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': {
          'inviteTicket': 'invite-ticket-1',
          'expireTime': '2026-04-20T09:00:00Z',
        },
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ShareRemoteSource(dioClient);

    final result = await remoteSource.createShareTouch(
      shareId: 'share-1',
      landingPage: '/report?reportId=report-1',
      visitorKey: 'visitor-1',
    );

    expect(
      adapter.lastRequestOptions.path,
      '/api/v1/saas/mobile/shares/touches',
    );
    expect(adapter.lastRequestOptions.method, 'POST');
    expect(adapter.lastRequestOptions.data, {
      'shareId': 'share-1',
      'landingPage': '/report?reportId=report-1',
      'visitorKey': 'visitor-1',
    });
    expect(result.inviteTicket, 'invite-ticket-1');
    expect(result.expireTime, '2026-04-20T09:00:00Z');
  });

  test('getAppIdMapping hits mapping endpoint and keeps raw fields', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': {
          'tenantId': 'tenant-1',
          'topOrgId': 'org-1',
          'storeId': 'store-1',
          'defaultStoreId': 'store-9',
        },
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ShareRemoteSource(dioClient);

    final result = await remoteSource.getAppIdMapping();

    expect(
      adapter.lastRequestOptions.path,
      '/api/v1/saas/mobile/appId/mapping',
    );
    expect(adapter.lastRequestOptions.method, 'GET');
    expect(result.tenantId, 'tenant-1');
    expect(result.topOrgId, 'org-1');
    expect(result.storeId, 'store-1');
    expect(result.defaultStoreId, 'store-9');
  });

  test('getRefererId parses object response', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': {'shareId': 'share-identity-1', 'globalUserId': 'user-1'},
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ShareRemoteSource(dioClient);

    final result = await remoteSource.getRefererId();

    expect(adapter.lastRequestOptions.path, '/api/v1/saas/mobile/shares/me');
    expect(adapter.lastRequestOptions.method, 'GET');
    expect(result.shareId, 'share-identity-1');
    expect(result.raw['globalUserId'], 'user-1');
  });

  test('getRefererId also accepts scalar shareId responses', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': 'share-identity-2',
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ShareRemoteSource(dioClient);

    final result = await remoteSource.getRefererId();

    expect(result.shareId, 'share-identity-2');
  });
}
