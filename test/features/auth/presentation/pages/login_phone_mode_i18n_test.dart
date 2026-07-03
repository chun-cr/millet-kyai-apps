import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:millet_kyai_apps/features/auth/presentation/pages/login_page.dart';
import 'package:millet_kyai_apps/l10n/app_localizations.dart';

Future<void> _pumpLoginPage(WidgetTester tester, Locale locale) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(const Size(1280, 2400));

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: LoginPage()),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
}

void main() {
  testWidgets('login page shows simplified phone-first layout in English', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('en'));

    await _pumpLoginPage(tester, const Locale('en'));

    expect(find.byKey(const ValueKey('login_identity_switch')), findsNothing);
    expect(find.text(l10n.authPhoneLabel), findsOneWidget);
    expect(find.text(l10n.authPhoneHint), findsOneWidget);
    expect(find.text('+86'), findsOneWidget);
    expect(find.byKey(const ValueKey('send_code_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('login_wechat_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('login_email_button')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('login page shows simplified phone-first layout in Chinese', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('zh'));

    await _pumpLoginPage(tester, const Locale('zh'));

    expect(find.byKey(const ValueKey('login_identity_switch')), findsNothing);
    expect(find.text(l10n.authPhoneLabel), findsOneWidget);
    expect(find.text(l10n.authPhoneHint), findsOneWidget);
    expect(find.text('微信小程序登�?), findsOneWidget);
    expect(find.byKey(const ValueKey('login_email_button')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });
}
