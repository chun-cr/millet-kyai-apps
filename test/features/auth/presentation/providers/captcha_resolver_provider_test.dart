import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/features/auth/presentation/providers/captcha_resolver_provider.dart';

void main() {
  group('AliyunCaptchaConfig.tryParse', () {
    test('parses valid payload and appends H5 query parameters', () {
      final config = AliyunCaptchaConfig.tryParse(
        challengeId: 'challenge-1',
        provider: 'ALIYUN',
        initPayload: const {
          'sceneId': 'scene-1',
          'region': 'cn',
          'prefix': 'prefix-1',
          'userCertifyId': 'cert-1',
          'h5Url': 'https://captcha.example.com/index.html?from=app',
          'mode': 'aliyun-captcha2',
        },
      );

      expect(config, isNotNull);
      expect(config!.challengeId, 'challenge-1');
      expect(config.provider, 'ALIYUN');
      expect(config.mode, 'aliyun-captcha2');

      final uri = config.buildUri();
      expect(uri.queryParameters['from'], 'app');
      expect(uri.queryParameters['sceneId'], 'scene-1');
      expect(uri.queryParameters['region'], 'cn');
      expect(uri.queryParameters['prefix'], 'prefix-1');
      expect(uri.queryParameters['userCertifyId'], 'cert-1');
      expect(uri.queryParameters['provider'], 'ALIYUN');
      expect(uri.queryParameters['challengeId'], 'challenge-1');
    });

    test('returns null when required fields are missing', () {
      final config = AliyunCaptchaConfig.tryParse(
        challengeId: 'challenge-1',
        provider: 'ALIYUN',
        initPayload: const {
          'sceneId': 'scene-1',
          'prefix': 'prefix-1',
          'h5Url': 'https://captcha.example.com/index.html',
        },
      );

      expect(config, isNull);
    });

    test('returns null when h5Url is not https', () {
      final config = AliyunCaptchaConfig.tryParse(
        challengeId: 'challenge-1',
        provider: 'ALIYUN',
        initPayload: const {
          'sceneId': 'scene-1',
          'prefix': 'prefix-1',
          'userCertifyId': 'cert-1',
          'h5Url': 'http://captcha.example.com/index.html',
        },
      );

      expect(config, isNull);
    });
  });

  group('AliyunCaptchaBridgeEvent.tryParse', () {
    test('parses success event', () {
      final event = AliyunCaptchaBridgeEvent.tryParse(
        '{"type":"success","captchaVerifyParam":"opaque-token"}',
      );

      expect(event, isNotNull);
      expect(event!.type, 'success');
      expect(event.captchaVerifyParam, 'opaque-token');
    });

    test('returns null for invalid json payload', () {
      expect(AliyunCaptchaBridgeEvent.tryParse('not-json'), isNull);
    });

    test('returns null when type is missing', () {
      expect(
        AliyunCaptchaBridgeEvent.tryParse('{"captchaVerifyParam":"opaque"}'),
        isNull,
      );
    });
  });
}
