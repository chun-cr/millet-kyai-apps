import 'dart:async';

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:millet_kyai_apps/core/di/injector.dart';
import 'package:millet_kyai_apps/core/network/dio_client.dart';
import 'package:millet_kyai_apps/core/platform/app_identity.dart';
import 'package:millet_kyai_apps/core/router/app_router.dart';
import 'package:millet_kyai_apps/core/widgets/app_toast.dart';
import 'package:millet_kyai_apps/features/history/presentation/pages/history/history_page.dart';
import 'package:millet_kyai_apps/features/history/presentation/pages/history/history_risk_trend_chart.dart';
import 'package:millet_kyai_apps/features/history/presentation/pages/history/history_widgets.dart';
import 'package:millet_kyai_apps/features/report/data/models/report_detail.dart';
import 'package:millet_kyai_apps/features/share/domain/entities/app_id_mapping_entity.dart';
import 'package:millet_kyai_apps/features/share/domain/entities/share_identity_entity.dart';
import 'package:millet_kyai_apps/features/share/domain/entities/share_touch_result_entity.dart';
import 'package:millet_kyai_apps/features/share/domain/repositories/share_referral_repository.dart';
import 'package:millet_kyai_apps/features/share/presentation/providers/share_referral_provider.dart';
import 'package:millet_kyai_apps/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../report/report_test_data.dart';

class _HistoryReportsAdapter implements HttpClientAdapter {
  _HistoryReportsAdapter({required this.reportDetailRaw, this.expectedTopOrgId});

  final Map<String, dynamic> reportDetailRaw;
  final int? expectedTopOrgId;
  final requestPaths = <String>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestPaths.add(options.path);

    if (options.path == '/api/v1/saas/mobile/physique/report') {
      expect(options.queryParameters['source'], 'KY_MA');
      if (expectedTopOrgId != null) {
        expect(options.queryParameters['topOrgId'], expectedTopOrgId);
      }
      return ResponseBody.fromString(
        jsonEncode({
          'code': 0,
          'message': 'ok',
          'data': {
            'records': [
              {
                'id': '88',
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
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (options.path == '/api/v1/saas/mobile/ai/diagnosis/report/88') {
      if (expectedTopOrgId != null) {
        expect(options.queryParameters['topOrgId'], expectedTopOrgId);
      }
      return ResponseBody.fromString(
        jsonEncode({
          'code': 400,
          'message': 'report id is not an AI diagnosis report id',
          'data': null,
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    if (options.path == '/api/v1/saas/mobile/physique/report/pre/diagnosis') {
      expect(options.queryParameters['reportId'], 88);
      if (expectedTopOrgId != null) {
        expect(options.queryParameters['topOrgId'], expectedTopOrgId);
      }
      return ResponseBody.fromString(
        jsonEncode({'code': 0, 'message': 'ok', 'data': reportDetailRaw}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    throw StateError('Unexpected path: ${options.path}');
  }
}

class _HistoryShareReferralRepository implements ShareReferralRepository {
  const _HistoryShareReferralRepository();

  @override
  Future<ShareTouchResultEntity> createShareTouch({
    required String shareId,
    required String landingPage,
    String? visitorKey,
  }) async {
    return const ShareTouchResultEntity(inviteTicket: '', expireTime: '');
  }

  @override
  Future<AppIdMappingEntity> getAppIdMapping() async {
    return const AppIdMappingEntity(
      appId: 'com.permillet.myapp.dev',
      tenantId: '100',
      topOrgId: '100',
      storeId: '200',
      clinicId: '200',
    );
  }

  @override
  Future<ShareIdentityEntity> getRefererId() async {
    return const ShareIdentityEntity(shareId: '');
  }
}

Future<GoRouter> _pumpHistoryRouter(
  WidgetTester tester, {
  required List<DiagnosisRecord> records,
  String initialLocation = AppRoutes.history,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 2400));

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.history,
        builder: (context, state) => HistoryReportPage(records: records),
      ),
      GoRoute(
        path: AppRoutes.reportAnalysis,
        builder: (context, state) {
          final reportId = state.uri.queryParameters['reportId'] ?? 'missing';
          return Scaffold(body: Center(child: Text('report:$reportId')));
        },
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(
      locale: const Locale('zh'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> _pumpHistoryPage(
  WidgetTester tester, {
  List<DiagnosisRecord> records = const <DiagnosisRecord>[],
  Future<List<DiagnosisRecord>> Function()? loadHistoryRecords,
  List<Override> providerOverrides = const <Override>[],
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 2400));

  final page = MaterialApp(
    locale: const Locale('zh'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: HistoryReportPage(
      records: records,
      loadHistoryRecords: loadHistoryRecords,
    ),
  );

  await tester.pumpWidget(
    providerOverrides.isEmpty
        ? page
        : ProviderScope(overrides: providerOverrides, child: page),
  );
}

Future<void> _tearDownHistoryPage(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.binding.setSurfaceSize(null);
}

Future<void> _pumpRiskTrendChart(
  WidgetTester tester, {
  required List<DiagnosisRecord> records,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 800));

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: HistoryRiskTrendChart(records: records)),
    ),
  );
  await tester.pumpAndSettle();
}

DiagnosisRecord _buildRecord({
  required String id,
  required String constitutionLabel,
  required DateTime date,
  required bool isUnlocked,
  int score = 82,
  List<DiagnosisRiskIndex> riskIndices = const <DiagnosisRiskIndex>[
    DiagnosisRiskIndex(name: '脾胃', value: 0.55),
    DiagnosisRiskIndex(name: '气虚', value: 0.38),
  ],
}) {
  return DiagnosisRecord(
    id: id,
    date: date,
    constitutionType: ConstitutionType.balanced,
    constitutionLabel: constitutionLabel,
    score: score,
    faceImageUrl: '',
    isUnlocked: isUnlocked,
    healthTrend: score.toDouble(),
    riskIndices: riskIndices,
    rawSummary: DiagnosisReportSummary(
      id: id,
      testTime: date.toIso8601String(),
      healthScore: score.toDouble(),
      physiqueName: constitutionLabel,
      imageUrl: '',
      faceImageUrl: '',
      lockedStatus: isUnlocked ? '1' : '0',
      deepPredicts: const DiagnosisDeepPredicts(
        categoryProbabilities: <DiagnosisNamedProbability>[],
        predictions: <DiagnosisNamedProbability>[],
        diseases: <DiagnosisDisease>[],
        raw: <String, dynamic>{},
      ),
      raw: const <String, dynamic>{},
    ),
  );
}

void main() {
  tearDown(hideAppToast);

  testWidgets('history page renders provided records without loading state', (
    tester,
  ) async {
    final router = await _pumpHistoryRouter(
      tester,
      records: [
        _buildRecord(
          id: 'record-1',
          constitutionLabel: 'Balanced',
          date: DateTime(2026, 4, 10),
          isUnlocked: true,
          score: 86,
        ),
        _buildRecord(
          id: 'record-2',
          constitutionLabel: 'Qi Deficiency',
          date: DateTime(2026, 4, 12),
          isUnlocked: false,
          score: 74,
        ),
      ],
    );
    final l10n = lookupAppLocalizations(const Locale('zh'));

    expect(find.byType(HistoryReportPage), findsOneWidget);
    expect(find.text(l10n.historyHealthTrend), findsOneWidget);
    expect(find.text(l10n.historyRiskTrend), findsOneWidget);
    expect(find.text(l10n.historyPastReports), findsOneWidget);
    expect(find.text('Balanced'), findsOneWidget);
    expect(find.text('Qi Deficiency'), findsOneWidget);
    expect(find.text('脾胃'), findsOneWidget);
    expect(find.text('气虚'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    router.dispose();
    await _tearDownHistoryPage(tester);
  });

  testWidgets('risk trend legend focuses a line instead of hiding it', (
    tester,
  ) async {
    await _pumpRiskTrendChart(
      tester,
      records: [
        _buildRecord(
          id: 'risk-1',
          constitutionLabel: 'Balanced',
          date: DateTime(2026, 4, 10),
          isUnlocked: true,
          riskIndices: const [
            DiagnosisRiskIndex(name: 'Digest', value: 0.62),
            DiagnosisRiskIndex(name: 'Sleep', value: 0.41),
            DiagnosisRiskIndex(name: 'Mood', value: 0.34),
          ],
        ),
        _buildRecord(
          id: 'risk-2',
          constitutionLabel: 'Balanced',
          date: DateTime(2026, 4, 14),
          isUnlocked: true,
          riskIndices: const [
            DiagnosisRiskIndex(name: 'Digest', value: 0.58),
            DiagnosisRiskIndex(name: 'Sleep', value: 0.48),
            DiagnosisRiskIndex(name: 'Mood', value: 0.52),
          ],
        ),
      ],
    );

    LineChart chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.length, 3);
    expect(
      chart.data.lineBarsData.map((item) => item.barWidth).toSet(),
      equals(<double>{1.6}),
    );

    await tester.tap(find.text('Digest'));
    await tester.pumpAndSettle();

    chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.length, 3);
    final digestIndex = chart.data.lineBarsData.indexWhere(
      (item) => item.color == const Color(0xFF8B6914),
    );
    expect(digestIndex, isNonNegative);
    expect(
      chart.data.lineBarsData.where((item) => item.barWidth > 2.5).length,
      1,
    );
    expect(
      chart.data.lineBarsData.where((item) => item.barWidth < 1.4).length,
      2,
    );
    expect(chart.data.lineBarsData[digestIndex].barWidth, 3);

    final digestBar = chart.data.lineBarsData[digestIndex];
    final digestSpot = digestBar.spots.firstWhere(
      (spot) => spot != FlSpot.nullSpot,
    );
    final tooltipItems = chart.data.lineTouchData.touchTooltipData
        .getTooltipItems(<LineBarSpot>[
          LineBarSpot(digestBar, digestIndex, digestSpot),
        ]);
    final tooltipText = tooltipItems.single?.text;
    expect(tooltipText, isNotNull);
    expect(tooltipText?.startsWith('04.10\nDigest'), isTrue);

    await tester.tap(find.text('Digest'));
    await tester.pumpAndSettle();

    chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(
      chart.data.lineBarsData.map((item) => item.barWidth).toSet(),
      equals(<double>{1.6}),
    );

    await _tearDownHistoryPage(tester);
  });

  testWidgets('tapping unlocked history record navigates to report analysis', (
    tester,
  ) async {
    final router = await _pumpHistoryRouter(
      tester,
      records: [
        _buildRecord(
          id: 'record-42',
          constitutionLabel: 'Balanced',
          date: DateTime(2026, 4, 10),
          isUnlocked: true,
        ),
      ],
    );

    await tester.tap(find.text('Balanced'));
    await tester.pumpAndSettle();

    expect(find.text('report:record-42'), findsOneWidget);

    router.dispose();
    await _tearDownHistoryPage(tester);
  });

  testWidgets('locked history record still navigates to report analysis', (
    tester,
  ) async {
    final router = await _pumpHistoryRouter(
      tester,
      records: [
        _buildRecord(
          id: 'record-99',
          constitutionLabel: 'Dampness',
          date: DateTime(2026, 4, 11),
          isUnlocked: false,
        ),
      ],
    );
    final l10n = lookupAppLocalizations(const Locale('zh'));

    expect(find.text(l10n.actionUnlockNow), findsOneWidget);

    await tester.tap(find.text(l10n.actionUnlockNow));
    await tester.pumpAndSettle();

    expect(find.text('report:record-99'), findsOneWidget);

    router.dispose();
    await _tearDownHistoryPage(tester);
  });

  testWidgets('history page loads records through injected loader', (
    tester,
  ) async {
    final completer = Completer<List<DiagnosisRecord>>();

    await _pumpHistoryPage(tester, loadHistoryRecords: () => completer.future);

    expect(find.byKey(const ValueKey('history_loading')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    completer.complete(<DiagnosisRecord>[
      _buildRecord(
        id: 'record-remote',
        constitutionLabel: 'Balanced',
        date: DateTime(2026, 4, 13),
        isUnlocked: true,
      ),
    ]);

    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('history_records_loaded')),
      findsOneWidget,
    );
    expect(find.text('Balanced'), findsOneWidget);

    await _tearDownHistoryPage(tester);
  });

  testWidgets('history page retries after loader failure', (tester) async {
    var attempts = 0;

    await _pumpHistoryPage(
      tester,
      loadHistoryRecords: () {
        attempts += 1;
        if (attempts == 1) {
          return Future<List<DiagnosisRecord>>.error(StateError('load failed'));
        }
        return Future<List<DiagnosisRecord>>.value(<DiagnosisRecord>[
          _buildRecord(
            id: 'record-retry',
            constitutionLabel: 'Qi Deficiency',
            date: DateTime(2026, 4, 14),
            isUnlocked: true,
          ),
        ]);
      },
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('history_error')), findsOneWidget);
    expect(find.byKey(const ValueKey('history_retry_button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('history_retry_button')));
    await tester.pump();

    expect(find.byKey(const ValueKey('history_loading')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(
      find.byKey(const ValueKey('history_records_loaded')),
      findsOneWidget,
    );
    expect(find.text('Qi Deficiency'), findsOneWidget);

    await _tearDownHistoryPage(tester);
  });

  testWidgets('history page shows empty state when loader returns no records', (
    tester,
  ) async {
    await _pumpHistoryPage(
      tester,
      loadHistoryRecords: () async => <DiagnosisRecord>[],
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('history_records_loaded')),
      findsOneWidget,
    );
    expect(find.text('暂无历史报告'), findsOneWidget);

    await _tearDownHistoryPage(tester);
  });

  testWidgets(
    'history page resolves face preview images from report detail by default',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      const channel = MethodChannel('app/info');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final adapter = _HistoryReportsAdapter(
        expectedTopOrgId: 100,
        reportDetailRaw: buildDiagnosisReportDetail(
          id: '88',
          imageUrl: 'https://example.com/tongue.png',
          faceImageUrl: 'https://example.com/face.png',
        ).raw,
      );

      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'getAppId');
        return 'com.permillet.myapp.dev';
      });
      AppIdentity.resetForTest();
      await getIt.reset();
      final dioClient = DioClient();
      dioClient.dio.httpClientAdapter = adapter;
      getIt.registerSingleton<DioClient>(dioClient);

      addTearDown(() async {
        messenger.setMockMethodCallHandler(channel, null);
        AppIdentity.resetForTest();
        await getIt.reset();
      });

      await _pumpHistoryPage(
        tester,
        providerOverrides: [
          shareReferralRepositoryProvider.overrideWithValue(
            const _HistoryShareReferralRepository(),
          ),
        ],
      );
      await tester.pumpAndSettle();

      final card = tester.widget<HistoryRecordCard>(
        find.byType(HistoryRecordCard),
      );
      expect(card.record.faceImageUrl, 'https://example.com/face.png');
      expect(
        adapter.requestPaths,
        equals([
          '/api/v1/saas/mobile/physique/report',
          '/api/v1/saas/mobile/ai/diagnosis/report/88',
          '/api/v1/saas/mobile/physique/report/pre/diagnosis',
        ]),
      );

      await _tearDownHistoryPage(tester);
    },
  );
}
