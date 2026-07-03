import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:millet_kyai_apps/core/network/auth_session_store.dart';
import 'package:millet_kyai_apps/core/router/app_router.dart';
import 'package:millet_kyai_apps/features/auth/data/models/auth_request.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/auth_session_entity.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/password_register_result_entity.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/verification_code_challenge_entity.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/verification_code_send_entity.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/verification_code_target.dart';
import 'package:millet_kyai_apps/features/auth/domain/repositories/auth_repository.dart';
import 'package:millet_kyai_apps/features/auth/presentation/pages/login_page.dart';
import 'package:millet_kyai_apps/features/auth/presentation/pages/register_page.dart';
import 'package:millet_kyai_apps/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:millet_kyai_apps/features/report/presentation/models/report_project_data.dart';
import 'package:millet_kyai_apps/features/report/presentation/pages/report_project_detail_page.dart';
import 'package:millet_kyai_apps/main.dart';

class _SuccessfulRegisterAuthRepository extends AuthRepositoryAdapter {
  @override
  Future<AuthSessionEntity> login(AuthRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSessionEntity> register(AuthRequest request) async {
    return const AuthSessionEntity(
      accessToken: 'token',
      refreshToken: 'refresh',
      tokenType: 'Bearer',
      expiresIn: 3600,
      scope: 'profile',
    );
  }

  @override
  Future<PasswordRegisterResultEntity> registerPassword(
    AuthRequest request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<VerificationCodeChallengeEntity> createVerificationCodeChallenge({
    required VerificationCodeScene scene,
    required VerificationCodeTarget target,
  }) async {
    if (scene == VerificationCodeScene.login) {
      throw DioException(
        requestOptions: RequestOptions(
          path: '/api/v1/saas/mobile/auth/verification-code/challenge',
        ),
        response: Response(
          requestOptions: RequestOptions(
            path: '/api/v1/saas/mobile/auth/verification-code/challenge',
          ),
          statusCode: 404,
          data: {'message': 'account not found'},
        ),
      );
    }
    return VerificationCodeChallengeEntity(
      challengeId: 'challenge-1',
      captchaRequired: false,
      captchaProvider: null,
      captchaPayload: null,
      expireAt: DateTime.now().add(const Duration(minutes: 10)),
    );
  }

  @override
  Future<VerificationCodeSendEntity> sendCode({
    required String challengeId,
  }) async => VerificationCodeSendEntity(
    channel: 'PHONE',
    maskedReceiver: '+861****8000',
    expireAt: DateTime.now().add(const Duration(minutes: 5)),
    resendAt: DateTime.now().add(const Duration(seconds: 60)),
  );

  @override
  Future<bool> verifyVerificationCodeCaptcha({
    required String challengeId,
    required String captchaProvider,
    required Map<String, String> captchaPayload,
  }) async => true;

  @override
  Future<AuthSessionEntity> authenticateVerificationCode({
    required VerificationCodeScene scene,
    required String challengeId,
    required String verificationCode,
    String? inviteTicket,
  }) async => const AuthSessionEntity(
    accessToken: 'token',
    refreshToken: 'refresh',
    tokenType: 'Bearer',
    expiresIn: 3600,
    scope: 'profile',
  );

  @override
  Future<void> logout({required String refreshToken}) async {}
}

Future<void> _pumpUntilLocation(
  WidgetTester tester,
  String expectedLocation, {
  Duration step = const Duration(milliseconds: 50),
  int maxTicks = 40,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(step);
    if (appRouter.state.matchedLocation == expectedLocation) {
      return;
    }
  }
}

void main() {
  setUp(() {
    AuthSessionStore.debugUseMemoryBackend = true;
  });

  tearDown(() {
    AuthSessionStore.debugUseMemoryBackend = false;
  });

  testWidgets('router exposes complete profile page route', (tester) async {
    SharedPreferences.setMockInitialValues({});
    setPreviewAuthenticated(false);
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    appRouter.go(AppRoutes.completeProfile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(CompleteProfilePage), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('complete profile skip without session routes back to login', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    setPreviewAuthenticated(false);
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    appRouter.go(AppRoutes.completeProfile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(
      find.byKey(const ValueKey('complete_profile_skip_button')),
    );
    await tester.pump();
    await _pumpUntilLocation(tester, AppRoutes.login);

    expect(appRouter.state.matchedLocation, AppRoutes.login);
    expect(isPreviewAuthenticated, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'complete profile primary action without session routes back to login',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      setPreviewAuthenticated(false);
      await tester.binding.setSurfaceSize(const Size(1280, 2400));

      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      appRouter.go(AppRoutes.completeProfile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(
        find.byKey(const ValueKey('complete_profile_primary_button')),
      );
      await tester.pump();
      await _pumpUntilLocation(tester, AppRoutes.login);

      expect(appRouter.state.matchedLocation, AppRoutes.login);
      expect(isPreviewAuthenticated, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('/register route now renders the unified login page', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    setPreviewAuthenticated(false);
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    appRouter.go(AppRoutes.register);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(RegisterPage), findsNothing);
    expect(appRouter.state.matchedLocation, AppRoutes.register);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('successful register routes to complete profile page', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    setPreviewAuthenticated(false);
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _SuccessfulRegisterAuthRepository(),
          ),
        ],
        child: const MyApp(),
      ),
    );
    appRouter.go(AppRoutes.register);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.enterText(find.byType(TextFormField).at(0), '13800138000');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.byKey(const ValueKey('send_code_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('login_terms_row')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('login_primary_button')));
    await tester.pump();
    await _pumpUntilLocation(tester, AppRoutes.completeProfile);

    expect(appRouter.state.matchedLocation, AppRoutes.completeProfile);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'register flow preserves redirect through complete profile to project detail',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      setPreviewAuthenticated(false);
      await tester.binding.setSurfaceSize(const Size(1280, 2400));

      final project = ReportProjectData(
        id: 'project-redirect',
        name: 'Warm Care',
        type: 'Clinic Service',
        description: 'Recovery-focused in-clinic project.',
        tag: 'Recommended',
        durationNote: '45 min',
        serviceNote: 'Booked after assessment.',
        consultNote: 'Consult before scheduling.',
        color: const Color(0xFFB96A3A),
        icon: Icons.spa_outlined,
      );
      final redirectLocation = Uri(
        path: AppRoutes.reportProjectDetail,
        queryParameters: project.toRouteQueryParameters(),
      ).toString();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              _SuccessfulRegisterAuthRepository(),
            ),
          ],
          child: const MyApp(),
        ),
      );
      appRouter.go(
        Uri(
          path: AppRoutes.register,
          queryParameters: {'redirect': redirectLocation},
        ).toString(),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.enterText(find.byType(TextFormField).at(0), '13800138000');
      await tester.enterText(find.byType(TextFormField).at(1), '123456');
      await tester.tap(find.byKey(const ValueKey('send_code_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const ValueKey('login_terms_row')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('login_primary_button')));
      await tester.pump();
      await _pumpUntilLocation(tester, AppRoutes.completeProfile);

      expect(appRouter.state.matchedLocation, AppRoutes.completeProfile);
      expect(appRouter.state.uri.queryParameters['redirect'], redirectLocation);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(
        find.byKey(const ValueKey('complete_profile_skip_button')),
      );
      await tester.pump();
      await _pumpUntilLocation(tester, AppRoutes.reportProjectDetail);

      expect(appRouter.state.matchedLocation, AppRoutes.reportProjectDetail);
      expect(find.byType(ReportProjectDetailPage), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );
}
