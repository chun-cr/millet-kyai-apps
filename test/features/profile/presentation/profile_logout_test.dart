import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:millet_kyai_apps/core/di/injector.dart';
import 'package:millet_kyai_apps/core/network/auth_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:millet_kyai_apps/features/auth/data/models/auth_request.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/auth_session_entity.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/password_register_result_entity.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/verification_code_challenge_entity.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/verification_code_send_entity.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/verification_code_target.dart';
import 'package:millet_kyai_apps/features/auth/domain/repositories/auth_repository.dart';
import 'package:millet_kyai_apps/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_me_entity.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_points_account_simple_entity.dart';
import 'package:millet_kyai_apps/features/profile/domain/entities/profile_shipping_address_entity.dart';
import 'package:millet_kyai_apps/features/profile/domain/repositories/profile_repository.dart';
import 'package:millet_kyai_apps/features/profile/presentation/pages/profile_page.dart';
import 'package:millet_kyai_apps/features/profile/presentation/providers/profile_repository_provider.dart';
import 'package:millet_kyai_apps/l10n/app_localizations.dart';

const _profileRoute = '/profile';
const _loginRoute = '/login';

const _address = ProfileShippingAddressEntity(
  id: 'addr-1',
  receiverName: 'Amin',
  receiverMobile: '13812345678',
  provinceCode: '110000',
  provinceName: 'Beijing',
  cityCode: '110100',
  cityName: 'Beijing',
  districtCode: '110101',
  districtName: 'Dongcheng',
  detailAddress: 'No.1',
  isDefault: true,
);

const _pointsBalance = ProfilePointsAccountSimpleEntity(
  id: 'points-1',
  userId: 'user-1',
  availableAmount: 88,
);

class _LogoutCapturingRepository extends AuthRepositoryAdapter {
  String? lastRefreshToken;

  @override
  Future<AuthSessionEntity> login(AuthRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSessionEntity> register(AuthRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<PasswordRegisterResultEntity> registerPassword(AuthRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<VerificationCodeChallengeEntity> createVerificationCodeChallenge({
    required VerificationCodeScene scene,
    required VerificationCodeTarget target,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<VerificationCodeSendEntity> sendCode({required String challengeId}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> verifyVerificationCodeCaptcha({
    required String challengeId,
    required String captchaProvider,
    required Map<String, String> captchaPayload,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSessionEntity> authenticateVerificationCode({
    required VerificationCodeScene scene,
    required String challengeId,
    required String verificationCode,
    String? inviteTicket,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    lastRefreshToken = refreshToken;
  }
}

class _FakeProfileRepository extends ProfileRepositoryAdapter {
  _FakeProfileRepository(this.currentProfile);

  ProfileMeEntity currentProfile;

  @override
  Future<ProfileMeEntity> fetchMe() async => currentProfile;

  @override
  Future<List<ProfileShippingAddressEntity>> fetchShippingAddresses() async {
    return const [_address];
  }

  @override
  Future<ProfileShippingAddressEntity> fetchDefaultShippingAddress() async {
    return _address;
  }

  @override
  Future<ProfilePointsAccountSimpleEntity>
  fetchPointsAccountSimpleInfo() async {
    return _pointsBalance;
  }
}

GoRouter _buildProfileRouter() {
  return GoRouter(
    initialLocation: _profileRoute,
    routes: [
      GoRoute(
        path: _profileRoute,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: _loginRoute,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('login'))),
      ),
    ],
  );
}

Widget _buildProfileApp({
  required GoRouter router,
  required AuthRepository authRepository,
  required ProfileRepository profileRepository,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(authRepository),
      profileRepositoryProvider.overrideWithValue(profileRepository),
    ],
    child: MaterialApp.router(
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    ),
  );
}

Future<void> _pumpUntilRoute(
  WidgetTester tester,
  GoRouter router,
  String expectedRoute, {
  Duration step = const Duration(milliseconds: 50),
  int maxTicks = 40,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    if (router.state.matchedLocation == expectedRoute) {
      return;
    }
  }
}

void _seedLegacySession({
  required String accessToken,
  required String refreshToken,
}) {
  SharedPreferences.setMockInitialValues({
    'auth_access_token': accessToken,
    'auth_refresh_token': refreshToken,
    'auth_token_type': 'Bearer',
    'auth_expires_in': 3600,
    'auth_expires_at_epoch_ms': DateTime.now()
        .add(const Duration(hours: 1))
        .millisecondsSinceEpoch,
    'auth_scope': 'mobile',
    'profile_shipping_addresses': '[]',
  });
}

void main() {
  setUp(() async {
    AuthSessionStore.debugUseMemoryBackend = true;
    await getIt.reset();
    initInjector();
  });

  tearDown(() {
    AuthSessionStore.debugUseMemoryBackend = false;
  });

  testWidgets('logout from profile returns to login page', (tester) async {
    final repository = _LogoutCapturingRepository();
    final profileRepository = _FakeProfileRepository(
      const ProfileMeEntity(
        nickname: 'Amin',
        realName: 'Zhang San',
        countryCode: '+86',
        phone: '13812345678',
      ),
    );
    final router = _buildProfileRouter();
    addTearDown(router.dispose);
    _seedLegacySession(accessToken: 'token', refreshToken: 'refresh');
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(
      _buildProfileApp(
        router: router,
        authRepository: repository,
        profileRepository: profileRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget);

    final logoutButton = find.byWidgetPredicate((widget) => widget is TextButton);
    expect(logoutButton, findsOneWidget);
    await tester.ensureVisible(logoutButton);
    await tester.pump();
    await tester.tap(logoutButton);
    await tester.pump();
    await _pumpUntilRoute(tester, router, _loginRoute);
    await tester.pump();

    final preferences = await SharedPreferences.getInstance();

    expect(repository.lastRefreshToken, 'refresh');
    expect(router.state.matchedLocation, _loginRoute);
    expect(preferences.getString('auth_access_token'), isNull);
    expect(preferences.getString('auth_refresh_token'), isNull);
    expect(preferences.getString('auth_token_type'), isNull);
    expect(preferences.getInt('auth_expires_in'), isNull);
    expect(preferences.getInt('auth_expires_at_epoch_ms'), isNull);
    expect(preferences.getString('auth_scope'), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('profile page refreshes after switching to a different account', (
    tester,
  ) async {
    final initialProfileRepository = _FakeProfileRepository(
      const ProfileMeEntity(
        nickname: 'Amin',
        realName: 'Zhang San',
        countryCode: '+86',
        phone: '13812345678',
      ),
    );
    final router = _buildProfileRouter();
    addTearDown(router.dispose);
    _seedLegacySession(accessToken: 'token-a', refreshToken: 'refresh-a');
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(
      _buildProfileApp(
        router: router,
        authRepository: _LogoutCapturingRepository(),
        profileRepository: initialProfileRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Amin'), findsOneWidget);

    final logoutButton = find.byWidgetPredicate((widget) => widget is TextButton);
    expect(logoutButton, findsOneWidget);
    await tester.ensureVisible(logoutButton);
    await tester.pump();
    await tester.tap(logoutButton);
    await tester.pump();
    await _pumpUntilRoute(tester, router, _loginRoute);
    await tester.pump();
    expect(router.state.matchedLocation, _loginRoute);

    final nextProfileRepository = _FakeProfileRepository(
      const ProfileMeEntity(
        nickname: 'Bora',
        realName: 'Li Si',
        countryCode: '+86',
        phone: '13987654321',
      ),
    );
    _seedLegacySession(accessToken: 'token-b', refreshToken: 'refresh-b');
    await tester.pumpWidget(
      _buildProfileApp(
        router: router,
        authRepository: _LogoutCapturingRepository(),
        profileRepository: nextProfileRepository,
      ),
    );
    await tester.pump();
    router.go(_profileRoute);
    await tester.pumpAndSettle();

    expect(find.text('Bora'), findsOneWidget);
    expect(find.text('Amin'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });
}
