import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:millet_kyai_apps/features/auth/presentation/providers/captcha_resolver_provider.dart';
import 'package:millet_kyai_apps/l10n/app_localizations.dart';

class _FixedCaptchaResolver implements CaptchaResolver {
  const _FixedCaptchaResolver(this.payload);

  final Map<String, String> payload;

  @override
  Future<Map<String, String>?> resolve({
    required BuildContext context,
    required String challengeId,
    required String provider,
    Map<String, dynamic>? initPayload,
  }) async {
    return payload;
  }
}

class _CaptchaRequiredRepository extends AuthRepositoryAdapter {
  bool verifyCalled = false;
  String? lastCaptchaProvider;
  Map<String, String>? lastCaptchaPayload;

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
  }) async => VerificationCodeChallengeEntity(
    challengeId: 'challenge-captcha',
    captchaRequired: true,
    captchaProvider: 'TENCENT',
    captchaPayload: const {'appId': 'captcha-app'},
    expireAt: DateTime.now().add(const Duration(minutes: 10)),
  );

  @override
  Future<VerificationCodeSendEntity> sendCode({
    required String challengeId,
  }) async {
    return VerificationCodeSendEntity(
      channel: 'PHONE',
      maskedReceiver: '+861****8000',
      expireAt: DateTime.now().add(const Duration(minutes: 5)),
      resendAt: DateTime.now().add(const Duration(seconds: 60)),
    );
  }

  @override
  Future<bool> verifyVerificationCodeCaptcha({
    required String challengeId,
    required String captchaProvider,
    required Map<String, String> captchaPayload,
  }) async {
    verifyCalled = true;
    lastCaptchaProvider = captchaProvider;
    lastCaptchaPayload = captchaPayload;
    return true;
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
  Future<void> logout({required String refreshToken}) async {}
}

class _InviteTicketCapturingRepository extends AuthRepositoryAdapter {
  VerificationCodeScene? lastAuthenticateScene;
  String? lastInviteTicket;
  String? lastPasswordLoginInviteTicket;

  @override
  Future<AuthSessionEntity> login(AuthRequest request) {
    lastPasswordLoginInviteTicket = request.inviteTicket;
    throw DioException(
      requestOptions: RequestOptions(
        path: '/api/v1/saas/mobile/auth/login/password',
      ),
      response: Response(
        requestOptions: RequestOptions(
          path: '/api/v1/saas/mobile/auth/login/password',
        ),
        statusCode: 400,
        data: {'message': 'capture'},
      ),
    );
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
  }) async => VerificationCodeChallengeEntity(
    challengeId: 'challenge-1',
    captchaRequired: false,
    captchaProvider: null,
    captchaPayload: null,
    expireAt: DateTime.now().add(const Duration(minutes: 10)),
  );

  @override
  Future<VerificationCodeSendEntity> sendCode({
    required String challengeId,
  }) async {
    return VerificationCodeSendEntity(
      channel: 'PHONE',
      maskedReceiver: '+861****8000',
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
  }) async {
    lastAuthenticateScene = scene;
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

Future<void> _pumpLocalizedApp(
  WidgetTester tester, {
  required Widget child,
  required List<dynamic> overrides,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(const Size(1280, 2400));
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides.cast(),
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

void main() {
  testWidgets('login page verifies captcha before sending code', (
    tester,
  ) async {
    final repository = _CaptchaRequiredRepository();
    await _pumpLocalizedApp(
      tester,
      child: const LoginPage(),
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        captchaResolverProvider.overrideWithValue(
          const _FixedCaptchaResolver({'ticket': 'ticket-001'}),
        ),
      ],
    );

    await tester.enterText(find.byType(TextFormField).first, '13800138000');
    await tester.tap(find.byKey(const ValueKey('send_code_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(repository.verifyCalled, isTrue);
    expect(repository.lastCaptchaProvider, 'TENCENT');
    expect(repository.lastCaptchaPayload, {'ticket': 'ticket-001'});
    expect(find.byKey(const ValueKey('send_code_countdown')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('login_masked_receiver_hint')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'login page forwards invite ticket on verification authenticate',
    (tester) async {
      final repository = _InviteTicketCapturingRepository();
      await _pumpLocalizedApp(
        tester,
        child: const LoginPage(inviteTicket: 'invite-login-1'),
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );

      await tester.enterText(find.byType(TextFormField).at(0), '13800138000');
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

      expect(repository.lastAuthenticateScene, VerificationCodeScene.login);
      expect(repository.lastInviteTicket, 'invite-login-1');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('login page forwards invite ticket on password login', (
    tester,
  ) async {
    final repository = _InviteTicketCapturingRepository();
    await _pumpLocalizedApp(
      tester,
      child: const LoginPage(inviteTicket: 'invite-password-1'),
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );

    await tester.enterText(find.byType(TextFormField).at(0), '13800138000');
    await tester.tap(find.text('密码登录'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.byKey(const ValueKey('login_terms_row')));
    await tester.pump();

    final button = tester.widget<GestureDetector>(
      find.byKey(const ValueKey('login_primary_button')),
    );
    expect(button.onTap, isNotNull);
    button.onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(repository.lastPasswordLoginInviteTicket, 'invite-password-1');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'register page forwards invite ticket on verification authenticate',
    (tester) async {
      final repository = _InviteTicketCapturingRepository();
      await _pumpLocalizedApp(
        tester,
        child: const RegisterPage(inviteTicket: 'invite-register-1'),
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );

      await tester.enterText(find.byType(TextFormField).at(0), '13800138000');
      await tester.enterText(find.byType(TextFormField).at(1), '123456');
      await tester.tap(find.byKey(const ValueKey('register_send_code_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const ValueKey('register_terms_row')));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('register_create_account_button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(repository.lastAuthenticateScene, VerificationCodeScene.register);
      expect(repository.lastInviteTicket, 'invite-register-1');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );
}
