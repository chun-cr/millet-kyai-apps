part of '../report_page.dart';

// ignore_for_file: unused_element

class _HeroPill extends StatelessWidget {
  final String label;
  final bool active;

  // ignore: unused_element_parameter
  const _HeroPill({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        // 核心：去掉边框，改用低透明度纯净底色。
        color: active
            ? const Color(0xFF2D6A4F).withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active
              ? const Color(0xFF2D6A4F)
              : const Color(0xFF2D6A4F).withValues(alpha: 0.6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// 共享子组件

/// 卡片容器。
class _SectionCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final Color? shadowColor;

  const _SectionCard({required this.child, this.borderColor, this.shadowColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor ?? const Color(0xFF2D6A4F).withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                shadowColor ?? const Color(0xFF2D6A4F).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FloatingSectionTitle extends StatelessWidget {
  final String title;
  final Color accentColor;

  const _FloatingSectionTitle({
    required this.title,
    this.accentColor = const Color(0xFFC9A84C),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E1810),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

String? _nonEmpty(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

Object? _valueForKey(Map<String, dynamic> payload, String key) {
  if (payload.containsKey(key)) {
    return payload[key];
  }
  final normalizedKey = key.toLowerCase();
  for (final entry in payload.entries) {
    if (entry.key.toLowerCase() == normalizedKey) {
      return entry.value;
    }
  }
  return null;
}

String? _firstNonEmptyText(Map<String, dynamic> payload, List<String> keys) {
  for (final key in keys) {
    final value = _valueForKey(payload, key);
    if (value is String) {
      final normalized = _nonEmpty(value);
      if (normalized != null) {
        return normalized;
      }
    } else if (value is num || value is bool) {
      return value.toString();
    }
  }
  return null;
}

Widget _buildPhysiqueAnalysisStatusCard(
  BuildContext context,
  _ReportPhysiqueAnalysisState state,
) {
  final l10n = context.l10n;
  final message = switch (state.status) {
    _ReportPhysiqueAnalysisStatus.loading => l10n.reportPhysiqueAnalysisLoading,
    _ReportPhysiqueAnalysisStatus.failed => l10n.reportPhysiqueAnalysisFailed,
    _ => l10n.reportPhysiqueAnalysisEmpty,
  };
  final color = switch (state.status) {
    _ReportPhysiqueAnalysisStatus.loading => const Color(0xFF4A7FA8),
    _ReportPhysiqueAnalysisStatus.failed => const Color(0xFFC06A3A),
    _ => const Color(0xFFC9A84C),
  };

  return _SectionCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 12,
              height: 1.55,
              color: const Color(0xFF3A3028).withValues(alpha: 0.62),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildPhysiqueAnalysisSectionCard(
  BuildContext context,
  _ReportPhysiqueAnalysisState state,
  ReportPhysiqueAnalysisSectionData? section,
) {
  if (section == null ||
      (section.title.isEmpty &&
          section.sectionImageUrl.isEmpty &&
          section.contents.isEmpty)) {
    return _buildPhysiqueAnalysisStatusCard(context, state);
  }

  final sectionType = section.sectionType.toLowerCase();
  final accentColor = _physiqueAnalysisSectionAccentColor(sectionType);
  final fallbackTitle =
      _nonEmpty(state.data?.name) ?? _nonEmpty(section.title) ?? '';

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _PhysiqueAnalysisSectionHero(
        key: ValueKey('report_physique_analysis_section_hero_$sectionType'),
        imageUrl: section.sectionImageUrl,
        imageAlt: section.sectionImageAlt,
        placeholderTitle: fallbackTitle,
        accentColor: accentColor,
      ),
      if (section.contents.isNotEmpty) const SizedBox(height: 12),
      ...List.generate(section.contents.length, (index) {
        final content = section.contents[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < section.contents.length - 1 ? 8 : 0,
          ),
          child: _PhysiqueAnalysisContentItem(
            key: ValueKey(
              'report_physique_analysis_section_content_${sectionType}_$index',
            ),
            content: content,
            accentColor: accentColor,
            icon: _physiqueAnalysisContentIcon(sectionType, index),
          ),
        );
      }),
    ],
  );
}

Color _physiqueAnalysisSectionAccentColor(String sectionType) {
  return switch (sectionType) {
    'interpretation' => const Color(0xFF6B5B95),
    'conditioning_reference' => const Color(0xFF2D6A4F),
    'diet_reference' => const Color(0xFFB96A3A),
    _ => const Color(0xFF4A7FA8),
  };
}

IconData _physiqueAnalysisContentIcon(String sectionType, int index) {
  const interpretationIcons = [
    Icons.menu_book_outlined,
    Icons.accessibility_new_outlined,
    Icons.health_and_safety_outlined,
    Icons.psychology_outlined,
  ];
  const conditioningIcons = [
    Icons.self_improvement_outlined,
    Icons.nightlight_outlined,
    Icons.directions_walk_outlined,
    Icons.spa_outlined,
  ];
  const dietIcons = [
    Icons.restaurant_outlined,
    Icons.local_dining_outlined,
    Icons.no_food_outlined,
    Icons.menu_book_outlined,
  ];

  final icons = switch (sectionType) {
    'interpretation' => interpretationIcons,
    'conditioning_reference' => conditioningIcons,
    'diet_reference' => dietIcons,
    _ => interpretationIcons,
  };
  return icons[index % icons.length];
}

class _PhysiqueAnalysisSectionHero extends StatelessWidget {
  const _PhysiqueAnalysisSectionHero({
    super.key,
    required this.imageUrl,
    required this.imageAlt,
    required this.placeholderTitle,
    required this.accentColor,
  });

  final String imageUrl;
  final String imageAlt;
  final String placeholderTitle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final semanticLabel =
        _nonEmpty(imageAlt) ?? _nonEmpty(placeholderTitle) ?? '';
    final hasImage = imageUrl.isNotEmpty;

    return Semantics(
      image: semanticLabel.isNotEmpty,
      label: semanticLabel.isEmpty ? null : semanticLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 1.84,
          child: hasImage
              ? Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return _PhysiqueAnalysisSectionImagePlaceholder(
                      title: placeholderTitle,
                      accentColor: accentColor,
                    );
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      _PhysiqueAnalysisSectionImagePlaceholder(
                        title: placeholderTitle,
                        accentColor: accentColor,
                      ),
                )
              : _PhysiqueAnalysisSectionImagePlaceholder(
                  key: const ValueKey(
                    'report_physique_analysis_section_image_placeholder',
                  ),
                  title: placeholderTitle,
                  accentColor: accentColor,
                ),
        ),
      ),
    );
  }
}

class _PhysiqueAnalysisSectionImagePlaceholder extends StatelessWidget {
  const _PhysiqueAnalysisSectionImagePlaceholder({
    super.key,
    required this.title,
    required this.accentColor,
  });

  final String title;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: accentColor.withValues(alpha: 0.06),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.image_outlined,
              size: 21,
              color: accentColor.withValues(alpha: 0.72),
            ),
          ),
          if (title.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1810),
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhysiqueAnalysisContentItem extends StatelessWidget {
  const _PhysiqueAnalysisContentItem({
    super.key,
    required this.content,
    required this.accentColor,
    required this.icon,
  });

  final ReportPhysiqueAnalysisContentData content;
  final Color accentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      borderColor: accentColor.withValues(alpha: 0.08),
      shadowColor: accentColor.withValues(alpha: 0.035),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (content.contentTitle.isNotEmpty) ...[
                  Text(
                    content.contentTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E1810),
                      height: 1.35,
                    ),
                  ),
                  if (content.contentText.isNotEmpty) const SizedBox(height: 4),
                ],
                if (content.contentText.isNotEmpty)
                  Text(
                    content.contentText,
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF3A3028).withValues(alpha: 0.66),
                      height: 1.6,
                    ),
                  ),
                if (content.imageUrl.isNotEmpty) ...[
                  if (content.hasTextContent) const SizedBox(height: 10),
                  _PhysiqueAnalysisNetworkImage(
                    imageUrl: content.imageUrl,
                    imageAlt: content.imageAlt,
                    height: 112,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhysiqueAnalysisNetworkImage extends StatelessWidget {
  const _PhysiqueAnalysisNetworkImage({
    required this.imageUrl,
    required this.imageAlt,
    required this.height,
  });

  final String imageUrl;
  final String imageAlt;
  final double height;

  @override
  Widget build(BuildContext context) {
    final alt = imageAlt.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        semanticLabel: alt.isEmpty ? null : alt,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Container(
            height: height,
            width: double.infinity,
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.05),
          );
        },
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class _SeasonalFocusBanner extends StatelessWidget {
  final String title;
  final String tag;
  final String subtitle;

  const _SeasonalFocusBanner({
    required this.title,
    required this.tag,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF3E0).withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFC9A84C).withValues(alpha: 0.16),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E1810),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: const Color(0xFFC9A84C).withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: Text(
              tag,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8B6914),
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              height: 1.5,
              color: const Color(0xFF3A3028).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndentedDivider extends StatelessWidget {
  final double indent;

  const _IndentedDivider({required this.indent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Container(
        height: 1,
        width: double.infinity,
        color: Colors.grey.withValues(alpha: 0.10),
      ),
    );
  }
}

/// 柔和连续渐变进度条。
class _SoftGradientProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final bool emphasize;
  final Color? trackColor;
  final List<Color>? fillColors;

  const _SoftGradientProgressBar({
    required this.value,
    this.height = 4,
    this.emphasize = false,
    this.trackColor,
    this.fillColors,
  });

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0);
    final radius = Radius.circular(height);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color:
            trackColor ??
            (emphasize ? const Color(0xFFF6F7F2) : const Color(0xFFF8F7F3)),
        borderRadius: BorderRadius.all(radius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.all(radius),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress == 0 ? 0 : progress,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors:
                      fillColors ??
                      const [
                        Color(0xFFD9EBDD),
                        Color(0xFFAED2B8),
                        Color(0xFF79B18C),
                      ],
                  stops: [0.0, 0.55, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF79B18C).withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiagScoreCell extends StatelessWidget {
  final String label;
  final double score;
  final Color color;
  final IconData icon;
  final String desc;
  final Animation<double> anim;

  const _DiagScoreCell({
    required this.label,
    required this.score,
    required this.color,
    required this.icon,
    required this.desc,
    required this.anim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: anim,
            builder: (context, child) => Text(
              '${(score * anim.value * 100).round()}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: anim,
            builder: (context, child) => _SoftGradientProgressBar(
              value: score * anim.value,
              height: 4,
              emphasize: true,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: const Color(0xFF3A3028).withValues(alpha: 0.5),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// 五行状态条
class _WuxingBars extends StatelessWidget {
  const _WuxingBars();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = [
      (l10n.reportWuxingWood, 0.82, const Color(0xFF2D6A4F)),
      (l10n.reportWuxingFire, 0.55, const Color(0xFFD4794A)),
      (l10n.reportWuxingEarth, 0.68, const Color(0xFFC9A84C)),
      (l10n.reportWuxingMetal, 0.45, const Color(0xFF909080)),
      (l10n.reportWuxingWater, 0.60, const Color(0xFF4A7FA8)),
    ];

    return Column(
      children: data.map((d) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: Text(
                  d.$1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: d.$3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SoftGradientProgressBar(
                  value: d.$2,
                  height: 4,
                  emphasize: true,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 28,
                child: Text(
                  '${(d.$2 * 100).round()}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D6A4F),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
