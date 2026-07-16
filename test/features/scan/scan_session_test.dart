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
    expect(session.tongueReportId, isNull);
  });

  test('tongue upload does not fallback to unrelated ids for report id', () {
    const upload = ScanTongueUploadResult(<String, dynamic>{
      'imageId': 'image-123',
      'id': 'data-id',
      'report': <String, dynamic>{'id': 456},
      'analysisResult': <String, dynamic>{'tongueReportId': 'analysis-id'},
      'tongueReport': <String, dynamic>{'id': 789, 'success': true},
      'medicalCase': <String, dynamic>{'id': 999},
    });
    final session = ScanSession()..saveTongueUpload(upload);

    expect(upload.reportId, isEmpty);
    expect(upload.tongueReportId, 789);
    expect(session.reportId, isNull);
    expect(session.tongueReportId, isNull);
  });

  test('tongueReport.reportId is used for question and report continuity', () {
    const upload = ScanTongueUploadResult(<String, dynamic>{
      'analysisResult': <String, dynamic>{'success': true, 'hasTongue': true},
      'tongueReport': <String, dynamic>{
        'id': 789,
        'success': true,
        'reportId': 456,
      },
    });
    final session = ScanSession()..saveTongueUpload(upload);

    expect(upload.reportId, '456');
    expect(upload.tongueReportId, 789);
    expect(session.reportId, '456');
    expect(session.tongueReportId, 789);
  });

  test('tongue upload separates tongue detection from report generation', () {
    const pendingReport = ScanTongueUploadResult(<String, dynamic>{
      'imageId': 'image-123',
      'analysisResult': <String, dynamic>{'success': true, 'hasTongue': true},
      'tongueReport': <String, dynamic>{'success': false, 'reportId': null},
    });
    const readyReport = ScanTongueUploadResult(<String, dynamic>{
      'analysisResult': <String, dynamic>{'success': true, 'hasTongue': true},
      'tongueReport': <String, dynamic>{
        'success': true,
        'reportId': 'report-123',
      },
    });

    expect(pendingReport.analysisSucceeded, isTrue);
    expect(pendingReport.hasDetectedTongue, isTrue);
    expect(pendingReport.tongueReportSucceeded, isFalse);
    expect(pendingReport.reportGenerationFailed, isTrue);
    expect(pendingReport.hasGeneratedReport, isFalse);
    expect(pendingReport.reportId, isEmpty);
    expect(pendingReport.imageId, 'image-123');
    expect(readyReport.hasGeneratedReport, isTrue);
    expect(readyReport.reportId, 'report-123');
  });

  test('valid report id remains usable when tongueReport.success is false', () {
    const upload = ScanTongueUploadResult(<String, dynamic>{
      'analysisResult': <String, dynamic>{'success': true, 'hasTongue': true},
      'tongueReport': <String, dynamic>{
        'id': 789,
        'success': false,
        'reportId': 'report-pending',
      },
    });

    final session = ScanSession()..saveTongueUpload(upload);

    expect(upload.tongueReportSucceeded, isFalse);
    expect(upload.reportGenerationFailed, isFalse);
    expect(upload.hasGeneratedReport, isTrue);
    expect(session.reportId, 'report-pending');
    expect(session.tongueReportId, 789);
  });

  test('saveReportId overrides the report id returned by tongue upload', () {
    const upload = ScanTongueUploadResult(<String, dynamic>{
      'analysisResult': <String, dynamic>{'success': true, 'hasTongue': true},
      'tongueReport': <String, dynamic>{'success': true, 'reportId': '456'},
    });
    final session = ScanSession()..saveTongueUpload(upload);

    session.saveReportId('report-final');

    expect(session.reportId, 'report-final');
  });
}
