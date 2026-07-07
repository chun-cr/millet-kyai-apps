import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/features/report/presentation/pages/report/report_page.dart';
import 'package:millet_kyai_apps/l10n/app_localizations.dart';

import 'report_test_data.dart';

void main() {
  testWidgets('advice enhancement tiles lay out on phone width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
        home: ReportPage(
          reportId: '88',
          loadReportViewData: (_) async => buildReportViewData(id: '88'),
          loadReportShareQrCode: (_) async => const DiagnosisReportShareQrCode(
            imageUrl: '',
            imageBase64: '',
            shareUrl: '',
            shareText: '',
            raw: <String, dynamic>{},
          ),
          addReportSymptom:
              ({
                required reportId,
                required symptomId,
                required symptomName,
                required recommendType,
              }) async {},
          deleteReportSymptom:
              ({
                required reportId,
                required symptomId,
                required recommendType,
              }) async {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    final l10n = lookupAppLocalizations(const Locale('zh'));
    await tester.tap(find.text(l10n.reportTabAdvice));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
