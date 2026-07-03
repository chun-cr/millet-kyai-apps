import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:millet_kyai_apps/features/auth/data/models/auth_request.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/auth_session_entity.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/password_register_result_entity.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/verification_code_challenge_entity.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/verification_code_send_entity.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/verification_code_target.dart';
import 'package:millet_kyai_apps/features/auth/domain/repositories/auth_repository.dart';
import 'package:millet_kyai_apps/features/auth/presentation/pages/login_page.dart';
import 'package:millet_kyai_apps/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:millet_kyai_apps/l10n/app_localizations.dart';

class _EmailLoginCaptureRepository extends AuthRepositoryAdapter {
  VerificationCodeScene? lastScene;
  VerificationCodeScene? lastAuthenticateScene;
  VerificationCodeTarget? lastTarget;
  String? lastChallengeId;
  String? lastVerificationCode;
  String? lastInviteTicket;

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
  }) async {
    lastScene = scene;
    lastTarget = target;
    return VerificationCodeChallengeEntity(
      challengeId: 'email-login-challenge-1',
      captchaRequired: false,
      captchaProvider: null,
      captchaPayload: null,
      expireAt: DateTime.now().add(const Duration(minutes: 10)),
    );
  }

  @override
  Future<VerificationCodeSendEntity> sendCode({
    required String challengeId,
  }) async {
    lastChallengeId = challengeId;
    return VerificationCodeSendEntity(
      channel: 'EMAIL',
      maskedReceiver: 'doc***@mai.ai',
      expireAt: DateTime.now().add(const Duration(minutes: 5)),
      resendAt: DateTime.now().add(const Duration(seconds: 60)),
    );
  }

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
  }) {
    lastAuthenticateScene = scene;
    lastChallengeId = challengeId;
    lastVerificationCode = verificationCode;
    lastInviteTicket = inviteTicket;
    throw DioException(
      requestOptions: RequestOptions(
        path: '/api/v1/saas/mobile/auth/login-or-register/verification-code',
      ),
      response: Response(
        requestOptions: RequestOptions(
          path: '/api/v1/saas/mobile/auth/login-or-register/verification-code',
        ),
        statusCode: 400,
        data: {'message': 'capture'},
      ),
    );
  }

  @override
  Future<void> logout({required String refreshToken}) async {}
}

Future<void> _pumpLoginPage(
  WidgetTester tester, {
  required Widget child,
  required AuthRepository repository,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(const Size(1280, 2400));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
}

Future<void> _pumpLoginRouter(
  WidgetTester tester, {
  required AuthRepository repository,
  required GoRouter router,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(const Size(1280, 2400));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(
        locale: const Locale('zh'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
}

void main() {
  testWidgets('email mode sends code and submits verification login', (
    tester,
  ) async {
    final repository = _EmailLoginCaptureRepository();
    await _pumpLoginPage(
      tester,
      repository: repository,
      child: const LoginPage(inviteTicket: 'invite-email-1'),
    );

    await tester.tap(find.byKey(const ValueKey('login_email_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.enterText(find.byType(TextFormField).at(0), 'doctor@mai.ai');
    await tester.tap(find.byKey(const ValueKey('send_code_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('login_terms_row')));
    await tester.pump();

    final button = tester.widget<GestureDetector>(
      find.byKey(const ValueKey('login_primary_button')),
    );
    button.onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(repository.lastScene, VerificationCodeScene.login);
    expect(repository.lastTarget, isNotNull);
    expect(repository.lastTarget!.isEmail, isTrue);
    expect(repository.lastTarget!.countryCode, isNull);
    expect(repository.lastTarget!.value, 'doctor@mai.ai');
    expect(repository.lastChallengeId, 'email-login-challenge-1');
    expect(repository.lastAuthenticateScene, VerificationCodeScene.login);
    expect(repository.lastVerificationCode, '123456');
    expect(repository.lastInviteTicket, 'invite-email-1');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('/register route opens unified login page in email mode', (
    tester,
  ) async {
    final repository = _EmailLoginCaptureRepository();
    final l10n = lookupAppLocalizations(const Locale('zh'));
    final router = GoRouter(
      initialLocation: '/register?mode=email&inviteTicket=invite-email-2',
      routes: [
        GoRoute(
          path: '/register',
          builder: (context, state) => LoginPage(
            initialMode: state.uri.queryParameters['mode'],
            inviteTicket: state.uri.queryParameters['inviteTicket'],
          ),
        ),
      ],
    );

    await _pumpLoginRouter(tester, repository: repository, router: router);

    expect(find.byKey(const ValueKey('email_input_area')), findsOneWidget);
    expect(find.text(l10n.authRegisterNow), findsNothing);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });
}
