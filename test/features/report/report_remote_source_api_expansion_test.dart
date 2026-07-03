import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/core/network/dio_client.dart';
import 'package:millet_kyai_apps/core/platform/app_identity.dart';
import 'package:millet_kyai_apps/features/report/data/sources/report_remote_source.dart';

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

  test('previewRetailOrder posts order preview payload', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': {'payAmountMinor': 9900},
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ReportRemoteSource(dioClient);

    final result = await remoteSource.previewRetailOrder(
      storeId: 12,
      employeeId: 34,
      deliveryType: 'EXPRESS',
      deliveryAddress: {'receiverName': 'Chen'},
      items: [
        {'retailSkuId': 'sku-1', 'quantity': 2, 'unused': null},
      ],
    );

    expect(
      adapter.lastRequestOptions.path,
      '/api/v1/saas/mobile/retail-orders/preview',
    );
    expect(adapter.lastRequestOptions.method, 'POST');
    expect(adapter.lastRequestOptions.data, {
      'storeId': 12,
      'employeeId': 34,
      'deliveryType': 'EXPRESS',
      'deliveryAddress': {'receiverName': 'Chen'},
      'items': [
        {'retailSkuId': 'sku-1', 'quantity': 2},
      ],
    });
    expect(result['payAmountMinor'], 9900);
  });

  test('prepayOrder posts optional payment deduction payload', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': {'prepayId': 'prepay-1'},
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ReportRemoteSource(dioClient);

    final result = await remoteSource.prepayOrder(
      'order 1',
      useStoredValueAmountMinor: 100,
      usePointsAmount: 5,
    );

    expect(
      adapter.lastRequestOptions.path,
      '/api/v1/saas/mobile/orders/order%201/prepay',
    );
    expect(adapter.lastRequestOptions.method, 'POST');
    expect(adapter.lastRequestOptions.data, {
      'useStoredValueAmountMinor': 100,
      'usePointsAmount': 5,
    });
    expect(result['prepayId'], 'prepay-1');
  });

  test('getRetailSpuDetail sends required storeId query', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': {'retailSpuId': 'spu-1'},
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ReportRemoteSource(dioClient);

    final result = await remoteSource.getRetailSpuDetail(
      id: 'spu-1',
      storeId: 8,
      selectedRetailSkuId: 'sku-2',
    );

    expect(adapter.lastRequestOptions.path, '/api/v1/saas/mobile/retail-spus/spu-1');
    expect(adapter.lastRequestOptions.queryParameters, {
      'storeId': 8,
      'selectedRetailSkuId': 'sku-2',
    });
    expect(result['retailSpuId'], 'spu-1');
  });

  test('mobile physique report mutation endpoints use documented payloads', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({'code': 0, 'message': 'ok', 'data': null});
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ReportRemoteSource(dioClient);

    await remoteSource.addReportSymptom(
      reportId: 101,
      symptomId: 202,
      symptomName: 'fatigue',
      recommendType: 'USER',
    );
    await remoteSource.deleteReportSymptom(
      reportId: 101,
      symptomId: 202,
      recommendType: 'USER',
    );
    await remoteSource.saveReportSelfDescription(
      reportId: 101,
      selfDescription: 'sleepy',
    );

    expect(adapter.requests[0].path,
        '/api/v1/saas/mobile/physique/ai/diagnosis/report/symptom');
    expect(adapter.requests[0].method, 'POST');
    expect(adapter.requests[0].data, {
      'reportId': 101,
      'symptomId': 202,
      'symptomName': 'fatigue',
      'recommendType': 'USER',
    });
    expect(adapter.requests[1].method, 'DELETE');
    expect(adapter.requests[1].data, {
      'reportId': 101,
      'symptomId': 202,
      'recommendType': 'USER',
    });
    expect(
      adapter.requests[2].path,
      '/api/v1/saas/mobile/physique/ai/diagnosis/report/self/description',
    );
    expect(adapter.requests[2].data, {
      'reportId': 101,
      'selfDescription': 'sleepy',
    });
  });

  test('survey report endpoints use canonical report APIs', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': {'status': 'UNLOCKED', 'token': 'download-token'},
      });
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ReportRemoteSource(dioClient);

    await remoteSource.unlockSurveyReport(
      reportId: 88,
      unlockingMethod: 'TIMES_CARD',
      cardId: 9,
    );
    await remoteSource.saveSurveyReportTreatmentSuggestion(
      reportId: 88,
      treatmentSuggestion: 'rest more',
    );
    final token = await remoteSource.createSurveyReportDownloadToken(88);

    expect(adapter.requests[0].path, '/api/v1/saas/physiques/reports/unlock');
    expect(adapter.requests[0].method, 'POST');
    expect(adapter.requests[0].data, {
      'reportId': 88,
      'cardId': 9,
      'unlockingMethod': 'TIMES_CARD',
    });
    expect(
      adapter.requests[1].path,
      '/api/v1/saas/physiques/reports/88/treatment-suggestion',
    );
    expect(adapter.requests[1].method, 'PUT');
    expect(adapter.requests[1].data, {'treatmentSuggestion': 'rest more'});
    expect(
      adapter.requests[2].path,
      '/api/v1/saas/physiques/reports/88/download-token',
    );
    expect(adapter.requests[2].method, 'POST');
    expect(token['token'], 'download-token');
  });

  test('activateAiDetectToken can use compatibility active path', () async {
    final dioClient = DioClient();
    final adapter = _CaptureAdapter((options) {
      return _jsonResponse({'code': 0, 'message': 'ok', 'data': null});
    });
    dioClient.dio.httpClientAdapter = adapter;
    final remoteSource = ReportRemoteSource(dioClient);

    await remoteSource.activateAiDetectToken(
      deviceToken: 'device-token',
      topOrgId: 7,
      ownerStaffAccount: true,
      useLegacyActivePath: true,
    );

    expect(
      adapter.lastRequestOptions.path,
      '/api/v1/saas/mobile/physique/ai/detect/token/active',
    );
    expect(adapter.lastRequestOptions.data, {
      'deviceToken': 'device-token',
      'topOrgId': 7,
      'ownerStaffAccount': true,
    });
  });
}
