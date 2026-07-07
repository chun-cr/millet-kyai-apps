part of '../report_page.dart';

// ignore_for_file: unused_element

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
