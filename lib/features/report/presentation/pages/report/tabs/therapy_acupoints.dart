part of '../report_page.dart';

const _backendPointKeys = [
  'point',
  'points',
  'pointName',
  'pointNames',
  'acupoint',
  'acupoints',
  'acupointName',
  'acupointNames',
  'acuPoint',
  'acuPoints',
  'bodyPoint',
  'bodyPoints',
];

const _acupointPalette = [
  Color(0xFF2D6A4F),
  Color(0xFF4A7FA8),
  Color(0xFFC9A84C),
  Color(0xFF6B5B95),
  Color(0xFFD4794A),
  Color(0xFF0D7A5A),
];

String? _therapyQuerySignature(ReportViewData viewData) {
  if (!viewData.isLive) {
    return null;
  }
  final physiqueId = _dominantPhysiqueId(viewData);
  if (physiqueId == null) {
    return null;
  }

  return [
    viewData.age?.toString() ?? '',
    viewData.sex?.trim() ?? '',
    viewData.token?.trim() ?? '',
    physiqueId.toString(),
  ].join('|');
}

Future<List<Map<String, dynamic>>> _loadTherapiesForDominantConstitution(
  ReportViewData viewData,
) {
  final physiqueId = _dominantPhysiqueId(viewData);
  if (physiqueId == null) {
    return Future.value(const <Map<String, dynamic>>[]);
  }

  return ReportRemoteSource(getIt<DioClient>()).getPhysiqueTherapies(
    age: viewData.age,
    sex: viewData.sex,
    token: viewData.token,
    physiqueIds: [physiqueId],
  );
}

_TherapyAcupointViewData _buildFallbackAcupointViewData(
  BuildContext context,
  ReportViewData viewData,
) {
  final points = _resolveAcupuncturePoints(context, viewData);
  final dominantConstitution = _dominantConstitution(viewData);
  return _TherapyAcupointViewData(
    constitutionName:
        dominantConstitution?.name ?? viewData.primaryConstitution,
    scorePercent: dominantConstitution?.scorePercent,
    intro: _resolveAcupunctureIntro(context, viewData, points.length),
    points: points,
    sourceLabel: viewData.isLive ? '本地兜底' : '示例取穴',
  );
}

_TherapyAcupointViewData _buildBackendAcupointViewData(
  BuildContext context,
  ReportViewData viewData,
  List<Map<String, dynamic>> therapies,
) {
  final points = _resolveBackendAcupuncturePoints(context.l10n, therapies);
  if (points.isEmpty) {
    return _buildFallbackAcupointViewData(context, viewData).copyWith(
      sourceLabel: '本地兜底',
      statusText: 'therapy 已返回，但 point 字段为空，先展示基础取穴建议。',
    );
  }

  final dominantConstitution = _dominantConstitution(viewData);
  return _TherapyAcupointViewData(
    constitutionName:
        dominantConstitution?.name ?? viewData.primaryConstitution,
    scorePercent: dominantConstitution?.scorePercent,
    intro: _resolveBackendAcupunctureIntro(
      context,
      viewData,
      therapies,
      points.length,
    ),
    points: points,
    sourceLabel: null,
  );
}

List<_AcuPoint> _resolveBackendAcupuncturePoints(
  AppLocalizations l10n,
  List<Map<String, dynamic>> therapies,
) {
  final resolved = <_AcuPoint>[];
  final seenNames = <String>{};

  for (final therapy in therapies) {
    final fallbackEffect = _firstNonEmptyText(therapy, const [
      'effect',
      'efficacy',
      'functions',
      'benefit',
      'summary',
      'description',
      'suggestion',
      'advice',
      'remark',
      'remarks',
      'note',
      'notes',
    ]);
    for (final value in _extractBackendPointValues(therapy)) {
      for (final candidate in _flattenBackendPointValue(
        value,
        fallbackEffect: fallbackEffect,
      )) {
        final name = _cleanPointName(candidate.name);
        if (name == null || !seenNames.add(_pointLookupKey(name))) {
          continue;
        }
        final color =
            _acupointPalette[resolved.length % _acupointPalette.length];
        resolved.add(_pointFromCandidate(l10n, candidate, name, color));
      }
    }
  }

  return resolved.take(8).toList(growable: false);
}

List<Object?> _extractBackendPointValues(Map<String, dynamic> payload) {
  final values = <Object?>[];
  for (final key in _backendPointKeys) {
    final value = _valueForKey(payload, key);
    if (value != null) {
      values.add(value);
    }
  }
  return values;
}

List<_BackendPointCandidate> _flattenBackendPointValue(
  Object? value, {
  String? fallbackEffect,
}) {
  if (value == null) {
    return const [];
  }
  if (value is String) {
    final decoded = _tryDecodePointJson(value);
    if (decoded != null) {
      return _flattenBackendPointValue(decoded, fallbackEffect: fallbackEffect);
    }
    return _splitBackendPointText(value, fallbackEffect: fallbackEffect);
  }
  if (value is Iterable) {
    return value
        .expand(
          (item) =>
              _flattenBackendPointValue(item, fallbackEffect: fallbackEffect),
        )
        .toList(growable: false);
  }
  if (value is Map) {
    final normalized = value.map(
      (key, mapValue) => MapEntry(key.toString(), mapValue),
    );
    final name = _firstNonEmptyText(normalized, const [
      'pointName',
      'acupointName',
      'name',
      'title',
      'label',
      'value',
      'text',
    ]);
    if (name != null) {
      return [
        _BackendPointCandidate(
          name: name,
          location: _firstNonEmptyText(normalized, const [
            'location',
            'position',
            'place',
            'bodyPart',
            'bodyPosition',
          ]),
          effect:
              _firstNonEmptyText(normalized, const [
                'effect',
                'efficacy',
                'function',
                'functions',
                'benefit',
                'description',
                'summary',
                'advice',
                'remark',
                'remarks',
                'note',
                'notes',
              ]) ??
              fallbackEffect,
          meridian: _firstNonEmptyText(normalized, const [
            'meridian',
            'meridianName',
            'channel',
            'jingLuo',
          ]),
        ),
      ];
    }

    final nestedValues = _extractBackendPointValues(normalized);
    if (nestedValues.isNotEmpty) {
      return nestedValues
          .expand(
            (item) =>
                _flattenBackendPointValue(item, fallbackEffect: fallbackEffect),
          )
          .toList(growable: false);
    }

    return const [];
  }
  return const [];
}

Object? _tryDecodePointJson(String value) {
  final text = value.trim();
  if (!(text.startsWith('[') || text.startsWith('{'))) {
    return null;
  }
  try {
    return jsonDecode(text);
  } catch (_) {
    return null;
  }
}

List<_BackendPointCandidate> _splitBackendPointText(
  String value, {
  String? fallbackEffect,
}) {
  final text = value.trim();
  if (text.isEmpty) {
    return const [];
  }
  return text
      .split(RegExp(r'(?:\r?\n)+|[、,，;；/|]+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .map((item) => _candidateFromPointText(item, fallbackEffect))
      .toList(growable: false);
}

_BackendPointCandidate _candidateFromPointText(
  String value,
  String? fallbackEffect,
) {
  final text = value.replaceFirst(RegExp(r'^[\s\d.、)）(（-]+'), '').trim();
  final parts = text.split(RegExp(r'\s*[:：-]\s*'));
  if (parts.length >= 2 && parts.first.length <= 8) {
    return _BackendPointCandidate(
      name: parts.first,
      effect: parts.skip(1).join('：').trim(),
    );
  }
  return _BackendPointCandidate(name: text, effect: fallbackEffect);
}

_AcuPoint _pointFromCandidate(
  AppLocalizations l10n,
  _BackendPointCandidate candidate,
  String name,
  Color color,
) {
  final known = _knownPoint(l10n, name);
  return _AcuPoint(
    name: name,
    location:
        _nonEmpty(candidate.location) ?? known?.location ?? '请按专业取穴定位图或医师指导操作',
    effect: _nonEmpty(candidate.effect) ?? known?.effect ?? '暂无穴位说明。',
    meridian: _nonEmpty(candidate.meridian) ?? known?.meridian ?? '推荐穴位',
    color: color,
  );
}

_AcuPoint? _knownPoint(AppLocalizations l10n, String name) {
  final lookupKey = _pointLookupKey(name);
  for (final point in _defaultAcupuncturePreset(l10n)) {
    if (_pointLookupKey(point.name) == lookupKey) {
      return point;
    }
  }
  return null;
}

String? _cleanPointName(String value) {
  final text = value.trim();
  if (text.isEmpty || text.length > 24) {
    return null;
  }
  return text;
}

String _pointLookupKey(String value) {
  return value
      .replaceAll(RegExp(r'[（(].*?[）)]'), '')
      .replaceAll(RegExp(r'\s+'), '')
      .trim();
}

String _resolveBackendAcupunctureIntro(
  BuildContext context,
  ReportViewData viewData,
  List<Map<String, dynamic>> therapies,
  int pointCount,
) {
  final method = _firstBackendTherapyText(therapies, const [
    'method',
    'methods',
    'therapyMethod',
    'operationMethod',
  ]);
  if (method != null) {
    return method;
  }

  final dominantConstitution = _dominantConstitutionName(viewData);
  if (dominantConstitution == null) {
    return context.l10n.reportTherapyAcupointsIntro;
  }
  return '依据$dominantConstitution体质对应的 point 字段，推荐以下 $pointCount 个重点穴位用于艾灸或按摩调理。';
}

String? _firstBackendTherapyText(
  List<Map<String, dynamic>> therapies,
  List<String> keys,
) {
  for (final therapy in therapies) {
    final text = _firstNonEmptyText(therapy, keys);
    if (text != null) {
      return text;
    }
  }
  return null;
}

ReportConstitutionScoreData? _dominantConstitution(ReportViewData viewData) {
  return viewData.constitutionScores.isNotEmpty
      ? viewData.constitutionScores.first
      : null;
}

String? _dominantConstitutionName(ReportViewData viewData) {
  return _nonEmpty(_dominantConstitution(viewData)?.name) ??
      _nonEmpty(viewData.primaryConstitution);
}

int? _dominantPhysiqueId(ReportViewData viewData) {
  final id = _dominantConstitution(viewData)?.id.trim();
  if (id == null || id.isEmpty) {
    return null;
  }
  return int.tryParse(id);
}

List<_AcuPoint> _resolveAcupuncturePoints(
  BuildContext context,
  ReportViewData viewData,
) {
  final l10n = context.l10n;
  final constitutions = viewData.constitutionScores
      .where((item) => item.name.trim().isNotEmpty)
      .take(1)
      .toList(growable: false);

  final resolved = <_AcuPoint>[];
  final seenNames = <String>{};
  for (final constitution in constitutions) {
    for (final point in _acupuncturePresetForName(l10n, constitution.name)) {
      if (seenNames.add(point.name)) {
        resolved.add(point);
      }
    }
  }

  if (resolved.isNotEmpty) {
    return resolved;
  }

  return _defaultAcupuncturePreset(l10n);
}

String _resolveAcupunctureIntro(
  BuildContext context,
  ReportViewData viewData,
  int pointCount,
) {
  final dominantConstitution = viewData.constitutionScores.isNotEmpty
      ? viewData.constitutionScores.first.name.trim()
      : (viewData.primaryConstitution?.trim() ?? '');

  if (dominantConstitution.isEmpty) {
    return context.l10n.reportTherapyAcupointsIntro;
  }

  return '依据$dominantConstitution体质偏向，推荐以下 $pointCount 个重点穴位用于艾灸或按摩调理，可结合当日状态选 2-3 个轮换。';
}

List<_AcuPoint> _acupuncturePresetForName(
  AppLocalizations l10n,
  String constitutionName,
) {
  final name = constitutionName.trim();
  if (name.isEmpty) {
    return const [];
  }

  if (name.contains('脾') || name.contains('气虚')) {
    return _buildQiDeficiencyPoints(l10n);
  }
  if (name.contains('阳虚')) {
    return _buildYangDeficiencyPoints(l10n);
  }
  if (name.contains('阴虚')) {
    return _buildYinDeficiencyPoints(l10n);
  }
  if (name.contains('痰湿')) {
    return _buildPhlegmDampnessPoints(l10n);
  }
  if (name.contains('湿热')) {
    return _buildDampHeatPoints(l10n);
  }
  if (name.contains('血瘀')) {
    return _buildBloodStasisPoints(l10n);
  }
  if (name.contains('气郁')) {
    return _buildQiStagnationPoints(l10n);
  }
  if (name.contains('特禀')) {
    return _buildSpecialConstitutionPoints(l10n);
  }
  if (name.contains('平和')) {
    return _buildBalancedConstitutionPoints(l10n);
  }

  return const [];
}

List<_AcuPoint> _defaultAcupuncturePreset(AppLocalizations l10n) {
  return _buildQiDeficiencyPoints(l10n);
}

List<_AcuPoint> _buildQiDeficiencyPoints(AppLocalizations l10n) {
  return [
    _presetPoint(
      l10n.reportTherapyAcuPointZusanli,
      l10n.reportTherapyAcuPointZusanliLocation,
      l10n.reportTherapyAcuPointZusanliEffect,
      l10n.reportTherapyAcuPointZusanliMeridian,
      const Color(0xFF2D6A4F),
    ),
    _presetPoint(
      l10n.reportTherapyAcuPointPishu,
      l10n.reportTherapyAcuPointPishuLocation,
      l10n.reportTherapyAcuPointPishuEffect,
      l10n.reportTherapyAcuPointPishuMeridian,
      const Color(0xFF0D7A5A),
    ),
    _presetPoint(
      l10n.reportTherapyAcuPointQihai,
      l10n.reportTherapyAcuPointQihaiLocation,
      l10n.reportTherapyAcuPointQihaiEffect,
      l10n.reportTherapyAcuPointQihaiMeridian,
      const Color(0xFF6B5B95),
    ),
    _presetPoint(
      l10n.reportTherapyAcuPointGuanyuan,
      l10n.reportTherapyAcuPointGuanyuanLocation,
      l10n.reportTherapyAcuPointGuanyuanEffect,
      l10n.reportTherapyAcuPointGuanyuanMeridian,
      const Color(0xFFC9A84C),
    ),
  ];
}

List<_AcuPoint> _buildYangDeficiencyPoints(AppLocalizations l10n) {
  return [
    _presetPoint(
      l10n.reportTherapyAcuPointGuanyuan,
      l10n.reportTherapyAcuPointGuanyuanLocation,
      '温补肾阳、固本培元，改善畏寒与乏力。',
      l10n.reportTherapyAcuPointGuanyuanMeridian,
      const Color(0xFFC9A84C),
    ),
    _presetPoint(
      l10n.reportTherapyAcuPointQihai,
      l10n.reportTherapyAcuPointQihaiLocation,
      '补气助阳、温中散寒，适合气短乏力人群。',
      l10n.reportTherapyAcuPointQihaiMeridian,
      const Color(0xFF4A7FA8),
    ),
    _presetPoint(
      '命门',
      '第二腰椎棘突下，后正中线上',
      '温肾壮阳、强腰固本，可配合艾灸提升阳气。',
      '督脉',
      const Color(0xFFD4794A),
    ),
    _presetPoint(
      '肾俞',
      '第二腰椎棘突下旁开1.5寸',
      '调补肾气、温阳固摄，适合腰膝酸软与怕冷。',
      '足太阳膀胱经',
      const Color(0xFF6B5B95),
    ),
  ];
}

List<_AcuPoint> _buildYinDeficiencyPoints(AppLocalizations l10n) {
  return [
    _presetPoint(
      '太溪',
      '内踝后方与跟腱之间凹陷处',
      '滋阴益肾、润燥降火，缓解口干与虚热。',
      '足少阴肾经',
      const Color(0xFF4A7FA8),
    ),
    _presetPoint(
      '三阴交',
      '内踝尖上3寸，胫骨内侧后缘',
      '调和肝脾肾，兼顾睡眠、情绪与内分泌。',
      '足太阴脾经',
      const Color(0xFF6B5B95),
    ),
    _presetPoint(
      l10n.reportTherapyAcuPointQihai,
      l10n.reportTherapyAcuPointQihaiLocation,
      '益气养阴，帮助改善虚弱与疲乏。',
      l10n.reportTherapyAcuPointQihaiMeridian,
      const Color(0xFF2D6A4F),
    ),
    _presetPoint(
      '照海',
      '内踝尖下方凹陷处',
      '滋阴清热，适合咽干、烦热和睡眠浅。',
      '足少阴肾经',
      const Color(0xFF0D7A5A),
    ),
  ];
}

List<_AcuPoint> _buildPhlegmDampnessPoints(AppLocalizations l10n) {
  return [
    _presetPoint(
      '丰隆',
      '外踝尖上8寸，胫骨前嵴外二横指',
      '化痰祛湿、和胃降逆，是痰湿体质常用要穴。',
      '足阳明胃经',
      const Color(0xFF2D6A4F),
    ),
    _presetPoint(
      l10n.reportTherapyAcuPointZusanli,
      l10n.reportTherapyAcuPointZusanliLocation,
      '健脾助运、祛湿化浊，改善困重与食后胀满。',
      l10n.reportTherapyAcuPointZusanliMeridian,
      const Color(0xFF0D7A5A),
    ),
    _presetPoint(
      l10n.reportTherapyAcuPointPishu,
      l10n.reportTherapyAcuPointPishuLocation,
      '健脾运湿，帮助改善舌苔厚腻与体重负担。',
      l10n.reportTherapyAcuPointPishuMeridian,
      const Color(0xFFC9A84C),
    ),
    _presetPoint(
      '阴陵泉',
      '胫骨内侧髁下缘凹陷处',
      '利水渗湿、清湿浊，适合下肢困重和水肿倾向。',
      '足太阴脾经',
      const Color(0xFF6B5B95),
    ),
  ];
}

List<_AcuPoint> _buildDampHeatPoints(AppLocalizations l10n) {
  return [
    _presetPoint(
      '曲池',
      '屈肘时肘横纹外侧端',
      '清热解表、泄火除烦，适合湿热偏盛人群。',
      '手阳明大肠经',
      const Color(0xFFD4794A),
    ),
    _presetPoint(
      '阴陵泉',
      '胫骨内侧髁下缘凹陷处',
      '利湿清热，帮助改善口苦、身重与湿滞。',
      '足太阴脾经',
      const Color(0xFF2D6A4F),
    ),
    _presetPoint(
      '足临泣',
      '第四、五跖骨结合部前方凹陷处',
      '疏肝利胆、清热化湿，适合湿热郁滞。',
      '足少阳胆经',
      const Color(0xFF4A7FA8),
    ),
    _presetPoint(
      '中脘',
      '脐上4寸，前正中线上',
      '和胃清热、调中化湿，适合胃肠湿热不适。',
      '任脉',
      const Color(0xFFC9A84C),
    ),
  ];
}

List<_AcuPoint> _buildBloodStasisPoints(AppLocalizations l10n) {
  return [
    _presetPoint(
      '血海',
      '髌底内侧端上2寸，股四头肌内侧隆起处',
      '活血化瘀、调经止痛，适合瘀滞型不适。',
      '足太阴脾经',
      const Color(0xFFD4794A),
    ),
    _presetPoint(
      '膈俞',
      '第七胸椎棘突下旁开1.5寸',
      '活血理气，改善瘀血阻滞导致的沉重与疼痛。',
      '足太阳膀胱经',
      const Color(0xFF6B5B95),
    ),
    _presetPoint(
      '太冲',
      '足背第一、二跖骨结合部前方凹陷处',
      '疏肝理气、行气活血，适合情志郁滞兼血瘀。',
      '足厥阴肝经',
      const Color(0xFF2D6A4F),
    ),
    _presetPoint(
      '合谷',
      '第一、二掌骨之间，第二掌骨桡侧中点处',
      '行气止痛、通络散结，可与太冲配伍。',
      '手阳明大肠经',
      const Color(0xFF4A7FA8),
    ),
  ];
}

List<_AcuPoint> _buildQiStagnationPoints(AppLocalizations l10n) {
  return [
    _presetPoint(
      '太冲',
      '足背第一、二跖骨结合部前方凹陷处',
      '疏肝解郁、调畅气机，适合胸闷和情绪压抑。',
      '足厥阴肝经',
      const Color(0xFF2D6A4F),
    ),
    _presetPoint(
      '内关',
      '腕横纹上2寸，掌长肌腱与桡侧腕屈肌腱之间',
      '宽胸理气、宁心安神，适合焦虑与胃脘不舒。',
      '手厥阴心包经',
      const Color(0xFF4A7FA8),
    ),
    _presetPoint(
      '膻中',
      '前正中线上，两乳头连线中点',
      '理气宽胸，缓解气郁所致的憋闷感。',
      '任脉',
      const Color(0xFF6B5B95),
    ),
    _presetPoint(
      '合谷',
      '第一、二掌骨之间，第二掌骨桡侧中点处',
      '调气开郁，配合太冲有“四关”之效。',
      '手阳明大肠经',
      const Color(0xFFC9A84C),
    ),
  ];
}

List<_AcuPoint> _buildSpecialConstitutionPoints(AppLocalizations l10n) {
  return [
    _presetPoint(
      '肺俞',
      '第三胸椎棘突下旁开1.5寸',
      '宣肺固表，帮助提升呼吸道防护能力。',
      '足太阳膀胱经',
      const Color(0xFF4A7FA8),
    ),
    _presetPoint(
      '合谷',
      '第一、二掌骨之间，第二掌骨桡侧中点处',
      '疏风解表，适合过敏体质日常调护。',
      '手阳明大肠经',
      const Color(0xFF2D6A4F),
    ),
    _presetPoint(
      '曲池',
      '屈肘时肘横纹外侧端',
      '清热祛风，适合皮肤易敏与风热偏盛。',
      '手阳明大肠经',
      const Color(0xFFD4794A),
    ),
    _presetPoint(
      '足三里',
      l10n.reportTherapyAcuPointZusanliLocation,
      '扶正培元，增强整体体质与适应能力。',
      l10n.reportTherapyAcuPointZusanliMeridian,
      const Color(0xFFC9A84C),
    ),
  ];
}

List<_AcuPoint> _buildBalancedConstitutionPoints(AppLocalizations l10n) {
  return [
    _presetPoint(
      l10n.reportTherapyAcuPointZusanli,
      l10n.reportTherapyAcuPointZusanliLocation,
      '健脾和胃、扶助正气，适合作为日常保养。',
      l10n.reportTherapyAcuPointZusanliMeridian,
      const Color(0xFF2D6A4F),
    ),
    _presetPoint(
      l10n.reportTherapyAcuPointQihai,
      l10n.reportTherapyAcuPointQihaiLocation,
      '培补元气、稳住体能节律，适合长期调护。',
      l10n.reportTherapyAcuPointQihaiMeridian,
      const Color(0xFF4A7FA8),
    ),
    _presetPoint(
      '三阴交',
      '内踝尖上3寸，胫骨内侧后缘',
      '调和三阴经，帮助维持睡眠、情绪与消化平衡。',
      '足太阴脾经',
      const Color(0xFF6B5B95),
    ),
  ];
}

_AcuPoint _presetPoint(
  String name,
  String location,
  String effect,
  String meridian,
  Color color,
) {
  return _AcuPoint(
    name: name,
    location: location,
    effect: effect,
    meridian: meridian,
    color: color,
  );
}

class _TherapyAcupointViewData {
  const _TherapyAcupointViewData({
    required this.constitutionName,
    required this.scorePercent,
    required this.intro,
    required this.points,
    required this.sourceLabel,
    this.isLoading = false,
    this.statusText,
  });

  final String? constitutionName;
  final double? scorePercent;
  final String intro;
  final List<_AcuPoint> points;
  final String? sourceLabel;
  final bool isLoading;
  final String? statusText;

  _TherapyAcupointViewData copyWith({
    String? intro,
    List<_AcuPoint>? points,
    String? sourceLabel,
    bool? isLoading,
    String? statusText,
  }) {
    return _TherapyAcupointViewData(
      constitutionName: constitutionName,
      scorePercent: scorePercent,
      intro: intro ?? this.intro,
      points: points ?? this.points,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      isLoading: isLoading ?? this.isLoading,
      statusText: statusText ?? this.statusText,
    );
  }
}

class _BackendPointCandidate {
  const _BackendPointCandidate({
    required this.name,
    this.location,
    this.effect,
    this.meridian,
  });

  final String name;
  final String? location;
  final String? effect;
  final String? meridian;
}

class _AcupointStatusNote extends StatelessWidget {
  const _AcupointStatusNote({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          height: 1.45,
          color: color.withValues(alpha: 0.9),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DynamicAcupointHeader extends StatelessWidget {
  const _DynamicAcupointHeader({
    required this.constitutionName,
    required this.scorePercent,
    required this.intro,
    required this.pointCount,
    this.sourceLabel,
    this.isLoading = false,
  });

  final String? constitutionName;
  final double? scorePercent;
  final String intro;
  final int pointCount;
  final String? sourceLabel;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((constitutionName ?? '').trim().isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SmallBadge(
                text: '主导体质 ${constitutionName!.trim()}',
                color: const Color(0xFF2D6A4F),
              ),
              if (scorePercent != null)
                _SmallBadge(
                  text:
                      '体质分 ${scorePercent!.toStringAsFixed(scorePercent! % 1 == 0 ? 0 : 1)}',
                  color: const Color(0xFF4A7FA8),
                ),
              _SmallBadge(
                text: '推荐穴位 $pointCount 个',
                color: const Color(0xFFC9A84C),
              ),
              if ((sourceLabel ?? '').trim().isNotEmpty)
                _SmallBadge(
                  text: sourceLabel!.trim(),
                  color: isLoading
                      ? const Color(0xFF4A7FA8)
                      : const Color(0xFF0D7A5A),
                ),
            ],
          ),
        if ((constitutionName ?? '').trim().isNotEmpty)
          const SizedBox(height: 10),
        Text(
          intro,
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFF3A3028).withValues(alpha: 0.55),
            height: 1.55,
          ),
        ),
      ],
    );
  }
}
