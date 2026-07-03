import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:millet_kyai_apps/core/l10n/seasonal_context.dart';
import 'package:millet_kyai_apps/features/auth/presentation/pages/register_page.dart';
import 'package:millet_kyai_apps/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'tapping outside input fields on register page dismisses the keyboard',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 2400));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: RegisterPage(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.byType(RegisterPage), findsOneWidget);
      final context = tester.element(find.byType(RegisterPage));
      final l10n = AppLocalizations.of(context);
      final expectedTag = l10n.seasonalTagLabel(SeasonalContext.now());
      expect(
        find.byKey(const ValueKey('register_seasonal_tag')),
        findsOneWidget,
      );
      expect(find.text(expectedTag), findsOneWidget);
      expect(
        find.byKey(const ValueKey('register_country_code_menu_trigger')),
        findsOneWidget,
      );
      expect(find.text('+86'), findsOneWidget);

      await tester.tap(find.byType(TextFormField).first);
      await tester.pump();

      expect(tester.testTextInput.isVisible, isTrue);

      await tester.tapAt(const Offset(8, 8));
      await tester.pump();

      expect(tester.testTextInput.isVisible, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );
}
