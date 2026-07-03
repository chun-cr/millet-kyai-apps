import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/features/history/presentation/pages/history/history_record.dart';
import 'package:millet_kyai_apps/features/report/data/models/report_detail.dart';

void main() {
  test(
    'DiagnosisRecord.fromSummary uses only face scan image for history cards',
    () {
      final record = DiagnosisRecord.fromSummary(
        DiagnosisReportSummary(
          id: 'report-001',
          testTime: '2026-04-17T10:30:00Z',
          healthScore: 82,
          physiqueName: 'Balanced',
          imageUrl: 'https://example.com/tongue.png',
          faceImageUrl: 'https://example.com/face.png',
          lockedStatus: '1',
          deepPredicts: const DiagnosisDeepPredicts(
            categoryProbabilities: <DiagnosisNamedProbability>[],
            predictions: <DiagnosisNamedProbability>[],
            diseases: <DiagnosisDisease>[],
            raw: <String, dynamic>{},
          ),
          raw: const <String, dynamic>{},
        ),
      );

      expect(record.faceImageUrl, 'https://example.com/face.png');
    },
  );

  test(
    'DiagnosisRecord.fromSummary does not fall back to tongue image when face scan is missing',
    () {
      final record = DiagnosisRecord.fromSummary(
        DiagnosisReportSummary(
          id: 'report-002',
          testTime: '2026-04-17T10:30:00Z',
          healthScore: 82,
          physiqueName: 'Balanced',
          imageUrl: 'https://example.com/tongue.png',
          faceImageUrl: '',
          lockedStatus: '1',
          deepPredicts: const DiagnosisDeepPredicts(
            categoryProbabilities: <DiagnosisNamedProbability>[],
            predictions: <DiagnosisNamedProbability>[],
            diseases: <DiagnosisDisease>[],
            raw: <String, dynamic>{},
          ),
          raw: const <String, dynamic>{},
        ),
      );

      expect(record.faceImageUrl, isEmpty);
    },
  );

  test(
    'DiagnosisRecord.fromSummary keeps the first four named risk indices in order',
    () {
      final record = DiagnosisRecord.fromSummary(
        DiagnosisReportSummary(
          id: 'report-003',
          testTime: '2026-04-17T10:30:00Z',
          healthScore: 82,
          physiqueName: 'Balanced',
          imageUrl: '',
          faceImageUrl: '',
          lockedStatus: '1',
          deepPredicts: DiagnosisDeepPredicts(
            categoryProbabilities: const <DiagnosisNamedProbability>[
              DiagnosisNamedProbability(
                id: 'risk-1',
                name: '脾胃',
                rawProbability: 0.91,
                probability: 91,
                raw: <String, dynamic>{},
              ),
              DiagnosisNamedProbability(
                id: 'risk-2',
                name: '气虚',
                rawProbability: 0.73,
                probability: 73,
                raw: <String, dynamic>{},
              ),
              DiagnosisNamedProbability(
                id: 'risk-3',
                name: '湿困',
                rawProbability: 0.65,
                probability: 65,
                raw: <String, dynamic>{},
              ),
              DiagnosisNamedProbability(
                id: 'risk-4',
                name: '肝郁',
                rawProbability: 0.54,
                probability: 54,
                raw: <String, dynamic>{},
              ),
              DiagnosisNamedProbability(
                id: 'risk-5',
                name: '血瘀',
                rawProbability: 0.49,
                probability: 49,
                raw: <String, dynamic>{},
              ),
            ],
            predictions: const <DiagnosisNamedProbability>[],
            diseases: const <DiagnosisDisease>[],
            raw: const <String, dynamic>{},
          ),
          raw: const <String, dynamic>{},
        ),
      );

      expect(record.riskIndices.map((item) => item.name).toList(), <String>[
        '脾胃',
        '气虚',
        '湿困',
        '肝郁',
      ]);
      expect(record.riskIndices.map((item) => item.value).toList(), <double>[
        0.91,
        0.73,
        0.65,
        0.54,
      ]);
    },
  );
}
