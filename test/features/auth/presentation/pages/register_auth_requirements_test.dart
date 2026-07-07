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
import 'package:millet_kyai_apps/features/auth/presentation/pages/register_page.dart';
import 'package:millet_kyai_apps/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:millet_kyai_apps/l10n/app_localizations.dart';

class _FailingRegisterAuthRepository extends AuthRepositoryAdapter {
  VerificationCodeScene? lastAuthenticateScene;
  @override
  Future<AuthSessionEntity> login(AuthRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSessionEntity> register(AuthRequest request) {
    throw DioException(
      requestOptions: RequestOptions(
        path: '/api/v1/saas/mobile/auth/register/password',
      ),
      response: Response(
        requestOptions: RequestOptions(
          path: '/api/v1/saas/mobile/auth/register/password',
        ),
        data: {'message': '该手机号已注册'},
        statusCode: 409,
      ),
    );
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
    lastAuthenticateScene = scene;
    throw DioException(
      requestOptions: RequestOptions(
        path: '/api/v1/saas/mobile/auth/login-or-register/verification-code',
      ),
      response: Response(
        requestOptions: RequestOptions(
          path: '/api/v1/saas/mobile/auth/login-or-register/verification-code',
        ),
        data: {'message': '验证码错误'},
        statusCode: 400,
      ),
    );
  }

  @override
  Future<void> logout({required String refreshToken}) async {}
}

class _CapturingRegisterAuthRepository extends AuthRepositoryAdapter {
  _CapturingRegisterAuthRepository({
    Duration resendAfter = const Duration(seconds: 60),
    Duration codeExpiresAfter = const Duration(minutes: 5),
  }) : _resendAfter = resendAfter,
       _codeExpiresAfter = codeExpiresAfter;

  final Duration _resendAfter;
  final Duration _codeExpiresAfter;
  VerificationCodeScene? lastScene;
  VerificationCodeScene? lastAuthenticateScene;
  String? lastCountryCode;
  String? lastPhoneNumber;
  String? lastChallengeId;
  String? lastVerificationCode;
  int createChallengeCallCount = 0;
  int sendCodeCallCount = 0;

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
    createChallengeCallCount++;
    lastScene = scene;
    lastCountryCode = target.countryCode ?? '';
    lastPhoneNumber = target.value;
    return VerificationCodeChallengeEntity(
      challengeId: 'challenge-1',
      captchaRequired: false,
      captchaProvider: null,
      captchaPayload: null,
      channel: 'PHONE',
      maskedReceiver: '+441****8000',
      expireAt: DateTime.now().add(_codeExpiresAfter),
      resendAt: DateTime.now().add(_resendAfter),
    );
  }

  @override
  Future<VerificationCodeSendEntity> sendCode({
    required String challengeId,
  }) async {
    sendCodeCallCount++;
    lastChallengeId = challengeId;
    return VerificationCodeSendEntity(
      channel: 'PHONE',
      maskedReceiver: '+441****8000',
      expireAt: DateTime.now().add(_codeExpiresAfter),
      resendAt: DateTime.now().add(_resendAfter),
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
    throw DioException(
      requestOptions: RequestOptions(
        path: '/api/v1/saas/mobile/auth/login-or-register/verification-code',
      ),
      response: Response(
        requestOptions: RequestOptions(
          path: '/api/v1/saas/mobile/auth/login-or-register/verification-code',
        ),
        data: {'message': 'capture'},
        statusCode: 400,
      ),
    );
  }

  @override
  Future<void> logout({required String refreshToken}) async {}
}

Future<void> _pumpRegisterPage(
  WidgetTester tester, {
  AuthRepository? repository,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(const Size(1280, 2400));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (repository != null)
          authRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
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
}

void main() {
  testWidgets('register page focuses on account creation only', (tester) async {
    await _pumpRegisterPage(tester);

    expect(find.text('手机号'), findsOneWidget);
    expect(find.text('验证码'), findsOneWidget);
    expect(find.text('微信'), findsNothing);
    expect(find.text('Apple 登录'), findsNothing);
    expect(find.text('昵称'), findsNothing);
    expect(find.text('性别'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('register page blocks submit on invalid phone format', (
    tester,
  ) async {
    await _pumpRegisterPage(tester);

    await tester.enterText(find.byType(TextFormField).at(0), '12ab');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text('创建账号'));
    await tester.pump();

    expect(find.text('请输入正确的手机号'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'register page requires verification code on account creation page',
    (tester) async {
      await _pumpRegisterPage(tester);

      await tester.enterText(find.byType(TextFormField).at(0), '13800138000');
      await tester.enterText(find.byType(TextFormField).at(1), '12');
      await tester.tap(find.text('创建账号'));
      await tester.pump();

      expect(find.text('请输入验证码'), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'register page sends verification code after register challenge',
    (tester) async {
      final repository = _CapturingRegisterAuthRepository();
      await _pumpRegisterPage(tester, repository: repository);

      await tester.enterText(find.byType(TextFormField).at(0), '13800138000');
      await tester.tap(find.byKey(const ValueKey('register_send_code_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(repository.createChallengeCallCount, 1);
      expect(repository.sendCodeCallCount, 1);
      expect(repository.lastScene, VerificationCodeScene.register);
      expect(repository.lastCountryCode, '+86');
      expect(repository.lastPhoneNumber, '13800138000');
      expect(repository.lastChallengeId, 'challenge-1');
      expect(find.text('验证码已发送，请注意查收'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('register_send_code_countdown')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('register_masked_receiver_hint')),
        findsOneWidget,
      );
      expect(find.text('验证码已发送至 +441****8000'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'register page moves focus to code field and keeps countdown after focus changes',
    (tester) async {
      final repository = _CapturingRegisterAuthRepository();
      await _pumpRegisterPage(tester, repository: repository);

      await tester.enterText(find.byType(TextFormField).at(0), '13800138000');
      await tester.tap(find.byKey(const ValueKey('register_send_code_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final codeField = tester.widget<EditableText>(
        find.byType(EditableText).at(1),
      );
      expect(codeField.focusNode.hasFocus, isTrue);

      await tester.tap(find.byKey(const ValueKey('register_terms_row')));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('register_send_code_countdown')),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'register page dismisses keyboard after one-time code autofill completes',
    (tester) async {
      final repository = _CapturingRegisterAuthRepository();
      await _pumpRegisterPage(tester, repository: repository);

      await tester.enterText(find.byType(TextFormField).at(0), '13800138000');
      await tester.tap(find.byKey(const ValueKey('register_send_code_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final codeFieldFinder = find.byType(TextFormField).at(1);
      final codeEditableFinder = find.byType(EditableText).at(1);
      final codeEditable = tester.widget<EditableText>(codeEditableFinder);
      expect(
        codeEditable.autofillHints,
        orderedEquals(const [AutofillHints.oneTimeCode]),
      );
      expect(tester.testTextInput.isVisible, isTrue);

      await tester.enterText(codeFieldFinder, '123456');
      await tester.pump();

      final updatedCodeEditable = tester.widget<EditableText>(
        codeEditableFinder,
      );
      expect(updatedCodeEditable.focusNode.hasFocus, isFalse);
      expect(tester.testTextInput.isVisible, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('register page submits the selected country code', (
    tester,
  ) async {
    final repository = _CapturingRegisterAuthRepository();
    await _pumpRegisterPage(tester, repository: repository);

    await tester.tap(
      find.byKey(const ValueKey('register_country_code_menu_trigger')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    await tester.tap(
      find.byKey(const ValueKey('country_code_picker_item_+44')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

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

    expect(repository.lastScene, VerificationCodeScene.register);
    expect(repository.lastCountryCode, '+44');
    expect(repository.lastPhoneNumber, '13800138000');
    expect(repository.lastChallengeId, 'challenge-1');
    expect(repository.lastAuthenticateScene, VerificationCodeScene.register);
    expect(repository.lastVerificationCode, '123456');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'register page still submits after resend countdown ends while code is valid',
    (tester) async {
      final repository = _CapturingRegisterAuthRepository(
        resendAfter: const Duration(seconds: 1),
        codeExpiresAfter: const Duration(minutes: 5),
      );
      await _pumpRegisterPage(tester, repository: repository);

      await tester.enterText(find.byType(TextFormField).at(0), '13800138000');
      await tester.tap(find.byKey(const ValueKey('register_send_code_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 2));

      await tester.enterText(find.byType(TextFormField).at(1), '123456');
      await tester.tap(find.byKey(const ValueKey('register_terms_row')));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('register_create_account_button')),
      );
      await tester.pump();

      expect(repository.lastAuthenticateScene, VerificationCodeScene.register);
      expect(repository.lastVerificationCode, '123456');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('register page blocks submit after verification code expires', (
    tester,
  ) async {
    final repository = _CapturingRegisterAuthRepository(
      resendAfter: const Duration(seconds: 60),
      codeExpiresAfter: const Duration(seconds: -1),
    );
    await _pumpRegisterPage(tester, repository: repository);

    await tester.enterText(find.byType(TextFormField).at(0), '13800138000');
    await tester.tap(find.byKey(const ValueKey('register_send_code_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.byKey(const ValueKey('register_terms_row')));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('register_create_account_button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(repository.lastAuthenticateScene, isNull);
    expect(find.byType(RegisterPage), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('register page shows server message on failure', (tester) async {
    await _pumpRegisterPage(
      tester,
      repository: _FailingRegisterAuthRepository(),
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
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('验证码错误'), findsOneWidget);
    expect(find.byType(RegisterPage), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });
}
