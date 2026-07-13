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

class PhysiqueQuestionFlowSnapshot {
  const PhysiqueQuestionFlowSnapshot({
    required this.requestContext,
    required this.answers,
    required this.amenorrhea,
    this.question,
    this.completedResult,
    this.completionReportId,
  });

  final PhysiqueQuestionRequestContext requestContext;
  final List<PhysiqueQuestionRequestAnswer> answers;
  final String? amenorrhea;
  final PhysiqueQuestionPayload? question;
  final Map<String, dynamic>? completedResult;
  final String? completionReportId;

  bool get hasQuestion => question != null;
  bool get hasCompletedResult => completedResult?.isNotEmpty == true;
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
    this.storeId,
    this.t,
    this.tenantId,
    this.key,
    this.reportId,
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
  final int? storeId;
  final int? t;
  final int? tenantId;
  final String? key;
  final String? reportId;
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
      storeId: storeId,
      t: t,
      tenantId: tenantId,
      key: key,
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
    this.storeId,
    this.t,
    this.tenantId,
    this.key,
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
  final int? storeId;
  final int? t;
  final int? tenantId;
  final String? key;
  final int? tongueReportId;
  final int? topOrgId;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'gender': gender,
      'phyCategory': phyCategory,
      'answers': answers.map((item) => item.toJson()).toList(growable: false),
      if (age != null) 'age': age,
      if (_isPresent(amenorrhea)) 'amenorrhea': amenorrhea,
      if (_isPresent(birthyear)) 'birthyear': birthyear,
      if (clinicId != null) 'clinicId': clinicId,
      if (_isPresent(exact)) 'exact': exact,
      if (medicalCaseId != null) 'medicalCaseId': medicalCaseId,
      if (_isPresent(name)) 'name': name,
      if (_isPresent(phone)) 'phone': phone,
      if (storeId != null) 'storeId': storeId,
      if (t != null) 't': t,
      if (tenantId != null) 'tenantId': tenantId,
      if (_isPresent(key)) 'key': key,
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
    this.completedResult,
  });

  factory PhysiqueQuestionFlowResult.fromData(Map<String, dynamic> data) {
    final question = PhysiqueQuestionPayload.fromData(data);
    final hasQuestion = question.hasRenderableQuestion;
    return PhysiqueQuestionFlowResult(
      rawData: data,
      question: hasQuestion ? question : null,
      reportId: _firstNonEmptyString(<Object?>[
        data['reportId'],
        data['id'],
        _readPath(data, 'report.reportId'),
        _readPath(data, 'report.id'),
        _readPath(data, 'tongueReport.reportId'),
        _readPath(data, 'result.reportId'),
        _readPath(data, 'result.id'),
        _readPath(data, 'diagnosisReport.reportId'),
        _readPath(data, 'diagnosisReport.id'),
        _readPath(data, 'medicalCase.reportId'),
      ]),
      completedResult: hasQuestion ? null : _resolveCompletedResult(data),
    );
  }

  final PhysiqueQuestionPayload? question;
  final String? reportId;
  final Map<String, dynamic>? completedResult;
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
    final optionMaps = _resolveOptionMaps(questionMap, data);
    return PhysiqueQuestionPayload(
      raw: questionMap,
      id: _firstInt(<Object?>[
        questionMap['id'],
        questionMap['questionId'],
        questionMap['question_id'],
        questionMap['qId'],
        questionMap['subjectId'],
        questionMap['subject_id'],
        questionMap['questionNo'],
        questionMap['questionNumber'],
        questionMap['sort'],
        questionMap['sortNo'],
      ]),
      title: _firstNonEmptyString(<Object?>[
        questionMap['question'],
        questionMap['title'],
        questionMap['questionTitle'],
        questionMap['questionText'],
        questionMap['questionName'],
        questionMap['questionContent'],
        questionMap['content'],
        questionMap['text'],
        questionMap['name'],
        questionMap['subject'],
        questionMap['stem'],
        questionMap['topic'],
        questionMap['displayName'],
        questionMap['labelText'],
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
        questionMap['question_code'],
        questionMap['code'],
        questionMap['key'],
        questionMap['slug'],
      ]),
      currentIndex: _firstInt(<Object?>[
        questionMap['currentIndex'],
        questionMap['questionIndex'],
        questionMap['index'],
        questionMap['sort'],
        questionMap['sortNo'],
        data['currentIndex'],
        data['questionTotal'],
        data['index'],
      ]),
      totalCount: _firstInt(<Object?>[
        questionMap['totalCount'],
        questionMap['questionTotal'],
        questionMap['total'],
        questionMap['count'],
        data['totalCount'],
        data['total'],
        data['count'],
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

  bool get isSingleChoice => !allowsMultipleSelection;

  bool get allowsMultipleSelection {
    for (final value in <Object?>[
      raw['multiple'],
      raw['multiSelect'],
      raw['isMultiple'],
      raw['multipleChoice'],
    ]) {
      if (value is bool && value) {
        return true;
      }
    }

    final normalizedType = _firstNonEmptyString(<Object?>[
      raw['selectionType'],
      raw['selectType'],
      raw['type'],
      raw['questionType'],
      raw['inputType'],
    ]).toLowerCase();
    return normalizedType.contains('multi') ||
        normalizedType.contains('multiple') ||
        normalizedType.contains('checkbox');
  }

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
        json['answerValue'],
        json['optionCode'],
        json['answerCode'],
        json['value'],
        json['code'],
        json['id'],
        json['score'],
        json['sort'],
        json['sortNo'],
      ]),
      label: _firstNonEmptyString(<Object?>[
        json['optionName'],
        json['optionText'],
        json['optionLabel'],
        json['answerName'],
        json['answerText'],
        json['answer'],
        json['text'],
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
  for (final source in _resolveResponseRoots(data)) {
    for (final key in _questionObjectKeys) {
      final map = _asMap(source[key]);
      if (map.isNotEmpty) {
        return map;
      }
    }

    if (_looksLikeQuestionMap(source)) {
      return source;
    }

    for (final key in _questionListKeys) {
      final list = _asListOfMaps(source[key]);
      for (final item in list) {
        if (_looksLikeQuestionMap(item)) {
          return item;
        }
      }
    }
  }
  return data;
}

Map<String, dynamic>? _resolveCompletedResult(Map<String, dynamic> data) {
  for (final value in <Object?>[
    data['result'],
    data['report'],
    data['diagnosisReport'],
    data['tongueReport'],
  ]) {
    final map = _asMap(value);
    if (map.isNotEmpty) {
      return map;
    }
  }
  return data.isEmpty ? null : Map<String, dynamic>.from(data);
}

List<Map<String, dynamic>> _resolveOptionMaps(
  Map<String, dynamic> questionMap,
  Map<String, dynamic> data,
) {
  final sources = <Map<String, dynamic>>[
    questionMap,
    ..._resolveResponseRoots(data),
  ];
  for (final source in sources) {
    for (final key in _optionListKeys) {
      final list = _asOptionList(source[key]);
      if (list.isNotEmpty) {
        return list;
      }
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

List<Map<String, dynamic>> _asOptionList(Object? value) {
  if (value is List) {
    return value
        .map(_normalizeOptionItem)
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  final map = _asMap(value);
  if (map.isEmpty) {
    return const <Map<String, dynamic>>[];
  }
  return map.entries
      .map((entry) {
        final option = _asMap(entry.value);
        if (option.isNotEmpty) {
          return <String, dynamic>{'value': entry.key, ...option};
        }
        final label = _asNullableString(entry.value);
        if (label == null) {
          return const <String, dynamic>{};
        }
        return <String, dynamic>{'value': entry.key, 'text': label};
      })
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

Map<String, dynamic> _normalizeOptionItem(Object? value) {
  final map = _asMap(value);
  if (map.isNotEmpty) {
    return map;
  }
  final label = _asNullableString(value);
  if (label == null) {
    return const <String, dynamic>{};
  }
  return <String, dynamic>{'value': label, 'text': label};
}

List<Map<String, dynamic>> _resolveResponseRoots(Map<String, dynamic> data) {
  final roots = <Map<String, dynamic>>[];
  final visited = <Map<String, dynamic>>{};

  void addRoot(Map<String, dynamic> root) {
    if (root.isEmpty || visited.contains(root)) {
      return;
    }
    visited.add(root);
    roots.add(root);
    for (final key in _responseContainerKeys) {
      final nested = _asMap(root[key]);
      if (nested.isNotEmpty) {
        addRoot(nested);
      }
    }
  }

  addRoot(data);
  return roots;
}

bool _looksLikeQuestionMap(Map<String, dynamic> data) {
  final hasId =
      _firstInt(<Object?>[
        data['id'],
        data['questionId'],
        data['question_id'],
        data['qId'],
        data['subjectId'],
        data['subject_id'],
      ]) !=
      null;
  final hasTitle = _firstNonEmptyString(<Object?>[
    data['question'],
    data['title'],
    data['questionTitle'],
    data['questionText'],
    data['questionName'],
    data['questionContent'],
    data['content'],
    data['text'],
    data['name'],
    data['subject'],
    data['stem'],
    data['topic'],
    data['displayName'],
    data['labelText'],
  ]).isNotEmpty;
  final hasOptions = _optionListKeys.any(
    (key) => _asOptionList(data[key]).isNotEmpty,
  );
  return (hasTitle && (hasId || hasOptions)) || (hasId && hasOptions);
}

const _responseContainerKeys = <String>[
  'data',
  'payload',
  'body',
  'resultData',
  'response',
];

const _questionObjectKeys = <String>[
  'question',
  'next',
  'currentQuestion',
  'nextQuestion',
  'item',
  'subject',
  'questionInfo',
  'questionItem',
  'current',
];

const _questionListKeys = <String>[
  'questions',
  'questionList',
  'questionItems',
  'records',
  'list',
];

const _optionListKeys = <String>[
  'options',
  'optionList',
  'questionOptions',
  'items',
  'answers',
  'answerList',
  'answerOptions',
  'choices',
  'choiceList',
  'optionItems',
  'optionDTOList',
];

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
