// 报告模块展示模型：`ReportProjectData`。把原始数据整理成页面卡片和详情页可直接渲染的字段。

import 'package:flutter/material.dart';
import 'package:millet_kyai_apps/l10n/app_localizations.dart';

@immutable
class ReportProjectData {
  const ReportProjectData({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.tag,
    required this.durationNote,
    required this.serviceNote,
    required this.consultNote,
    required this.color,
    required this.icon,
  });

  final String id;
  final String name;
  final String type;
  final String description;
  final String tag;
  final String durationNote;
  final String serviceNote;
  final String consultNote;
  final Color color;
  final IconData icon;

  Map<String, String> toRouteQueryParameters() {
    return <String, String>{
      'id': id,
      'name': name,
      'type': type,
      'description': description,
      'tag': tag,
      'durationNote': durationNote,
      'serviceNote': serviceNote,
      'consultNote': consultNote,
      'color': color.toARGB32().toString(),
      'iconCodePoint': icon.codePoint.toString(),
      if (icon.fontFamily != null && icon.fontFamily!.isNotEmpty)
        'iconFontFamily': icon.fontFamily!,
      if (icon.fontPackage != null && icon.fontPackage!.isNotEmpty)
        'iconFontPackage': icon.fontPackage!,
      'iconMatchTextDirection': icon.matchTextDirection.toString(),
    };
  }

  static ReportProjectData? fromRouteQueryParameters(
    Map<String, String> queryParameters,
  ) {
    final id = queryParameters['id']?.trim() ?? '';
    final name = queryParameters['name']?.trim() ?? '';
    final type = queryParameters['type']?.trim() ?? '';
    final description = queryParameters['description']?.trim() ?? '';
    final tag = queryParameters['tag']?.trim() ?? '';
    final durationNote = queryParameters['durationNote']?.trim() ?? '';
    final serviceNote = queryParameters['serviceNote']?.trim() ?? '';
    final consultNote = queryParameters['consultNote']?.trim() ?? '';
    if (id.isEmpty ||
        name.isEmpty ||
        type.isEmpty ||
        description.isEmpty ||
        tag.isEmpty ||
        durationNote.isEmpty ||
        serviceNote.isEmpty ||
        consultNote.isEmpty) {
      return null;
    }

    final colorValue = int.tryParse(queryParameters['color'] ?? '');
    final iconCodePoint = int.tryParse(queryParameters['iconCodePoint'] ?? '');
    final iconFontFamily = queryParameters['iconFontFamily'];
    final iconFontPackage = queryParameters['iconFontPackage'];
    final iconMatchTextDirection =
        queryParameters['iconMatchTextDirection'] == 'true';

    return ReportProjectData(
      id: id,
      name: name,
      type: type,
      description: description,
      tag: tag,
      durationNote: durationNote,
      serviceNote: serviceNote,
      consultNote: consultNote,
      color: colorValue != null
          ? Color(colorValue)
          : _kProjectFallbackColors.first,
      icon: iconCodePoint != null
          ? IconData(
              iconCodePoint,
              fontFamily: iconFontFamily ?? 'MaterialIcons',
              fontPackage: iconFontPackage,
              matchTextDirection: iconMatchTextDirection,
            )
          : Icons.healing_outlined,
    );
  }

  factory ReportProjectData.fromBackend(
    Map<String, dynamic> json, {
    int index = 0,
  }) {
    return ReportProjectData(
      id:
          _firstText(json, const ['id', 'projectId', 'itemId', 'code']) ??
          'project-$index',
      name: _firstText(json, const ['name', 'projectName', 'title']) ?? '推荐项目',
      type:
          _firstText(json, const [
            'type',
            'typeName',
            'categoryName',
            'projectType',
          ]) ??
          _kDefaultProjectType,
      description:
          _firstText(json, const [
            'description',
            'desc',
            'detail',
            'recommendationReason',
            'reason',
            'summary',
          ]) ??
          _kDefaultProjectDescription,
      tag:
          _firstText(json, const [
            'tag',
            'label',
            'badge',
            'recommendTag',
            'sceneTag',
          ]) ??
          (index == 0 ? '推荐' : '精选'),
      durationNote:
          _firstText(json, const [
            'durationDesc',
            'duration',
            'courseDesc',
            'cycleDesc',
            'serviceDuration',
          ]) ??
          _kDefaultProjectDurationNote,
      serviceNote:
          _firstText(json, const [
            'serviceNote',
            'serviceDesc',
            'notice',
            'bookingNote',
            'treatmentNote',
            'applyNote',
          ]) ??
          _kDefaultProjectServiceNote,
      consultNote:
          _firstText(json, const [
            'consultNote',
            'consultDesc',
            'contactNote',
            'reservationNote',
            'instructions',
          ]) ??
          _kDefaultProjectConsultNote,
      color: _resolveColor(json, index),
      icon: _resolveIcon(json, index),
    );
  }
}

List<ReportProjectData> buildReportProjects(AppLocalizations l10n) {
  return [
    ReportProjectData(
      id: 'warm-moxibustion',
      name: l10n.reportProjectWarmMoxibustion,
      type: l10n.reportProjectWarmMoxibustionType,
      description: l10n.reportProjectWarmMoxibustionDesc,
      tag: l10n.reportProjectWarmMoxibustionTag,
      durationNote: l10n.reportProjectWarmMoxibustionDuration,
      serviceNote: l10n.reportProjectCommonServiceNote,
      consultNote: l10n.reportProjectCommonConsultNote,
      color: const Color(0xFFB96A3A),
      icon: Icons.local_fire_department_outlined,
    ),
    ReportProjectData(
      id: 'meridian-relief',
      name: l10n.reportProjectMeridianRelief,
      type: l10n.reportProjectMeridianReliefType,
      description: l10n.reportProjectMeridianReliefDesc,
      tag: l10n.reportProjectMeridianReliefTag,
      durationNote: l10n.reportProjectMeridianReliefDuration,
      serviceNote: l10n.reportProjectCommonServiceNote,
      consultNote: l10n.reportProjectCommonConsultNote,
      color: const Color(0xFF2D6A4F),
      icon: Icons.spa_outlined,
    ),
  ];
}

const _kProjectFallbackColors = <Color>[
  Color(0xFF2D6A4F),
  Color(0xFFB96A3A),
  Color(0xFF4A7FA8),
  Color(0xFF6B5B95),
];

const _kDefaultProjectType = '调理项目';
const _kDefaultProjectDescription = '基于报告结果匹配的到店服务项目。';
const _kDefaultProjectDurationNote = '服务时长以门店安排为准';
const _kDefaultProjectServiceNote = '需由门店评估后安排具体服务方案。';
const _kDefaultProjectConsultNote = '支持到店咨询与预约，实际排期以门店安排为准。';

String? _firstText(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty) {
      return text;
    }
  }
  return null;
}

Color _resolveColor(Map<String, dynamic> json, int index) {
  return _tryResolveColor(json) ??
      _kProjectFallbackColors[index % _kProjectFallbackColors.length];
}

Color? _tryResolveColor(Map<String, dynamic> json) {
  for (final key in const ['color', 'themeColor', 'brandColor', 'mainColor']) {
    final color = _parseColorValue(json[key]);
    if (color != null) {
      return color;
    }
  }
  return null;
}

Color? _parseColorValue(Object? value) {
  if (value is Color) {
    return value;
  }
  if (value is int) {
    return Color(value);
  }
  if (value is String) {
    var hex = value.trim();
    if (hex.isEmpty) {
      return null;
    }
    hex = hex
        .replaceFirst('#', '')
        .replaceFirst('0x', '')
        .replaceFirst('0X', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length != 8) {
      return null;
    }
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) {
      return null;
    }
    return Color(parsed);
  }
  return null;
}

IconData _resolveIcon(Map<String, dynamic> json, int index) {
  return _tryResolveIcon(json) ??
      switch (index % 4) {
        0 => Icons.local_fire_department_outlined,
        1 => Icons.spa_outlined,
        2 => Icons.favorite_outline,
        _ => Icons.healing_outlined,
      };
}

IconData? _tryResolveIcon(Map<String, dynamic> json) {
  final hint = [
    _firstText(json, const ['icon', 'iconName', 'iconKey']),
    _firstText(json, const ['category', 'categoryName', 'type', 'typeName']),
    _firstText(json, const ['name', 'title', 'description']),
  ].whereType<String>().join(' ').toLowerCase();

  if (hint.trim().isEmpty) {
    return null;
  }

  if (hint.contains('mox') ||
      hint.contains('warm') ||
      hint.contains('艾') ||
      hint.contains('灸')) {
    return Icons.local_fire_department_outlined;
  }

  if (hint.contains('massage') ||
      hint.contains('meridian') ||
      hint.contains('spa') ||
      hint.contains('推拿') ||
      hint.contains('经络')) {
    return Icons.spa_outlined;
  }

  if (hint.contains('care') ||
      hint.contains('repair') ||
      hint.contains('调理') ||
      hint.contains('理疗')) {
    return Icons.healing_outlined;
  }

  return Icons.favorite_outline;
}
