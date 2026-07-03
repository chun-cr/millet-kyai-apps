import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/l10n/app_localizations_en.dart';
import 'package:millet_kyai_apps/l10n/app_localizations_ja.dart';
import 'package:millet_kyai_apps/l10n/app_localizations_ko.dart';
import 'package:millet_kyai_apps/l10n/app_localizations_zh.dart';

void main() {
  test('scan upload failure dialog titles are localized across supported locales', () {
    expect(AppLocalizationsZh().scanFaceUploadFailedTitle, '人脸上传失败');
    expect(AppLocalizationsZh().scanTongueUploadFailedTitle, '舌诊上传失败');

    expect(AppLocalizationsEn().scanFaceUploadFailedTitle, 'Face upload failed');
    expect(AppLocalizationsEn().scanTongueUploadFailedTitle, 'Tongue upload failed');

    expect(AppLocalizationsJa().scanFaceUploadFailedTitle, isNotEmpty);
    expect(AppLocalizationsJa().scanTongueUploadFailedTitle, isNotEmpty);
    expect(AppLocalizationsKo().scanFaceUploadFailedTitle, isNotEmpty);
    expect(AppLocalizationsKo().scanTongueUploadFailedTitle, isNotEmpty);
  });
}
