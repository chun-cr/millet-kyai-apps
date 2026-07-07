import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/features/report/data/models/report_detail.dart';

import 'report_test_data.dart';

void main() {
  test('DiagnosisNamedProbability keeps raw and percent-like probability', () {
    final detail = buildDiagnosisReportDetail(
      categoryProbabilities: [
        {'name': '神志精神及情绪', 'prob': 0.89},
        {'name': '饮食习惯', 'prob': 1.0},
      ],
    );

    final probabilities =
        detail.analysisResult.deepPredicts.categoryProbabilities;

    expect(probabilities, hasLength(2));
    expect(probabilities.first.rawProbability, closeTo(0.89, 0.0001));
    expect(probabilities.first.probability, closeTo(89, 0.0001));
    expect(probabilities.last.rawProbability, closeTo(1.0, 0.0001));
    expect(probabilities.last.probability, closeTo(100, 0.0001));
  });

  test(
    'DiagnosisReportDetail normalizes top-level riskIndexes into deepPredicts',
    () {
      final detail = buildDiagnosisReportDetail(
        categoryProbabilities: const [],
        riskIndexes: [
          {'displayName': '作息睡眠', 'score': 69},
          {'name': '消化道', 'score': 41},
        ],
      );

      final probabilities =
          detail.analysisResult.deepPredicts.categoryProbabilities;

      expect(probabilities, hasLength(2));
      expect(probabilities.first.name, '作息睡眠');
      expect(probabilities.first.rawProbability, closeTo(0.69, 0.0001));
      expect(probabilities.first.probability, closeTo(69, 0.0001));
      expect(probabilities.last.name, '消化道');
      expect(probabilities.last.rawProbability, closeTo(0.41, 0.0001));
      expect(probabilities.last.probability, closeTo(41, 0.0001));
    },
  );

  test(
    'DiagnosisReportSummary prefers face payload image for faceImageUrl',
    () {
      final summary = DiagnosisReportSummary.fromJson({
        'id': 'report-001',
        'testTime': '2026-04-17 10:30',
        'healthScore': 82,
        'physiqueName': 'Balanced',
        'imageUrl': 'https://example.com/tongue-top-level.png',
        'tongue': {
          'imageUrl': 'https://example.com/tongue.png',
          'thumbImageUrl': 'https://example.com/tongue-thumb.png',
        },
        'face': {
          'imageUrl': 'https://example.com/face.png',
          'thumbImageUrl': 'https://example.com/face-thumb.png',
        },
        'lockedStatus': '1',
        'deepPredicts': const <String, Object>{},
      });

      expect(summary.imageUrl, 'https://example.com/tongue-top-level.png');
      expect(summary.faceImageUrl, 'https://example.com/face.png');
    },
  );

  test(
    'DiagnosisReportSummary keeps faceImageUrl empty when only tongue images exist',
    () {
      final summary = DiagnosisReportSummary.fromJson({
        'id': 'report-002',
        'testTime': '2026-04-17 10:30',
        'healthScore': 82,
        'physiqueName': 'Balanced',
        'imageUrl': 'https://example.com/tongue-top-level.png',
        'tongue': {
          'imageUrl': 'https://example.com/tongue.png',
          'thumbImageUrl': 'https://example.com/tongue-thumb.png',
        },
        'lockedStatus': '1',
        'deepPredicts': const <String, Object>{},
      });

      expect(summary.imageUrl, 'https://example.com/tongue-top-level.png');
      expect(summary.faceImageUrl, isEmpty);
    },
  );

  test(
    'DiagnosisReportSummary reads faceImageUrl from faceAnalysisResult when face payload is absent',
    () {
      final summary = DiagnosisReportSummary.fromJson({
        'id': 'report-003',
        'testTime': '2026-04-17 10:30',
        'healthScore': 82,
        'physiqueName': 'Balanced',
        'imageUrl': 'https://example.com/tongue-top-level.png',
        'faceAnalysisResult': {
          'imageUrl': 'https://example.com/face-from-analysis.png',
        },
        'lockedStatus': '1',
        'deepPredicts': const <String, Object>{},
      });

      expect(
        summary.faceImageUrl,
        'https://example.com/face-from-analysis.png',
      );
    },
  );
}
