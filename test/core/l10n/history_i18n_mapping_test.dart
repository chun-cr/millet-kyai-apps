import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/features/history/presentation/pages/history/history_page.dart';
import 'package:millet_kyai_apps/l10n/app_localizations.dart';

void main() {
  Future<BuildContext> pumpLocalizedContext(
    WidgetTester tester,
    Locale locale,
  ) async {
    late BuildContext capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: supportedAppLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    return capturedContext;
  }

  testWidgets('constitution labels localize across locales', (tester) async {
    final zhContext = await pumpLocalizedContext(tester, const Locale('zh'));
    expect(ConstitutionType.balanced.label(zhContext), '平和质');

    final enContext = await pumpLocalizedContext(tester, const Locale('en'));
    expect(ConstitutionType.balanced.label(enContext), 'Balanced');

    final jaContext = await pumpLocalizedContext(tester, const Locale('ja'));
    expect(ConstitutionType.qiDeficiency.label(jaContext), '気虚質');

    final koContext = await pumpLocalizedContext(tester, const Locale('ko'));
    expect(ConstitutionType.dampness.label(koContext), '담습질');
  });

  testWidgets('risk labels localize across locales', (tester) async {
    final zhContext = await pumpLocalizedContext(tester, const Locale('zh'));
    expect(RiskCategory.spleenStomach.label(zhContext), '脾胃');

    final enContext = await pumpLocalizedContext(tester, const Locale('en'));
    expect(RiskCategory.spleenStomach.label(enContext), 'Spleen/Stomach');

    final jaContext = await pumpLocalizedContext(tester, const Locale('ja'));
    expect(RiskCategory.qiDeficiency.label(jaContext), '気虚');

    final koContext = await pumpLocalizedContext(tester, const Locale('ko'));
    expect(RiskCategory.dampness.label(koContext), '습곤');
  });
}
