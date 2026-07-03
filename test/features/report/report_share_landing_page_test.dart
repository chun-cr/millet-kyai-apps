import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:millet_kyai_apps/core/router/app_router.dart';
import 'package:millet_kyai_apps/features/report/presentation/pages/report_share_landing_page.dart';

Future<GoRouter> _pumpLandingRouter(
  WidgetTester tester, {
  required String initialLocation,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 2400));

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text('home', key: ValueKey('landing_home_target')),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.reportShareLanding,
        builder: (context, state) =>
            ReportShareLandingPage(initialUri: state.uri),
      ),
      GoRoute(
        path: AppRoutes.report,
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text(
              'report:${state.uri.queryParameters['reportId'] ?? ''}',
              key: const ValueKey('landing_report_target'),
            ),
          ),
        ),
      ),
    ],
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150));
  return router;
}

void main() {
  testWidgets('redirects to report route from p payload path', (tester) async {
    final payload = Uri.encodeComponent(
      jsonEncode(<String, dynamic>{
        'path': AppRoutes.report,
        'params': <String, String>{'reportId': 'report-from-payload'},
      }),
    );

    final router = await _pumpLandingRouter(
      tester,
      initialLocation: '${AppRoutes.reportShareLanding}?p=$payload',
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('landing_report_target')), findsOneWidget);
    expect(find.text('report:report-from-payload'), findsOneWidget);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('redirects to report route from bare reportId', (tester) async {
    final router = await _pumpLandingRouter(
      tester,
      initialLocation: '${AppRoutes.reportShareLanding}?reportId=report-42',
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('landing_report_target')), findsOneWidget);
    expect(find.text('report:report-42'), findsOneWidget);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('shows fallback for invalid payload and returns home', (
    tester,
  ) async {
    final router = await _pumpLandingRouter(
      tester,
      initialLocation: '${AppRoutes.reportShareLanding}?p=%7Bbroken',
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('report_share_landing_invalid')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('report_share_landing_home_button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('landing_home_target')), findsOneWidget);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });
}
