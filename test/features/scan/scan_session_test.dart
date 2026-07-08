import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/features/scan/data/models/scan_session.dart';
import 'package:millet_kyai_apps/features/scan/data/models/scan_upload_result.dart';

void main() {
  test(
    'markFaceScanSkipped seeds a placeholder face upload for downstream steps',
    () {
      final session = ScanSession();

      session.markFaceScanSkipped();

      expect(session.faceScanSkipped, isTrue);
      expect(session.faceUpload, isNotNull);
      expect(session.faceUpload!.toTongueFaceData(), isEmpty);
      expect(session.detectedAge, isNull);
      expect(session.detectedGender, isEmpty);
    },
  );

  test('saveFaceUpload clears the temporary skip marker', () {
    final session = ScanSession()..markFaceScanSkipped();

    session.saveFaceUpload(
      const ScanFaceUploadResult(<String, dynamic>{'faceNum': 1, 'sex': 'M'}),
    );

    expect(session.faceScanSkipped, isFalse);
    expect(session.faceUpload?.faceNum, 1);
    expect(session.detectedGender, 'M');
  });

  test(
    'tongue upload result distinguishes analysis failure from missing tongue',
    () {
      const failed = ScanTongueUploadResult(<String, dynamic>{
        'analysisResult': <String, dynamic>{'success': false},
      });
      const missing = ScanTongueUploadResult(<String, dynamic>{
        'analysisResult': <String, dynamic>{
          'success': true,
          'hasTongue': false,
        },
      });

      expect(failed.analysisFailed, isTrue);
      expect(failed.missingTongue, isFalse);
      expect(missing.analysisFailed, isFalse);
      expect(missing.missingTongue, isTrue);
    },
  );

  test('tongue upload keeps tongueReport.id separate from reportId', () {
    const upload = ScanTongueUploadResult(<String, dynamic>{
      'tongueReport': <String, dynamic>{'id': 789},
    });
    final session = ScanSession()..saveTongueUpload(upload);

    expect(upload.reportId, isEmpty);
    expect(upload.tongueReportId, 789);
    expect(session.reportId, isNull);
  });

  test('tongue upload parses nested report ids for report persistence', () {
    const upload = ScanTongueUploadResult(<String, dynamic>{
      'report': <String, dynamic>{'id': 456},
      'tongueReport': <String, dynamic>{'id': 789},
    });
    final session = ScanSession()..saveTongueUpload(upload);

    expect(upload.reportId, '456');
    expect(upload.tongueReportId, 789);
    expect(session.reportId, '456');
  });
}
