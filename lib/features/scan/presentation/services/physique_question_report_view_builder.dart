import '../../../../features/report/data/models/report_detail.dart';
import '../../../../features/report/presentation/pages/report/report_view_data.dart';
import '../../data/models/physique_question_models.dart';
import '../../data/models/scan_session.dart';

ReportViewData? buildPhysiqueQuestionCompletionReportViewData({
  required ScanSession scanSession,
  required PhysiqueQuestionFlowSnapshot snapshot,
  required String reportId,
}) {
  final completedResult =
      snapshot.completedResult ?? scanSession.questionCompletionResult;
  if (completedResult == null || !_hasCompletionReportData(completedResult)) {
    return null;
  }

  final payload = buildPhysiqueQuestionCompletionReportPayload(
    scanSession: scanSession,
    completedResult: completedResult,
    reportId: reportId,
  );
  if (payload == null) {
    return null;
  }

  return ReportViewData.fromDetail(DiagnosisReportDetail.fromJson(payload));
}

Map<String, dynamic>? buildPhysiqueQuestionCompletionReportPayload({
  required ScanSession scanSession,
  required Map<String, dynamic> completedResult,
  required String reportId,
}) {
  final normalizedReportId = reportId.trim();
  if (normalizedReportId.isEmpty ||
      !_hasCompletionReportData(completedResult)) {
    return null;
  }

  final completion = _deepCopyMap(completedResult);
  final tongueData = _deepCopyMap(
    scanSession.tongueUpload?.data ?? const <String, dynamic>{},
  );
  final payload = _deepCopyMap(tongueData);
  for (final key in const <String>[
    'testTime',
    'token',
    'lockedStatus',
    'saveReportUrl',
    'source',
    'tenantId',
    'storeId',
    'topOrgId',
    'clinicId',
  ]) {
    _copyPresentField(payload, completion, key);
  }

  payload['id'] = normalizedReportId;
  payload['reportId'] = normalizedReportId;
  payload['source'] = _firstNonEmptyString(<Object?>[
    payload['source'],
    ScanSession.reportSource,
  ]);
  _setIfPresent(payload, 'tenantId', scanSession.tenantId);
  _setIfPresent(payload, 'storeId', scanSession.storeId);
  _setIfPresent(payload, 'topOrgId', scanSession.topOrgId);
  _setIfPresent(payload, 'clinicId', scanSession.clinicId);

  final imageUrl = _firstNonEmptyString(<Object?>[
    completion['imageUrl'],
    payload['imageUrl'],
    scanSession.tongueUpload?.imageUrl,
    _readPath(tongueData, 'analysisResult.imageUrl'),
    _readPath(tongueData, 'tongueReport.imageUrl'),
  ]);
  if (imageUrl.isNotEmpty) {
    payload['imageUrl'] = imageUrl;
  }

  final physiqueResults = _resolvePhysiqueResults(completion);
  final analysisResult = _buildAnalysisResult(
    tongueData: tongueData,
    completion: completion,
    physiqueResults: physiqueResults,
  );
  payload['analysisResult'] = analysisResult;
  payload['tzpdAnalysisResult'] = _buildTzpdAnalysisResult(
    payload: payload,
    completion: completion,
    physiqueResults: physiqueResults,
  );
  payload['faceAnalysisResult'] = _buildFaceAnalysisResult(
    scanSession: scanSession,
    payload: payload,
    completion: completion,
  );
  payload['handAnalysisResult'] = _deepCopyMap(
    _firstMap(<Object?>[
      completion['handAnalysisResult'],
      payload['handAnalysisResult'],
      _readPath(tongueData, 'handAnalysisResult'),
    ]),
  );

  final healthScore = _firstValue(<Object?>[
    completion['healthScore'],
    completion['score'],
    payload['healthScore'],
    analysisResult['healthScore'],
    analysisResult['score'],
  ]);
  if (healthScore != null) {
    payload['healthScore'] = healthScore;
  }

  return payload;
}

Map<String, dynamic> _buildAnalysisResult({
  required Map<String, dynamic> tongueData,
  required Map<String, dynamic> completion,
  required List<Map<String, dynamic>> physiqueResults,
}) {
  final analysisResult = _deepCopyMap(
    _firstMap(<Object?>[
      tongueData['analysisResult'],
      _readPath(tongueData, 'result.analysisResult'),
      _readPath(tongueData, 'diagnosisReport.analysisResult'),
    ]),
  );
  analysisResult.addAll(
    _deepCopyMap(_firstMap(<Object?>[completion['analysisResult']])),
  );

  final deepPredicts = _firstMap(<Object?>[
    analysisResult['deepPredicts'],
    completion['deepPredicts'],
  ]);
  if (deepPredicts.isNotEmpty) {
    analysisResult['deepPredicts'] = _deepCopyMap(deepPredicts);
  }

  _copyPresentField(analysisResult, completion, 'visceraRisk');
  _copyPresentField(analysisResult, completion, 'pos');
  if (_asList(analysisResult['relativeSyms']).isEmpty) {
    final relativeSymptoms = _asList(completion['relativeSymptoms']);
    if (relativeSymptoms.isNotEmpty) {
      analysisResult['relativeSyms'] = _deepCopyList(relativeSymptoms);
    }
  }

  if (physiqueResults.isNotEmpty) {
    analysisResult['physiqueResults'] = _deepCopyList(physiqueResults);
  }

  final primary = _resolvePrimaryConstitution(completion, physiqueResults);
  if (primary.isNotEmpty) {
    analysisResult['tz'] = <String, dynamic>{
      ..._asMap(analysisResult['tz']),
      ...primary,
    };
  }

  analysisResult['includeQuestions'] = true;
  return analysisResult;
}

Map<String, dynamic> _buildTzpdAnalysisResult({
  required Map<String, dynamic> payload,
  required Map<String, dynamic> completion,
  required List<Map<String, dynamic>> physiqueResults,
}) {
  final tzpdAnalysisResult = _deepCopyMap(
    _firstMap(<Object?>[
      payload['tzpdAnalysisResult'],
      completion['tzpdAnalysisResult'],
    ]),
  );
  final completedTzpd = _asMap(completion['tzpdAnalysisResult']);
  if (completedTzpd.isNotEmpty) {
    tzpdAnalysisResult.addAll(_deepCopyMap(completedTzpd));
  }
  if (physiqueResults.isNotEmpty) {
    tzpdAnalysisResult['results'] = _deepCopyList(physiqueResults);
  }
  return tzpdAnalysisResult;
}

Map<String, dynamic> _buildFaceAnalysisResult({
  required ScanSession scanSession,
  required Map<String, dynamic> payload,
  required Map<String, dynamic> completion,
}) {
  final face = _deepCopyMap(
    _firstMap(<Object?>[
      completion['faceAnalysisResult'],
      payload['faceAnalysisResult'],
      scanSession.faceUpload?.data,
    ]),
  );

  final faceImageUrl = _firstNonEmptyString(<Object?>[
    face['imageUrl'],
    scanSession.faceUpload?.imageUrl,
  ]);
  if (faceImageUrl.isNotEmpty) {
    face['imageUrl'] = faceImageUrl;
  }
  final age = _firstValue(<Object?>[
    completion['age'],
    face['age'],
    scanSession.detectedAge,
  ]);
  if (age != null) {
    face['age'] = age;
  }
  final sex = _firstNonEmptyString(<Object?>[
    completion['sex'],
    completion['gender'],
    face['sex'],
    scanSession.questionGender,
    scanSession.detectedGender,
  ]);
  if (sex.isNotEmpty) {
    face['sex'] = sex;
  }
  return face;
}

Map<String, dynamic> _resolvePrimaryConstitution(
  Map<String, dynamic> completion,
  List<Map<String, dynamic>> physiqueResults,
) {
  final phyType = _firstNonEmptyString(<Object?>[
    completion['phyType'],
    completion['physiqueId'],
    completion['physicalId'],
    completion['constitutionId'],
  ]);
  final phyName = _firstNonEmptyString(<Object?>[
    completion['phyName'],
    completion['phyTypeName'],
    completion['physiqueName'],
    completion['constitutionName'],
    completion['tzName'],
  ]);

  Map<String, dynamic> selected = const <String, dynamic>{};
  for (final item in physiqueResults) {
    final id = _constitutionId(item);
    final name = _constitutionName(item);
    if ((phyType.isNotEmpty && id == phyType) ||
        (phyName.isNotEmpty && name == phyName)) {
      selected = item;
      break;
    }
  }
  if (selected.isEmpty && physiqueResults.isNotEmpty) {
    selected = physiqueResults.reduce((left, right) {
      return _constitutionScore(right) > _constitutionScore(left)
          ? right
          : left;
    });
  }

  final normalized = _normalizeConstitution(selected);
  if (phyType.isNotEmpty) {
    if (_looksNumeric(phyType)) {
      normalized.putIfAbsent('id', () => phyType);
    } else {
      normalized.putIfAbsent('name', () => phyType);
    }
  }
  if (phyName.isNotEmpty) {
    normalized['name'] = phyName;
  }
  return normalized;
}

List<Map<String, dynamic>> _resolvePhysiqueResults(
  Map<String, dynamic> completion,
) {
  for (final value in <Object?>[
    completion['physiqueResults'],
    _readPath(completion, 'tzpdAnalysisResult.results'),
    _readPath(completion, 'analysisResult.physiqueResults'),
  ]) {
    final items = _asListOfMaps(value);
    if (items.isNotEmpty) {
      return items;
    }
  }
  return const <Map<String, dynamic>>[];
}

Map<String, dynamic> _normalizeConstitution(Map<String, dynamic> item) {
  if (item.isEmpty) {
    return <String, dynamic>{};
  }
  final normalized = <String, dynamic>{...item};
  final id = _constitutionId(item);
  final name = _constitutionName(item);
  final score = _firstValue(<Object?>[
    item['score'],
    item['prob'],
    item['percent'],
    item['ratio'],
    item['value'],
  ]);
  if (id.isNotEmpty) {
    normalized['id'] = id;
  }
  if (name.isNotEmpty) {
    normalized['name'] = name;
  }
  if (score != null) {
    normalized['score'] = score;
  }
  return normalized;
}

String _constitutionId(Map<String, dynamic> value) {
  return _firstNonEmptyString(<Object?>[
    value['id'],
    value['physiqueId'],
    value['constitutionId'],
    value['tzId'],
    value['typeId'],
    value['phyType'],
    value['physicalId'],
    value['type'],
  ]);
}

String _constitutionName(Map<String, dynamic> value) {
  return _firstNonEmptyString(<Object?>[
    value['name'],
    value['phyName'],
    value['phyTypeName'],
    value['physiqueName'],
    value['constitutionName'],
    value['tzName'],
    value['typeName'],
    value['displayName'],
    value['physicalName'],
  ]);
}

double _constitutionScore(Map<String, dynamic> value) {
  final score = _firstValue(<Object?>[
    value['score'],
    value['prob'],
    value['percent'],
    value['ratio'],
    value['value'],
  ]);
  if (score is num) {
    return score.toDouble();
  }
  if (score is String) {
    return double.tryParse(score) ?? 0;
  }
  return 0;
}

bool _hasCompletionReportData(Map<String, dynamic> result) {
  return _asList(result['physiqueResults']).isNotEmpty ||
      _asMap(result['analysisResult']).isNotEmpty ||
      _asMap(result['tzpdAnalysisResult']).isNotEmpty ||
      _firstNonEmptyString(<Object?>[
        result['phyType'],
        result['physiqueName'],
        result['imageUrl'],
        result['name'],
        result['age'],
        result['sex'],
      ]).isNotEmpty;
}

void _copyPresentField(
  Map<String, dynamic> target,
  Map<String, dynamic> source,
  String key,
) {
  if (!_isPresent(source[key])) {
    return;
  }
  target[key] = _deepCopy(source[key]);
}

void _setIfPresent(Map<String, dynamic> target, String key, Object? value) {
  if (_isPresent(value)) {
    target[key] = value;
  }
}

bool _isPresent(Object? value) {
  if (value == null) {
    return false;
  }
  if (value is String) {
    return value.trim().isNotEmpty;
  }
  return true;
}

bool _looksNumeric(String value) => num.tryParse(value.trim()) != null;

Object? _firstValue(List<Object?> values) {
  for (final value in values) {
    if (_isPresent(value)) {
      return value;
    }
  }
  return null;
}

String _firstNonEmptyString(List<Object?> values) {
  for (final value in values) {
    if (value == null) {
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty) {
      return text;
    }
  }
  return '';
}

Map<String, dynamic> _firstMap(List<Object?> values) {
  for (final value in values) {
    final map = _asMap(value);
    if (map.isNotEmpty) {
      return map;
    }
  }
  return const <String, dynamic>{};
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

List<dynamic> _asList(Object? value) {
  if (value is List) {
    return value;
  }
  return const <dynamic>[];
}

List<Map<String, dynamic>> _asListOfMaps(Object? value) {
  return _asList(value)
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

Object? _readPath(Map<String, dynamic> source, String path) {
  final parts = path.split('.');
  Object? current = source;
  for (final part in parts) {
    if (current is Map<String, dynamic>) {
      current = current[part];
      continue;
    }
    if (current is Map) {
      current = Map<String, dynamic>.from(current)[part];
      continue;
    }
    return null;
  }
  return current;
}

Object? _deepCopy(Object? value) {
  if (value is Map<String, dynamic>) {
    return _deepCopyMap(value);
  }
  if (value is Map) {
    return _deepCopyMap(Map<String, dynamic>.from(value));
  }
  if (value is List) {
    return _deepCopyList(value);
  }
  return value;
}

Map<String, dynamic> _deepCopyMap(Map<String, dynamic> value) {
  return value.map((key, item) => MapEntry(key, _deepCopy(item)));
}

List<dynamic> _deepCopyList(List<dynamic> value) {
  return value.map(_deepCopy).toList(growable: false);
}
