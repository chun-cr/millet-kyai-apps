import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/features/scan/data/models/scan_session.dart';
import 'package:millet_kyai_apps/features/scan/data/models/scan_upload_result.dart';

void main() {
  test('markFaceScanSkipped seeds a placeholder face upload for downstream steps', () {
    final session = ScanSession();

    session.markFaceScanSkipped();

    expect(session.faceScanSkipped, isTrue);
    expect(session.faceUpload, isNotNull);
    expect(session.faceUpload!.toTongueFaceData(), isEmpty);
    expect(session.detectedAge, isNull);
    expect(session.detectedGender, isEmpty);
  });

  test('saveFaceUpload clears the temporary skip marker', () {
    final session = ScanSession()..markFaceScanSkipped();

    session.saveFaceUpload(
      const ScanFaceUploadResult(<String, dynamic>{'faceNum': 1, 'sex': 'M'}),
    );

    expect(session.faceScanSkipped, isFalse);
    expect(session.faceUpload?.faceNum, 1);
    expect(session.detectedGender, 'M');
  });
}
