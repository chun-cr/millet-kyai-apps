// 报告页展示模型集合。把后端明细结构归一化成页面卡片、图表和摘要可以直接消费的字段。

import 'package:flutter/foundation.dart';
import 'package:millet_kyai_apps/features/report/data/models/report_detail.dart';

/// 区分演示态报告和真实接口报告来源。
enum ReportViewMode { demo, live }

@immutable
class ReportRiskIndexData {
  /// 报告摘要区单个风险环的展示模型。
  const ReportRiskIndexData({required this.name, required this.rawProbability});

  final String name;
  final double rawProbability;

  double get _normalizedRawProbability =>
      rawProbability.clamp(0.0, 1.0).toDouble();

  int get displayProb =>
      (_normalizedRawProbability * 100).round().clamp(0, 100).toInt();

  int get ringScore => displayProb == 100 ? 98 : displayProb;

  bool get isWarning => ringScore > 50;

  String get statusLabel => isWarning ? '警惕' : '关注';
}

@immutable
class ReportConstitutionScoreData {
  /// 体质分布区使用的标准化得分模型。
  const ReportConstitutionScoreData({
    required this.id,
    required this.name,
    required this.scorePercent,
    this.hasScore = true,
  });

  final String id;
  final String name;
  final double scorePercent;
  final bool hasScore;

  double get scoreFraction => (scorePercent / 100).clamp(0.0, 1.0).toDouble();
}

enum ReportHealthRadarMode { aiDeep, classic }

@immutable
class ReportHealthRadarSymptomData {
  /// 健康雷达区域中的单个症状项展示模型。
  const ReportHealthRadarSymptomData({
    required this.id,
    required this.name,
    required this.selected,
    required this.raw,
  });

  final String id;
  final String name;
  final bool selected;
  final Map<String, dynamic> raw;

  bool get hasPersistableId => id.trim().isNotEmpty;

  ReportHealthRadarSymptomData copyWith({
    String? id,
    String? name,
    bool? selected,
    Map<String, dynamic>? raw,
  }) {
    return ReportHealthRadarSymptomData(
      id: id ?? this.id,
      name: name ?? this.name,
      selected: selected ?? this.selected,
      raw: raw ?? this.raw,
    );
  }
}

@immutable
class ReportTongueAnalysisItemData {
  /// 报告详情里单张舌象分析卡片的数据模型。
  const ReportTongueAnalysisItemData({
    required this.key,
    required this.title,
    required this.resultText,
    required this.pathologyText,
  });

  final String key;
  final String title;
  final String resultText;
  final String pathologyText;
}

@immutable
class ReportPhysiqueAnalysisData {
  const ReportPhysiqueAnalysisData({
    required this.id,
    required this.name,
    required this.standardVersion,
    required this.mainFeature,
    required this.bodyFeature,
    required this.psychologicalFeature,
    required this.diseaseTendencyNote,
    required this.environmentAdaptability,
    required this.manifestations,
    required this.diseaseTendencies,
    required this.sections,
  });

  factory ReportPhysiqueAnalysisData.fromJson(Map<String, dynamic> json) {
    final manifestations =
        _asList(json['manifestations'])
            .map((item) => ReportPhysiqueAnalysisItemData.fromDynamic(item))
            .where((item) => item.name.isNotEmpty)
            .toList(growable: false)
          ..sort(_compareAnalysisSort);
    final diseaseTendencies =
        _asList(json['diseaseTendencies'])
            .map((item) => ReportPhysiqueAnalysisItemData.fromDynamic(item))
            .where((item) => item.name.isNotEmpty)
            .toList(growable: false)
          ..sort(_compareAnalysisSort);
    final sections =
        _asList(json['sections'])
            .map(
              (item) =>
                  ReportPhysiqueAnalysisSectionData.fromJson(_asMap(item)),
            )
            .where((item) => item.hasDisplayableContent)
            .toList(growable: false)
          ..sort(_compareAnalysisSort);

    return ReportPhysiqueAnalysisData(
      id: _asString(json['id']).trim(),
      name: _asString(json['name']).trim(),
      standardVersion: _asString(json['standardVersion']).trim(),
      mainFeature: _asString(json['mainFeature']).trim(),
      bodyFeature: _asString(json['bodyFeature']).trim(),
      psychologicalFeature: _asString(json['psychologicalFeature']).trim(),
      diseaseTendencyNote: _asString(json['diseaseTendencyNote']).trim(),
      environmentAdaptability: _asString(
        json['environmentAdaptability'],
      ).trim(),
      manifestations: List.unmodifiable(manifestations),
      diseaseTendencies: List.unmodifiable(diseaseTendencies),
      sections: List.unmodifiable(sections),
    );
  }

  final String id;
  final String name;
  final String standardVersion;
  final String mainFeature;
  final String bodyFeature;
  final String psychologicalFeature;
  final String diseaseTendencyNote;
  final String environmentAdaptability;
  final List<ReportPhysiqueAnalysisItemData> manifestations;
  final List<ReportPhysiqueAnalysisItemData> diseaseTendencies;
  final List<ReportPhysiqueAnalysisSectionData> sections;

  ReportPhysiqueAnalysisSectionData? sectionByType(String sectionType) {
    final normalized = sectionType.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    for (final section in sections) {
      if (section.sectionType.toLowerCase() == normalized) {
        return section;
      }
    }
    return null;
  }

  ReportPhysiqueAnalysisSectionData? get interpretation =>
      sectionByType('interpretation');

  ReportPhysiqueAnalysisSectionData? get conditioningReference =>
      sectionByType('conditioning_reference');

  ReportPhysiqueAnalysisSectionData? get dietReference =>
      sectionByType('diet_reference');

  bool get hasFeatureContent {
    return mainFeature.isNotEmpty ||
        bodyFeature.isNotEmpty ||
        psychologicalFeature.isNotEmpty ||
        diseaseTendencyNote.isNotEmpty ||
        environmentAdaptability.isNotEmpty ||
        manifestations.isNotEmpty ||
        diseaseTendencies.isNotEmpty;
  }

  bool get hasDisplayableContent => hasFeatureContent || sections.isNotEmpty;
}

@immutable
class ReportPhysiqueAnalysisItemData {
  const ReportPhysiqueAnalysisItemData({
    required this.id,
    required this.name,
    required this.sortNo,
  });

  factory ReportPhysiqueAnalysisItemData.fromDynamic(Object? value) {
    if (value is String || value is num || value is bool) {
      return ReportPhysiqueAnalysisItemData(
        id: '',
        name: _asString(value).trim(),
        sortNo: null,
      );
    }

    final json = _asMap(value);
    return ReportPhysiqueAnalysisItemData(
      id: _firstNonEmpty([
        _asString(json['id']),
        _asString(json['physiqueId']),
        _asString(json['manifestationId']),
        _asString(json['diseaseTendencyId']),
      ]),
      name: _firstNonEmpty([
        _asString(json['name']),
        _asString(json['title']),
        _asString(json['label']),
        _asString(json['contentTitle']),
        _asString(json['contentText']),
        _asString(json['description']),
      ]),
      sortNo: _asNum(json['sortNo'])?.toInt(),
    );
  }

  final String id;
  final String name;
  final int? sortNo;
}

@immutable
class ReportPhysiqueAnalysisSectionData {
  const ReportPhysiqueAnalysisSectionData({
    required this.sectionType,
    required this.title,
    required this.sectionImageUrl,
    required this.sectionImageAlt,
    required this.sortNo,
    required this.contents,
  });

  factory ReportPhysiqueAnalysisSectionData.fromJson(
    Map<String, dynamic> json,
  ) {
    final contents =
        _asList(json['contents'])
            .map(
              (item) =>
                  ReportPhysiqueAnalysisContentData.fromJson(_asMap(item)),
            )
            .where((item) => item.hasDisplayableContent)
            .toList(growable: false)
          ..sort(_compareAnalysisSort);

    return ReportPhysiqueAnalysisSectionData(
      sectionType: _asString(json['sectionType']).trim(),
      title: _asString(json['title']).trim(),
      sectionImageUrl: _asString(json['sectionImageUrl']).trim(),
      sectionImageAlt: _asString(json['sectionImageAlt']).trim(),
      sortNo: _asNum(json['sortNo'])?.toInt(),
      contents: List.unmodifiable(contents),
    );
  }

  final String sectionType;
  final String title;
  final String sectionImageUrl;
  final String sectionImageAlt;
  final int? sortNo;
  final List<ReportPhysiqueAnalysisContentData> contents;

  bool get hasDisplayableContent =>
      sectionType.isNotEmpty ||
      title.isNotEmpty ||
      sectionImageUrl.isNotEmpty ||
      contents.isNotEmpty;
}

@immutable
class ReportPhysiqueAnalysisContentData {
  const ReportPhysiqueAnalysisContentData({
    required this.contentTitle,
    required this.contentText,
    required this.imageUrl,
    required this.imageAlt,
    required this.sortNo,
  });

  factory ReportPhysiqueAnalysisContentData.fromJson(
    Map<String, dynamic> json,
  ) {
    return ReportPhysiqueAnalysisContentData(
      contentTitle: _asString(json['contentTitle']).trim(),
      contentText: _asString(json['contentText']).trim(),
      imageUrl: _asString(json['imageUrl']).trim(),
      imageAlt: _asString(json['imageAlt']).trim(),
      sortNo: _asNum(json['sortNo'])?.toInt(),
    );
  }

  final String contentTitle;
  final String contentText;
  final String imageUrl;
  final String imageAlt;
  final int? sortNo;

  bool get hasTextContent => contentTitle.isNotEmpty || contentText.isNotEmpty;

  bool get hasDisplayableContent => hasTextContent || imageUrl.isNotEmpty;
}

/// 报告页唯一面向 UI 的展示模型。
///
/// 后端返回的 detail 结构字段多、层级深，而且不同区域的数据来源并不一致。
/// 这里先做一次归一化，保证页面层只消费稳定字段，不直接耦合接口细节。
@immutable
class ReportViewData {
  const ReportViewData({
    required this.mode,
    required this.reportId,
    required this.token,
    required this.overallScore,
    required this.faceScore,
    required this.tongueScore,
    required this.palmScore,
    required this.constitutionScores,
    required this.riskIndexes,
    required this.healthRadarClassicSymptoms,
    required this.healthRadarDeepSymptoms,
    required this.heroSecondaryConstitutions,
    required this.heroTongueSymptoms,
    required this.tongueAnalysisItems,
    required this.heroImageUrls,
    this.recordedAt,
    this.source,
    this.tenantId,
    this.storeId,
    this.age,
    this.sex,
    this.primaryConstitution,
    this.secondaryBias,
    this.summary,
    this.heroSkinAge,
    this.heroTherapySummary,
    this.consultNavigate,
    this.includeQuestions = false,
  });

  final ReportViewMode mode;
  final String? reportId;
  final String? token;
  final double overallScore;
  final double faceScore;
  final double tongueScore;
  final double palmScore;
  final List<ReportConstitutionScoreData> constitutionScores;
  final List<ReportRiskIndexData> riskIndexes;
  final List<ReportHealthRadarSymptomData> healthRadarClassicSymptoms;
  final List<ReportHealthRadarSymptomData> healthRadarDeepSymptoms;
  final List<String> heroSecondaryConstitutions;
  final List<String> heroTongueSymptoms;
  final List<ReportTongueAnalysisItemData> tongueAnalysisItems;
  final List<String> heroImageUrls;
  final String? recordedAt;
  final String? source;
  final String? tenantId;
  final String? storeId;
  final int? age;
  final String? sex;
  final String? primaryConstitution;
  final String? secondaryBias;
  final String? summary;
  final double? heroSkinAge;
  final String? heroTherapySummary;
  final DiagnosisMaNavigate? consultNavigate;
  final bool includeQuestions;

  bool get hasRiskIndexes => riskIndexes.isNotEmpty;
  bool get hasHealthRadar =>
      healthRadarClassicSymptoms.isNotEmpty ||
      healthRadarDeepSymptoms.isNotEmpty;
  bool get hasTongueAnalysis => tongueAnalysisItems.isNotEmpty;
  bool get hasHeroImages => heroImageUrls.isNotEmpty;

  List<ReportRiskIndexData> get warningRiskIndexes =>
      riskIndexes.where((item) => item.isWarning).toList(growable: false);

  List<ReportRiskIndexData> get visibleRiskIndexes =>
      riskIndexes.take(4).toList(growable: false);

  bool get isLive => mode == ReportViewMode.live;

  ReportViewData copyWith({DiagnosisMaNavigate? consultNavigate}) {
    return ReportViewData(
      mode: mode,
      reportId: reportId,
      token: token,
      overallScore: overallScore,
      faceScore: faceScore,
      tongueScore: tongueScore,
      palmScore: palmScore,
      constitutionScores: constitutionScores,
      riskIndexes: riskIndexes,
      healthRadarClassicSymptoms: healthRadarClassicSymptoms,
      healthRadarDeepSymptoms: healthRadarDeepSymptoms,
      heroSecondaryConstitutions: heroSecondaryConstitutions,
      heroTongueSymptoms: heroTongueSymptoms,
      tongueAnalysisItems: tongueAnalysisItems,
      heroImageUrls: heroImageUrls,
      recordedAt: recordedAt,
      source: source,
      tenantId: tenantId,
      storeId: storeId,
      age: age,
      sex: sex,
      primaryConstitution: primaryConstitution,
      secondaryBias: secondaryBias,
      summary: summary,
      heroSkinAge: heroSkinAge,
      heroTherapySummary: heroTherapySummary,
      consultNavigate: consultNavigate ?? this.consultNavigate,
      includeQuestions: includeQuestions,
    );
  }

  /// 本地演示/设计联调使用的固定样例数据。
  factory ReportViewData.demo({String? reportId}) {
    return ReportViewData(
      mode: ReportViewMode.demo,
      reportId: reportId,
      token: null,
      overallScore: 78,
      faceScore: 86,
      tongueScore: 72,
      palmScore: 80,
      constitutionScores: const [],
      riskIndexes: const [
        ReportRiskIndexData(name: '神志精神及情绪', rawProbability: 0.89),
        ReportRiskIndexData(name: '作息睡眠', rawProbability: 0.69),
        ReportRiskIndexData(name: '两性泌尿生殖', rawProbability: 0.67),
        ReportRiskIndexData(name: '消化道', rawProbability: 0.41),
      ],
      healthRadarClassicSymptoms: const [
        ReportHealthRadarSymptomData(
          id: 'classic-1',
          name: '痛经',
          selected: false,
          raw: <String, dynamic>{},
        ),
        ReportHealthRadarSymptomData(
          id: 'classic-2',
          name: '神经官能症',
          selected: false,
          raw: <String, dynamic>{},
        ),
        ReportHealthRadarSymptomData(
          id: 'classic-3',
          name: '咽喉异物感',
          selected: false,
          raw: <String, dynamic>{},
        ),
        ReportHealthRadarSymptomData(
          id: 'classic-4',
          name: '饭后胃胀痛',
          selected: false,
          raw: <String, dynamic>{},
        ),
      ],
      healthRadarDeepSymptoms: const [
        ReportHealthRadarSymptomData(
          id: 'deep-1',
          name: '腹冷',
          selected: false,
          raw: <String, dynamic>{},
        ),
        ReportHealthRadarSymptomData(
          id: 'deep-2',
          name: '声音无力',
          selected: false,
          raw: <String, dynamic>{},
        ),
        ReportHealthRadarSymptomData(
          id: 'deep-3',
          name: '肥胖',
          selected: false,
          raw: <String, dynamic>{},
        ),
        ReportHealthRadarSymptomData(
          id: 'deep-4',
          name: '眼睛干涩',
          selected: false,
          raw: <String, dynamic>{},
        ),
      ],
      recordedAt: null,
      source: null,
      tenantId: null,
      storeId: null,
      age: 23,
      sex: 'F',
      primaryConstitution: null,
      secondaryBias: null,
      summary: null,
      heroSecondaryConstitutions: const ['阳虚体质', '湿热体质'],
      heroTongueSymptoms: const ['舌边齿痕', '舌苔白'],
      tongueAnalysisItems: const [
        ReportTongueAnalysisItemData(
          key: 'moss_color',
          title: '舌苔颜色',
          resultText: '舌苔白',
          pathologyText: '多提示寒湿偏盛，阳气稍弱。',
        ),
        ReportTongueAnalysisItemData(
          key: 'tongue_isIndentation',
          title: '齿痕',
          resultText: '舌边齿痕',
          pathologyText: '多见于脾虚湿盛，运化乏力。',
        ),
      ],
      heroImageUrls: const [],
      heroSkinAge: 23,
      heroTherapySummary: '疏肝解郁，多参加社交活动，食用香菜、金橘，练习瑜伽、冥想。',
      consultNavigate: null,
    );
  }

  factory ReportViewData.fromSummary(DiagnosisReportSummary summary) {
    final riskIndexes =
        summary.deepPredicts.categoryProbabilities
            .map(
              (item) => ReportRiskIndexData(
                name: item.name.trim().isNotEmpty ? item.name.trim() : '风险指数',
                rawProbability: item.rawProbability,
              ),
            )
            .toList(growable: false)
          ..sort(
            (left, right) =>
                right.rawProbability.compareTo(left.rawProbability),
          );
    final primaryConstitution = summary.physiqueName.trim();
    final faceImageUrl = summary.faceImageUrl.trim();

    return ReportViewData(
      mode: ReportViewMode.live,
      reportId: summary.id.trim().isNotEmpty ? summary.id.trim() : null,
      token: null,
      overallScore: _clampPercent(summary.healthScore),
      faceScore: _clampPercent(summary.healthScore),
      tongueScore: _clampPercent(summary.healthScore),
      palmScore: _clampPercent(summary.healthScore),
      constitutionScores: primaryConstitution.isEmpty
          ? const <ReportConstitutionScoreData>[]
          : <ReportConstitutionScoreData>[
              ReportConstitutionScoreData(
                id: '',
                name: primaryConstitution,
                scorePercent: _clampPercent(summary.healthScore),
                hasScore: false,
              ),
            ],
      riskIndexes: List.unmodifiable(riskIndexes),
      healthRadarClassicSymptoms: const <ReportHealthRadarSymptomData>[],
      healthRadarDeepSymptoms: const <ReportHealthRadarSymptomData>[],
      heroSecondaryConstitutions: const <String>[],
      heroTongueSymptoms: const <String>[],
      tongueAnalysisItems: const <ReportTongueAnalysisItemData>[],
      heroImageUrls: faceImageUrl.isEmpty
          ? const <String>[]
          : List.unmodifiable(<String>[faceImageUrl]),
      recordedAt: summary.testTime.trim().isNotEmpty
          ? summary.testTime.trim()
          : null,
      source: null,
      tenantId: null,
      storeId: null,
      age: null,
      sex: null,
      primaryConstitution: primaryConstitution.isEmpty
          ? null
          : primaryConstitution,
      secondaryBias: null,
      summary: null,
      heroSkinAge: null,
      heroTherapySummary: null,
      consultNavigate: null,
    );
  }

  factory ReportViewData.fromDetail(
    DiagnosisReportDetail detail, {
    DiagnosisMaNavigate? consultNavigate,
  }) {
    final constitutions = detail.analysisResult.tzData;
    final constitutionScores = _buildConstitutionScores(detail);
    DiagnosisConstitution? secondaryConstitution;
    // 主体质会同时出现在 tz 和 tzData 中，hero 区只需要“次要偏向”，
    // 所以这里跳过主 id，拿第一个不同且有名称的结果作为补充说明。
    for (final item in constitutions) {
      final isDistinct = item.id != detail.analysisResult.tz.id;
      if (isDistinct && item.name.isNotEmpty) {
        secondaryConstitution = item;
        break;
      }
    }
    final primaryFinding = detail.analysisResult.result.isNotEmpty
        ? detail.analysisResult.result.first
        : null;
    final riskIndexes = <ReportRiskIndexData>[];
    for (final item
        in detail.analysisResult.deepPredicts.categoryProbabilities) {
      final name = item.name.isNotEmpty ? item.name : '风险指数';
      riskIndexes.add(
        ReportRiskIndexData(name: name, rawProbability: item.rawProbability),
      );
    }
    riskIndexes.sort(
      (left, right) => right.rawProbability.compareTo(left.rawProbability),
    );
    final classicSymptoms = detail.analysisResult.relativeSyms
        .map(_mapClassicHealthRadarSymptom)
        .whereType<ReportHealthRadarSymptomData>()
        .toList(growable: false);
    final deepSymptoms = detail.analysisResult.deepPredicts.predictions
        .map(_mapDeepHealthRadarSymptom)
        .whereType<ReportHealthRadarSymptomData>()
        .toList(growable: false);

    return ReportViewData(
      mode: ReportViewMode.live,
      reportId: detail.id.isNotEmpty ? detail.id : null,
      token: detail.token.trim().isNotEmpty ? detail.token.trim() : null,
      // 接口没有稳定提供面 / 舌 / 手三路独立总分，
      // 页面上的分项分数因此由总分 + finding 数量做保守推导。
      overallScore: _clampPercent(detail.healthScore),
      faceScore: _scoreFromFindings(
        detail.faceAnalysisResult.result.length,
        fallback: detail.healthScore - 2,
      ),
      tongueScore: _scoreFromFindings(
        detail.analysisResult.result.length,
        fallback: detail.healthScore - 8,
      ),
      palmScore: _scoreFromFindings(
        detail.handAnalysisResult.result.length,
        fallback: detail.healthScore - 4,
      ),
      recordedAt: detail.testTime.isNotEmpty ? detail.testTime : null,
      source: detail.source.isNotEmpty ? detail.source : null,
      tenantId: detail.tenantId.isNotEmpty ? detail.tenantId : null,
      storeId: detail.storeId.isNotEmpty ? detail.storeId : null,
      age: detail.faceAnalysisResult.age?.round(),
      sex: detail.faceAnalysisResult.sex.trim().isNotEmpty
          ? detail.faceAnalysisResult.sex.trim()
          : null,
      constitutionScores: constitutionScores,
      primaryConstitution: detail.analysisResult.tz.name.isNotEmpty
          ? detail.analysisResult.tz.name
          : null,
      secondaryBias: secondaryConstitution?.name.isNotEmpty == true
          ? secondaryConstitution!.name
          : null,
      summary: primaryFinding?.result.isNotEmpty == true
          ? primaryFinding!.result
          : null,
      heroSecondaryConstitutions: constitutionScores
          .skip(1)
          .map((item) => item.name.trim())
          .where((item) => item.isNotEmpty)
          .take(2)
          .toList(growable: false),
      heroTongueSymptoms: _extractHeroTongueSymptoms(detail.analysisResult),
      tongueAnalysisItems: _buildTongueAnalysisItems(detail.analysisResult),
      heroImageUrls: _collectHeroImageUrls(detail),
      heroSkinAge: detail.hideAge ? null : detail.faceAnalysisResult.age,
      heroTherapySummary: _resolveHeroTherapySummary(detail),
      riskIndexes: riskIndexes,
      healthRadarClassicSymptoms: classicSymptoms,
      healthRadarDeepSymptoms: deepSymptoms,
      consultNavigate: consultNavigate,
      includeQuestions:
          _asBool(detail.analysisResult.raw['includeQuestions']) == true ||
          _asBool(detail.raw['includeQuestions']) == true,
    );
  }
}

int _compareAnalysisSort(Object left, Object right) {
  final leftSortNo = _analysisSortNo(left) ?? 1 << 30;
  final rightSortNo = _analysisSortNo(right) ?? 1 << 30;
  return leftSortNo.compareTo(rightSortNo);
}

int? _analysisSortNo(Object value) {
  if (value is ReportPhysiqueAnalysisItemData) {
    return value.sortNo;
  }
  if (value is ReportPhysiqueAnalysisSectionData) {
    return value.sortNo;
  }
  if (value is ReportPhysiqueAnalysisContentData) {
    return value.sortNo;
  }
  return null;
}

List<ReportConstitutionScoreData> _buildConstitutionScores(
  DiagnosisReportDetail detail,
) {
  // 体质分一部分来自 analysisResult.tzData，另一部分来自 tzpdAnalysisResult。
  // 这里先把补充分统一叠加，再按展示分排序。
  final scoreAdjustments = _constitutionScoreAdjustments(
    detail.tzpdAnalysisResult,
  );
  final scores = <ReportConstitutionScoreData>[];
  final seenKeys = <String>{};

  void addScore({
    required String id,
    required String name,
    required double scorePercent,
    bool hasScore = true,
  }) {
    final normalizedId = id.trim();
    final normalizedName = name.trim();
    final resolvedName = normalizedName.isNotEmpty
        ? normalizedName
        : _constitutionNameForId(normalizedId);
    if (resolvedName.isEmpty) {
      return;
    }

    final key = normalizedId.isNotEmpty
        ? 'id:$normalizedId'
        : 'name:${resolvedName.toLowerCase()}';
    if (!seenKeys.add(key)) {
      return;
    }

    scores.add(
      ReportConstitutionScoreData(
        id: normalizedId,
        name: resolvedName,
        scorePercent: _clampPercent(scorePercent),
        hasScore: hasScore,
      ),
    );
  }

  for (final item in detail.analysisResult.tzData) {
    addScore(
      id: item.id,
      name: item.name,
      scorePercent: item.score + (scoreAdjustments[item.id] ?? 0),
      hasScore:
          _hasConstitutionScoreField(item.raw) ||
          scoreAdjustments.containsKey(item.id),
    );
  }

  if (scores.isEmpty) {
    for (final item in _constitutionScoresFromTzpd(detail.tzpdAnalysisResult)) {
      addScore(id: item.$1, name: item.$2, scorePercent: item.$3);
    }
  }

  final primaryConstitution = detail.analysisResult.tz;
  final primaryHasScore = _hasConstitutionScoreField(primaryConstitution.raw);
  if (primaryConstitution.name.trim().isNotEmpty &&
      (primaryHasScore || scores.isEmpty)) {
    addScore(
      id: primaryConstitution.id,
      name: primaryConstitution.name,
      scorePercent: primaryConstitution.score,
      hasScore: primaryHasScore,
    );
  }

  scores.sort((a, b) => b.scorePercent.compareTo(a.scorePercent));
  return List.unmodifiable(scores);
}

List<String> _extractHeroTongueSymptoms(
  DiagnosisAnalysisResult analysisResult,
) {
  final symptoms = <String>[];
  for (final finding in analysisResult.result) {
    for (final symptom in finding.symptoms) {
      final name = symptom.name.trim();
      // Hero 区只保留去重后的短标签，避免同一舌象在摘要里重复占位。
      if (name.isEmpty || symptoms.contains(name)) {
        continue;
      }
      symptoms.add(name);
    }
  }
  return List.unmodifiable(symptoms);
}

List<ReportTongueAnalysisItemData> _buildTongueAnalysisItems(
  DiagnosisAnalysisResult analysisResult,
) {
  final items = <ReportTongueAnalysisItemData>[];
  for (final finding in analysisResult.result) {
    final title = _resolveTongueFindingTitle(finding);
    if (title.isEmpty) {
      continue;
    }

    final symptomNames = _collectUniqueTexts(
      finding.symptoms.map((item) => item.name),
    );
    if (symptomNames.isEmpty) {
      continue;
    }

    final pathologyNotes = _collectUniqueTexts(
      finding.symptoms.map(
        (item) => _resolveTonguePathologyText(finding, item),
      ),
    );

    final findingKey = _resolveTongueFindingKey(finding);
    items.add(
      ReportTongueAnalysisItemData(
        key: findingKey.isNotEmpty ? findingKey : title,
        title: title,
        resultText: symptomNames.join('、'),
        pathologyText: pathologyNotes.isNotEmpty
            ? pathologyNotes.join('；')
            : '提示舌象存在偏性，建议结合体感与生活习惯综合判断。',
      ),
    );
  }
  return List.unmodifiable(items);
}

String _resolveTongueFindingTitle(DiagnosisFinding finding) {
  final rawTitle = _asString(finding.raw['typeDesc']).trim();
  if (rawTitle.isNotEmpty) {
    return rawTitle;
  }
  return finding.name.trim();
}

String _resolveTongueFindingKey(DiagnosisFinding finding) {
  final rawKey = _asString(finding.raw['type']).trim();
  if (rawKey.isNotEmpty) {
    return rawKey;
  }
  return finding.key.trim();
}

String _resolveTonguePathologyText(
  DiagnosisFinding finding,
  DiagnosisSymptom symptom,
) {
  final describe = _asString(symptom.raw['describe']).trim();
  if (describe.isNotEmpty) {
    return describe;
  }

  final symptomName = symptom.name.trim();
  final byName = _kTonguePathologyBySymptomName[symptomName];
  if (byName != null) {
    return byName;
  }

  for (final entry in _kTonguePathologyBySymptomKeyword.entries) {
    if (symptomName.contains(entry.key)) {
      return entry.value;
    }
  }

  // 后端 `describe` 缺失时，按“症状名精确映射 -> 关键词映射 -> finding 兜底”
  // 逐层回退，尽量保证每张舌象卡片都有可读解释。
  for (final candidate in [
    _resolveTongueFindingKey(finding),
    _resolveTongueFindingTitle(finding),
  ]) {
    final resolved = _kTonguePathologyByFinding[candidate];
    if (resolved != null) {
      return resolved;
    }
  }

  return '提示舌象存在偏性，建议结合体感与生活习惯综合判断。';
}

List<String> _collectUniqueTexts(Iterable<String> values) {
  final resolved = <String>[];
  for (final value in values) {
    final normalized = value.trim();
    if (normalized.isEmpty || resolved.contains(normalized)) {
      continue;
    }
    resolved.add(normalized);
  }
  return List.unmodifiable(resolved);
}

List<String> _collectHeroImageUrls(DiagnosisReportDetail detail) {
  final urls = <String>[];
  for (final value in [
    detail.imageUrl,
    detail.faceAnalysisResult.imageUrl,
    detail.handAnalysisResult.imageUrl,
  ]) {
    final normalized = value.trim();
    if (normalized.isEmpty || urls.contains(normalized)) {
      continue;
    }
    urls.add(normalized);
  }
  return List.unmodifiable(urls);
}

String? _resolveHeroTherapySummary(DiagnosisReportDetail detail) {
  final therapy = detail.analysisResult.tz.solutions.trim();
  if (therapy.isNotEmpty) {
    return therapy;
  }

  for (final finding in detail.analysisResult.result) {
    final result = finding.result.trim();
    if (result.isNotEmpty) {
      return result;
    }
  }

  return null;
}

Map<String, double> _constitutionScoreAdjustments(
  Map<String, dynamic> tzpdAnalysisResult,
) {
  final results = tzpdAnalysisResult['results'];
  if (results is! List) {
    return const <String, double>{};
  }

  final adjustments = <String, double>{};
  for (final item in results) {
    final value = _asMap(item);
    final id = _asString(value['id']).trim();
    if (id.isEmpty) {
      continue;
    }

    // 历史接口里既出现过 score，也出现过 prob，量纲还可能是 0-1 或 0-100。
    // 先做字段兜底，再统一归一到百分制。
    final rawScore = _asNum(value['score']) ?? _asNum(value['prob']);
    if (rawScore == null) {
      continue;
    }
    final score = _normalizePercent(rawScore);
    adjustments[id] = score;
  }
  return adjustments;
}

List<(String, String, double)> _constitutionScoresFromTzpd(
  Map<String, dynamic> tzpdAnalysisResult,
) {
  final results = tzpdAnalysisResult['results'];
  if (results is! List) {
    return const <(String, String, double)>[];
  }

  final scores = <(String, String, double)>[];
  for (final item in results) {
    final value = _asMap(item);
    final id = _firstNonEmpty([
      _asString(value['id']),
      _asString(value['physiqueId']),
      _asString(value['constitutionId']),
      _asString(value['tzId']),
      _asString(value['typeId']),
    ]);
    final name = _firstNonEmpty([
      _asString(value['name']),
      _asString(value['physiqueName']),
      _asString(value['constitutionName']),
      _asString(value['tzName']),
      _asString(value['typeName']),
      _asString(value['displayName']),
    ]);
    final rawScore =
        _asNum(value['score']) ??
        _asNum(value['prob']) ??
        _asNum(value['percent']) ??
        _asNum(value['ratio']) ??
        _asNum(value['value']);
    if (rawScore == null) {
      continue;
    }

    final resolvedName = name.isNotEmpty ? name : _constitutionNameForId(id);
    if (resolvedName.isEmpty) {
      continue;
    }
    scores.add((id, resolvedName, _normalizePercent(rawScore)));
  }
  return List.unmodifiable(scores);
}

String _constitutionNameForId(String id) {
  return switch (id.trim()) {
    '1' => '平和质',
    '2' => '气虚质',
    '3' => '阳虚质',
    '4' => '阴虚质',
    '5' => '痰湿质',
    '6' => '湿热质',
    '7' => '血瘀质',
    '8' => '气郁质',
    '9' => '特禀质',
    _ => '',
  };
}

String _firstNonEmpty(List<String> values) {
  for (final value in values) {
    final normalized = value.trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }
  }
  return '';
}

bool _hasConstitutionScoreField(Map<String, dynamic> value) {
  for (final key in const ['score', 'prob', 'percent', 'ratio', 'value']) {
    if (_asNum(value[key]) != null) {
      return true;
    }
  }
  return false;
}

ReportHealthRadarSymptomData? _mapClassicHealthRadarSymptom(
  DiagnosisNamedProbability item,
) {
  final name = item.name.trim();
  if (name.isEmpty) {
    return null;
  }
  return ReportHealthRadarSymptomData(
    id: item.id,
    name: name,
    selected: _resolveSelectedFlag(item.raw),
    raw: item.raw,
  );
}

ReportHealthRadarSymptomData? _mapDeepHealthRadarSymptom(
  DiagnosisNamedProbability item,
) {
  final name = item.name.trim();
  if (name.isEmpty) {
    return null;
  }
  return ReportHealthRadarSymptomData(
    id: item.id,
    name: name,
    selected: false,
    raw: item.raw,
  );
}

bool _resolveSelectedFlag(Map<String, dynamic> raw) {
  for (final key in const ['selected', 'isSelected', 'checked']) {
    final value = raw[key];
    final resolved = _asBool(value);
    if (resolved != null) {
      return resolved;
    }
  }
  return false;
}

double _scoreFromFindings(int count, {required double fallback}) {
  final seed = fallback + (count * 3);
  return _clampPercent(seed);
}

double _clampPercent(num value) {
  return value.toDouble().clamp(0.0, 100.0);
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

List<Object?> _asList(Object? value) {
  if (value is List) {
    return value;
  }
  return const <Object?>[];
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

double _normalizePercent(num? value) {
  if (value == null) {
    return 0;
  }
  final normalized = value.toDouble();
  // 兼容 0-1 小数概率和 0-100 百分制两种返回格式。
  if (normalized <= 1) {
    return normalized * 100;
  }
  if (normalized <= 100) {
    return normalized;
  }
  return 100;
}

bool? _asBool(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
  }
  return null;
}

const Map<String, String> _kTonguePathologyBySymptomName = {
  '舌苔白': '多提示寒湿偏盛，阳气稍弱。',
  '齿痕': '多见于脾虚湿盛，运化乏力。',
  '芒刺瘀点': '多提示热象或瘀阻，需留意气血运行。',
  '瘀点': '多提示热象或瘀阻，需留意气血运行。',
  '舌裂': '多提示阴液不足或津血偏亏。',
  '舌苔黄': '多提示湿热或里热偏盛。',
};

const Map<String, String> _kTonguePathologyBySymptomKeyword = {
  '薄腻': '多提示湿浊内停，脾胃运化不畅。',
  '厚腻': '多提示湿浊内停，脾胃运化不畅。',
  '腻': '多提示湿浊内停，脾胃运化不畅。',
};

const Map<String, String> _kTonguePathologyByFinding = {
  'tongue_isIndentation': '多见于脾虚湿盛，运化乏力。',
  '齿痕': '多见于脾虚湿盛，运化乏力。',
  'tongue_isStab': '多提示热象或瘀阻，需留意气血运行。',
  '芒刺瘀点': '多提示热象或瘀阻，需留意气血运行。',
  'tongue_bao_greasy': '多提示湿浊内停，脾胃运化不畅。',
  '舌苔薄腻': '多提示湿浊内停，脾胃运化不畅。',
  'tongue_isCrack': '多提示阴液不足或津血偏亏。',
  '舌裂': '多提示阴液不足或津血偏亏。',
  'moss_color': '提示舌苔颜色存在偏性，建议结合体感继续观察。',
  '舌苔颜色': '提示舌苔颜色存在偏性，建议结合体感继续观察。',
  'tongue_moss_state': '提示舌苔状态存在偏性，建议结合饮食与作息继续观察。',
  '舌苔状态': '提示舌苔状态存在偏性，建议结合饮食与作息继续观察。',
  'tongue_color': '提示舌色存在偏性，建议结合体感继续观察。',
  '舌色': '提示舌色存在偏性，建议结合体感继续观察。',
};
