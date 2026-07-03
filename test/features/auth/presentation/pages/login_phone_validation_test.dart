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

GestureDetector _primaryButton(WidgetTester tester) {
  return tester.widget<GestureDetector>(
    find.byKey(const ValueKey('login_primary_button')),
  );
}

void main() {
  testWidgets(
    'login page keeps primary button disabled until phone, code, and agreement are ready',
    (tester) async {
      await _pumpLoginPage(tester);

      expect(_primaryButton(tester).onTap, isNull);

      await tester.enterText(find.byType(TextFormField).first, '13800138000');
      await tester.pump();
      expect(_primaryButton(tester).onTap, isNull);

      await tester.enterText(find.byType(TextFormField).at(1), '123456');
      await tester.pump();
      expect(_primaryButton(tester).onTap, isNull);

      await tester.tap(find.byKey(const ValueKey('login_terms_row')));
      await tester.pump();
      expect(_primaryButton(tester).onTap, isNotNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'login page rejects invalid phone format once button is enabled',
    (tester) async {
      final l10n = lookupAppLocalizations(const Locale('zh'));
      await _pumpLoginPage(tester);

      await tester.enterText(find.byType(TextFormField).first, '12ab');
      await tester.enterText(find.byType(TextFormField).at(1), '123456');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('login_terms_row')));
      await tester.pump();

      final button = _primaryButton(tester);
      expect(button.onTap, isNotNull);
      button.onTap!();
      await tester.pump();

      expect(find.text(l10n.authPhoneFormatError), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'password login stays disabled without terms and validates min length once enabled',
    (tester) async {
      final l10n = lookupAppLocalizations(const Locale('zh'));
      await _pumpLoginPage(tester);

      await tester.tap(find.byKey(const ValueKey('switch_to_password_login')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextFormField).at(0), '13800138000');
      final passwordField = find.descendant(
        of: find.byKey(const ValueKey('password_field')),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(passwordField, '123');
      await tester.pump();

      expect(_primaryButton(tester).onTap, isNull);

      await tester.tap(find.byKey(const ValueKey('login_terms_row')));
      await tester.pump();

      final button = _primaryButton(tester);
      expect(button.onTap, isNotNull);
      button.onTap!();
      await tester.pump();

      expect(find.text(l10n.authPasswordMin6), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );
}
