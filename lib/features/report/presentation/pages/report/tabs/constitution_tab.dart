part of '../report_page.dart';

class _Tab2Constitution extends StatefulWidget {
  final ReportViewData viewData;
  final _ReportPhysiqueAnalysisState physiqueAnalysisState;
  final bool isUnlocked;
  final Future<void> Function() onUnlock;

  const _Tab2Constitution({
    required this.viewData,
    required this.physiqueAnalysisState,
    required this.isUnlocked,
    required this.onUnlock,
  });

  @override
  State<_Tab2Constitution> createState() => _Tab2ConstitutionState();
}

class _Tab2ConstitutionState extends State<_Tab2Constitution>
    with SingleTickerProviderStateMixin {
  Future<List<Map<String, dynamic>>>? _therapyFuture;
  String? _therapySignature;
  late final AnimationController _radarController;
  late final Animation<double> _radarProgress;
  late String _radarSignature;

  ReportViewData get viewData => widget.viewData;
  _ReportPhysiqueAnalysisState get physiqueAnalysisState =>
      widget.physiqueAnalysisState;
  bool get isUnlocked => widget.isUnlocked;
  Future<void> Function() get onUnlock => widget.onUnlock;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _radarProgress = CurvedAnimation(
      parent: _radarController,
      curve: Curves.easeOutCubic,
    );
    _radarSignature = _constitutionRadarSignature(widget.viewData);
    _radarController.forward();
    _syncTherapyFuture();
  }

  @override
  void didUpdateWidget(covariant _Tab2Constitution oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextRadarSignature = _constitutionRadarSignature(widget.viewData);
    if (_radarSignature != nextRadarSignature) {
      _radarSignature = nextRadarSignature;
      _radarController.forward(from: 0);
    }
    _syncTherapyFuture();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  void _syncTherapyFuture() {
    final signature = _therapyQuerySignature(widget.viewData);
    if (signature == null) {
      _therapyFuture = null;
      _therapySignature = null;
      return;
    }
    if (_therapySignature == signature) {
      return;
    }
    _therapySignature = signature;
    try {
      _therapyFuture = _loadTherapiesForDominantConstitution(widget.viewData);
    } catch (_) {
      _therapyFuture = Future.value(const <Map<String, dynamic>>[]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppResponsiveListView(
      physics: const ClampingScrollPhysics(),
      children: [
        _buildConstitutionDetail(context),
        const SizedBox(height: 20),
        _FloatingSectionTitle(title: l10n.reportCausalAnalysisTitle),
        const SizedBox(height: 10),
        _Lockable(
          isUnlocked: isUnlocked,
          lockTitle: l10n.reportUnlockCausalAnalysisTitle,
          onUnlock: onUnlock,
          child: _buildCausalAnalysisContent(context),
        ),
        const SizedBox(height: 20),
        _FloatingSectionTitle(title: l10n.reportBadHabitsTitle),
        const SizedBox(height: 10),
        _Lockable(
          isUnlocked: isUnlocked,
          lockTitle: l10n.reportUnlockBadHabitsTitle,
          onUnlock: onUnlock,
          child: _buildBadHabitsContent(context),
        ),
      ],
    );
  }

  // ── 体质详解 ─────────────────────────────────────────────────────
  Widget _buildConstitutionDetail(BuildContext context) {
    final l10n = context.l10n;
    final coreConclusionValue = _constitutionCoreConclusionValue(context);
    final constitutionScores = _constitutionScores(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FloatingSectionTitle(title: l10n.reportConstitutionDetailTitle),
        const SizedBox(height: 10),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 150,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF8FC7A5).withValues(alpha: 0.16),
                                const Color(0xFFC9A84C).withValues(alpha: 0.05),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.48, 1.0],
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _radarProgress,
                          builder: (context, child) {
                            return CustomPaint(
                              key: const ValueKey('report_constitution_radar'),
                              size: const Size(140, 140),
                              painter: _ConstitutionRadarPainter(
                                scores: constitutionScores,
                                progress: _radarProgress.value,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.reportConstitutionCoreConclusionLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(
                                0xFFA09080,
                              ).withValues(alpha: 0.9),
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            coreConclusionValue,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E1810),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildCoreConclusionBody(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D6A4F).withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: constitutionScores.isEmpty
                      ? [
                          Text(
                            '暂无体质分数数据。',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(
                                0xFF3A3028,
                              ).withValues(alpha: 0.55),
                              height: 1.5,
                            ),
                          ),
                        ]
                      : constitutionScores
                            .map(
                              (c) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _ConstitutionScoreRow(
                                  label: c.$1,
                                  score: c.$2,
                                  color: c.$3,
                                  isMain: c.$4,
                                ),
                              ),
                            )
                            .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _constitutionRadarSignature(ReportViewData viewData) {
    if (viewData.constitutionScores.isEmpty) {
      return 'fallback';
    }
    return viewData.constitutionScores
        .map(
          (item) =>
              '${item.id}|${item.name}|${item.scorePercent.toStringAsFixed(3)}',
        )
        .join(';');
  }

  String _constitutionCoreConclusionValue(BuildContext context) {
    final name =
        (viewData.constitutionScores.isNotEmpty
            ? _nonEmpty(viewData.constitutionScores.first.name)
            : null) ??
        _nonEmpty(viewData.primaryConstitution);
    if (name == null) {
      return '暂无体质数据';
    }
    return '主导偏颇体质：$name';
  }

  Widget _buildCoreConclusionBody(BuildContext context) {
    final future = _therapyFuture;
    if (future == null) {
      return _coreConclusionBodyText(context, '暂无体质特征与调理原则数据。');
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _coreConclusionBodyText(context, '正在读取体质特征与调理原则...');
        }
        if (snapshot.hasError) {
          return _coreConclusionBodyText(context, '体质特征与调理原则暂未加载成功。');
        }

        final therapyText = _therapyFeaturePrincipleText(
          snapshot.data ?? const <Map<String, dynamic>>[],
        );
        return _coreConclusionBodyText(
          context,
          therapyText ?? '暂无体质特征与调理原则数据。',
        );
      },
    );
  }

  Widget _coreConclusionBodyText(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: const Color(0xFF3A3028).withValues(alpha: 0.65),
        height: 1.65,
      ),
    );
  }

  String? _therapyFeaturePrincipleText(List<Map<String, dynamic>> therapies) {
    String? feature;
    String? principle;
    for (final therapy in therapies) {
      feature ??= _firstNonEmptyText(therapy, const [
        'feature',
        'features',
        'physiqueFeature',
      ]);
      principle ??= _firstNonEmptyText(therapy, const [
        'principle',
        'principles',
        'therapyPrinciple',
      ]);
      if (feature != null && principle != null) {
        break;
      }
    }

    if (feature == null && principle == null) {
      return null;
    }
    return [
      if (feature != null) '体质特征：$feature',
      if (principle != null) '调理原则：$principle',
    ].join('\n');
  }

  List<(String, double, Color, bool)> _constitutionScores(
    BuildContext context,
  ) {
    final liveScores = viewData.constitutionScores
        .where((item) => item.hasScore)
        .toList(growable: false);
    if (liveScores.isNotEmpty) {
      return [
        for (var index = 0; index < liveScores.length; index++)
          (
            liveScores[index].name,
            liveScores[index].scoreFraction,
            _constitutionColorFor(liveScores[index], index),
            index < 2,
          ),
      ];
    }

    if (viewData.isLive) {
      return const <(String, double, Color, bool)>[];
    }

    return [
      (context.l10n.constitutionBalanced, 0.72, const Color(0xFF2D6A4F), true),
      (
        context.l10n.constitutionQiDeficiency,
        0.58,
        const Color(0xFF6B5B95),
        true,
      ),
      (
        context.l10n.reportConstitutionYangDeficiency,
        0.25,
        const Color(0xFF4A7FA8),
        false,
      ),
      (
        context.l10n.reportConstitutionYinDeficiency,
        0.20,
        const Color(0xFF0D7A5A),
        false,
      ),
      (context.l10n.constitutionDampness, 0.30, const Color(0xFFC9A84C), false),
      (
        context.l10n.reportConstitutionDampHeat,
        0.18,
        const Color(0xFFD4794A),
        false,
      ),
      (
        context.l10n.reportConstitutionBloodStasis,
        0.15,
        const Color(0xFFB05A5A),
        false,
      ),
      (
        context.l10n.reportConstitutionQiStagnation,
        0.22,
        const Color(0xFF7A6BA0),
        false,
      ),
      (
        context.l10n.reportConstitutionSpecial,
        0.10,
        const Color(0xFF909080),
        false,
      ),
    ];
  }

  Color _constitutionColorFor(
    ReportConstitutionScoreData constitution,
    int index,
  ) {
    final key = '${constitution.id} ${constitution.name}'.toLowerCase();
    if (key.contains('balanced') || key.contains('平和')) {
      return const Color(0xFF2D6A4F);
    }
    if (key.contains('qi deficiency') || key.contains('气虚')) {
      return const Color(0xFF6B5B95);
    }
    if (key.contains('yang deficiency') || key.contains('阳虚')) {
      return const Color(0xFF4A7FA8);
    }
    if (key.contains('yin deficiency') || key.contains('阴虚')) {
      return const Color(0xFF0D7A5A);
    }
    if (key.contains('phlegm') ||
        key.contains('dampness') ||
        key.contains('痰湿')) {
      return const Color(0xFFC9A84C);
    }
    if (key.contains('damp-heat') ||
        key.contains('damp heat') ||
        key.contains('湿热')) {
      return const Color(0xFFD4794A);
    }
    if (key.contains('blood stasis') || key.contains('血瘀')) {
      return const Color(0xFFB05A5A);
    }
    if (key.contains('qi stagnation') || key.contains('气郁')) {
      return const Color(0xFF7A6BA0);
    }
    if (key.contains('special') ||
        key.contains('inherited') ||
        key.contains('特禀')) {
      return const Color(0xFF909080);
    }

    const fallbackColors = [
      Color(0xFF2D6A4F),
      Color(0xFF6B5B95),
      Color(0xFF4A7FA8),
      Color(0xFF0D7A5A),
      Color(0xFFC9A84C),
      Color(0xFFD4794A),
      Color(0xFFB05A5A),
      Color(0xFF7A6BA0),
      Color(0xFF909080),
    ];
    return fallbackColors[index % fallbackColors.length];
  }

  // ── 分析成因 ─────────────────────────────────────────────────────
  Widget _buildCausalAnalysisContent(BuildContext context) {
    if (viewData.isLive) {
      return _buildLivePhysiqueFeatureContent(context);
    }

    final l10n = context.l10n;
    final causes = [
      (
        Icons.bedtime_outlined,
        l10n.reportCauseRoutine,
        l10n.reportCauseRoutineBody,
      ),
      (
        Icons.restaurant_outlined,
        l10n.reportCauseDiet,
        l10n.reportCauseDietBody,
      ),
      (
        Icons.self_improvement_outlined,
        l10n.reportCauseEmotion,
        l10n.reportCauseEmotionBody,
      ),
      (
        Icons.directions_run_outlined,
        l10n.reportCauseExercise,
        l10n.reportCauseExerciseBody,
      ),
    ];

    return _SectionCard(
      child: Column(
        children: List.generate(causes.length, (index) {
          final c = causes[index];
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B5B95).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(c.$1, size: 17, color: const Color(0xFF6B5B95)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.$2,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E1810),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.$3,
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(
                              0xFF3A3028,
                            ).withValues(alpha: 0.6),
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (index < causes.length - 1) ...[
                const SizedBox(height: 12),
                const _IndentedDivider(indent: 46),
                const SizedBox(height: 12),
              ],
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLivePhysiqueFeatureContent(BuildContext context) {
    final l10n = context.l10n;
    final analysis = physiqueAnalysisState.data;
    if (analysis == null) {
      return _buildPhysiqueAnalysisStatusCard(context, physiqueAnalysisState);
    }

    final rows = <(String, String)>[
      if (analysis.mainFeature.isNotEmpty)
        (l10n.reportPhysiqueAnalysisMainFeatureLabel, analysis.mainFeature),
      if (analysis.bodyFeature.isNotEmpty)
        (l10n.reportPhysiqueAnalysisBodyFeatureLabel, analysis.bodyFeature),
      if (analysis.manifestations.isNotEmpty)
        (
          l10n.reportPhysiqueAnalysisManifestationsLabel,
          analysis.manifestations.map((item) => item.name).join('、'),
        ),
      if (analysis.diseaseTendencies.isNotEmpty)
        (
          l10n.reportPhysiqueAnalysisDiseaseTendenciesLabel,
          analysis.diseaseTendencies.map((item) => item.name).join('、'),
        ),
      if (analysis.diseaseTendencyNote.isNotEmpty)
        (
          l10n.reportPhysiqueAnalysisDiseaseTendencyNoteLabel,
          analysis.diseaseTendencyNote,
        ),
      if (analysis.psychologicalFeature.isNotEmpty)
        (
          l10n.reportPhysiqueAnalysisPsychologicalFeatureLabel,
          analysis.psychologicalFeature,
        ),
      if (analysis.environmentAdaptability.isNotEmpty)
        (
          l10n.reportPhysiqueAnalysisEnvironmentAdaptabilityLabel,
          analysis.environmentAdaptability,
        ),
    ];

    if (rows.isEmpty) {
      return _buildPhysiqueAnalysisStatusCard(
        context,
        const _ReportPhysiqueAnalysisState.empty(),
      );
    }

    return _SectionCard(
      child: Column(
        children: List.generate(rows.length, (index) {
          final row = rows[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 7),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6B5B95),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.$1,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E1810),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          row.$2,
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(
                              0xFF3A3028,
                            ).withValues(alpha: 0.66),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (index < rows.length - 1) ...[
                const SizedBox(height: 12),
                const _IndentedDivider(indent: 16),
                const SizedBox(height: 12),
              ],
            ],
          );
        }),
      ),
    );
  }

  // ── 不当举动 ─────────────────────────────────────────────────────
  Widget _buildBadHabitsContent(BuildContext context) {
    if (viewData.isLive) {
      final section = physiqueAnalysisState.data?.interpretation;
      return _buildPhysiqueAnalysisSectionCard(
        context,
        physiqueAnalysisState,
        section,
      );
    }

    final l10n = context.l10n;
    final habits = [
      (l10n.reportBadHabitOverwork, l10n.reportBadHabitOverworkBody),
      (l10n.reportBadHabitColdFood, l10n.reportBadHabitColdFoodBody),
      (l10n.reportBadHabitLateSleep, l10n.reportBadHabitLateSleepBody),
      (l10n.reportBadHabitDieting, l10n.reportBadHabitDietingBody),
      (l10n.reportBadHabitBinge, l10n.reportBadHabitBingeBody),
    ];

    return _SectionCard(
      child: Column(
        children: List.generate(habits.length, (index) {
          final h = habits[index];
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF8B6914),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1E1810),
                        ),
                        children: [
                          TextSpan(
                            text: '${h.$1}　',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6E5830),
                            ),
                          ),
                          TextSpan(
                            text: h.$2,
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              color: const Color(
                                0xFF3A3028,
                              ).withValues(alpha: 0.58),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (index < habits.length - 1) ...[
                const SizedBox(height: 12),
                const _IndentedDivider(indent: 18),
                const SizedBox(height: 12),
              ],
            ],
          );
        }),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 选项卡三：调理
// ══════════════════════════════════════════════════════════════════
