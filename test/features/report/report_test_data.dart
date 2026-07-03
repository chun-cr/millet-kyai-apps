import 'package:millet_kyai_apps/features/report/presentation/pages/report/report_page.dart';

DiagnosisReportDetail buildDiagnosisReportDetail({
  String id = 'report-001',
  String testTime = '2026-04-17 10:30',
  String source = 'scan-booth',
  double healthScore = 82,
  String summary = 'Live summary insight',
  String primaryConstitution = 'Balanced',
  String secondaryConstitution = 'Qi deficiency',
  String therapySummary = 'Prefer warm meals and steady routines.',
  bool includeSecondaryConstitution = true,
  bool hideAge = false,
  int faceFindingCount = 2,
  int analysisFindingCount = 1,
  int handFindingCount = 1,
  double faceAge = 30,
  String imageUrl = '',
  String faceImageUrl = '',
  String handImageUrl = '',
  List<String> analysisFindingSymptoms = const ['舌边齿痕', '舌苔白'],
  List<Map<String, Object?>> analysisFindings = const [],
  List<Map<String, Object>> categoryProbabilities = const [],
  List<Map<String, Object>> riskIndexes = const [],
  List<Map<String, Object>> relativeSyms = const [],
  List<Map<String, Object>> predictions = const [],
  List<Map<String, Object?>> constitutionScores = const [],
  List<Map<String, Object?>> tzpdResults = const [],
}) {
  List<Map<String, Object>> findings(
    int count,
    String leadingResult, {
    List<String> firstSymptoms = const [],
  }) {
    return List.generate(count, (index) {
      return {
        'name': 'finding-$index',
        'result': index == 0 ? leadingResult : 'detail-$index',
        'key': 'key-$index',
        'symptoms': index == 0
            ? firstSymptoms
                  .asMap()
                  .entries
                  .map((entry) {
                    return {
                      'id': 'symptom-$index-${entry.key}',
                      'name': entry.value,
                    };
                  })
                  .toList(growable: false)
            : const <Map<String, Object>>[],
      };
    });
  }

  final resolvedConstitutionScores = constitutionScores.isNotEmpty
      ? constitutionScores
      : <Map<String, Object?>>[
          {
            'id': 'constitution-primary',
            'name': primaryConstitution,
            'score': healthScore,
            'solutions': therapySummary,
          },
          if (includeSecondaryConstitution)
            {
              'id': 'constitution-secondary',
              'name': secondaryConstitution,
              'score': healthScore - 12,
              'solutions': '',
            },
        ];
  final primaryConstitutionData = resolvedConstitutionScores.first;

  return DiagnosisReportDetail.fromJson({
    'id': id,
    'testTime': testTime,
    'imageUrl': imageUrl,
    'healthScore': healthScore,
    'riskIndexes': riskIndexes,
    'analysisResult': {
      'tz': {
        'id': primaryConstitutionData['id'] ?? 'constitution-primary',
        'name': primaryConstitutionData['name'] ?? primaryConstitution,
        'score': primaryConstitutionData['score'] ?? healthScore,
        'solutions': primaryConstitutionData['solutions'] ?? therapySummary,
      },
      'tzData': resolvedConstitutionScores,
      'symptoms': const <Map<String, Object>>[],
      'result': analysisFindings.isNotEmpty
          ? analysisFindings
          : findings(
              analysisFindingCount,
              summary,
              firstSymptoms: analysisFindingSymptoms,
            ),
      'relativeSyms': relativeSyms,
      'deepPredicts': {
        'categoryProbabilities': categoryProbabilities,
        'predictions': predictions,
        'diseases': <Map<String, Object>>[],
        if (riskIndexes.isNotEmpty) 'riskIndexes': riskIndexes,
      },
      'visceraRisk': '',
      'pos': const <String, Object>{},
    },
    'faceAnalysisResult': {
      'imageUrl': faceImageUrl,
      'age': faceAge,
      'sex': 'F',
      'sexDesc': 'Female',
      'result': findings(faceFindingCount, 'face-summary'),
    },
    'handAnalysisResult': {
      'imageUrl': handImageUrl,
      'age': faceAge,
      'sex': 'F',
      'sexDesc': 'Female',
      'result': findings(handFindingCount, 'hand-summary'),
    },
    'tzpdAnalysisResult': tzpdResults.isEmpty
        ? const <String, Object>{}
        : <String, Object?>{'results': tzpdResults},
    'saveReportUrl': '',
    'source': source,
    'token': '',
    'lockedStatus': 'UNLOCKED',
    'hideAge': hideAge,
    'tenantId': 'tenant-1',
    'storeId': 'store-1',
  });
}

ReportViewData buildReportViewData({
  String id = 'report-001',
  String testTime = '2026-04-17 10:30',
  String source = 'scan-booth',
  double healthScore = 82,
  String summary = 'Live summary insight',
  String primaryConstitution = 'Balanced',
  String secondaryConstitution = 'Qi deficiency',
  String therapySummary = 'Prefer warm meals and steady routines.',
  bool includeSecondaryConstitution = true,
  bool hideAge = false,
  int faceFindingCount = 2,
  int analysisFindingCount = 1,
  int handFindingCount = 1,
  double faceAge = 30,
  String imageUrl = '',
  String faceImageUrl = '',
  String handImageUrl = '',
  List<String> analysisFindingSymptoms = const ['舌边齿痕', '舌苔白'],
  List<Map<String, Object?>> analysisFindings = const [],
  List<Map<String, Object>> categoryProbabilities = const [],
  List<Map<String, Object>> riskIndexes = const [],
  List<Map<String, Object>> relativeSyms = const [],
  List<Map<String, Object>> predictions = const [],
  List<Map<String, Object?>> constitutionScores = const [],
  List<Map<String, Object?>> tzpdResults = const [],
}) {
  return ReportViewData.fromDetail(
    buildDiagnosisReportDetail(
      id: id,
      testTime: testTime,
      source: source,
      healthScore: healthScore,
      summary: summary,
      primaryConstitution: primaryConstitution,
      secondaryConstitution: secondaryConstitution,
      therapySummary: therapySummary,
      includeSecondaryConstitution: includeSecondaryConstitution,
      hideAge: hideAge,
      faceFindingCount: faceFindingCount,
      analysisFindingCount: analysisFindingCount,
      handFindingCount: handFindingCount,
      faceAge: faceAge,
      imageUrl: imageUrl,
      faceImageUrl: faceImageUrl,
      handImageUrl: handImageUrl,
      analysisFindingSymptoms: analysisFindingSymptoms,
      analysisFindings: analysisFindings,
      categoryProbabilities: categoryProbabilities,
      riskIndexes: riskIndexes,
      relativeSyms: relativeSyms,
      predictions: predictions,
      constitutionScores: constitutionScores,
      tzpdResults: tzpdResults,
    ),
  );
}
