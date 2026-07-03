import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/features/auth/presentation/pages/register_page.dart';
import 'package:millet_kyai_apps/l10n/app_localizations.dart';

AppLocalizations _localizations(WidgetTester tester) {
  final context = tester.element(find.byType(CompleteProfilePage));
  return AppLocalizations.of(context);
}

void main() {
  testWidgets('complete profile page shows skip nickname and gender fields', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: CompleteProfilePage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    final l10n = _localizations(tester);

    expect(find.text(l10n.completeProfileSkip), findsOneWidget);
    expect(find.text(l10n.completeProfileTitle), findsOneWidget);
    expect(find.text(l10n.completeProfileSubtitle), findsOneWidget);
    expect(find.text(l10n.authNameLabel), findsOneWidget);
    expect(find.text(l10n.registerGenderOptional), findsOneWidget);
    expect(
      find.text('${l10n.appBrandPrefix}AI${l10n.appBrandSuffix}'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    expect(find.text(l10n.authPhoneLabel), findsNothing);
    expect(find.text(l10n.authPasswordLabel), findsNothing);
    expect(find.text(l10n.registerGenderOther), findsNothing);
    expect(
      find.byKey(const ValueKey('complete_profile_avatar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('complete_profile_bottom_bar')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'complete profile avatar ring pulses and gender cards stay balanced',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 2400));

      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: CompleteProfilePage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));

      final ringFinder = find.byKey(
        const ValueKey('complete_profile_avatar_ring'),
      );
      expect(ringFinder, findsOneWidget);
      final initialScale = tester
          .widget<Transform>(ringFinder)
          .transform
          .getMaxScaleOnAxis();
      await tester.pump(const Duration(milliseconds: 1200));
      final laterScale = tester
          .widget<Transform>(ringFinder)
          .transform
          .getMaxScaleOnAxis();

      expect((laterScale - initialScale).abs(), greaterThan(0.01));

      final l10n = _localizations(tester);
      expect(find.text(l10n.registerGenderMale), findsOneWidget);
      expect(find.text(l10n.registerGenderFemale), findsOneWidget);
      expect(find.text(l10n.registerGenderOther), findsNothing);

      final maleSize = tester.getSize(
        find.byKey(const ValueKey('complete_profile_gender_male')),
      );
      final femaleSize = tester.getSize(
        find.byKey(const ValueKey('complete_profile_gender_female')),
      );
      expect((maleSize.width - femaleSize.width).abs(), lessThanOrEqualTo(1));

      final maleTopLeft = tester.getTopLeft(
        find.byKey(const ValueKey('complete_profile_gender_male')),
      );
      final femaleTopLeft = tester.getTopLeft(
        find.byKey(const ValueKey('complete_profile_gender_female')),
      );
      expect(femaleTopLeft.dx, greaterThan(maleTopLeft.dx));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );
}
