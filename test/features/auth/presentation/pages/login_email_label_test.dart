import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:millet_kyai_apps/features/auth/presentation/pages/login_page.dart';
import 'package:millet_kyai_apps/l10n/app_localizations.dart';

Future<void> _pumpLoginPage(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
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
}

void main() {
  testWidgets('login page switches only the input area for email login', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('zh'));

    await _pumpLoginPage(tester);

    expect(find.byKey(const ValueKey('login_identity_switch')), findsNothing);
    expect(find.text(l10n.authPhoneLabel), findsOneWidget);
    expect(find.byKey(const ValueKey('send_code_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('login_wechat_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('login_email_button')), findsOneWidget);
    expect(find.text('微信小程序登�?), findsOneWidget);
    expect(find.text(l10n.authEmailLogin), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('login_email_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byKey(const ValueKey('email_input_area')), findsOneWidget);
    expect(find.byKey(const ValueKey('email_field')), findsOneWidget);
    expect(find.text(l10n.authEmailLabel), findsOneWidget);
    expect(find.text(l10n.authVerificationCodeLabel), findsOneWidget);
    expect(
      find.byKey(const ValueKey('return_phone_login_button')),
      findsNothing,
    );
    expect(find.text(l10n.authPhoneLogin), findsOneWidget);
    expect(find.byKey(const ValueKey('send_code_button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('login_email_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byKey(const ValueKey('phone_input_area')), findsOneWidget);
    expect(find.text(l10n.authPhoneLabel), findsOneWidget);
    expect(find.byKey(const ValueKey('send_code_button')), findsOneWidget);
    expect(find.text(l10n.authEmailLogin), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });
}
