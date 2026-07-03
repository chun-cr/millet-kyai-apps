// 报告模块数据模型：`ReportDetail`。用于承接接口原始字段，并在需要时转换为上层可消费的稳定结构。

import 'dart:math' as math;

class DiagnosisReportDetail {
  const DiagnosisReportDetail({
    required this.id,
    required this.testTime,
    required this.imageUrl,
    required this.healthScore,
    required this.analysisResult,
    required this.faceAnalysisResult,
    required this.handAnalysisResult,
    required this.tzpdAnalysisResult,
    required this.saveReportUrl,
    required this.source,
    required this.token,
    required this.lockedStatus,
    required this.hideAge,
    required this.tenantId,
    required this.storeId,
    required this.raw,
  });

  factory DiagnosisReportDetail.fromJson(Map<String, dynamic> json) {
    final analysisResultJson = _asMap(json['analysisResult']);
    final deepPredicts = _normalizeDeepPredictsFromRiskIndexes(
      _asMap(analysisResultJson['deepPredicts']).isNotEmpty
          ? _asMap(analysisResultJson['deepPredicts'])
          : _asMap(json['deepPredicts']),
      _resolveRiskIndexes(json, analysisResultJson),
    );
    final analysisResult = DiagnosisAnalysisResult.fromJson(<String, dynamic>{
      ...analysisResultJson,
      'deepPredicts': deepPredicts,
    });

    return DiagnosisReportDetail(
      id: _asString(json['id']),
      testTime: _asString(json['testTime']),
      imageUrl: _asString(json['imageUrl']),
      healthScore: _resolveHealthScore(json, analysisResult),
      analysisResult: analysisResult,
      faceAnalysisResult: DiagnosisAuxiliaryResult.fromJson(
        _asMap(json['faceAnalysisResult']),
      ),
      handAnalysisResult: DiagnosisAuxiliaryResult.fromJson(
        _asMap(json['handAnalysisResult']),
      ),
      tzpdAnalysisResult: _asMap(json['tzpdAnalysisResult']),
      saveReportUrl: _asString(json['saveReportUrl']),
      source: _asString(json['source']),
      token: _asString(json['token']),
      lockedStatus: _asString(json['lockedStatus']),
      hideAge: _asBool(json['hideAge']),
      tenantId: _asString(json['tenantId']).isNotEmpty
          ? _asString(json['tenantId'])
          : _asString(json['topOrgId']),
      storeId: _asString(json['storeId']).isNotEmpty
          ? _asString(json['storeId'])
          : _asString(json['clinicId']),
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String id;
  final String testTime;
  final String imageUrl;
  final double healthScore;
  final DiagnosisAnalysisResult analysisResult;
  final DiagnosisAuxiliaryResult faceAnalysisResult;
  final DiagnosisAuxiliaryResult handAnalysisResult;
  final Map<String, dynamic> tzpdAnalysisResult;
  final String saveReportUrl;
  final String source;
  final String token;
  final String lockedStatus;
  final bool hideAge;
  final String tenantId;
  final String storeId;
  final Map<String, dynamic> raw;

  bool get isLocked =>
      !(lockedStatus == '1' || lockedStatus == '9') &&
      lockedStatus != 'UNLOCKED';
}

class DiagnosisAnalysisResult {
  const DiagnosisAnalysisResult({
    required this.tz,
    required this.tzData,
    required this.symptoms,
    required this.result,
    required this.relativeSyms,
    required this.deepPredicts,
    required this.visceraRisk,
    required this.pos,
    required this.raw,
  });

  factory DiagnosisAnalysisResult.fromJson(Map<String, dynamic> json) {
    return DiagnosisAnalysisResult(
      tz: DiagnosisConstitution.fromJson(_asMap(json['tz'])),
      tzData: _asList(
        json['tzData'],
      ).map((item) => DiagnosisConstitution.fromJson(_asMap(item))).toList(),
      symptoms: _asList(
        json['symptoms'],
      ).map((item) => DiagnosisSymptom.fromJson(_asMap(item))).toList(),
      result: _asList(
        json['result'],
      ).map((item) => DiagnosisFinding.fromJson(_asMap(item))).toList(),
      relativeSyms: _asList(json['relativeSyms'])
          .map((item) => DiagnosisNamedProbability.fromJson(_asMap(item)))
          .toList(),
      deepPredicts: DiagnosisDeepPredicts.fromJson(
        _asMap(json['deepPredicts']),
      ),
      visceraRisk: _asString(json['visceraRisk']),
      pos: _asMap(json['pos']),
      raw: Map<String, dynamic>.from(json),
    );
  }

  final DiagnosisConstitution tz;
  final List<DiagnosisConstitution> tzData;
  final List<DiagnosisSymptom> symptoms;
  final List<DiagnosisFinding> result;
  final List<DiagnosisNamedProbability> relativeSyms;
  final DiagnosisDeepPredicts deepPredicts;
  final String visceraRisk;
  final Map<String, dynamic> pos;
  final Map<String, dynamic> raw;
}

class DiagnosisConstitution {
  const DiagnosisConstitution({
    required this.id,
    required this.name,
    required this.score,
    required this.solutions,
    required this.raw,
  });

  factory DiagnosisConstitution.fromJson(Map<String, dynamic> json) {
    return DiagnosisConstitution(
      id: _asString(json['id']),
      name: _asString(json['name']),
      score: _normalizePercent(_asNum(json['score'])),
      solutions: _asString(json['solutions']),
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String id;
  final String name;
  final double score;
  final String solutions;
  final Map<String, dynamic> raw;
}

class DiagnosisFinding {
  const DiagnosisFinding({
    required this.name,
    required this.result,
    required this.key,
    required this.symptoms,
    required this.raw,
  });

  factory DiagnosisFinding.fromJson(Map<String, dynamic> json) {
    final rawSymptoms = json['symptoms'];
    return DiagnosisFinding(
      name: _asString(json['name']).isNotEmpty
          ? _asString(json['name'])
          : _asString(json['typeDesc']),
      result: _asString(json['result']).isNotEmpty
          ? _asString(json['result'])
          : _asString(json['detail']),
      key: _asString(json['key']).isNotEmpty
          ? _asString(json['key'])
          : _asString(json['type']),
      symptoms: rawSymptoms is List
          ? rawSymptoms
                .map((item) => DiagnosisSymptom.fromJson(_asMap(item)))
                .toList()
          : rawSymptoms is String && rawSymptoms.trim().isNotEmpty
          ? <DiagnosisSymptom>[
              DiagnosisSymptom(
                id: '',
                name: rawSymptoms.trim(),
                raw: const <String, dynamic>{},
              ),
            ]
          : const <DiagnosisSymptom>[],
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String name;
  final String result;
  final String key;
  final List<DiagnosisSymptom> symptoms;
  final Map<String, dynamic> raw;
}

class DiagnosisSymptom {
  const DiagnosisSymptom({
    required this.id,
    required this.name,
    required this.raw,
  });

  factory DiagnosisSymptom.fromJson(Map<String, dynamic> json) {
    return DiagnosisSymptom(
      id: _asString(json['id']),
      name: _asString(json['name']),
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String id;
  final String name;
  final Map<String, dynamic> raw;
}

class DiagnosisDeepPredicts {
  const DiagnosisDeepPredicts({
    required this.categoryProbabilities,
    required this.predictions,
    required this.diseases,
    required this.raw,
  });

  factory DiagnosisDeepPredicts.fromJson(Map<String, dynamic> json) {
    return DiagnosisDeepPredicts(
      categoryProbabilities: _asList(json['categoryProbabilities'])
          .map((item) => DiagnosisNamedProbability.fromJson(_asMap(item)))
          .toList(),
      predictions: _asList(json['predictions'])
          .map((item) => DiagnosisNamedProbability.fromJson(_asMap(item)))
          .toList(),
      diseases: _asList(
        json['diseases'],
      ).map((item) => DiagnosisDisease.fromJson(_asMap(item))).toList(),
      raw: Map<String, dynamic>.from(json),
    );
  }

  final List<DiagnosisNamedProbability> categoryProbabilities;
  final List<DiagnosisNamedProbability> predictions;
  final List<DiagnosisDisease> diseases;
  final Map<String, dynamic> raw;
}

class DiagnosisNamedProbability {
  const DiagnosisNamedProbability({
    required this.id,
    required this.name,
    required this.rawProbability,
    required this.probability,
    required this.raw,
  });

  factory DiagnosisNamedProbability.fromJson(Map<String, dynamic> json) {
    final rawProbability = _normalizeProbability(
      _asNum(json['prob']) ?? _asNum(json['score']),
    );
    return DiagnosisNamedProbability(
      id: _asString(json['id']),
      name: _asString(json['name']),
      rawProbability: rawProbability,
      probability: rawProbability * 100,
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String id;
  final String name;
  final double rawProbability;
  final double probability;
  final Map<String, dynamic> raw;
}

class DiagnosisDisease {
  const DiagnosisDisease({
    required this.id,
    required this.name,
    required this.probability,
    required this.raw,
  });

  factory DiagnosisDisease.fromJson(Map<String, dynamic> json) {
    return DiagnosisDisease(
      id: _asString(json['id']),
      name: _asString(json['name']),
      probability: _normalizePercent(_asNum(json['prob'])),
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String id;
  final String name;
  final double probability;
  final Map<String, dynamic> raw;
}

class DiagnosisAuxiliaryResult {
  const DiagnosisAuxiliaryResult({
    required this.imageUrl,
    required this.age,
    required this.sex,
    required this.sexDesc,
    required this.result,
    required this.raw,
  });

  factory DiagnosisAuxiliaryResult.fromJson(Map<String, dynamic> json) {
    return DiagnosisAuxiliaryResult(
      imageUrl: _asString(json['imageUrl']),
      age: _asNum(json['age'])?.toDouble(),
      sex: _asString(json['sex']),
      sexDesc: _asString(json['sexDesc']).isNotEmpty
          ? _asString(json['sexDesc'])
          : _sexDescription(_asString(json['sex'])),
      result: _asList(
        json['result'],
      ).map((item) => DiagnosisFinding.fromJson(_asMap(item))).toList(),
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String imageUrl;
  final double? age;
  final String sex;
  final String sexDesc;
  final List<DiagnosisFinding> result;
  final Map<String, dynamic> raw;
}

class DiagnosisReportSummary {
  const DiagnosisReportSummary({
    required this.id,
    required this.testTime,
    required this.healthScore,
    required this.physiqueName,
    required this.imageUrl,
    required this.faceImageUrl,
    required this.lockedStatus,
    required this.deepPredicts,
    required this.raw,
  });

  factory DiagnosisReportSummary.fromJson(Map<String, dynamic> json) {
    final tongue = _asMap(json['tongue']);
    final face = _asMap(json['face']);
    final faceAnalysisResult = _asMap(json['faceAnalysisResult']);
    final analysisResult = _asMap(json['analysisResult']);
    final deepPredicts = _normalizeDeepPredictsFromRiskIndexes(
      _asMap(json['deepPredicts']).isNotEmpty
          ? _asMap(json['deepPredicts'])
          : _asMap(tongue['deepPredicts']),
      _asList(json['riskIndexes']).isNotEmpty
          ? _asList(json['riskIndexes'])
          : _asList(tongue['riskIndexes']),
    );

    return DiagnosisReportSummary(
      id: _asString(json['id']),
      testTime: _asString(json['testTime']),
      healthScore: _resolveSummaryHealthScore(json, analysisResult),
      physiqueName: _resolveSummaryPhysiqueName(json, analysisResult),
      imageUrl: _firstNonEmptyString(<String>[
        _asString(json['imageUrl']),
        _asString(tongue['imageUrl']),
        _asString(tongue['thumbImageUrl']),
        _asString(face['imageUrl']),
        _asString(face['thumbImageUrl']),
      ]),
      faceImageUrl: _firstNonEmptyString(<String>[
        _asString(json['faceImageUrl']),
        _asString(faceAnalysisResult['imageUrl']),
        _asString(faceAnalysisResult['thumbImageUrl']),
        _asString(face['imageUrl']),
        _asString(face['thumbImageUrl']),
      ]),
      lockedStatus: _asString(json['lockedStatus']),
      deepPredicts: DiagnosisDeepPredicts.fromJson(deepPredicts),
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String id;
  final String testTime;
  final double healthScore;
  final String physiqueName;
  final String imageUrl;
  final String faceImageUrl;
  final String lockedStatus;
  final DiagnosisDeepPredicts deepPredicts;
  final Map<String, dynamic> raw;

  DiagnosisReportSummary copyWith({String? faceImageUrl}) {
    return DiagnosisReportSummary(
      id: id,
      testTime: testTime,
      healthScore: healthScore,
      physiqueName: physiqueName,
      imageUrl: imageUrl,
      faceImageUrl: faceImageUrl ?? this.faceImageUrl,
      lockedStatus: lockedStatus,
      deepPredicts: deepPredicts,
      raw: raw,
    );
  }

  bool get isLocked =>
      !(lockedStatus == '1' || lockedStatus == '9') &&
      lockedStatus != 'UNLOCKED';
}

class DiagnosisMaNavigate {
  const DiagnosisMaNavigate({
    required this.type,
    required this.appId,
    required this.path,
    required this.imageUrl,
    required this.imageTitle,
    required this.title,
    required this.raw,
  });

  factory DiagnosisMaNavigate.fromJson(Map<String, dynamic> json) {
    return DiagnosisMaNavigate(
      type: _asString(json['type']),
      appId: _asString(json['appId']),
      path: _asString(json['path']),
      imageUrl: _asString(json['imageUrl']),
      imageTitle: _asString(json['imageTitle']),
      title: _asString(json['title']),
      raw: Map<String, dynamic>.from(json),
    );
  }

  final String type;
  final String appId;
  final String path;
  final String imageUrl;
  final String imageTitle;
  final String title;
  final Map<String, dynamic> raw;

  bool get hasImage => imageUrl.isNotEmpty;

  bool get hasMiniProgram => type == 'M';

  String get displayTitle {
    if (imageTitle.trim().isNotEmpty) {
      return imageTitle;
    }
    if (title.trim().isNotEmpty) {
      return title;
    }
    return '专家解读';
  }
}

class DiagnosisReportShareQrCode {
  const DiagnosisReportShareQrCode({
    required this.imageUrl,
    required this.imageBase64,
    required this.shareUrl,
    required this.shareText,
    required this.raw,
  });

  factory DiagnosisReportShareQrCode.fromDynamic(Object? value) {
    final payload = _asMap(value);
    if (payload.isNotEmpty) {
      final directQrValue = _firstNonEmptyString(<String>[
        _asString(payload['qrCode']),
        _asString(payload['qrcode']),
      ]);
      final imageUrlCandidate = _firstNonEmptyString(<String>[
        _asString(payload['imageUrl']),
        _asString(payload['qrCodeUrl']),
        _asString(payload['qrcodeUrl']),
        _asString(payload['qrCodeImageUrl']),
        _asString(payload['qrcodeImageUrl']),
        _asString(payload['imgUrl']),
        _asString(payload['image']),
        if (_looksLikeUrl(directQrValue)) directQrValue,
        if (_looksLikeUrl(_asString(payload['url']))) _asString(payload['url']),
      ]);
      final imageBase64Candidate = _normalizeBase64Image(
        _firstNonEmptyString(<String>[
          _asString(payload['imageBase64']),
          _asString(payload['base64Image']),
          _asString(payload['base64']),
          _asString(payload['qrCodeBase64']),
          _asString(payload['qrcodeBase64']),
          _asString(payload['imgBase64']),
          if (_looksLikeImageDataUri(directQrValue) ||
              _looksLikeBase64Payload(directQrValue))
            directQrValue,
        ]),
      );
      final shareUrlCandidate = _firstNonEmptyString(<String>[
        _asString(payload['shareUrl']),
        _asString(payload['link']),
        _asString(payload['landingPage']),
        _asString(payload['pageUrl']),
        _asString(payload['url']),
      ]);
      final shareTextCandidate = _firstNonEmptyString(<String>[
        _asString(payload['shareText']),
        _asString(payload['content']),
        _asString(payload['text']),
        _asString(payload['message']),
      ]);

      return DiagnosisReportShareQrCode(
        imageUrl: imageUrlCandidate,
        imageBase64: imageBase64Candidate,
        shareUrl: shareUrlCandidate,
        shareText: shareTextCandidate,
        raw: payload,
      );
    }

    final scalarValue = _asString(value).trim();
    if (scalarValue.isEmpty) {
      return const DiagnosisReportShareQrCode(
        imageUrl: '',
        imageBase64: '',
        shareUrl: '',
        shareText: '',
        raw: <String, dynamic>{},
      );
    }

    return DiagnosisReportShareQrCode(
      imageUrl: _looksLikeUrl(scalarValue) ? scalarValue : '',
      imageBase64: _normalizeBase64Image(scalarValue),
      shareUrl: _looksLikeUrl(scalarValue) ? scalarValue : '',
      shareText: _looksLikeUrl(scalarValue) ? '' : scalarValue,
      raw: <String, dynamic>{'value': scalarValue},
    );
  }

  final String imageUrl;
  final String imageBase64;
  final String shareUrl;
  final String shareText;
  final Map<String, dynamic> raw;

  bool get hasImageUrl => imageUrl.trim().isNotEmpty;

  bool get hasImageBase64 => imageBase64.trim().isNotEmpty;

  bool get hasDisplayableImage => hasImageUrl || hasImageBase64;

  String get copyValue => shareUrl.trim().isNotEmpty ? shareUrl : shareText;
}

double _resolveSummaryHealthScore(
  Map<String, dynamic> json,
  Map<String, dynamic> analysisResult,
) {
  final constitution = _asMap(analysisResult['tz']);
  final score =
      _asNum(json['healthScore']) ??
      _asNum(json['score']) ??
      _asNum(analysisResult['score']) ??
      _asNum(constitution['score']);
  return _normalizePercent(score);
}

String _resolveSummaryPhysiqueName(
  Map<String, dynamic> json,
  Map<String, dynamic> analysisResult,
) {
  final constitution = _asMap(analysisResult['tz']);
  return _firstNonEmptyString(<String>[
    _asString(json['physiqueName']),
    _asString(json['physiqueDesc']),
    _asString(json['tzName']),
    _asString(constitution['name']),
  ]);
}

Map<String, dynamic> _normalizeDeepPredictsFromRiskIndexes(
  Map<String, dynamic> deepPredicts,
  List<dynamic> riskIndexes,
) {
  if (_asList(deepPredicts['categoryProbabilities']).isNotEmpty) {
    return deepPredicts;
  }

  if (riskIndexes.isEmpty) {
    return deepPredicts;
  }

  final categoryProbabilities = riskIndexes
      .map((item) {
        final value = _asMap(item);
        final score = _asNum(value['score']);
        final prob = _asNum(value['prob']);
        final normalizedProb = score != null
            ? score.toDouble() / 100
            : prob != null && prob > 1
            ? prob.toDouble() / 100
            : (prob?.toDouble() ?? 0);

        return <String, dynamic>{
          ...value,
          'name': _firstNonEmptyString(<String>[
            _asString(value['displayName']),
            _asString(value['name']),
            _asString(value['sourceKey']),
          ]),
          'prob': normalizedProb,
        };
      })
      .toList(growable: false);

  final categoryRisk = categoryProbabilities.fold<double>(
    0,
    (current, item) =>
        math.max(current, (_asNum(_asMap(item)['prob']) ?? 0).toDouble()),
  );

  return <String, dynamic>{
    ...deepPredicts,
    'categoryProbabilities': categoryProbabilities,
    'categoryRisk': categoryRisk,
  };
}

List<dynamic> _resolveRiskIndexes(
  Map<String, dynamic> json,
  Map<String, dynamic> analysisResult,
) {
  final topLevelRiskIndexes = _asList(json['riskIndexes']);
  if (topLevelRiskIndexes.isNotEmpty) {
    return topLevelRiskIndexes;
  }

  final analysisRiskIndexes = _asList(analysisResult['riskIndexes']);
  if (analysisRiskIndexes.isNotEmpty) {
    return analysisRiskIndexes;
  }

  final tongue = _asMap(json['tongue']);
  final tongueRiskIndexes = _asList(tongue['riskIndexes']);
  if (tongueRiskIndexes.isNotEmpty) {
    return tongueRiskIndexes;
  }

  return const <dynamic>[];
}

double _resolveHealthScore(
  Map<String, dynamic> json,
  DiagnosisAnalysisResult analysisResult,
) {
  final score =
      _asNum(json['healthScore']) ??
      _asNum(analysisResult.raw['score']) ??
      _asNum(json['score']);
  return _normalizePercent(score);
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

String _asString(Object? value) {
  if (value == null) {
    return '';
  }
  return value.toString();
}

num? _asNum(Object? value) {
  if (value is num) {
    return value;
  }
  if (value is String) {
    return num.tryParse(value);
  }
  return null;
}

bool _asBool(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    return value == 'true' || value == '1';
  }
  return false;
}

double _normalizePercent(num? value) {
  if (value == null) {
    return 0;
  }
  final normalized = value.toDouble();
  if (normalized <= 1) {
    return normalized * 100;
  }
  if (normalized <= 100) {
    return normalized;
  }
  return 100;
}

double _normalizeProbability(num? value) {
  if (value == null) {
    return 0;
  }
  final normalized = value.toDouble();
  if (normalized <= 1) {
    return normalized.clamp(0, 1).toDouble();
  }
  if (normalized <= 100) {
    return (normalized / 100).clamp(0, 1).toDouble();
  }
  return 1;
}

String _firstNonEmptyString(List<String> values) {
  for (final value in values) {
    if (value.trim().isNotEmpty) {
      return value;
    }
  }
  return '';
}

String _sexDescription(String sex) {
  return switch (sex.toUpperCase()) {
    'F' => 'Female',
    'M' => 'Male',
    _ => sex,
  };
}

bool _looksLikeUrl(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized.startsWith('https://') || normalized.startsWith('http://');
}

bool _looksLikeImageDataUri(String value) {
  return value.trim().toLowerCase().startsWith('data:image/');
}

bool _looksLikeBase64Payload(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.contains(' ')) {
    return false;
  }
  return RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(normalized);
}

String _normalizeBase64Image(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return '';
  }
  if (_looksLikeImageDataUri(normalized) ||
      _looksLikeBase64Payload(normalized)) {
    return normalized;
  }
  return '';
}
