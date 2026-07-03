import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:millet_kyai_apps/core/di/injector.dart';
import 'package:millet_kyai_apps/core/network/auth_session_store.dart';
import 'package:millet_kyai_apps/core/router/app_router.dart';
import 'package:millet_kyai_apps/features/auth/data/models/auth_request.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/auth_session_entity.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/password_register_result_entity.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/verification_code_challenge_entity.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/verification_code_send_entity.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/verification_code_target.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/wechat_mini_program_auth_result_entity.dart';
import 'package:millet_kyai_apps/features/auth/domain/repositories/auth_repository.dart';
import 'package:millet_kyai_apps/features/auth/presentation/pages/login_page.dart';
import 'package:millet_kyai_apps/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:millet_kyai_apps/features/auth/presentation/providers/wechat_code_acquirer_provider.dart';
import 'package:millet_kyai_apps/l10n/app_localizations.dart';
import 'package:millet_kyai_apps/main.dart';

class _SlowAuthRepository extends AuthRepositoryAdapter {
  @override
  Future<AuthSessionEntity> login(AuthRequest request) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return const AuthSessionEntity(
      accessToken: 'token',
      refreshToken: 'refresh',
      tokenType: 'Bearer',
      expiresIn: 3600,
      scope: 'mobile',
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
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return const AuthSessionEntity(
      accessToken: 'token',
      refreshToken: 'refresh',
      tokenType: 'Bearer',
      expiresIn: 3600,
      scope: 'mobile',
    );
  }

  @override
  Future<void> logout({required String refreshToken}) async {}
}

class _FailingAuthRepository extends AuthRepositoryAdapter {
  @override
  Future<AuthSessionEntity> login(AuthRequest request) {
    throw DioException(
      requestOptions: RequestOptions(
        path: '/api/v1/saas/mobile/auth/login/password',
      ),
      response: Response(
        requestOptions: RequestOptions(
          path: '/api/v1/saas/mobile/auth/login/password',
        ),
        data: {'message': 'account-error'},
        statusCode: 401,
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
  }) {
    throw DioException(
      requestOptions: RequestOptions(
        path: '/api/v1/saas/mobile/auth/login-or-register/verification-code',
      ),
      response: Response(
        requestOptions: RequestOptions(
          path: '/api/v1/saas/mobile/auth/login-or-register/verification-code',
        ),
        data: {'message': 'account-error'},
        statusCode: 401,
      ),
    );
  }

  @override
  Future<void> logout({required String refreshToken}) async {}
}

class _WechatCodeAcquirerStub implements WechatCodeAcquirer {
  final String? code;

  const _WechatCodeAcquirerStub(this.code);

  @override
  Future<String?> acquireWechatCode() async => code;
}

class _WechatMiniProgramRepositoryStub extends AuthRepositoryAdapter {
  String? capturedWechatCode;
  String? capturedInviteTicket;

  @override
  Future<WechatMiniProgramAuthResultEntity> loginWithWechatMiniProgram({
    required String wechatCode,
    String? inviteTicket,
  }) async {
    capturedWechatCode = wechatCode;
    capturedInviteTicket = inviteTicket;
    return const WechatMiniProgramAuthResultEntity(
      authStatus: 'AUTHORIZED',
      session: AuthSessionEntity(
        accessToken: 'wechat-token',
        refreshToken: 'wechat-refresh',
        tokenType: 'Bearer',
        expiresIn: 3600,
        scope: 'mobile',
      ),
      globalUserId: 'global-user-1',
    );
  }

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
  Future<void> logout({required String refreshToken}) async {}
}

void main() {
  setUp(() {
    AuthSessionStore.debugUseMemoryBackend = true;
  });

  tearDown(() {
    AuthSessionStore.debugUseMemoryBackend = false;
  });

  testWidgets(
    'login button enters subdued submitting state without playful phases',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(1280, 2400));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_SlowAuthRepository()),
          ],
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: LoginPage()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.byType(LoginPage), findsOneWidget);
      expect(
        find.byKey(const ValueKey('login_primary_button')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('login_locale_button')), findsOneWidget);

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
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const ValueKey('login_submitting')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const ValueKey('login_idle')), findsNothing);
      expect(find.byKey(const ValueKey('login_loading')), findsNothing);
      expect(find.byKey(const ValueKey('login_confirming')), findsNothing);

      await tester.pump(const Duration(milliseconds: 3000));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('tapping outside input fields dismisses the keyboard', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    setPreviewAuthenticated(false);
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byKey(const ValueKey('login_locale_button')), findsOneWidget);

    await tester.tap(find.byType(TextFormField).first);
    await tester.pump();

    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tapAt(const Offset(8, 8));
    await tester.pump();

    expect(tester.testTextInput.isVisible, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('login shows server message and resets button on failure', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1280, 2400));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FailingAuthRepository()),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: LoginPage()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

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
    await tester.pump(const Duration(milliseconds: 1800));

    expect(find.textContaining('account-error'), findsOneWidget);
    expect(find.byKey(const ValueKey('login_idle')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('wechat mini program button acquires code and persists session', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    setPreviewAuthenticated(false);
    final repository = _WechatMiniProgramRepositoryStub();

    await tester.binding.setSurfaceSize(const Size(1280, 2400));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          wechatCodeAcquirerProvider.overrideWithValue(
            const _WechatCodeAcquirerStub('wx-code-123'),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    await tester.tap(find.byKey(const ValueKey('login_wechat_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 400));

    expect(repository.capturedWechatCode, 'wx-code-123');
    expect(isPreviewAuthenticated, isTrue);

    expect(
      await getIt<AuthSessionStore>().authorizationHeader(),
      'Bearer wechat-token',
    );
    expect(await getIt<AuthSessionStore>().refreshToken(), 'wechat-refresh');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });
}
