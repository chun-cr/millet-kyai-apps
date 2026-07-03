part of 'report_page.dart';

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

const _kReportSymRecommendTypeAiDeep = '1';
const _kReportSymRecommendTypeClassic = '2';

class _HealthRadarSectionBlock extends StatefulWidget {
  const _HealthRadarSectionBlock({
    required this.viewData,
    required this.addReportSymptom,
    required this.deleteReportSymptom,
  });

  final ReportViewData viewData;
  final ReportAddSymptomAction addReportSymptom;
  final ReportDeleteSymptomAction deleteReportSymptom;

  @override
  State<_HealthRadarSectionBlock> createState() =>
      _HealthRadarSectionBlockState();
}

class _HealthRadarSectionBlockState extends State<_HealthRadarSectionBlock> {
  late bool _isClassicMode;
  late List<ReportHealthRadarSymptomData> _classicSymptoms;
  late List<ReportHealthRadarSymptomData> _visibleSymptoms;

  @override
  void initState() {
    super.initState();
    _isClassicMode = true;
    _resetSymptoms();
  }

  @override
  void didUpdateWidget(covariant _HealthRadarSectionBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldReset =
        oldWidget.viewData.reportId != widget.viewData.reportId ||
        !_symptomListsEqual(
          oldWidget.viewData.healthRadarClassicSymptoms,
          widget.viewData.healthRadarClassicSymptoms,
        ) ||
        !_symptomListsEqual(
          oldWidget.viewData.healthRadarDeepSymptoms,
          widget.viewData.healthRadarDeepSymptoms,
        );
    if (shouldReset) {
      _resetSymptoms();
    }
  }

  void _resetSymptoms() {
    _classicSymptoms = _cloneSymptoms(
      widget.viewData.healthRadarClassicSymptoms,
      preserveSelection: true,
    );
    _visibleSymptoms = _isClassicMode
        ? _classicSymptoms
        : _cloneSymptoms(
            widget.viewData.healthRadarDeepSymptoms,
            preserveSelection: false,
          );
  }

  List<ReportHealthRadarSymptomData> _cloneSymptoms(
    List<ReportHealthRadarSymptomData> source, {
    required bool preserveSelection,
  }) {
    return source
        .map(
          (item) => item.copyWith(
            selected: preserveSelection ? item.selected : false,
            raw: Map<String, dynamic>.from(item.raw),
          ),
        )
        .toList(growable: true);
  }

  void _handleModeChanged(bool value) {
    setState(() {
      _isClassicMode = value;
      _resetSymptoms();
    });
  }

  Future<void> _handleSymptomTap(int index) async {
    if (index < 0 || index >= _visibleSymptoms.length) {
      return;
    }

    final current = _visibleSymptoms[index];
    final next = current.copyWith(selected: !current.selected);

    setState(() {
      _visibleSymptoms[index] = next;
      if (_isClassicMode) {
        _classicSymptoms[index] = next;
      }
    });

    final reportId = widget.viewData.reportId?.trim() ?? '';
    if (reportId.isEmpty || !next.hasPersistableId) {
      return;
    }

    final recommendType = _isClassicMode
        ? _kReportSymRecommendTypeClassic
        : _kReportSymRecommendTypeAiDeep;

    try {
      if (next.selected) {
        await widget.addReportSymptom(
          reportId: reportId,
          symptomId: next.id,
          symptomName: next.name,
          recommendType: recommendType,
        );
      } else {
        await widget.deleteReportSymptom(
          reportId: reportId,
          symptomId: next.id,
          recommendType: recommendType,
        );
      }
    } catch (_) {
      // 保持和小程序一致的乐观切换体验：即使持久化失败，也先保留当前点击反馈。
      if (!mounted) {
        return;
      }
      showAppToast(
        context,
        _isChineseLocale(context)
            ? '症状已先在本页更新，保存到后端失败，请稍后重试。'
            : 'The symptom changed locally, but saving it failed.',
        kind: AppToastKind.info,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final symptoms = _visibleSymptoms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _FloatingSectionTitle(title: '健康雷达'),
                  SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '点击症状获取专属调理',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE36A53),
                      ),
                    ),
                  ),
                ],
              );
            }

            return const Row(
              children: [
                Expanded(child: _FloatingSectionTitle(title: '健康雷达')),
                Text(
                  '点击症状获取专属调理',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE36A53),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        _SectionCard(
          borderColor: const Color(0xFFF0E6DE),
          shadowColor: const Color(0x12000000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 360;
                  final title = const Text(
                    '大数据提示容易伴有',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1810),
                    ),
                  );

                  final switcher = _HealthRadarModeSwitch(
                    isClassicMode: _isClassicMode,
                    onChanged: _handleModeChanged,
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title,
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: switcher,
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: title),
                      const SizedBox(width: 12),
                      switcher,
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              if (symptoms.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: Text(
                      '暂无数据',
                      style: TextStyle(fontSize: 13, color: Color(0xFF9A8776)),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 12,
                  children: List.generate(symptoms.length, (index) {
                    final symptom = symptoms[index];
                    return _HealthRadarSymptomChip(
                      key: ValueKey(
                        'report_health_radar_chip_${_isClassicMode ? 'classic' : 'deep'}_$index',
                      ),
                      label: symptom.name,
                      selected: symptom.selected,
                      onTap: () => _handleSymptomTap(index),
                    );
                  }),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HealthRadarModeSwitch extends StatelessWidget {
  const _HealthRadarModeSwitch({
    required this.isClassicMode,
    required this.onChanged,
  });

  final bool isClassicMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFD89B49);
    const inactiveColor = Color(0xFFB8AB99);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'AI深度',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isClassicMode ? inactiveColor : activeColor,
          ),
        ),
        Transform.scale(
          scale: 0.78,
          child: Switch(
            key: const ValueKey('report_health_radar_mode_switch'),
            value: isClassicMode,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: activeColor,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE8DDD1),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        Text(
          '大医经验',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isClassicMode ? activeColor : inactiveColor,
          ),
        ),
      ],
    );
  }
}

class _HealthRadarSymptomChip extends StatelessWidget {
  const _HealthRadarSymptomChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF3E6) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? const Color(0xFFD1883A)
                  : const Color(0xFFD8A867),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected
                  ? const Color(0xFFC9781D)
                  : const Color(0xFF5D4B39),
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

bool _symptomListsEqual(
  List<ReportHealthRadarSymptomData> lhs,
  List<ReportHealthRadarSymptomData> rhs,
) {
  if (lhs.length != rhs.length) {
    return false;
  }

  for (var i = 0; i < lhs.length; i++) {
    final left = lhs[i];
    final right = rhs[i];
    if (left.id != right.id ||
        left.name != right.name ||
        left.selected != right.selected) {
      return false;
    }
  }
  return true;
}

class _RiskIndexSectionBlock extends StatelessWidget {
  final List<ReportRiskIndexData> riskIndexes;
  final Animation<double> scoreAnim;
  final DiagnosisMaNavigate? consultNavigate;

  const _RiskIndexSectionBlock({
    required this.riskIndexes,
    required this.scoreAnim,
    this.consultNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedConsultNavigate = consultNavigate;
    final visibleRiskIndexes = riskIndexes.take(4).toList(growable: false);
    if (visibleRiskIndexes.isEmpty) {
      return const SizedBox.shrink();
    }

    final warningRiskIndexes = riskIndexes
        .where((item) => item.isWarning)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FloatingSectionTitle(
          title: '风险指数',
          accentColor: Color(0xFFC57B08),
        ),
        const SizedBox(height: 6),
        _SectionCard(
          borderColor: const Color(0xFFF0E6DE),
          shadowColor: const Color(0x12000000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (warningRiskIndexes.isNotEmpty) ...[
                _RiskIndexTipCard(
                  warningRiskIndexes: warningRiskIndexes,
                  consultNavigate: resolvedConsultNavigate,
                  onConsultTap: resolvedConsultNavigate == null
                      ? null
                      : () => _showConsultNavigateDialog(
                          context,
                          resolvedConsultNavigate,
                        ),
                ),
                const SizedBox(height: 4),
              ],
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 380;
                  return GridView.builder(
                    primary: false,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: visibleRiskIndexes.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: compact ? 6 : 8,
                      crossAxisSpacing: compact ? 6 : 8,
                      mainAxisExtent: compact ? 160 : 164,
                    ),
                    itemBuilder: (context, index) => _RiskIndexCard(
                      item: visibleRiskIndexes[index],
                      anim: scoreAnim,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RiskIndexTipCard extends StatelessWidget {
  final List<ReportRiskIndexData> warningRiskIndexes;
  final DiagnosisMaNavigate? consultNavigate;
  final VoidCallback? onConsultTap;

  const _RiskIndexTipCard({
    required this.warningRiskIndexes,
    required this.consultNavigate,
    required this.onConsultTap,
  });

  @override
  Widget build(BuildContext context) {
    final highlightNames = warningRiskIndexes
        .map((item) => item.name)
        .where((item) => item.trim().isNotEmpty)
        .take(4)
        .toList(growable: false);

    final spans = <InlineSpan>[const TextSpan(text: '根据大数据，您的')];
    for (var i = 0; i < highlightNames.length; i++) {
      spans.add(
        TextSpan(
          text: highlightNames[i],
          style: const TextStyle(
            color: Color(0xFFE36A53),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      if (i < highlightNames.length - 1) {
        spans.add(const TextSpan(text: '、'));
      }
    }
    spans.add(
      const TextSpan(text: '风险偏高，检测前是否吃了有色饮料或者食物，如果是自然状态的检测结果，建议咨询健康顾问。'),
    );
    if (consultNavigate != null) {
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: GestureDetector(
              key: const ValueKey('report_risk_consult_button'),
              onTap: onConsultTap,
              child: const Text(
                '点击咨询',
                style: TextStyle(
                  color: Color(0xFFE36A53),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationThickness: 1.1,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      key: const ValueKey('report_risk_tip_card'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3D9D5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0B000000),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFE86E64),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF66584E),
                  height: 1.55,
                ),
                children: spans,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskIndexCard extends StatelessWidget {
  final ReportRiskIndexData item;
  final Animation<double> anim;

  const _RiskIndexCard({required this.item, required this.anim});

  @override
  Widget build(BuildContext context) {
    final palette = item.isWarning
        ? _kRiskWarningPalette
        : _kRiskAttentionPalette;

    return Container(
      key: ValueKey('report_risk_card_${item.name}'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1E7E0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A000000),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: AnimatedBuilder(
        animation: anim,
        builder: (context, child) {
          final value = (item.displayProb * anim.value)
              .round()
              .clamp(0, 100)
              .toInt();
          final progress = (item.ringScore / 100) * anim.value;

          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(72, 72),
                      painter: _RiskIndexRingPainter(
                        progress: progress,
                        colors: palette.ringColors,
                      ),
                    ),
                    Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: palette.numberColor,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              _RiskStatusPill(item: item, palette: palette),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 32),
                child: Center(
                  child: Text(
                    item.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF54493F),
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RiskStatusPill extends StatelessWidget {
  final ReportRiskIndexData item;
  final _RiskCardPalette palette;

  const _RiskStatusPill({required this.item, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: palette.pillBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.pillBorder),
      ),
      child: Text(
        item.statusLabel,
        style: TextStyle(
          color: palette.pillText,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }
}

class _ConsultFallbackCard extends StatelessWidget {
  final DiagnosisMaNavigate consultNavigate;

  const _ConsultFallbackCard({required this.consultNavigate});

  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      if (consultNavigate.appId.trim().isNotEmpty)
        'AppId: ${consultNavigate.appId}',
      if (consultNavigate.path.trim().isNotEmpty)
        'Path: ${consultNavigate.path}',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9DDCF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.qr_code_2_rounded,
            size: 42,
            color: Color(0xFFC57B08),
          ),
          const SizedBox(height: 10),
          Text(
            consultNavigate.hasMiniProgram ? '当前版本不支持直接打开小程序' : '暂无二维码图片',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B5B4B),
              height: 1.5,
            ),
          ),
          if (lines.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              lines.join('\n'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF8A7868),
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _showConsultNavigateDialog(
  BuildContext context,
  DiagnosisMaNavigate consultNavigate,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                consultNavigate.displayTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1810),
                ),
              ),
              const SizedBox(height: 16),
              if (consultNavigate.hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      consultNavigate.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          _ConsultFallbackCard(
                            consultNavigate: consultNavigate,
                          ),
                    ),
                  ),
                )
              else
                _ConsultFallbackCard(consultNavigate: consultNavigate),
              if (consultNavigate.hasImage) ...[
                const SizedBox(height: 10),
                const Text(
                  '长按图片识别二维码',
                  style: TextStyle(fontSize: 11, color: Color(0xFF8B7A69)),
                ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('关闭'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _RiskCardPalette {
  const _RiskCardPalette({
    required this.numberColor,
    required this.pillBackground,
    required this.pillBorder,
    required this.pillText,
    required this.ringColors,
  });

  final Color numberColor;
  final Color pillBackground;
  final Color pillBorder;
  final Color pillText;
  final List<Color> ringColors;
}

const _RiskCardPalette _kRiskWarningPalette = _RiskCardPalette(
  numberColor: Color(0xFFE24D43),
  pillBackground: Color(0xFFFBE7E5),
  pillBorder: Color(0xFFF1C5C0),
  pillText: Color(0xFFE35A4B),
  ringColors: [Color(0xFFF2B132), Color(0xFFE94B3F)],
);

const _RiskCardPalette _kRiskAttentionPalette = _RiskCardPalette(
  numberColor: Color(0xFF4E9A42),
  pillBackground: Color(0xFFF5ECD2),
  pillBorder: Color(0xFFE7D39C),
  pillText: Color(0xFFC39A2F),
  ringColors: [Color(0xFFF2B132), Color(0xFF4E9A42)],
);

Future<void> _showReportUnlockSheet(
  BuildContext context, {
  required ValueListenable<ReportUnlockState> unlockStateListenable,
  required Future<void> Function() onPurchase,
  required Future<void> Function() onRestore,
}) async {
  final l10n = context.l10n;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xFFF7F2E8).withValues(alpha: 0.12),
    isScrollControlled: true,
    builder: (context) {
      return ValueListenableBuilder<ReportUnlockState>(
        valueListenable: unlockStateListenable,
        builder: (context, unlockState, child) {
          if (unlockState.isUnlocked) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            });
          }

          final purchaseLabel = switch (unlockState.status) {
            ReportUnlockStatus.purchasing => l10n.reportUnlockSheetPurchasing,
            ReportUnlockStatus.restoring => l10n.reportUnlockSheetRestoring,
            _ => l10n.reportUnlockSheetConfirm,
          };

          final statusMessage = _resolveUnlockStatusMessage(l10n, unlockState);

          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.82),
                              const Color(0xFFF9F4EC).withValues(alpha: 0.9),
                              const Color(0xFFF1F8F4).withValues(alpha: 0.92),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.56),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF2D6A4F,
                              ).withValues(alpha: 0.08),
                              blurRadius: 30,
                              offset: const Offset(0, 14),
                            ),
                            BoxShadow(
                              color: const Color(
                                0xFFDDECE3,
                              ).withValues(alpha: 0.85),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -34,
                              right: -18,
                              child: Container(
                                width: 132,
                                height: 132,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(
                                        0xFFDAF0E1,
                                      ).withValues(alpha: 0.95),
                                      const Color(
                                        0xFFDAF0E1,
                                      ).withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: -26,
                              bottom: -38,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(
                                        0xFFF3E8CF,
                                      ).withValues(alpha: 0.72),
                                      const Color(
                                        0xFFF3E8CF,
                                      ).withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                22,
                                22,
                                22,
                                22,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const _UnlockGlyph(size: 72),
                                  const SizedBox(height: 14),
                                  _UnlockTag(
                                    label: l10n.reportUnlockInvitationTag,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    l10n.reportUnlockSheetTitle,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E1810),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    l10n.reportUnlockInvitationSubtitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.7,
                                      color: const Color(
                                        0xFF3A3028,
                                      ).withValues(alpha: 0.74),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  const _UnlockBenefitsCard(),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      12,
                                      14,
                                      12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.48,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF2D6A4F,
                                        ).withValues(alpha: 0.08),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          unlockState.displayPrice ??
                                              l10n.reportUnlockSheetPriceFallback,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF215840),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          l10n.reportUnlockSheetStoreHint,
                                          style: TextStyle(
                                            fontSize: 11,
                                            height: 1.55,
                                            color: const Color(
                                              0xFF7A6B5A,
                                            ).withValues(alpha: 0.85),
                                          ),
                                        ),
                                        if (statusMessage != null) ...[
                                          const SizedBox(height: 10),
                                          Text(
                                            statusMessage,
                                            style: TextStyle(
                                              fontSize: 11,
                                              height: 1.5,
                                              color:
                                                  unlockState.status ==
                                                      ReportUnlockStatus.error
                                                  ? const Color(0xFF9B4B4B)
                                                  : const Color(0xFF5E6C61),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  _UnlockButton(
                                    label: purchaseLabel,
                                    isLoading: unlockState.isBusy,
                                    onTap: unlockState.isBusy
                                        ? null
                                        : () {
                                            unawaited(onPurchase());
                                          },
                                  ),
                                  const SizedBox(height: 10),
                                  TextButton(
                                    onPressed: unlockState.isBusy
                                        ? null
                                        : () {
                                            unawaited(onRestore());
                                          },
                                    child: Text(
                                      l10n.reportUnlockRestoreButton,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF2D6A4F)
                                            .withValues(
                                              alpha: unlockState.isBusy
                                                  ? 0.45
                                                  : 0.9,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

String? _resolveUnlockStatusMessage(
  AppLocalizations l10n,
  ReportUnlockState unlockState,
) {
  return switch (unlockState.message) {
    'store-unavailable' => l10n.reportUnlockStatusStoreUnavailable,
    'product-not-found' => l10n.reportUnlockStatusProductUnavailable,
    'purchase-launch-failed' => l10n.reportUnlockStatusPurchaseFailed,
    'purchase-cancelled' => l10n.reportUnlockStatusPurchaseCancelled,
    'restore-not-found' => l10n.reportUnlockStatusRestoreNotFound,
    'purchase-stream-error' => l10n.reportUnlockStatusPurchaseFailed,
    'purchase-failed' => l10n.reportUnlockStatusPurchaseFailed,
    null => switch (unlockState.status) {
      ReportUnlockStatus.purchasing => l10n.reportUnlockStatusPurchasing,
      ReportUnlockStatus.restoring => l10n.reportUnlockStatusRestoring,
      ReportUnlockStatus.unavailable => l10n.reportUnlockStatusStoreUnavailable,
      _ => null,
    },
    _ => l10n.reportUnlockStatusPurchaseFailed,
  };
}

class _Lockable extends StatelessWidget {
  final bool isUnlocked;
  final String lockTitle;
  final Future<void> Function() onUnlock;
  final Widget child;

  const _Lockable({
    required this.isUnlocked,
    required this.lockTitle,
    required this.onUnlock,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (isUnlocked) return child;

    return Stack(
      alignment: Alignment.center,
      children: [
        IgnorePointer(
          ignoring: true,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Opacity(opacity: 0.72, child: child),
          ),
        ),
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      const Color(0xFFF6F2EA).withValues(alpha: 0.18),
                      const Color(0xFFF6F2EA).withValues(alpha: 0.34),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _LockOverlay(title: lockTitle, onUnlock: onUnlock),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LockOverlay extends StatelessWidget {
  final String title;
  final Future<void> Function() onUnlock;

  const _LockOverlay({required this.title, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTight = constraints.maxHeight <= 300;
            final isVeryTight = constraints.maxHeight <= 245;

            return Container(
              constraints: const BoxConstraints(maxWidth: 332),
              padding: EdgeInsets.fromLTRB(
                isVeryTight ? 16 : 20,
                isVeryTight ? 16 : 20,
                isVeryTight ? 16 : 20,
                isVeryTight ? 14 : 18,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.78),
                    const Color(0xFFF8F3EA).withValues(alpha: 0.86),
                    const Color(0xFFF0F7F2).withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _UnlockGlyph(size: isVeryTight ? 42 : 56),
                  SizedBox(height: isVeryTight ? 8 : 12),
                  if (!isVeryTight) ...[
                    _UnlockTag(label: l10n.reportUnlockInvitationTag),
                    SizedBox(height: isTight ? 8 : 12),
                  ],
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: isVeryTight ? 2 : null,
                    overflow: isVeryTight ? TextOverflow.ellipsis : null,
                    style: TextStyle(
                      fontSize: isVeryTight ? 14 : 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1810),
                      letterSpacing: 0.2,
                      height: isVeryTight ? 1.25 : 1.3,
                    ),
                  ),
                  SizedBox(height: isVeryTight ? 6 : 8),
                  Text(
                    l10n.reportUnlockDescription,
                    textAlign: TextAlign.center,
                    maxLines: isVeryTight ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isVeryTight ? 11 : 12,
                      height: isVeryTight ? 1.45 : 1.65,
                      color: const Color(0xFF3A3028).withValues(alpha: 0.66),
                    ),
                  ),
                  SizedBox(height: isVeryTight ? 10 : 14),
                  _UnlockBenefitsCard(
                    compact: true,
                    maxItems: isVeryTight ? 1 : (isTight ? 2 : 3),
                  ),
                  SizedBox(height: isVeryTight ? 10 : 14),
                  _UnlockButton(
                    label: l10n.reportUnlockButton,
                    onTap: () {
                      unawaited(onUnlock());
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UnlockGlyph extends StatelessWidget {
  final double size;

  const _UnlockGlyph({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFFEEF7F1).withValues(alpha: 0.96),
            const Color(0xFFE2F0E7).withValues(alpha: 0.88),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.spa_outlined,
            size: size * 0.42,
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.92),
          ),
          Positioned(
            top: size * 0.22,
            right: size * 0.18,
            child: Icon(
              Icons.lock_outline_rounded,
              size: size * 0.2,
              color: const Color(0xFF6B5B95).withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockTag extends StatelessWidget {
  final String label;

  const _UnlockTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF6F1).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: const Color(0xFF2D6A4F).withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class _UnlockBenefitsCard extends StatelessWidget {
  final bool compact;
  final int maxItems;

  const _UnlockBenefitsCard({this.compact = false, this.maxItems = 3});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final benefits = [
      l10n.reportUnlockBenefitConstitution,
      l10n.reportUnlockBenefitTherapy,
      l10n.reportUnlockBenefitAdvice,
    ].take(maxItems).toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 16,
        compact ? 12 : 14,
        compact ? 14 : 16,
        compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF2D6A4F).withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: List.generate(benefits.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == benefits.length - 1 ? 0 : (compact ? 10 : 12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: compact ? 20 : 22,
                  height: compact ? 20 : 22,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF78B99A).withValues(alpha: 0.95),
                        const Color(0xFF2D6A4F),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D6A4F).withValues(alpha: 0.16),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: compact ? 12 : 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    benefits[index],
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 11.5 : 12.5,
                      height: compact ? 1.5 : 1.6,
                      color: const Color(0xFF2B241D).withValues(alpha: 0.84),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _UnlockButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const _UnlockButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8FC9AE), Color(0xFF3E8E6C), Color(0xFF1F6447)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D6A4F).withValues(alpha: 0.26),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF9DCCB7).withValues(alpha: 0.24),
                blurRadius: 20,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 1,
                right: 1,
                top: 1,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.34),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 键值信息行
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: const Color(0xFFA09080).withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E1810),
          ),
        ),
      ],
    );
  }
}

class _ConstitutionScoreRow extends StatefulWidget {
  final String label;
  final double score;
  final Color color;
  final bool isMain;

  const _ConstitutionScoreRow({
    required this.label,
    required this.score,
    required this.color,
    required this.isMain,
  });

  @override
  State<_ConstitutionScoreRow> createState() => _ConstitutionScoreRowState();
}

class _ConstitutionScoreRowState extends State<_ConstitutionScoreRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(
      const Duration(milliseconds: 300),
      () => mounted ? _ctrl.forward() : null,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSecondaryLow = !widget.isMain && widget.score < 0.28;

    return Row(
      children: [
        if (widget.isMain)
          Container(
            width: 4,
            height: 16,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(2),
            ),
          )
        else
          const SizedBox(width: 10),
        SizedBox(
          width: 52,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: widget.isMain ? FontWeight.w700 : FontWeight.w400,
              color: widget.isMain
                  ? const Color(0xFF1E1810)
                  : (isSecondaryLow
                        ? const Color(0xFFA09080).withValues(alpha: 0.72)
                        : const Color(0xFFA09080)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, child) => _SoftGradientProgressBar(
              value: widget.score * _anim.value,
              height: widget.isMain ? 4 : 3,
              emphasize: widget.isMain,
              trackColor: isSecondaryLow ? Colors.transparent : null,
              fillColors: widget.isMain
                  ? const [
                      Color(0xFFD7EFD9),
                      Color(0xFFA9D6B5),
                      Color(0xFF74B58A),
                    ]
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, child) => Text(
              '${(widget.score * _anim.value * 100).round()}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: widget.isMain ? FontWeight.w700 : FontWeight.w400,
                color: widget.isMain
                    ? const Color(0xFF2D6A4F)
                    : (isSecondaryLow
                          ? const Color(0xFFA09080).withValues(alpha: 0.7)
                          : const Color(0xFF6E8E7A)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 穴位卡片。
class _AcuPointCard extends StatelessWidget {
  final _AcuPoint point;
  const _AcuPointCard({required this.point});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: point.color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: point.color.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          point.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: point.color,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          point.meridian,
                          style: TextStyle(
                            fontSize: 11,
                            color: point.color.withValues(alpha: 0.68),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: const Color(0xFFA09080),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            point.location,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFA09080),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      point.effect,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF3A3028).withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 食材标签。
class _FoodChip extends StatelessWidget {
  final String name;
  final String desc;
  final Color color;

  const _FoodChip({
    required this.name,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            desc,
            style: TextStyle(
              fontSize: 10,
              color: const Color(0xFF3A3028).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// 项目推荐卡片。
class _ProjectCard extends StatelessWidget {
  final ReportProjectData project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return GestureDetector(
      onTap: () {
        context.push(
          Uri(
            path: AppRoutes.reportProjectDetail,
            queryParameters: project.toRouteQueryParameters(),
          ).toString(),
          extra: project,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: project.color.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: project.color.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: project.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(project.icon, size: 24, color: project.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            project.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E1810),
                            ),
                          ),
                        ),
                        Text(
                          project.tag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: project.color.withValues(alpha: 0.68),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      project.type,
                      style: TextStyle(
                        fontSize: 11,
                        color: project.color.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      project.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF3A3028).withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            project.durationNote,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: project.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: project.color.withValues(alpha: 0.22),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            l10n.reportAdviceProjectDetailButton,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: project.color.withValues(alpha: 0.82),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ReportProductData product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.reportProductDetail, extra: product);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: product.color.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: product.color.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: product.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(product.icon, size: 24, color: product.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E1810),
                            ),
                          ),
                        ),
                        Text(
                          product.tag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: product.color.withValues(alpha: 0.68),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.type,
                      style: TextStyle(
                        fontSize: 11,
                        color: product.color.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF3A3028).withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          product.priceLabel,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: product.color,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: product.color.withValues(alpha: 0.22),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            l10n.reportAdviceProductDetailButton,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: product.color.withValues(alpha: 0.82),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 数据模型

class _AcuPoint {
  final String name;
  final String location;
  final String effect;
  final String meridian;
  final Color color;

  const _AcuPoint({
    required this.name,
    required this.location,
    required this.effect,
    required this.meridian,
    required this.color,
  });
}

class _SeasonData {
  final String name;
  final Color color;
  final Color lightColor;
  final String advice;
  final String avoid;

  const _SeasonData({
    required this.name,
    required this.color,
    required this.lightColor,
    required this.advice,
    required this.avoid,
  });
}

// 自定义绘制器
