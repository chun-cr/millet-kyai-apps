import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_me_entity.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_points_overview_entity.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_shipping_address_entity.dart';
import 'package:millet_kyai_apps/features/profile/presentation/pages/points_page.dart';
import 'package:millet_kyai_apps/features/profile/presentation/pages/profile_page.dart';
import 'package:millet_kyai_apps/features/profile/presentation/pages/shipping_address_page.dart';
import 'package:millet_kyai_apps/features/profile/presentation/providers/profile_address_provider.dart';
import 'package:millet_kyai_apps/features/profile/presentation/providers/profile_points_provider.dart';
import 'package:millet_kyai_apps/features/profile/presentation/providers/profile_repository_provider.dart';
import 'package:millet_kyai_apps/l10n/app_localizations.dart';

Widget _buildShell(Widget child) {
  return MaterialApp(
    locale: const Locale('zh'),
    supportedLocales: supportedAppLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('profile page shows shimmer skeleton while loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileMeProvider.overrideWith(
            (ref) => Completer<ProfileMeEntity>().future,
          ),
        ],
        child: _buildShell(const ProfilePage()),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('profile_loading')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('points page shows shimmer skeleton while loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profilePointsProvider.overrideWith(() => _LoadingPointsController()),
        ],
        child: _buildShell(const PointsPage()),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('points_loading')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shipping address page shows shimmer skeleton while loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileAddressesProvider.overrideWith(
            () => _LoadingAddressesController(),
          ),
        ],
        child: _buildShell(const ShippingAddressPage()),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('shipping_address_loading')),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

class _LoadingPointsController extends ProfilePointsController {
  @override
  FutureOr<ProfilePointsOverviewEntity> build() {
    return Completer<ProfilePointsOverviewEntity>().future;
  }
}

class _LoadingAddressesController extends ProfileAddressesController {
  @override
  FutureOr<List<ProfileShippingAddressEntity>> build() {
    return Completer<List<ProfileShippingAddressEntity>>().future;
  }
}
