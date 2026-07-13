import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/l10n/app_localizations_en.dart';
import 'package:millet_kyai_apps/l10n/app_localizations_ja.dart';
import 'package:millet_kyai_apps/l10n/app_localizations_ko.dart';
import 'package:millet_kyai_apps/l10n/app_localizations_zh.dart';
import 'package:millet_kyai_apps/features/scan/data/sources/scan_remote_source.dart';
import 'package:millet_kyai_apps/features/scan/presentation/utils/scan_failure_feedback.dart';

void main() {
  test(
    'scan upload failure dialog titles are localized across supported locales',
    () {
      expect(AppLocalizationsZh().scanFaceUploadFailedTitle, '人脸上传失败');
      expect(AppLocalizationsZh().scanTongueUploadFailedTitle, '舌诊上传失败');

      expect(
        AppLocalizationsEn().scanFaceUploadFailedTitle,
        'Face upload failed',
      );
      expect(
        AppLocalizationsEn().scanTongueUploadFailedTitle,
        'Tongue upload failed',
      );

      expect(AppLocalizationsJa().scanFaceUploadFailedTitle, isNotEmpty);
      expect(AppLocalizationsJa().scanTongueUploadFailedTitle, isNotEmpty);
      expect(AppLocalizationsKo().scanFaceUploadFailedTitle, isNotEmpty);
      expect(AppLocalizationsKo().scanTongueUploadFailedTitle, isNotEmpty);
    },
  );

  test('scan failure feedback hides raw diagnostics from users', () {
    expect(
      scanFailureUserMessage(
        stage: ScanFailureStage.tongue,
        error: const ScanUploadException(
          stage: 'tongue',
          path: '/api/v1/saas/mobile/ai/diagnosis/upload',
          message: 'stage: tongue\npath: /debug\nmessage: raw backend error',
          businessCode: 24043,
          messageKey: 'physique.param_invalid',
        ),
      ),
      '舌诊上传失败，请重新扫描。',
    );

    expect(
      scanFailureUserMessage(
        stage: ScanFailureStage.palm,
        error: const ScanUploadException(
          stage: 'palm',
          path: '/api/v1/saas/mobile/ai/diagnosis/upload/hand',
          message: '报告ID缺失，无法上传手诊。',
        ),
      ),
      '舌诊报告生成失败，请重新扫描。',
    );
  });

  test(
    'scan failure feedback treats auth business codes as expired session',
    () {
      expect(
        scanFailureUserMessage(
          stage: ScanFailureStage.face,
          error: const ScanUploadException(
            stage: 'face',
            path: '/api/v1/saas/mobile/ai/diagnosis/upload/face',
            message: '未登录',
            businessCode: 40101,
            messageKey: 'AUTH_ACCESS_EXPIRED',
          ),
        ),
        '登录状态已失效，请重新登录后再试。',
      );
    },
  );
}
