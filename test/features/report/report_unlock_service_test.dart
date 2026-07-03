import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:millet_kyai_apps/features/report/application/report_unlock_service.dart';
import 'package:millet_kyai_apps/features/report/presentation/pages/report/report_page.dart';
import 'package:millet_kyai_apps/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReportUnlockService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'marks store unavailable on unsupported platforms without crashing',
      () async {
        try {
          debugDefaultTargetPlatformOverride = TargetPlatform.windows;

          final service = ReportUnlockService();
          addTearDown(service.dispose);

          await service.initialize();

          expect(service.state.value.status, ReportUnlockStatus.unavailable);
          expect(service.state.value.isStoreAvailable, isFalse);
          expect(service.state.value.message, 'store-unavailable');
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    test(
      'purchase reports store unavailable on unsupported platforms',
      () async {
        try {
          debugDefaultTargetPlatformOverride = TargetPlatform.windows;

          final service = ReportUnlockService();
          addTearDown(service.dispose);

          await service.initialize();
          await service.purchase();

          expect(service.state.value.status, ReportUnlockStatus.error);
          expect(service.state.value.isStoreAvailable, isFalse);
          expect(service.state.value.message, 'store-unavailable');
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets('report page initializes safely on unsupported platforms', (
      tester,
    ) async {
      try {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        await tester.binding.setSurfaceSize(const Size(1280, 2400));
        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
        });

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ReportPage(),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.byType(ReportPage), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
