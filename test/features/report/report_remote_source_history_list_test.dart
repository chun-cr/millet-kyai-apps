import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/core/network/dio_client.dart';
import 'package:millet_kyai_apps/core/platform/app_identity.dart';
import 'package:millet_kyai_apps/features/report/data/sources/report_remote_source.dart';

import 'report_test_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(AppIdentity.resetForTest);

  test('getAllReports queries the mobile report list first', () async {
    final adapter = _HistoryListAdapter((options) {
      expect(options.path, '/api/v1/saas/mobile/physique/report');
      expect(options.queryParameters['source'], 'KY_MA');
      expect(options.queryParameters['topOrgId'], 100);
      return _jsonResponse({
        'code': 0,
        'message': 'ok',
        'data': {
          'records': [
            {
              'id': 'report-1',
              'testTime': '2026-04-17 10:30',
              'healthScore': 82,
              'physiqueName': 'Balanced',
              'lockedStatus': '1',
            },
          ],
          'total': 1,
        },
      });
    });

    final remoteSource = _remoteSource(adapter);

    final reports = await remoteSource.getAllReports(
      source: 'KY_MA',
      topOrgId: 100,
    );

    expect(reports, hasLength(1));
    expect(reports.single.id, 'report-1');
    expect(adapter.paths, ['/api/v1/saas/mobile/physique/report']);
  });

  test(
    'getReportsPage returns one page without draining later pages',
    () async {
      final adapter = _HistoryListAdapter((options) {
        expect(options.path, '/api/v1/saas/mobile/physique/report');
        expect(options.queryParameters['source'], 'KY_MA');
        expect(options.queryParameters['topOrgId'], 100);
        expect(options.queryParameters['pageNo'], 2);
        expect(options.queryParameters['pageSize'], 2);
        return _jsonResponse({
          'code': 0,
          'message': 'ok',
          'data': {
            'records': [
              {
                'id': 'report-3',
                'testTime': '2026-04-17 10:30',
                'healthScore': 82,
                'physiqueName': 'Balanced',
                'lockedStatus': '1',
              },
              {
                'id': 'report-4',
                'testTime': '2026-04-18 10:30',
                'healthScore': 78,
                'physiqueName': 'Qi deficiency',
                'lockedStatus': '0',
              },
            ],
            'totalCount': 5,
          },
        });
      });

      final remoteSource = _remoteSource(adapter);

      final page = await remoteSource.getReportsPage(
        source: 'KY_MA',
        topOrgId: 100,
        pageNo: 2,
        pageSize: 2,
      );

      expect(page.items.map((item) => item.id), ['report-3', 'report-4']);
      expect(page.pageNo, 2);
      expect(page.pageSize, 2);
      expect(page.totalCount, 5);
      expect(page.hasMore, isTrue);
      expect(adapter.paths, ['/api/v1/saas/mobile/physique/report']);
    },
  );

  test(
    'getAllReports falls back to the legacy list after mobile 400',
    () async {
      final adapter = _HistoryListAdapter((options) {
        if (options.path == '/api/v1/saas/mobile/physique/report') {
          return _jsonResponse({
            'code': 400,
            'message': 'unsupported path',
            'data': null,
          });
        }

        expect(options.path, '/api/v1/saas/physiques/reports');
        expect(options.queryParameters.containsKey('source'), isFalse);
        return _jsonResponse({
          'code': 0,
          'message': 'ok',
          'data': {
            'datas': [
              {
                'id': 'legacy-report',
                'testTime': '2026-04-17 10:30',
                'healthScore': 79,
                'physiqueName': 'Qi deficiency',
                'lockedStatus': '1',
              },
            ],
            'totalCount': 1,
          },
        });
      });

      final remoteSource = _remoteSource(adapter);

      final reports = await remoteSource.getAllReports(source: 'KY_MA');

      expect(reports, hasLength(1));
      expect(reports.single.id, 'legacy-report');
      expect(adapter.paths, [
        '/api/v1/saas/mobile/physique/report',
        '/api/v1/saas/physiques/reports',
      ]);
    },
  );

  test(
    'getReportDetail falls back to pre-diagnosis detail after AI detail 400',
    () async {
      final detail = buildDiagnosisReportDetail(
        id: '88',
        faceImageUrl: 'https://example.com/face.png',
      );
      final adapter = _HistoryListAdapter((options) {
        if (options.path == '/api/v1/saas/mobile/ai/diagnosis/report/88') {
          expect(options.queryParameters['topOrgId'], 100);
          return _jsonResponse({
            'code': 400,
            'message': 'report id is not an AI diagnosis report id',
            'data': null,
          });
        }

        expect(
          options.path,
          '/api/v1/saas/mobile/physique/report/pre/diagnosis',
        );
        expect(options.queryParameters['reportId'], 88);
        expect(options.queryParameters['topOrgId'], 100);
        return _jsonResponse({'code': 0, 'message': 'ok', 'data': detail.raw});
      });
      final remoteSource = _remoteSource(adapter);

      final result = await remoteSource.getReportDetail('88', topOrgId: 100);

      expect(result.id, '88');
      expect(
        result.faceAnalysisResult.imageUrl,
        'https://example.com/face.png',
      );
      expect(adapter.paths, [
        '/api/v1/saas/mobile/ai/diagnosis/report/88',
        '/api/v1/saas/mobile/physique/report/pre/diagnosis',
      ]);
    },
  );
}

ReportRemoteSource _remoteSource(HttpClientAdapter adapter) {
  final dioClient = DioClient();
  dioClient.dio.httpClientAdapter = adapter;
  return ReportRemoteSource(dioClient);
}

ResponseBody _jsonResponse(Map<String, dynamic> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _HistoryListAdapter implements HttpClientAdapter {
  _HistoryListAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  final paths = <String>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    return handler(options);
  }
}
