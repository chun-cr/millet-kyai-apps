import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_me_entity.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_points_account_simple_entity.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_shipping_address_entity.dart';
import 'package:millet_kyai_apps/features/profile/domain/repositories/profile_repository.dart';
import 'package:millet_kyai_apps/features/profile/presentation/pages/profile_page.dart';
import 'package:millet_kyai_apps/features/profile/presentation/providers/profile_repository_provider.dart';
import 'package:millet_kyai_apps/l10n/app_localizations.dart';

class _ProfilePageRepository extends ProfileRepositoryAdapter {
  int shippingAddressesFetchCount = 0;
  int defaultShippingAddressFetchCount = 0;
  int pointsSimpleFetchCount = 0;

  @override
  Future<ProfileMeEntity> fetchMe() async {
    return const ProfileMeEntity(
      nickname: 'Amin',
      realName: 'Zhang San',
      countryCode: '+86',
      phone: '13812345678',
    );
  }

  @override
  Future<ProfilePointsAccountSimpleEntity>
  fetchPointsAccountSimpleInfo() async {
    pointsSimpleFetchCount += 1;
    return const ProfilePointsAccountSimpleEntity(
      id: 'points-1',
      userId: 'user-1',
      availableAmount: 88,
    );
  }

  @override
  Future<List<ProfileShippingAddressEntity>> fetchShippingAddresses() async {
    shippingAddressesFetchCount += 1;
    return const <ProfileShippingAddressEntity>[];
  }

  @override
  Future<ProfileShippingAddressEntity> fetchDefaultShippingAddress() async {
    defaultShippingAddressFetchCount += 1;
    throw StateError('Profile page should not fetch shipping addresses.');
  }
}

void main() {
  testWidgets('profile page shows user info from /user/me response', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    final repository = _ProfilePageRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: supportedAppLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const ProfilePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Amin'), findsOneWidget);
    expect(find.textContaining('Zhang San'), findsOneWidget);
    expect(find.textContaining('138****5678'), findsOneWidget);
    expect(find.text('健康基底'), findsNothing);
    expect(find.text('我的调理舱'), findsNothing);
    expect(repository.shippingAddressesFetchCount, 0);
    expect(repository.defaultShippingAddressFetchCount, 0);
    expect(repository.pointsSimpleFetchCount, 0);

    await tester.binding.setSurfaceSize(null);
  });
}
