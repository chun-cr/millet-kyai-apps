import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:millet_kyai_apps/features/auth/presentation/pages/login_page.dart';
import 'package:millet_kyai_apps/core/router/app_router.dart';
import 'package:millet_kyai_apps/l10n/app_localizations.dart';

Future<void> _pumpLoginPage(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  setPreviewAuthenticated(false);
  await tester.binding.setSurfaceSize(const Size(1280, 2400));

  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: LoginPage()),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));

  expect(find.byType(LoginPage), findsOneWidget);
}

void main() {
  testWidgets('login page removes feature chips section', (tester) async {
    await _pumpLoginPage(tester);

    expect(find.text('面部扫描'), findsNothing);
    expect(find.text('舌象分析'), findsNothing);
    expect(find.text('AI 诊断'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('other methods block is anchored near the bottom on tall layouts', (
    tester,
  ) async {
    await _pumpLoginPage(tester);

    final bottomBlockFinder = find.byKey(
      const ValueKey('login_bottom_auxiliary'),
    );

    expect(bottomBlockFinder, findsOneWidget);
    expect(tester.getBottomLeft(bottomBlockFinder).dy, greaterThan(2200));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });
}
