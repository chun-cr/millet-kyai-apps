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
import 'package:millet_kyai_apps/features/auth/presentation/pages/register_page.dart';
import 'package:millet_kyai_apps/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:millet_kyai_apps/l10n/app_localizations.dart';

class _CapturingRegisterRepository extends AuthRepositoryAdapter {
  VerificationCodeScene? lastScene;
  String? lastCountryCode;
  String? lastPhoneNumber;

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
    lastCountryCode = target.countryCode ?? '';
    lastPhoneNumber = target.value;
    return VerificationCodeChallengeEntity(
      challengeId: 'challenge-email-1',
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
    channel: 'EMAIL',
    maskedReceiver: 'doc***@example.com',
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
      requestOptions: RequestOptions(path: '/auth'),
      response: Response(
        requestOptions: RequestOptions(path: '/auth'),
        statusCode: 400,
        data: {'message': 'capture'},
      ),
    );
  }

  @override
  Future<void> logout({required String refreshToken}) async {}
}

Future<void> _pumpRegisterPage(
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

Future<void> _pumpRegisterRouter(
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
  testWidgets('register page shows tabs and bottom login entry', (
    tester,
  ) async {
    final repository = _CapturingRegisterRepository();
    await _pumpRegisterPage(
      tester,
      repository: repository,
      child: const RegisterPage(),
    );

    expect(find.byKey(const ValueKey('register_phone_tab')), findsOneWidget);
    expect(find.byKey(const ValueKey('register_email_tab')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('register_go_login_button')),
      findsOneWidget,
    );
    expect(find.text('立即登录'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('typing @ in phone field auto-switches to email register', (
    tester,
  ) async {
    final repository = _CapturingRegisterRepository();
    await _pumpRegisterPage(
      tester,
      repository: repository,
      child: const RegisterPage(),
    );

    await tester.enterText(
      find.byType(TextFormField).first,
      'doctor@example.com',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byKey(const ValueKey('register_email_fields')), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller
          ?.text,
      'doctor@example.com',
    );
    expect(
      find.byKey(const ValueKey('register_country_code_menu_trigger')),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('email register sends challenge without country code', (
    tester,
  ) async {
    final repository = _CapturingRegisterRepository();
    await _pumpRegisterPage(
      tester,
      repository: repository,
      child: const RegisterPage(),
    );

    await tester.tap(find.byKey(const ValueKey('register_email_tab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(
      find.byType(TextFormField).first,
      'doctor@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('register_send_code_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(repository.lastScene, VerificationCodeScene.register);
    expect(repository.lastCountryCode, '');
    expect(repository.lastPhoneNumber, 'doctor@example.com');
    expect(find.text('验证码已发送，如未收到请检查垃圾邮件箱�?), findsOneWidget);
    expect(
      find.byKey(const ValueKey('register_send_code_countdown')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('email register validates format in real time', (tester) async {
    final repository = _CapturingRegisterRepository();
    await _pumpRegisterPage(
      tester,
      repository: repository,
      child: const RegisterPage(),
    );

    await tester.tap(find.byKey(const ValueKey('register_email_tab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(find.byType(TextFormField).first, 'doctor@');
    await tester.pump();

    expect(find.text('请输入正确的邮箱'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('bottom login action keeps current email mode', (tester) async {
    final repository = _CapturingRegisterRepository();
    final router = GoRouter(
      initialLocation: '/register?inviteTicket=invite-register-1',
      routes: [
        GoRoute(
          path: '/register',
          builder: (context, state) => RegisterPage(
            inviteTicket: state.uri.queryParameters['inviteTicket'],
            initialMode: state.uri.queryParameters['mode'],
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => Scaffold(
            body: Text(
              'login:${state.uri.queryParameters['mode']}:${state.uri.queryParameters['inviteTicket']}',
            ),
          ),
        ),
      ],
    );

    await _pumpRegisterRouter(tester, repository: repository, router: router);

    await tester.tap(find.byKey(const ValueKey('register_email_tab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const ValueKey('register_go_login_button')));
    await tester.pumpAndSettle();

    expect(find.text('login:email:invite-register-1'), findsOneWidget);

    router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });
}
