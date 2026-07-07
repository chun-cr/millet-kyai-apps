part of '../report_page.dart';

class _StatusHeroCard extends StatelessWidget {
  const _StatusHeroCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.13)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1810),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTimelineItem extends StatelessWidget {
  const _HistoryTimelineItem({required this.item, required this.isLast});

  final DiagnosisReportSummary item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final healthScore = item.healthScore;
    final score = healthScore.toStringAsFixed(healthScore % 1 == 0 ? 0 : 1);
    final title = _nonEmpty(item.physiqueName) ?? '历史报告';
    final status = _nonEmpty(item.lockedStatus) ?? '状态未知';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5B95).withValues(alpha: 0.11),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF6B5B95).withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  size: 15,
                  color: Color(0xFF6B5B95),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    color: const Color(0xFF6B5B95).withValues(alpha: 0.16),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: const Color(0xFF6B5B95).withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E1810),
                            ),
                          ),
                        ),
                        _SmallBadge(
                          text: status,
                          color: const Color(0xFF6B5B95),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InlineFact(label: '分数', value: score),
                        _InlineFact(
                          label: '时间',
                          value: _nonEmpty(item.testTime) ?? '未知',
                        ),
                        _InlineFact(label: 'ID', value: item.id),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NarrativeBlock extends StatelessWidget {
  const _NarrativeBlock({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.11)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 1.65,
              color: const Color(0xFF3A3028).withValues(alpha: 0.74),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyValueCard extends StatelessWidget {
  const _CopyValueCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF1E1810),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filledTonal(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (context.mounted) {
                showAppToast(context, '$title 已复制', kind: AppToastKind.success);
              }
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            color: color,
            tooltip: '复制$title',
          ),
        ],
      ),
    );
  }
}

class _ReportFact {
  const _ReportFact({required this.label, required this.value});

  final String label;
  final String value;
}

class _ReportFactGrid extends StatelessWidget {
  const _ReportFactGrid({required this.facts});

  final List<_ReportFact> facts;

  @override
  Widget build(BuildContext context) {
    if (facts.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 500;
        final width = useTwoColumns
            ? (constraints.maxWidth - 8) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final fact in facts)
              SizedBox(
                width: width,
                child: _FactCard(fact: fact),
              ),
          ],
        );
      },
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({required this.fact});

  final _ReportFact fact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF3A3028).withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fact.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF3A3028).withValues(alpha: 0.42),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            fact.value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E1810),
            ),
          ),
        ],
      ),
    );
  }
}

class _RawPayloadBlock extends StatelessWidget {
  const _RawPayloadBlock({required this.payload});

  final Object payload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          title: Text(
            '技术字段',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF3A3028).withValues(alpha: 0.58),
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1810).withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
              ),
              child: SelectableText(
                _prettyJson(payload),
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.45,
                  color: Color(0xFF3A3028),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportEmptyVisual extends StatelessWidget {
  const _ReportEmptyVisual({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF3A3028).withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF4A7FA8).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_outlined,
              color: Color(0xFF4A7FA8),
              size: 23,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E1810),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: const Color(0xFF3A3028).withValues(alpha: 0.56),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _InlineFact extends StatelessWidget {
  const _InlineFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF6B5B95).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B5B95),
        ),
      ),
    );
  }
}

List<_ReportFact> _buildFacts(
  Map<String, dynamic> payload, {
  Set<String> excludeKeys = const {},
  int maxItems = 8,
}) {
  final facts = <_ReportFact>[];
  final lowerExcludes = excludeKeys.map((key) => key.toLowerCase()).toSet();

  for (final entry in payload.entries) {
    if (lowerExcludes.contains(entry.key.toLowerCase())) {
      continue;
    }
    final value = _compactValue(entry.value);
    if (value == null) {
      continue;
    }
    facts.add(
      _ReportFact(label: _humanizeKey(entry.key), value: _clip(value, 120)),
    );
    if (facts.length >= maxItems) {
      break;
    }
  }

  return facts;
}

String? _firstNonEmptyText(Map<String, dynamic> payload, List<String> keys) {
  for (final key in keys) {
    final value = _valueForKey(payload, key);
    final text = _compactValue(value);
    if (text != null) {
      return text;
    }
  }
  return null;
}

Object? _valueForKey(Map<String, dynamic> payload, String key) {
  if (payload.containsKey(key)) {
    return payload[key];
  }
  final lowerKey = key.toLowerCase();
  for (final entry in payload.entries) {
    if (entry.key.toLowerCase() == lowerKey) {
      return entry.value;
    }
  }
  return null;
}

String? _compactValue(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return _nonEmpty(value);
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  if (value is Iterable) {
    final values = value
        .map(_compactValue)
        .whereType<String>()
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
    if (values.isEmpty) {
      return null;
    }
    return values.length <= 4 ? values.join('、') : _prettyJson(value);
  }
  if (value is Map) {
    final normalized = value.map(
      (key, mapValue) => MapEntry(key.toString(), mapValue),
    );
    return _firstNonEmptyText(normalized, const [
          'name',
          'title',
          'label',
          'value',
          'content',
          'description',
        ]) ??
        _prettyJson(normalized);
  }
  return _nonEmpty(value.toString());
}

String? _nonEmpty(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
}

String _clip(String value, int maxLength) {
  if (value.length <= maxLength) {
    return value;
  }
  return '${value.substring(0, maxLength)}...';
}

String _humanizeKey(String key) {
  const labels = {
    'id': 'ID',
    'reportId': '报告ID',
    'lockedStatus': '锁定状态',
    'status': '状态',
    'state': '状态',
    'token': '令牌',
    'downloadToken': '下载令牌',
    'shareToken': '分享令牌',
    'url': '链接',
    'downloadUrl': '下载链接',
    'shareUrl': '分享链接',
    'createdAt': '创建时间',
    'updatedAt': '更新时间',
    'testTime': '检测时间',
    'healthScore': '健康分',
    'physiqueName': '体质',
    'name': '名称',
    'title': '标题',
    'type': '类型',
    'category': '分类',
    'summary': '摘要',
    'description': '描述',
    'content': '内容',
    'suggestion': '建议',
    'advice': '建议',
    'effect': '作用',
    'functions': '功效',
  };
  final labeled = labels[key];
  if (labeled != null) {
    return labeled;
  }
  final spaced = key
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) {
        return '${match.group(1)} ${match.group(2)}';
      })
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .trim();
  return spaced.isEmpty ? key : spaced;
}

String _prettyJson(Object payload) {
  try {
    return const JsonEncoder.withIndent('  ').convert(payload);
  } catch (_) {
    return payload.toString();
  }
}
