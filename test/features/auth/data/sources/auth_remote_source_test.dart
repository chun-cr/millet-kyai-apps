import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/core/network/dio_client.dart';
import 'package:millet_kyai_apps/features/auth/data/models/auth_request.dart';
import 'package:millet_kyai_apps/features/auth/data/sources/auth_remote_source.dart';
import 'package:millet_kyai_apps/features/auth/domain/entities/verification_code_target.dart';
import 'package:millet_kyai_apps/features/auth/domain/repositories/auth_repository.dart';

void main() {
  group('AuthRemoteSource.login', () {
    late DioClient dioClient;
    late AuthRemoteSource remoteSource;
    late RequestOptions capturedOptions;

    setUp(() {
      dioClient = DioClient();
      dioClient.dio.interceptors.clear();
      remoteSource = AuthRemoteSource(dioClient);
    });

    Response<Map<String, dynamic>> successResponse(RequestOptions options) {
      return Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 200,
        data: {
          'code': 0,
          'message': 'ok',
          'data': {
            'accessToken': 'access-token',
            'refreshToken': 'refresh-token',
            'tokenType': 'Bearer',
            'expiresIn': 3600,
            'scope': 'mobile',
          },
        },
      );
    }

    test('sends phone password payload unchanged', () async {
      dioClient.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedOptions = options;
            handler.resolve(successResponse(options));
          },
        ),
      );

      final result = await remoteSource.login(
        const AuthRequest(
          countryCode: '+86',
          phoneNumber: '13800138000',
          password: 'secret123',
          inviteTicket: 'invite-login-1',
        ),
      );

      expect(capturedOptions.path, '/api/v1/saas/mobile/auth/login/password');
      expect(capturedOptions.data, {
        'loginValue': '13800138000',
        'countryCode': '+86',
        'password': 'secret123',
        'inviteTicket': 'invite-login-1',
      });
      expect(result.accessToken, 'access-token');
    });

    test('sends email password payload with loginValue and email', () async {
      dioClient.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedOptions = options;
            handler.resolve(successResponse(options));
          },
        ),
      );

      final result = await remoteSource.login(
        const AuthRequest(
          countryCode: '',
          phoneNumber: 'doctor@example.com',
          password: 'secret123',
        ),
      );

      expect(capturedOptions.path, '/api/v1/saas/mobile/auth/login/password');
      expect(capturedOptions.data, {
        'loginValue': 'doctor@example.com',
        'password': 'secret123',
      });
      expect(result.refreshToken, 'refresh-token');
    });
  });

  group('AuthRemoteSource.registerPassword', () {
    late DioClient dioClient;
    late AuthRemoteSource remoteSource;
    late RequestOptions capturedOptions;

    setUp(() {
      dioClient = DioClient();
      dioClient.dio.interceptors.clear();
      remoteSource = AuthRemoteSource(dioClient);
    });

    test('sends OpenAPI password register payload with loginValue', () async {
      dioClient.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedOptions = options;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'code': 0,
                  'message': 'ok',
                  'data': {
                    'result': 'REGISTERED',
                    'token': {
                      'accessToken': 'register-token',
                      'refreshToken': 'refresh-token',
                      'tokenType': 'Bearer',
                      'expiresIn': 3600,
                      'scope': 'mobile',
                    },
                  },
                },
              ),
            );
          },
        ),
      );

      final result = await remoteSource.registerPassword(
        const AuthRequest(
          countryCode: '+86',
          phoneNumber: ' 13800138000 ',
          password: ' secret123 ',
          inviteTicket: ' invite-register-1 ',
        ),
      );

      expect(
        capturedOptions.path,
        '/api/v1/saas/mobile/auth/register/password',
      );
      expect(capturedOptions.data, {
        'loginValue': '13800138000',
        'phoneNumber': '13800138000',
        'countryCode': '+86',
        'password': 'secret123',
        'inviteTicket': 'invite-register-1',
      });
      expect(result.session!.accessToken, 'register-token');
    });
  });

  group('AuthRemoteSource.createVerificationCodeChallenge', () {
    late DioClient dioClient;
    late AuthRemoteSource remoteSource;
    late RequestOptions capturedOptions;

    setUp(() {
      dioClient = DioClient();
      dioClient.dio.interceptors.clear();
      remoteSource = AuthRemoteSource(dioClient);
    });

    test('uses shared endpoint with scene for register challenge', () async {
      dioClient.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedOptions = options;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'code': 0,
                  'message': 'ok',
                  'data': {
                    'challengeId': 'register-challenge-1',
                    'captchaRequired': true,
                    'captcha': {
                      'provider': 'TENCENT',
                      'payload': {'appId': 'captcha-app'},
                    },
                    'expireAt': '2026-04-10T08:00:00Z',
                  },
                },
              ),
            );
          },
        ),
      );

      final result = await remoteSource.createVerificationCodeChallenge(
        scene: VerificationCodeScene.register,
        target: const VerificationCodeTarget.phone(
          countryCode: '+86',
          value: '13800138000',
        ),
      );

      expect(
        capturedOptions.path,
        '/api/v1/saas/mobile/auth/verification-code/challenge',
      );
      expect(capturedOptions.data, {
        'scene': 'REGISTER',
        'countryCode': '+86',
        'phoneNumber': '13800138000',
        'loginValue': '13800138000',
      });
      expect(result.challengeId, 'register-challenge-1');
      expect(result.captchaRequired, isTrue);
      expect(result.captchaProvider, 'TENCENT');
      expect(result.captchaPayload, {'appId': 'captcha-app'});
      expect(result.expireAt, DateTime.parse('2026-04-10T08:00:00Z'));
    });

    test('uses shared endpoint with scene for login challenge', () async {
      dioClient.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedOptions = options;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'code': 0,
                  'message': 'ok',
                  'data': {
                    'challengeId': 'login-challenge-1',
                    'captchaRequired': false,
                    'captcha': null,
                    'expireAt': '2026-04-10T08:10:00Z',
                  },
                },
              ),
            );
          },
        ),
      );

      final result = await remoteSource.createVerificationCodeChallenge(
        scene: VerificationCodeScene.login,
        target: const VerificationCodeTarget.phone(
          countryCode: '+86',
          value: '13800138000',
        ),
      );

      expect(
        capturedOptions.path,
        '/api/v1/saas/mobile/auth/verification-code/challenge',
      );
      expect(capturedOptions.data, {
        'scene': 'LOGIN',
        'countryCode': '+86',
        'phoneNumber': '13800138000',
        'loginValue': '13800138000',
      });
      expect(result.challengeId, 'login-challenge-1');
      expect(result.captchaRequired, isFalse);
      expect(result.expireAt, DateTime.parse('2026-04-10T08:10:00Z'));
    });

    test('omits country code for email challenge payload', () async {
      dioClient.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedOptions = options;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'code': 0,
                  'message': 'ok',
                  'data': {
                    'challengeId': 'email-challenge-1',
                    'captchaRequired': false,
                    'captcha': null,
                    'expireAt': '2026-04-10T08:20:00Z',
                  },
                },
              ),
            );
          },
        ),
      );

      final result = await remoteSource.createVerificationCodeChallenge(
        scene: VerificationCodeScene.register,
        target: const VerificationCodeTarget.email(value: 'doctor@example.com'),
      );

      expect(
        capturedOptions.path,
        '/api/v1/saas/mobile/auth/verification-code/challenge',
      );
      expect(capturedOptions.data, {
        'scene': 'REGISTER',
        'phoneNumber': 'doctor@example.com',
        'loginValue': 'doctor@example.com',
      });
      expect(result.challengeId, 'email-challenge-1');
    });
  });

  group('AuthRemoteSource.authenticateVerificationCode', () {
    late DioClient dioClient;
    late AuthRemoteSource remoteSource;
    late RequestOptions capturedOptions;

    setUp(() {
      dioClient = DioClient();
      dioClient.dio.interceptors.clear();
      remoteSource = AuthRemoteSource(dioClient);
    });

    test('uses login verification endpoint for login scene', () async {
      dioClient.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedOptions = options;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'code': 0,
                  'message': 'ok',
                  'data': {
                    'accessToken': 'auth-token',
                    'refreshToken': 'refresh-token',
                    'tokenType': 'Bearer',
                    'expiresIn': 3600,
                    'scope': 'mobile',
                  },
                },
              ),
            );
          },
        ),
      );

      final result = await remoteSource.authenticateVerificationCode(
        scene: VerificationCodeScene.login,
        challengeId: ' challenge-1 ',
        verificationCode: ' 123456 ',
        inviteTicket: ' invite-1 ',
      );

      expect(
        capturedOptions.path,
        '/api/v1/saas/mobile/auth/login/verification-code',
      );
      expect(capturedOptions.data, {
        'challengeId': 'challenge-1',
        'verificationCode': '123456',
        'inviteTicket': 'invite-1',
      });
      expect(result.accessToken, 'auth-token');
    });

    test('uses register verification endpoint for register scene', () async {
        dioClient.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              capturedOptions = options;
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'code': 0,
                    'message': 'ok',
                    'data': {
                      'accessToken': 'auth-token',
                      'refreshToken': 'refresh-token',
                      'tokenType': 'Bearer',
                      'expiresIn': 3600,
                      'scope': 'mobile',
                    },
                  },
                ),
              );
            },
          ),
        );

        final result = await remoteSource.authenticateVerificationCode(
          scene: VerificationCodeScene.register,
          challengeId: 'challenge-1',
          verificationCode: '123456',
          inviteTicket: 'invite-1',
        );

        expect(
          capturedOptions.path,
          '/api/v1/saas/mobile/auth/register/verification-code',
        );
        expect(capturedOptions.data, {
          'challengeId': 'challenge-1',
          'verificationCode': '123456',
          'inviteTicket': 'invite-1',
        });
        expect(result.accessToken, 'auth-token');
      });
  });

  group('AuthRemoteSource verification-code split endpoints', () {
    late DioClient dioClient;
    late AuthRemoteSource remoteSource;
    late RequestOptions capturedOptions;

    setUp(() {
      dioClient = DioClient();
      dioClient.dio.interceptors.clear();
      remoteSource = AuthRemoteSource(dioClient);
      dioClient.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedOptions = options;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'code': 0,
                  'message': 'ok',
                  'data': {
                    'accessToken': 'split-token',
                    'refreshToken': 'refresh-token',
                    'tokenType': 'Bearer',
                    'expiresIn': 3600,
                    'scope': 'mobile',
                  },
                },
              ),
            );
          },
        ),
      );
    });

    test('loginByVerificationCode uses login-only endpoint', () async {
      final result = await remoteSource.loginByVerificationCode(
        challengeId: ' login-challenge ',
        verificationCode: ' 123456 ',
        inviteTicket: ' invite-1 ',
      );

      expect(
        capturedOptions.path,
        '/api/v1/saas/mobile/auth/login/verification-code',
      );
      expect(capturedOptions.data, {
        'challengeId': 'login-challenge',
        'verificationCode': '123456',
        'inviteTicket': 'invite-1',
      });
      expect(result.accessToken, 'split-token');
    });

    test('registerByVerificationCode uses register-only endpoint', () async {
      await remoteSource.registerByVerificationCode(
        challengeId: 'register-challenge',
        verificationCode: '654321',
      );

      expect(
        capturedOptions.path,
        '/api/v1/saas/mobile/auth/register/verification-code',
      );
      expect(capturedOptions.data, {
        'challengeId': 'register-challenge',
        'verificationCode': '654321',
      });
    });
  });

  group('AuthRemoteSource.registerWithWechatMiniProgram', () {
    late DioClient dioClient;
    late AuthRemoteSource remoteSource;
    late RequestOptions capturedOptions;

    setUp(() {
      dioClient = DioClient();
      dioClient.dio.interceptors.clear();
      remoteSource = AuthRemoteSource(dioClient);
    });

    test('posts appId, wechatCode, phoneCode and referral fields', () async {
      dioClient.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedOptions = options;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'code': 0,
                  'message': 'ok',
                  'data': {
                    'authStatus': 'REGISTERED',
                    'token': {
                      'accessToken': 'wechat-token',
                      'refreshToken': 'wechat-refresh',
                      'tokenType': 'Bearer',
                      'expiresIn': 3600,
                      'scope': 'mobile',
                    },
                    'globalUserId': 'user-1',
                    'phoneNumber': '13800138000',
                  },
                },
              ),
            );
          },
        ),
      );

      final result = await remoteSource.registerWithWechatMiniProgram(
        wechatCode: ' wx-code ',
        phoneCode: ' phone-code ',
        inviteTicket: ' invite-ticket ',
        visitorKey: ' visitor-1 ',
      );

      expect(
        capturedOptions.path,
        '/api/v1/saas/mobile/auth/register/wechat-mini-program',
      );
      expect(capturedOptions.data, {
        'appId': DioClient.wechatMiniProgramAppId,
        'wechatCode': 'wx-code',
        'phoneCode': 'phone-code',
        'inviteTicket': 'invite-ticket',
        'visitorKey': 'visitor-1',
      });
      expect(result.token!.accessToken, 'wechat-token');
    });
  });
}
