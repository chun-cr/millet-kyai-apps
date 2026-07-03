import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/core/network/dio_client.dart';
import 'package:millet_kyai_apps/core/platform/app_identity.dart';
import 'package:millet_kyai_apps/features/home/data/sources/mobile_utility_remote_source.dart';

typedef _AdapterHandler = ResponseBody Function(RequestOptions options);

class _CaptureAdapter implements HttpClientAdapter {
  _CaptureAdapter(this._handler);

  final _AdapterHandler _handler;

  final requests = <RequestOptions>[];

  RequestOptions get lastRequestOptions => requests.last;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
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

  test('getIndexContent requests homepage aggregation content', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': [
          {'advertisementId': 'ad-1', 'title': 'Banner'},
        ],
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = MobileUtilityRemoteSource(dioClient);

    final result = await remoteSource.getIndexContent(withPlayAuth: true);

    expect(adapter.lastRequestOptions.path, '/api/v1/saas/mobile/index/content');
    expect(adapter.lastRequestOptions.method, 'GET');
    expect(adapter.lastRequestOptions.queryParameters, {'withPlayAuth': true});
    expect(result.single['advertisementId'], 'ad-1');
  });

  test('getAngelicaLoginQrCode sends required query fields', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': {'sceneCode': 'scene-1', 'key': 'auth-key'},
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = MobileUtilityRemoteSource(dioClient);

    final result = await remoteSource.getAngelicaLoginQrCode(
      platform: ' APP ',
      authKey: ' auth-key ',
      channel: 'h5',
    );

    expect(
      adapter.lastRequestOptions.path,
      '/api/v1/saas/mobile/angelica/login/qrcode',
    );
    expect(adapter.lastRequestOptions.queryParameters, {
      'platform': 'APP',
      'authKey': 'auth-key',
      'channel': 'h5',
    });
    expect(result['sceneCode'], 'scene-1');
  });

  test('scene code APIs parse code and fetch image url', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      if (options.path == '/api/v1/saas/mobile/scene/parse') {
        return _jsonResponse({
          'code': 0,
          'message': 'ok',
          'data': {'bizType': 'REPORT', 'success': true},
        });
      }
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': 'https://example.com/scene.png',
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = MobileUtilityRemoteSource(dioClient);

    final parsed = await remoteSource.parseSceneCode(' scene-code ');
    final imageUrl = await remoteSource.getSceneImageUrl(id: 9, width: 320);

    expect(adapter.requests[0].path, '/api/v1/saas/mobile/scene/parse');
    expect(adapter.requests[0].method, 'POST');
    expect(adapter.requests[0].data, {'code': 'scene-code'});
    expect(
      adapter.requests[1].path,
      '/api/v1/saas/mobile/scene/image/url',
    );
    expect(adapter.requests[1].queryParameters, {'id': 9, 'width': 320});
    expect(parsed['bizType'], 'REPORT');
    expect(imageUrl, 'https://example.com/scene.png');
  });

  test('message subscription APIs use documented payloads', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      if (options.method == 'POST') {
        return _jsonResponse({'code': 0, 'message': 'ok', 'data': null});
      }
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': {
          'keepingFlags': {'tpl-1': true},
        },
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = MobileUtilityRemoteSource(dioClient);

    await remoteSource.subscribeUserMessage(
      templateId: 'tpl-1',
      acceptFlag: 'Y',
      keepingFlag: 'Y',
    );
    final result = await remoteSource.getUserMessageKeepingFlag(
      templateIds: const ['tpl-1', ' ', 'tpl-2'],
    );

    expect(
      adapter.requests[0].path,
      '/api/v1/saas/mobile/user/sub/msg/subscribe',
    );
    expect(adapter.requests[0].data, {
      'templateId': 'tpl-1',
      'acceptFlag': 'Y',
      'keepingFlag': 'Y',
    });
    expect(
      adapter.requests[1].path,
      '/api/v1/saas/mobile/user/sub/msg/template/keeping/flag',
    );
    expect(adapter.requests[1].queryParameters, {
      'templateIds': ['tpl-1', 'tpl-2'],
    });
    expect(result['keepingFlags'], {'tpl-1': true});
  });
}
