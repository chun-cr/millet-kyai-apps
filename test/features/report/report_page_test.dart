import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:millet_kyai_apps/core/di/injector.dart';
import 'package:millet_kyai_apps/core/network/dio_client.dart';
import 'package:millet_kyai_apps/core/platform/app_identity.dart';
import 'package:millet_kyai_apps/core/router/app_router.dart';
import 'package:millet_kyai_apps/features/report/presentation/models/report_project_data.dart';
import 'package:millet_kyai_apps/features/report/presentation/models/report_product_data.dart';
import 'package:millet_kyai_apps/features/report/presentation/pages/report_checkout_page.dart';
import 'package:millet_kyai_apps/features/report/presentation/pages/report/report_page.dart';
import 'package:millet_kyai_apps/features/report/presentation/pages/report_project_detail_page.dart';
import 'package:millet_kyai_apps/features/report/presentation/pages/report_product_detail_page.dart';
import 'package:millet_kyai_apps/l10n/app_localizations.dart';

import 'report_test_data.dart';

typedef _ReportPageAdapterHandler =
    ResponseBody Function(RequestOptions options);

class _ReportPageCaptureAdapter implements HttpClientAdapter {
  _ReportPageCaptureAdapter(this._handler);

  final _ReportPageAdapterHandler _handler;
  final requests = <RequestOptions>[];

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

Widget _buildFallbackReportPage(
  GoRouterState state, {
  Widget Function(BuildContext context, GoRouterState state)? reportBuilder,
  required BuildContext context,
}) {
  final initialViewData = state.extra is ReportViewData
      ? state.extra as ReportViewData
      : null;
  return reportBuilder?.call(context, state) ??
      ReportPage(
        reportId:
            state.uri.queryParameters['reportId'] ??
            (state.extra is String ? state.extra as String : null) ??
            initialViewData?.reportId,
        initialViewData: initialViewData,
      );
}

Future<GoRouter> _pumpReportRouter(
  WidgetTester tester, {
  String initialLocation = AppRoutes.report,
  Size surfaceSize = const Size(1280, 2400),
  Widget Function(BuildContext context, GoRouterState state)? reportBuilder,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(surfaceSize);

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.reportProjectDetail,
        builder: (context, state) {
          final project = state.extra;
          if (project is! ReportProjectData) {
            final routedProject = ReportProjectData.fromRouteQueryParameters(
              state.uri.queryParameters,
            );
            if (routedProject == null) {
              return _buildFallbackReportPage(
                state,
                reportBuilder: reportBuilder,
                context: context,
              );
            }
            return ReportProjectDetailPage(project: routedProject);
          }
          return ReportProjectDetailPage(project: project);
        },
      ),
      GoRoute(
        path: AppRoutes.reportProductDetail,
        builder: (context, state) {
          final product = state.extra;
          if (product is! ReportProductData) {
            return _buildFallbackReportPage(
              state,
              reportBuilder: reportBuilder,
              context: context,
            );
          }
          return ReportProductDetailPage(product: product);
        },
      ),
      GoRoute(
        path: AppRoutes.reportCheckout,
        builder: (context, state) {
          final args = state.extra;
          if (args is! ReportCheckoutArgs) {
            return _buildFallbackReportPage(
              state,
              reportBuilder: reportBuilder,
              context: context,
            );
          }
          return ReportCheckoutPage(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.reportAnalysis,
        builder: (context, state) => _buildFallbackReportPage(
          state,
          reportBuilder: reportBuilder,
          context: context,
        ),
      ),
      GoRoute(
        path: AppRoutes.report,
        builder: (context, state) => _buildFallbackReportPage(
          state,
          reportBuilder: reportBuilder,
          context: context,
        ),
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
  await tester.pump(const Duration(milliseconds: 900));
  return router;
}

void main() {
  String twoDigits(int value) => value.toString().padLeft(2, '0');

  testWidgets('report page reports missing reportId instead of demo data', (
    tester,
  ) async {
    final router = await _pumpReportRouter(tester);

    expect(find.byType(ReportPage), findsOneWidget);
    expect(
      find.byKey(const ValueKey('report_missing_report_id')),
      findsOneWidget,
    );
    expect(find.textContaining('报告ID缺失'), findsOneWidget);
    expect(find.byKey(const ValueKey('report_mode_demo')), findsNothing);
    expect(tester.takeException(), isNull);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('report page resolves live data when reportId loader succeeds', (
    tester,
  ) async {
    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'live-report',
        loadReportViewData: (_) async => buildReportViewData(
          summary: 'Recovered live summary',
          categoryProbabilities: const [
            {'name': '神志精神及情绪', 'prob': 0.89},
            {'name': '作息睡眠', 'prob': 0.69},
            {'name': '两性泌尿生殖', 'prob': 0.67},
            {'name': '消化道', 'prob': 0.41},
          ],
        ),
      ),
    );

    expect(find.byKey(const ValueKey('report_mode_live')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 250));

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('report page shows history summary while detail is loading', (
    tester,
  ) async {
    final detailCompleter = Completer<ReportViewData>();
    final summary = DiagnosisReportSummary(
      id: 'history-report',
      testTime: '2026-04-17 10:30',
      healthScore: 76,
      physiqueName: 'History Quick',
      imageUrl: '',
      faceImageUrl: '',
      lockedStatus: '1',
      deepPredicts: const DiagnosisDeepPredicts(
        categoryProbabilities: <DiagnosisNamedProbability>[],
        predictions: <DiagnosisNamedProbability>[],
        diseases: <DiagnosisDisease>[],
        raw: <String, dynamic>{},
      ),
      raw: const <String, dynamic>{},
    );

    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'history-report',
        initialViewData: ReportViewData.fromSummary(summary),
        loadReportViewData: (_) => detailCompleter.future,
      ),
    );

    expect(find.byKey(const ValueKey('report_mode_live')), findsOneWidget);
    expect(find.byKey(const ValueKey('report_loading')), findsNothing);
    expect(find.text('History Quick'), findsWidgets);

    detailCompleter.complete(
      buildReportViewData(
        id: 'history-report',
        primaryConstitution: 'Loaded Detail',
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Loaded Detail'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 250));

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('report hero reflects shared backend summary fields', (
    tester,
  ) async {
    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'live-report',
        loadReportViewData: (_) async => buildReportViewData(
          testTime: '2026-04-17 10:30',
          source: 'scan-booth',
          primaryConstitution: '气虚体质',
          therapySummary: '疏肝解郁，少食生冷，多做舒展运动。',
          faceAge: 23,
          imageUrl: 'https://example.com/tongue.png',
          faceImageUrl: 'https://example.com/face.png',
          handImageUrl: 'https://example.com/hand.png',
          analysisFindingSymptoms: const ['舌边齿痕', '舌苔白'],
          constitutionScores: const [
            {
              'id': 'constitution-primary',
              'name': '气虚体质',
              'score': 82,
              'solutions': '疏肝解郁，少食生冷，多做舒展运动。',
            },
            {
              'id': 'constitution-secondary',
              'name': '阳虚体质',
              'score': 67,
              'solutions': '',
            },
            {
              'id': 'constitution-third',
              'name': '痰湿体质',
              'score': 58,
              'solutions': '',
            },
          ],
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('report_hero_primary_constitution')),
      findsOneWidget,
    );
    expect(find.text('气虚体质'), findsWidgets);
    expect(find.text('阳虚体质'), findsOneWidget);
    expect(find.text('痰湿体质'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('report_hero_view_images_button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('report_hero_age_badge')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('report_hero_tongue_line')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('report_hero_therapy_line')),
      findsOneWidget,
    );
    expect(find.textContaining('2026.04.17'), findsWidgets);
    expect(tester.takeException(), isNull);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('share button opens report share dialog', (tester) async {
    const qrCodeBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9s2kZXcAAAAASUVORK5CYII=';
    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'share-report',
        loadReportViewData: (_) async =>
            buildReportViewData(id: 'share-report'),
        loadReportShareQrCode: (_) async => const DiagnosisReportShareQrCode(
          imageUrl: '',
          imageBase64: 'data:image/png;base64,$qrCodeBase64',
          shareUrl: 'https://example.com/report?reportId=share-report',
          shareText: '',
          raw: <String, dynamic>{},
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('report_share_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('report_share_dialog')), findsOneWidget);
    expect(
      find.text('https://example.com/report?reportId=share-report'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('report_share_copy_button')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('report time renders formatted date when backend returns epoch', (
    tester,
  ) async {
    const rawTimestamp = '1776326400000';
    final expectedDateTime = DateTime.fromMillisecondsSinceEpoch(
      int.parse(rawTimestamp),
    );
    final expectedDate =
        '${expectedDateTime.year}.${twoDigits(expectedDateTime.month)}.${twoDigits(expectedDateTime.day)}';
    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'timestamp-report',
        loadReportViewData: (_) async =>
            buildReportViewData(testTime: rawTimestamp, source: 'scan-booth'),
      ),
    );

    expect(find.textContaining(rawTimestamp), findsNothing);
    expect(find.textContaining(expectedDate), findsWidgets);
    expect(tester.takeException(), isNull);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'report header keeps time in the toolbar row while fading into AI title',
    (tester) async {
      final router = await _pumpReportRouter(
        tester,
        surfaceSize: const Size(390, 844),
        reportBuilder: (context, state) => ReportPage(
          reportId: 'header-fade-report',
          loadReportViewData: (_) async => buildReportViewData(
            testTime: '2026-04-17 10:30',
            source: 'scan-booth',
            primaryConstitution: '气虚体质',
            therapySummary: '疏肝解郁，规律作息，少食生冷。',
            analysisFindingSymptoms: const ['舌边齿痕', '舌苔白腻'],
            constitutionScores: const [
              {
                'id': 'constitution-primary',
                'name': '气虚体质',
                'score': 82,
                'solutions': '疏肝解郁，规律作息，少食生冷。',
              },
              {
                'id': 'constitution-secondary',
                'name': '阳虚体质',
                'score': 64,
                'solutions': '',
              },
            ],
          ),
        ),
      );

      final reportTime = find.byKey(const ValueKey('report_header_time'));
      final collapsedTitle = find.byKey(
        const ValueKey('report_header_collapsed_title'),
      );
      final backButton = find.byKey(const ValueKey('report_back_button'));
      final shareButton = find.byKey(const ValueKey('report_share_button'));
      final therapyLine = find.byKey(
        const ValueKey('report_hero_therapy_line'),
      );

      expect(reportTime, findsOneWidget);
      expect(collapsedTitle, findsOneWidget);
      expect(
        (tester.getCenter(reportTime).dy - tester.getCenter(backButton).dy)
            .abs(),
        lessThan(4),
      );
      expect(
        (tester.getCenter(reportTime).dy - tester.getCenter(shareButton).dy)
            .abs(),
        lessThan(4),
      );

      final initialTimeOpacity = tester.widget<Opacity>(reportTime).opacity;
      final initialTitleOpacity = tester
          .widget<Opacity>(collapsedTitle)
          .opacity;
      expect(initialTimeOpacity, greaterThan(0.9));
      expect(initialTitleOpacity, lessThan(0.1));

      await tester.drag(therapyLine, const Offset(0, -700));
      await tester.pumpAndSettle();

      final scrolledTimeOpacity = tester.widget<Opacity>(reportTime).opacity;
      final scrolledTitleOpacity = tester
          .widget<Opacity>(collapsedTitle)
          .opacity;
      expect(scrolledTimeOpacity, lessThan(initialTimeOpacity));
      expect(scrolledTitleOpacity, greaterThan(initialTitleOpacity));
      expect(scrolledTimeOpacity, lessThan(0.4));
      expect(scrolledTitleOpacity, greaterThan(0.6));
      expect(tester.takeException(), isNull);

      router.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('hero content does not jump upward on first small scroll', (
    tester,
  ) async {
    final router = await _pumpReportRouter(
      tester,
      surfaceSize: const Size(390, 844),
      reportBuilder: (context, state) => ReportPage(
        reportId: 'hero-scroll-stability',
        loadReportViewData: (_) async => buildReportViewData(),
      ),
    );

    final therapyLine = find.byKey(const ValueKey('report_hero_therapy_line'));
    expect(therapyLine, findsOneWidget);

    final initialTop = tester.getTopLeft(therapyLine).dy;

    await tester.drag(therapyLine, const Offset(0, -24));
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final scrollOffset = scrollable.position.pixels;
    final shiftedTop = tester.getTopLeft(therapyLine).dy;
    final upwardShift = initialTop - shiftedTop;

    expect(scrollOffset, greaterThan(0));
    expect(upwardShift, lessThan(scrollOffset + 12));
    expect(tester.takeException(), isNull);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('hero grows to fit long therapy content on handset', (
    tester,
  ) async {
    final longTherapy = List.filled(4, '疏肝理气，规律作息，减少生冷甜腻，晚间泡脚并做舒展运动。').join();
    final router = await _pumpReportRouter(
      tester,
      surfaceSize: const Size(390, 1400),
      reportBuilder: (context, state) => ReportPage(
        reportId: 'long-hero',
        loadReportViewData: (_) async => buildReportViewData(
          primaryConstitution: '气虚体质',
          faceAge: 23,
          therapySummary: longTherapy,
          analysisFindingSymptoms: const [
            '舌边齿痕',
            '舌苔白',
            '舌体偏胖',
            '津液稍少',
            '舌尖偏红',
          ],
          constitutionScores: const [
            {
              'id': 'constitution-primary',
              'name': '气虚体质',
              'score': 82,
              'solutions': '',
            },
            {
              'id': 'constitution-secondary-1',
              'name': '阳虚体质',
              'score': 74,
              'solutions': '',
            },
            {
              'id': 'constitution-secondary-2',
              'name': '痰湿体质',
              'score': 68,
              'solutions': '',
            },
            {
              'id': 'constitution-secondary-3',
              'name': '湿热体质',
              'score': 63,
              'solutions': '',
            },
            {
              'id': 'constitution-secondary-4',
              'name': '血瘀体质',
              'score': 57,
              'solutions': '',
            },
          ],
        ),
      ),
    );

    final therapyLine = find.byKey(const ValueKey('report_hero_therapy_line'));
    final disclaimer = find.byKey(const ValueKey('report_hero_disclaimer'));
    final tabBar = find.byType(TabBar);

    expect(therapyLine, findsOneWidget);
    expect(disclaimer, findsOneWidget);
    expect(
      tester.getBottomLeft(therapyLine).dy,
      lessThan(tester.getTopLeft(tabBar).dy),
    );
    expect(
      tester.getTopLeft(tabBar).dy - tester.getBottomLeft(disclaimer).dy,
      greaterThanOrEqualTo(0),
    );
    expect(tester.takeException(), isNull);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('hero keeps disclaimer visible above the tab bar on handset', (
    tester,
  ) async {
    final router = await _pumpReportRouter(
      tester,
      surfaceSize: const Size(390, 844),
      reportBuilder: (context, state) => ReportPage(
        reportId: 'short-hero',
        loadReportViewData: (_) async => buildReportViewData(
          primaryConstitution: '平和体质',
          therapySummary: '疏肝解郁，规律作息。',
          analysisFindingSymptoms: const ['舌边齿痕', '舌苔白'],
          constitutionScores: const [
            {
              'id': 'constitution-primary',
              'name': '平和体质',
              'score': 78,
              'solutions': '疏肝解郁，规律作息。',
            },
            {
              'id': 'constitution-secondary',
              'name': '阳虚体质',
              'score': 64,
              'solutions': '',
            },
          ],
        ),
      ),
    );

    final therapyLine = find.byKey(const ValueKey('report_hero_therapy_line'));
    final disclaimer = find.byKey(const ValueKey('report_hero_disclaimer'));
    final tabBar = find.byType(TabBar);

    expect(therapyLine, findsOneWidget);
    expect(disclaimer, findsOneWidget);
    expect(
      tester.getTopLeft(disclaimer).dy - tester.getBottomLeft(therapyLine).dy,
      lessThan(6),
    );
    expect(
      tester.getTopLeft(tabBar).dy - tester.getBottomLeft(disclaimer).dy,
      greaterThanOrEqualTo(0),
    );
    expect(
      tester.getTopLeft(tabBar).dy - tester.getBottomLeft(disclaimer).dy,
      lessThan(96),
    );
    expect(tester.takeException(), isNull);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('hero keeps disclaimer visible on 430dp wide handset', (
    tester,
  ) async {
    final router = await _pumpReportRouter(
      tester,
      surfaceSize: const Size(430, 932),
      reportBuilder: (context, state) => ReportPage(
        reportId: 'wide-handset-hero',
        loadReportViewData: (_) async => buildReportViewData(
          primaryConstitution: '平和体质',
          therapySummary: '疏肝解郁，规律作息。',
          analysisFindingSymptoms: const ['舌边齿痕', '舌苔白'],
          constitutionScores: const [
            {
              'id': 'constitution-primary',
              'name': '平和体质',
              'score': 78,
              'solutions': '疏肝解郁，规律作息。',
            },
            {
              'id': 'constitution-secondary',
              'name': '阳虚体质',
              'score': 64,
              'solutions': '',
            },
          ],
        ),
      ),
    );

    final therapyLine = find.byKey(const ValueKey('report_hero_therapy_line'));
    final disclaimer = find.byKey(const ValueKey('report_hero_disclaimer'));
    final tabBar = find.byType(TabBar);

    expect(therapyLine, findsOneWidget);
    expect(disclaimer, findsOneWidget);
    expect(
      tester.getTopLeft(disclaimer).dy - tester.getBottomLeft(therapyLine).dy,
      lessThan(6),
    );
    expect(
      tester.getTopLeft(tabBar).dy - tester.getBottomLeft(disclaimer).dy,
      greaterThanOrEqualTo(0),
    );
    expect(
      tester.getTopLeft(tabBar).dy - tester.getBottomLeft(disclaimer).dy,
      lessThan(96),
    );
    expect(tester.takeException(), isNull);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('tongue analysis keeps only the small heading in overview', (
    tester,
  ) async {
    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'tongue-report',
        loadReportViewData: (_) async => buildReportViewData(
          analysisFindings: const [
            {
              'type': 'tongue_isIndentation',
              'typeDesc': '齿痕',
              'symptoms': [
                {
                  'id': 'indentation-1',
                  'name': '齿痕',
                  'describe': '多见于脾虚湿盛，运化乏力。',
                },
              ],
            },
            {
              'type': 'moss_color',
              'typeDesc': '舌苔颜色',
              'symptoms': [
                {'id': 'moss-1', 'name': '舌苔白'},
              ],
            },
            {'type': 'tongue_isCrack', 'typeDesc': '舌裂', 'symptoms': []},
          ],
          categoryProbabilities: const [],
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('report_overview_tongue_analysis_section')),
      findsOneWidget,
    );
    expect(find.text('舌象解析'), findsOneWidget);
    expect(find.text('辨证摘要'), findsNothing);
    expect(find.text('齿痕'), findsWidgets);
    expect(find.text('舌苔颜色'), findsOneWidget);
    expect(find.text('病理解析'), findsNWidgets(2));

    await tester.tap(find.byType(Tab).at(3));
    await tester.pumpAndSettle();

    expect(find.text('舌象解析'), findsNothing);
    expect(find.text('病理解析'), findsNothing);
    expect(find.text('检测结果'), findsNothing);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('constitution detail table reflects live constitution ranking', (
    tester,
  ) async {
    await getIt.reset();
    AppIdentity.resetForTest();
    final dioClient = DioClient();
    final adapter = _ReportPageCaptureAdapter((options) {
      if (options.path == '/api/v1/saas/mobile/physique/therapy') {
        return _jsonResponse({
          'code': 0,
          'message': 'ok',
          'data': {
            'therapies': [
              {'feature': '少气懒言，容易疲乏。', 'principle': '益气健脾，规律作息。'},
            ],
          },
        });
      }
      return _jsonResponse({'code': 0, 'message': 'ok', 'data': null});
    });
    dioClient.dio.httpClientAdapter = adapter;
    getIt.registerSingleton<DioClient>(dioClient);
    addTearDown(() async {
      await getIt.reset();
      AppIdentity.resetForTest();
    });
    final l10n = lookupAppLocalizations(const Locale('zh'));
    final viewData = buildReportViewData(
      token: 'therapy-token',
      constitutionScores: const [
        {'id': '1', 'name': 'Balanced', 'score': 40},
        {'id': '2', 'name': 'Qi deficiency', 'score': 35},
        {'id': '3', 'name': 'Yang deficiency', 'score': 20},
      ],
      tzpdResults: const [
        {'id': '2', 'score': 30},
        {'id': '3', 'score': 15},
      ],
      categoryProbabilities: const [],
    );
    expect(viewData.isLive, isTrue);
    expect(viewData.constitutionScores.first.id, '2');
    expect(viewData.constitutionScores.first.name, 'Qi deficiency');

    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'live-report',
        loadReportViewData: (_) async => viewData,
      ),
    );

    await tester.tap(find.text(l10n.reportTabConstitution));
    await tester.pumpAndSettle();
    expect(find.text(l10n.reportConstitutionDetailTitle), findsOneWidget);
    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 20; attempt++) {
        if (adapter.requests.any(
          (request) => request.path == '/api/v1/saas/mobile/physique/therapy',
        )) {
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    await tester.pumpAndSettle();

    final qiLabel = find.text('Qi deficiency').last;
    final balancedLabel = find.text('Balanced').last;
    final yangLabel = find.text('Yang deficiency').last;

    expect(find.text('Qi deficiency'), findsWidgets);
    expect(find.text('Balanced'), findsWidgets);
    expect(find.text('Yang deficiency'), findsWidgets);
    expect(
      adapter.requests.map((request) => request.path),
      contains('/api/v1/saas/mobile/physique/therapy'),
    );
    final therapyRequest = adapter.requests.singleWhere(
      (request) => request.path == '/api/v1/saas/mobile/physique/therapy',
    );
    expect(therapyRequest.queryParameters['physiqueIds'], [2]);
    expect(
      therapyRequest.queryParameters.keys,
      unorderedEquals(['age', 'sex', 'token', 'physiqueIds']),
    );
    expect(therapyRequest.queryParameters['age'], 30);
    expect(therapyRequest.queryParameters['sex'], 'F');
    expect(therapyRequest.queryParameters['token'], 'therapy-token');
    expect(find.textContaining('体质特征：少气懒言，容易疲乏。'), findsOneWidget);
    expect(find.textContaining('调理原则：益气健脾，规律作息。'), findsOneWidget);
    expect(find.textContaining('整体以平和质为基础'), findsNothing);
    expect(
      tester.getTopLeft(qiLabel).dy,
      lessThan(tester.getTopLeft(balancedLabel).dy),
    );
    expect(
      tester.getTopLeft(balancedLabel).dy,
      lessThan(tester.getTopLeft(yangLabel).dy),
    );

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('therapy tab renders backend point field for dominant physique', (
    tester,
  ) async {
    await getIt.reset();
    AppIdentity.resetForTest();
    final dioClient = DioClient();
    final adapter = _ReportPageCaptureAdapter((options) {
      if (options.path == '/api/v1/saas/mobile/physique/therapy') {
        return _jsonResponse({
          'code': 0,
          'message': 'ok',
          'data': {
            'therapies': [
              {
                'method': '每日按揉太冲、内关各 3-5 分钟，配合深呼吸放松。',
                'remark': '以酸胀为度，孕期或明显不适时请先咨询医师。',
                'point': [
                  {
                    'pointName': '太冲',
                    'location': '足背第一、二跖骨结合部前方凹陷处',
                    'meridian': '足厥阴肝经',
                  },
                  {
                    'pointName': '内关',
                    'location': '腕横纹上2寸',
                    'meridian': '手厥阴心包经',
                  },
                ],
              },
            ],
          },
        });
      }
      return _jsonResponse({'code': 0, 'message': 'ok', 'data': null});
    });
    dioClient.dio.httpClientAdapter = adapter;
    getIt.registerSingleton<DioClient>(dioClient);
    addTearDown(() async {
      await getIt.reset();
      AppIdentity.resetForTest();
    });
    final l10n = lookupAppLocalizations(const Locale('zh'));
    final viewData = buildReportViewData(
      constitutionScores: const [
        {'id': '8', 'name': '气郁体质', 'score': 76},
        {'id': '1', 'name': '平和体质', 'score': 42},
      ],
      categoryProbabilities: const [],
    );

    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'therapy-report',
        loadReportViewData: (_) async => viewData,
      ),
    );

    await tester.tap(find.text(l10n.reportTabTherapy));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 20; attempt++) {
        if (adapter.requests.any(
          (request) => request.path == '/api/v1/saas/mobile/physique/therapy',
        )) {
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    await tester.pumpAndSettle();

    final therapyRequests = adapter.requests
        .where(
          (request) => request.path == '/api/v1/saas/mobile/physique/therapy',
        )
        .toList(growable: false);
    expect(therapyRequests, isNotEmpty);
    expect(therapyRequests.last.queryParameters['physiqueIds'], [8]);
    expect(
      therapyRequests.last.queryParameters.keys,
      unorderedEquals(['age', 'sex', 'physiqueIds']),
    );
    expect(therapyRequests.last.queryParameters['age'], 30);
    expect(therapyRequests.last.queryParameters['sex'], 'F');
    expect(find.text('太冲'), findsOneWidget);
    expect(find.text('内关'), findsOneWidget);
    expect(find.text('point 接口'), findsNothing);
    expect(find.textContaining('point', skipOffstage: false), findsNothing);
    expect(find.text('每日按揉太冲、内关各 3-5 分钟，配合深呼吸放松。'), findsOneWidget);
    expect(find.textContaining('以酸胀为度', skipOffstage: false), findsWidgets);
    expect(find.textContaining('结合当前体质偏向'), findsNothing);
    expect(find.text('足三里'), findsNothing);
    expect(tester.takeException(), isNull);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('physique analysis content is shared across live report tabs', (
    tester,
  ) async {
    await getIt.reset();
    AppIdentity.resetForTest();
    final dioClient = DioClient();
    final adapter = _ReportPageCaptureAdapter((options) {
      if (options.path == '/api/v1/saas/mobile/physique/2/analysis') {
        return _jsonResponse({
          'code': 0,
          'message': 'ok',
          'data': {
            'id': 2,
            'name': '气虚质',
            'standardVersion': '2026',
            'mainFeature': '元气不足，容易疲乏。',
            'bodyFeature': '肌肉松软，声音偏低。',
            'psychologicalFeature': '性格偏内向，情绪起伏不大。',
            'diseaseTendencyNote': '长期疲劳时需关注免疫力。',
            'environmentAdaptability': '不耐寒暑，换季易不适。',
            'manifestations': [
              {'id': 'm2', 'name': '气短', 'sortNo': 2},
              {'id': 1, 'name': '疲乏', 'sortNo': 1},
            ],
            'diseaseTendencies': [
              {'id': 8, 'name': '易感冒', 'sortNo': 1},
              {'id': '9', 'name': '内脏下垂倾向', 'sortNo': 2},
            ],
            'sections': [
              {
                'sectionType': 'diet_reference',
                'title': '饮食参考',
                'sortNo': 3,
                'contents': [
                  {
                    'contentTitle': '饮食节律',
                    'contentText': '少量多餐，优先温软易消化食物。',
                    'sortNo': 1,
                  },
                ],
              },
              {
                'sectionType': 'interpretation',
                'title': '体质解读',
                'sortNo': 1,
                'contents': [
                  {
                    'contentTitle': '气虚解读',
                    'contentText': '重点是补气健脾，减少持续透支。',
                    'sortNo': 1,
                  },
                ],
              },
              {
                'sectionType': 'conditioning_reference',
                'heroTitle': 'Qi recovery routine',
                'heroSubtitle': 'Build a steady daily rhythm.',
                'heroDescription':
                    'Rest, meals, and light activity come first.',
                'title': '调养参考',
                'sortNo': 2,
                'contents': [
                  {
                    'contentTitle': '作息调养',
                    'contentText': '保持固定入睡时间，避免连续熬夜。',
                    'sortNo': 1,
                  },
                ],
              },
            ],
          },
        });
      }
      if (options.path == '/api/v1/saas/mobile/physique/therapy') {
        return _jsonResponse({
          'code': 0,
          'message': 'ok',
          'data': {'therapies': const <Map<String, Object>>[]},
        });
      }
      return _jsonResponse({'code': 0, 'message': 'ok', 'data': null});
    });
    dioClient.dio.httpClientAdapter = adapter;
    getIt.registerSingleton<DioClient>(dioClient);
    addTearDown(() async {
      await getIt.reset();
      AppIdentity.resetForTest();
    });

    final l10n = lookupAppLocalizations(const Locale('zh'));
    final viewData = buildReportViewData(
      constitutionScores: const [
        {'id': '2', 'name': '气虚质', 'score': 82},
        {'id': '1', 'name': '平和质', 'score': 32},
      ],
      categoryProbabilities: const [],
    );
    expect(viewData.isLive, isTrue);
    expect(viewData.constitutionScores.first.id, '2');

    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'analysis-report',
        loadReportViewData: (_) async => viewData,
      ),
    );
    expect(find.byKey(const ValueKey('report_mode_live')), findsOneWidget);

    await tester.tap(find.text(l10n.reportTabConstitution));
    await tester.pumpAndSettle();
    for (var attempt = 0; attempt < 20; attempt++) {
      if (adapter.requests.any(
        (request) => request.path == '/api/v1/saas/mobile/physique/2/analysis',
      )) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
    }
    expect(
      adapter.requests.map((request) => request.path),
      contains('/api/v1/saas/mobile/physique/2/analysis'),
    );
    await tester.pumpAndSettle();
    final interpretationHero = find.byKey(
      const ValueKey('report_physique_analysis_section_hero_interpretation'),
    );
    expect(interpretationHero, findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('report_physique_analysis_section_image_placeholder'),
      ),
      findsOneWidget,
    );
    final interpretationHeroSize = tester.getSize(interpretationHero);
    expect(interpretationHeroSize.height, greaterThanOrEqualTo(196));
    expect(
      find.byKey(const ValueKey('report_physique_analysis_section_image_fade')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey(
          'report_physique_analysis_section_content_interpretation_0',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('体质分析'), findsOneWidget);
    expect(find.text('主要特征'), findsOneWidget);
    expect(find.text('元气不足，容易疲乏。'), findsWidgets);
    expect(find.textContaining('疲乏、气短'), findsOneWidget);
    expect(find.textContaining('易感冒、内脏下垂倾向'), findsOneWidget);
    expect(find.text('体质解读'), findsOneWidget);
    expect(find.text('气虚解读'), findsOneWidget);
    expect(find.text('重点是补气健脾，减少持续透支。'), findsOneWidget);
    final interpretationContentText = tester.widget<Text>(
      find.text('重点是补气健脾，减少持续透支。'),
    );
    expect(interpretationContentText.maxLines, isNull);
    expect(interpretationContentText.overflow, isNull);
    expect(find.text('作息'), findsNothing);
    expect(find.text('过度劳累'), findsNothing);

    await tester.tap(find.text(l10n.reportTabTherapy));
    await tester.pumpAndSettle();
    expect(find.text('调养参考'), findsOneWidget);
    expect(find.text('Qi recovery routine'), findsOneWidget);
    expect(find.text('Build a steady daily rhythm.'), findsOneWidget);
    expect(
      find.text('Rest, meals, and light activity come first.'),
      findsOneWidget,
    );
    final conditioningHeroDescription = tester.widget<Text>(
      find.text('Rest, meals, and light activity come first.'),
    );
    expect(conditioningHeroDescription.maxLines, isNull);
    expect(conditioningHeroDescription.overflow, isNull);
    expect(find.text('作息调养'), findsOneWidget);
    expect(find.text('保持固定入睡时间，避免连续熬夜。'), findsOneWidget);
    expect(find.text('恬淡虚无'), findsNothing);

    expect(
      find.byKey(
        const ValueKey(
          'report_physique_analysis_section_hero_conditioning_reference',
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text(l10n.reportTabAdvice));
    await tester.pumpAndSettle();
    expect(find.text('饮食建议'), findsOneWidget);
    expect(find.text('饮食节律'), findsWidgets);
    expect(find.text('少量多餐，优先温软易消化食物。'), findsWidgets);
    expect(find.text('山药'), findsNothing);
    expect(find.text('薏仁'), findsNothing);
    expect(find.text('红枣'), findsNothing);

    expect(
      find.byKey(
        const ValueKey('report_physique_analysis_section_hero_diet_reference'),
      ),
      findsOneWidget,
    );

    final analysisRequests = adapter.requests
        .where(
          (request) =>
              request.path == '/api/v1/saas/mobile/physique/2/analysis',
        )
        .toList(growable: false);
    expect(analysisRequests, hasLength(1));
    expect(tester.takeException(), isNull);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('risk section hides when there is no risk data', (tester) async {
    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'live-report',
        loadReportViewData: (_) async =>
            buildReportViewData(categoryProbabilities: const []),
      ),
    );

    expect(find.text('风险指数'), findsNothing);
    expect(
      find.byKey(const ValueKey('report_risk_consult_button')),
      findsNothing,
    );

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('risk section shows only the highest four scores', (
    tester,
  ) async {
    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'live-report',
        loadReportViewData: (_) async => buildReportViewData(
          categoryProbabilities: const [
            {'name': '消化道', 'prob': 0.41},
            {'name': '神志精神及情绪', 'prob': 0.89},
            {'name': '作息睡眠', 'prob': 0.69},
            {'name': '两性泌尿生殖', 'prob': 0.67},
            {'name': '睡眠失调', 'prob': 0.58},
            {'name': '饮食习惯', 'prob': 1.0},
          ],
        ),
      ),
    );

    expect(find.byKey(const ValueKey('report_risk_card_饮食习惯')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('report_risk_card_神志精神及情绪')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('report_risk_card_作息睡眠')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('report_risk_card_两性泌尿生殖')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('report_risk_card_睡眠失调')), findsNothing);
    expect(find.byKey(const ValueKey('report_risk_card_消化道')), findsNothing);
    expect(tester.takeException(), isNull);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('health radar hides when both symptom sources are empty', (
    tester,
  ) async {
    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'live-report',
        loadReportViewData: (_) async =>
            buildReportViewData(relativeSyms: const [], predictions: const []),
      ),
    );

    expect(find.text('健康雷达'), findsNothing);
    expect(
      find.byKey(const ValueKey('report_health_radar_mode_switch')),
      findsNothing,
    );

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'health radar shows empty classic state then switches to ai deep data',
    (tester) async {
      final router = await _pumpReportRouter(
        tester,
        reportBuilder: (context, state) => ReportPage(
          reportId: 'live-report',
          loadReportViewData: (_) async => buildReportViewData(
            relativeSyms: const [],
            predictions: const [
              {'id': 'deep-1', 'name': '声音无力', 'prob': 0.63},
            ],
          ),
        ),
      );

      expect(find.text('健康雷达'), findsOneWidget);
      expect(find.text('暂无数据'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('report_health_radar_mode_switch')),
      );
      await tester.pumpAndSettle();

      expect(find.text('声音无力'), findsOneWidget);
      expect(find.text('暂无数据'), findsNothing);

      router.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'health radar taps persist classic and ai deep symptoms with miniapp recommend types',
    (tester) async {
      final calls = <String>[];
      final router = await _pumpReportRouter(
        tester,
        reportBuilder: (context, state) => ReportPage(
          reportId: 'live-report',
          loadReportViewData: (_) async => buildReportViewData(
            relativeSyms: const [
              {'id': 'classic-1', 'name': '饭后胃胀痛'},
            ],
            predictions: const [
              {'id': 'deep-1', 'name': '声音无力', 'prob': 0.63},
            ],
          ),
          addReportSymptom:
              ({
                required reportId,
                required symptomId,
                required symptomName,
                required recommendType,
              }) async {
                calls.add('add:$recommendType:$symptomId:$symptomName');
              },
          deleteReportSymptom:
              ({
                required reportId,
                required symptomId,
                required recommendType,
              }) async {
                calls.add('delete:$recommendType:$symptomId');
              },
        ),
      );

      await tester.tap(find.text('饭后胃胀痛'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('饭后胃胀痛'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('report_health_radar_mode_switch')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('声音无力'));
      await tester.pumpAndSettle();

      expect(
        calls,
        equals([
          'add:2:classic-1:饭后胃胀痛',
          'delete:2:classic-1',
          'add:1:deep-1:声音无力',
        ]),
      );

      router.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('health radar toggles locally without persistence handlers', (
    tester,
  ) async {
    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'live-report',
        loadReportViewData: (_) async => buildReportViewData(
          relativeSyms: const [
            {'id': 'classic-1', 'name': 'Classic symptom'},
          ],
        ),
      ),
    );

    final chipFinder = find.byKey(
      const ValueKey('report_health_radar_chip_classic_0'),
    );
    BoxDecoration readDecoration() {
      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: chipFinder,
          matching: find.byType(AnimatedContainer),
        ),
      );
      return container.decoration! as BoxDecoration;
    }

    expect(readDecoration().color, equals(Colors.white));

    await tester.tap(chipFinder);
    await tester.pumpAndSettle();

    expect(readDecoration().color, equals(const Color(0xFFFFF3E6)));
    expect(tester.takeException(), isNull);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('risk cards fit on handset viewport without overflow', (
    tester,
  ) async {
    final router = await _pumpReportRouter(
      tester,
      surfaceSize: const Size(390, 844),
      reportBuilder: (context, state) => ReportPage(
        reportId: 'live-report',
        loadReportViewData: (_) async => buildReportViewData(
          summary: 'Recovered live summary',
          categoryProbabilities: const [
            {'name': '神志精神及情绪', 'prob': 0.89},
            {'name': '作息睡眠', 'prob': 0.69},
            {'name': '两性泌尿生殖', 'prob': 0.67},
            {'name': '消化道', 'prob': 0.41},
          ],
        ),
      ),
    );

    expect(find.byKey(const ValueKey('report_mode_live')), findsOneWidget);
    expect(tester.takeException(), isNull);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('risk tip stays tight to cards without grid auto padding', (
    tester,
  ) async {
    final router = await _pumpReportRouter(
      tester,
      surfaceSize: const Size(390, 844),
      reportBuilder: (context, state) => ReportPage(
        reportId: 'risk-spacing',
        loadReportViewData: (_) async => buildReportViewData(
          categoryProbabilities: const [
            {'name': 'Mood', 'prob': 0.89},
            {'name': 'Sleep', 'prob': 0.82},
            {'name': 'Digestive', 'prob': 0.77},
            {'name': 'Stress', 'prob': 0.69},
          ],
        ),
      ),
    );

    final tipCard = find.byKey(const ValueKey('report_risk_tip_card'));
    final firstRiskCard = find.byKey(const ValueKey('report_risk_card_Mood'));
    final gridView = tester.widget<GridView>(find.byType(GridView).first);

    expect(tipCard, findsOneWidget);
    expect(firstRiskCard, findsOneWidget);
    expect(gridView.primary, isFalse);
    expect(gridView.padding, equals(EdgeInsets.zero));
    expect(
      tester.getTopLeft(firstRiskCard).dy - tester.getBottomLeft(tipCard).dy,
      lessThan(8),
    );
    expect(tester.takeException(), isNull);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('consult cta appears after sidecar navigate loads', (
    tester,
  ) async {
    final consultCompleter = Completer<DiagnosisMaNavigate?>();
    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'live-report',
        loadReportViewData: (_) async => buildReportViewData(
          summary: 'Recovered live summary',
          categoryProbabilities: const [
            {'name': '消化道', 'prob': 0.41},
            {'name': '神志精神及情绪', 'prob': 0.89},
            {'name': '作息睡眠', 'prob': 0.69},
            {'name': '两性泌尿生殖', 'prob': 0.67},
            {'name': '睡眠失调', 'prob': 0.58},
          ],
        ),
        loadConsultNavigate: (_) => consultCompleter.future,
      ),
    );

    expect(find.text('风险指数'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('report_risk_consult_button')),
      findsNothing,
    );

    consultCompleter.complete(
      const DiagnosisMaNavigate(
        type: 'QR',
        appId: '',
        path: '',
        imageUrl: '',
        imageTitle: '专家解读',
        title: '专家解读',
        raw: <String, dynamic>{},
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('report_risk_consult_button')),
      findsOneWidget,
    );
    expect(find.text('睡眠失调'), findsOneWidget);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('report page shows retry state when live loader fails first', (
    tester,
  ) async {
    var attempts = 0;
    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'live-report',
        loadReportViewData: (_) async {
          attempts++;
          if (attempts == 1) {
            throw Exception('temporary failure');
          }
          return buildReportViewData(summary: 'Retry success summary');
        },
      ),
    );

    expect(find.byKey(const ValueKey('report_error')), findsOneWidget);
    expect(find.byKey(const ValueKey('report_retry_button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('report_retry_button')));
    await tester.pump();

    expect(find.byKey(const ValueKey('report_loading')), findsOneWidget);

    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.byKey(const ValueKey('report_mode_live')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 250));

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('switching to advice tab reveals project and product actions', (
    tester,
  ) async {
    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'advice-report',
        loadReportViewData: (_) async =>
            ReportViewData.demo(reportId: 'advice-report'),
      ),
    );
    final l10n = lookupAppLocalizations(const Locale('zh'));

    await tester.tap(find.text(l10n.reportTabAdvice));
    await tester.pumpAndSettle();

    expect(find.text(l10n.reportAdviceProjectDetailButton), findsWidgets);
    expect(find.text(l10n.reportAdviceProductDetailButton), findsWidgets);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('project detail route works from report advice tab', (
    tester,
  ) async {
    final router = await _pumpReportRouter(
      tester,
      reportBuilder: (context, state) => ReportPage(
        reportId: 'project-report',
        loadReportViewData: (_) async =>
            ReportViewData.demo(reportId: 'project-report'),
      ),
    );
    final l10n = lookupAppLocalizations(const Locale('zh'));

    await tester.tap(find.text(l10n.reportTabAdvice));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.reportAdviceProjectDetailButton).first);
    await tester.pumpAndSettle();

    expect(find.byType(ReportProjectDetailPage), findsOneWidget);
    expect(find.text(l10n.reportProjectDetailActionButton), findsOneWidget);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('project detail route restores from query parameters', (
    tester,
  ) async {
    final project = ReportProjectData(
      id: 'project-route-1',
      name: 'Warm Care',
      type: 'In-clinic service',
      description: 'Route-safe description',
      tag: 'Recommended',
      durationNote: '45 min',
      serviceNote: 'Service note',
      consultNote: 'Consult note',
      color: const Color(0xFF2D6A4F),
      icon: Icons.spa_outlined,
    );
    final router = await _pumpReportRouter(
      tester,
      initialLocation: Uri(
        path: AppRoutes.reportProjectDetail,
        queryParameters: project.toRouteQueryParameters(),
      ).toString(),
    );

    expect(find.byType(ReportProjectDetailPage), findsOneWidget);
    expect(find.text('Warm Care'), findsOneWidget);
    expect(find.text('Route-safe description'), findsOneWidget);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'product detail and checkout routes still work from report page',
    (tester) async {
      final router = await _pumpReportRouter(
        tester,
        reportBuilder: (context, state) => ReportPage(
          reportId: 'product-report',
          loadReportViewData: (_) async =>
              ReportViewData.demo(reportId: 'product-report'),
        ),
      );
      final l10n = lookupAppLocalizations(const Locale('zh'));

      await tester.tap(find.text(l10n.reportTabAdvice));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.reportAdviceProductDetailButton).first);
      await tester.pumpAndSettle();

      expect(find.byType(ReportProductDetailPage), findsOneWidget);

      await tester.tap(find.text(l10n.reportProductDetailCheckoutButton));
      await tester.pumpAndSettle();

      expect(find.byType(ReportCheckoutPage), findsOneWidget);

      router.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );
}
