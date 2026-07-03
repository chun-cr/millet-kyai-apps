import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:millet_kyai_apps/core/router/app_router.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_me_entity.dart';
import 'package:millet_kyai_apps/features/profile/presentation/pages/profile_page.dart';
import 'package:millet_kyai_apps/features/profile/presentation/providers/profile_repository_provider.dart';
import 'package:millet_kyai_apps/main.dart';

void main() {
  testWidgets('switching language from profile updates UI', (tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'en'});
    setPreviewAuthenticated(true);
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileMeProvider.overrideWith(
            (ref) async => const ProfileMeEntity(
              nickname: 'Alice',
              realName: 'Alice Chen',
              countryCode: '+1',
              phone: '4155550123',
            ),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Language'), findsOneWidget);
    await tester.tap(find.text('日本�?));
    await tester.pumpAndSettle();

    expect(find.text('プロフィール'), findsWidgets);

    setPreviewAuthenticated(false);
    await tester.binding.setSurfaceSize(null);
  });
}
