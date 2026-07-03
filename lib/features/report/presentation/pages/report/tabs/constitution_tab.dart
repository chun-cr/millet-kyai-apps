part of '../report_page.dart';

class _Tab2Constitution extends StatelessWidget {
  final ReportViewData viewData;
  final bool isUnlocked;
  final Future<void> Function() onUnlock;

  const _Tab2Constitution({
    required this.viewData,
    required this.isUnlocked,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
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
                        CustomPaint(
                          size: const Size(140, 140),
                          painter: _ConstitutionRadarPainter(),
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
                            l10n.reportConstitutionCoreConclusionValue,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E1810),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.reportConstitutionCoreConclusionBody,
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(
                                0xFF3A3028,
                              ).withValues(alpha: 0.65),
                              height: 1.65,
                            ),
                          ),
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
                  children: _constitutionScores(context)
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

  List<(String, double, Color, bool)> _constitutionScores(
    BuildContext context,
  ) {
    final liveScores = viewData.constitutionScores;
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

  // ── 不当举动 ─────────────────────────────────────────────────────
  Widget _buildBadHabitsContent(BuildContext context) {
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
