// 扫描模块数据模型：`PhysiqueQuestionModels`。用于承接接口原始字段，并在需要时转换为上层可消费的稳定结构。

class PhysiqueQuestionRequestAnswer {
  const PhysiqueQuestionRequestAnswer({
    required this.id,
    required this.optionValue,
  });

  final int id;
  final String optionValue;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'optionValue': optionValue};
  }
}

class PhysiqueQuestionRequestContext {
  const PhysiqueQuestionRequestContext({
    required this.gender,
    required this.phyCategory,
    this.age,
    this.birthyear,
    this.clinicId,
    this.exact,
    this.medicalCaseId,
    this.name,
    this.phone,
    this.tongueReportId,
    this.topOrgId,
  });

  final int? age;
  final String? birthyear;
  final int? clinicId;
  final String? exact;
  final String gender;
  final int? medicalCaseId;
  final String? name;
  final String? phone;
  final String phyCategory;
  final int? tongueReportId;
  final int? topOrgId;

  PhysiqueQuestionRequest buildRequest({
    required List<PhysiqueQuestionRequestAnswer> answers,
    String? amenorrhea,
  }) {
    return PhysiqueQuestionRequest(
      age: age,
      amenorrhea: amenorrhea,
      answers: answers,
      birthyear: birthyear,
      clinicId: clinicId,
      exact: exact,
      gender: gender,
      medicalCaseId: medicalCaseId,
      name: name,
      phone: phone,
      phyCategory: phyCategory,
      tongueReportId: tongueReportId,
      topOrgId: topOrgId,
    );
  }
}

class PhysiqueQuestionRequest {
  const PhysiqueQuestionRequest({
    required this.gender,
    required this.phyCategory,
    this.age,
    this.amenorrhea,
    this.answers = const <PhysiqueQuestionRequestAnswer>[],
    this.birthyear,
    this.clinicId,
    this.exact,
    this.medicalCaseId,
    this.name,
    this.phone,
    this.tongueReportId,
    this.topOrgId,
  });

  final int? age;
  final String? amenorrhea;
  final List<PhysiqueQuestionRequestAnswer> answers;
  final String? birthyear;
  final int? clinicId;
  final String? exact;
  final String gender;
  final int? medicalCaseId;
  final String? name;
  final String? phone;
  final String phyCategory;
  final int? tongueReportId;
  final int? topOrgId;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'gender': gender,
      'phyCategory': phyCategory,
      if (age != null) 'age': age,
      if (_isPresent(amenorrhea)) 'amenorrhea': amenorrhea,
      if (answers.isNotEmpty)
        'answers': answers.map((item) => item.toJson()).toList(growable: false),
      if (_isPresent(birthyear)) 'birthyear': birthyear,
      if (clinicId != null) 'clinicId': clinicId,
      if (_isPresent(exact)) 'exact': exact,
      if (medicalCaseId != null) 'medicalCaseId': medicalCaseId,
      if (_isPresent(name)) 'name': name,
      if (_isPresent(phone)) 'phone': phone,
      if (tongueReportId != null) 'tongueReportId': tongueReportId,
      if (topOrgId != null) 'topOrgId': topOrgId,
    };
    return data;
  }
}

class PhysiqueQuestionEnvelope {
  const PhysiqueQuestionEnvelope({
    this.code,
    this.data = const <String, dynamic>{},
    this.message,
    this.messageKey,
    this.requestId,
  });

  factory PhysiqueQuestionEnvelope.fromJson(Map<String, dynamic> json) {
    return PhysiqueQuestionEnvelope(
      code: _asInt(json['code']),
      data: _asMap(json['data']),
      message: _asNullableString(json['message']),
      messageKey: _asNullableString(json['messageKey']),
      requestId: _asNullableString(json['requestId']),
    );
  }

  final int? code;
  final Map<String, dynamic> data;
  final String? message;
  final String? messageKey;
  final String? requestId;
}

class PhysiqueQuestionFlowResult {
  const PhysiqueQuestionFlowResult({
    required this.rawData,
    this.question,
    this.reportId,
  });

  factory PhysiqueQuestionFlowResult.fromData(Map<String, dynamic> data) {
    final question = PhysiqueQuestionPayload.fromData(data);
    return PhysiqueQuestionFlowResult(
      rawData: data,
      question: question.hasRenderableQuestion ? question : null,
      reportId: _firstNonEmptyString(<Object?>[
        data['reportId'],
        _readPath(data, 'report.reportId'),
        _readPath(data, 'tongueReport.reportId'),
        _readPath(data, 'result.reportId'),
      ]),
    );
  }

  final PhysiqueQuestionPayload? question;
  final String? reportId;
  final Map<String, dynamic> rawData;

  bool get isCompleted => question == null;
}

class PhysiqueQuestionPayload {
  const PhysiqueQuestionPayload({
    required this.raw,
    required this.options,
    this.id,
    this.title = '',
    this.description = '',
    this.fieldCode = '',
    this.currentIndex,
    this.totalCount,
  });

  factory PhysiqueQuestionPayload.fromData(Map<String, dynamic> data) {
    final questionMap = _resolveQuestionMap(data);
    final optionMaps = _resolveOptionMaps(questionMap);
    return PhysiqueQuestionPayload(
      raw: questionMap,
      id: _firstInt(<Object?>[
        questionMap['id'],
        questionMap['questionId'],
        questionMap['subjectId'],
      ]),
      title: _firstNonEmptyString(<Object?>[
        questionMap['title'],
        questionMap['questionTitle'],
        questionMap['questionText'],
        questionMap['content'],
        questionMap['name'],
      ]),
      description: _firstNonEmptyString(<Object?>[
        questionMap['description'],
        questionMap['subtitle'],
        questionMap['tip'],
        questionMap['tips'],
        questionMap['helpText'],
      ]),
      fieldCode: _firstNonEmptyString(<Object?>[
        questionMap['fieldCode'],
        questionMap['questionCode'],
        questionMap['code'],
        questionMap['key'],
        questionMap['slug'],
      ]),
      currentIndex: _firstInt(<Object?>[
        questionMap['currentIndex'],
        questionMap['questionIndex'],
        data['currentIndex'],
        data['index'],
      ]),
      totalCount: _firstInt(<Object?>[
        questionMap['totalCount'],
        questionMap['questionTotal'],
        data['totalCount'],
        data['total'],
      ]),
      options: optionMaps
          .map(PhysiqueQuestionOption.fromJson)
          .where((item) => item.value.isNotEmpty && item.label.isNotEmpty)
          .toList(growable: false),
    );
  }

  final int? id;
  final String title;
  final String description;
  final String fieldCode;
  final int? currentIndex;
  final int? totalCount;
  final List<PhysiqueQuestionOption> options;
  final Map<String, dynamic> raw;

  bool get hasRenderableQuestion =>
      id != null && title.trim().isNotEmpty && options.isNotEmpty;

  bool get isAmenorrheaQuestion {
    final normalizedFieldCode = fieldCode.toLowerCase();
    if (normalizedFieldCode.contains('amenorrhea')) {
      return true;
    }
    return title.contains('闭经');
  }
}

class PhysiqueQuestionOption {
  const PhysiqueQuestionOption({
    required this.value,
    required this.label,
    this.description = '',
    this.raw = const <String, dynamic>{},
  });

  factory PhysiqueQuestionOption.fromJson(Map<String, dynamic> json) {
    return PhysiqueQuestionOption(
      value: _firstNonEmptyString(<Object?>[
        json['optionValue'],
        json['value'],
        json['code'],
        json['id'],
      ]),
      label: _firstNonEmptyString(<Object?>[
        json['optionName'],
        json['label'],
        json['name'],
        json['title'],
        json['content'],
        json['description'],
      ]),
      description: _firstNonEmptyString(<Object?>[
        json['desc'],
        json['helpText'],
        json['tip'],
      ]),
      raw: json,
    );
  }

  final String value;
  final String label;
  final String description;
  final Map<String, dynamic> raw;
}

bool _isPresent(String? value) => value != null && value.trim().isNotEmpty;

Map<String, dynamic> _resolveQuestionMap(Map<String, dynamic> data) {
  final nested = <Object?>[
    data['question'],
    data['currentQuestion'],
    data['nextQuestion'],
    data['item'],
  ];
  for (final value in nested) {
    final map = _asMap(value);
    if (map.isNotEmpty) {
      return map;
    }
  }
  return data;
}

List<Map<String, dynamic>> _resolveOptionMaps(
  Map<String, dynamic> questionMap,
) {
  final values = <Object?>[
    questionMap['options'],
    questionMap['optionList'],
    questionMap['questionOptions'],
    questionMap['items'],
  ];
  for (final value in values) {
    final list = _asListOfMaps(value);
    if (list.isNotEmpty) {
      return list;
    }
  }
  return const <Map<String, dynamic>>[];
}

List<Map<String, dynamic>> _asListOfMaps(Object? value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
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

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

int? _firstInt(List<Object?> values) {
  for (final value in values) {
    final parsed = _asInt(value);
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

String _firstNonEmptyString(List<Object?> values) {
  for (final value in values) {
    final parsed = _asNullableString(value);
    if (parsed != null && parsed.isNotEmpty) {
      return parsed;
    }
  }
  return '';
}

String? _asNullableString(Object? value) {
  if (value == null) {
    return null;
  }
  final parsed = value.toString().trim();
  return parsed.isEmpty ? null : parsed;
}
