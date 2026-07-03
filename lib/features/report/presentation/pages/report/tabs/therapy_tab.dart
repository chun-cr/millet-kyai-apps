part of '../report_page.dart';

class _Tab3Therapy extends StatelessWidget {
  final bool isUnlocked;
  final Future<void> Function() onUnlock;

  const _Tab3Therapy({required this.isUnlocked, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final seasonalContext = SeasonalContext.now();
    final seasonalTag = l10n.seasonalTagLabel(seasonalContext);
    final seasonalTitle = l10n.reportSeasonalCareCurrentTitle(
      l10n.solarTermLabel(seasonalContext.solarTerm),
    );

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        _FloatingSectionTitle(title: l10n.reportTherapyAcupointsTitle),
        const SizedBox(height: 10),
        _Lockable(
          isUnlocked: isUnlocked,
          lockTitle: l10n.reportUnlockAcupuncturePointsTitle,
          onUnlock: onUnlock,
          child: _buildAcupuncturePointsContent(context),
        ),
        const SizedBox(height: 20),
        _FloatingSectionTitle(title: l10n.reportMentalWellnessTitle),
        const SizedBox(height: 10),
        _Lockable(
          isUnlocked: isUnlocked,
          lockTitle: l10n.reportUnlockMentalWellnessTitle,
          onUnlock: onUnlock,
          child: _buildMentalWellnessContent(context),
        ),
        const SizedBox(height: 20),
        _FloatingSectionTitle(title: l10n.reportSeasonalCareTitle),
        const SizedBox(height: 10),
        _SeasonalFocusBanner(
          title: seasonalTitle,
          tag: seasonalTag,
          subtitle: l10n.reportSeasonalCareCurrentSubtitle,
        ),
        const SizedBox(height: 10),
        _Lockable(
          isUnlocked: isUnlocked,
          lockTitle: l10n.reportUnlockSeasonalCareTitle,
          onUnlock: onUnlock,
          child: _buildSeasonalCareContent(context),
        ),
      ],
    );
  }

  // ── 辩证取穴 ─────────────────────────────────────────────────────
  Widget _buildAcupuncturePointsContent(BuildContext context) {
    final l10n = context.l10n;
    final points = [
      _AcuPoint(
        name: l10n.reportTherapyAcuPointZusanli,
        location: l10n.reportTherapyAcuPointZusanliLocation,
        effect: l10n.reportTherapyAcuPointZusanliEffect,
        meridian: l10n.reportTherapyAcuPointZusanliMeridian,
        color: Color(0xFF2D6A4F),
      ),
      _AcuPoint(
        name: l10n.reportTherapyAcuPointPishu,
        location: l10n.reportTherapyAcuPointPishuLocation,
        effect: l10n.reportTherapyAcuPointPishuEffect,
        meridian: l10n.reportTherapyAcuPointPishuMeridian,
        color: Color(0xFF0D7A5A),
      ),
      _AcuPoint(
        name: l10n.reportTherapyAcuPointQihai,
        location: l10n.reportTherapyAcuPointQihaiLocation,
        effect: l10n.reportTherapyAcuPointQihaiEffect,
        meridian: l10n.reportTherapyAcuPointQihaiMeridian,
        color: Color(0xFF6B5B95),
      ),
      _AcuPoint(
        name: l10n.reportTherapyAcuPointGuanyuan,
        location: l10n.reportTherapyAcuPointGuanyuanLocation,
        effect: l10n.reportTherapyAcuPointGuanyuanEffect,
        meridian: l10n.reportTherapyAcuPointGuanyuanMeridian,
        color: Color(0xFFC9A84C),
      ),
    ];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.reportTherapyAcupointsIntro,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF3A3028).withValues(alpha: 0.55),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          ...points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AcuPointCard(point: p),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF3E0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFC9A84C).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Color(0xFFC9A84C),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.reportTherapyAcupointsWarning,
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFF8B6914).withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 精神养生 ─────────────────────────────────────────────────────
  Widget _buildMentalWellnessContent(BuildContext context) {
    final l10n = context.l10n;
    final tips = [
      (
        l10n.reportMentalTipCalm,
        Icons.self_improvement_outlined,
        l10n.reportMentalTipCalmBody,
      ),
      (
        l10n.reportMentalTipNature,
        Icons.nature_outlined,
        l10n.reportMentalTipNatureBody,
      ),
      (
        l10n.reportMentalTipEmotion,
        Icons.mood_outlined,
        l10n.reportMentalTipEmotionBody,
      ),
      (
        l10n.reportMentalTipMeditation,
        Icons.spa_outlined,
        l10n.reportMentalTipMeditationBody,
      ),
    ];

    return _SectionCard(
      child: Column(
        children: List.generate(tips.length, (index) {
          final t = tips[index];
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      t.$2,
                      size: 18,
                      color: const Color(0xFF2D6A4F).withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.$1,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E1810),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          t.$3,
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(
                              0xFF3A3028,
                            ).withValues(alpha: 0.6),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (index < tips.length - 1) ...[
                const SizedBox(height: 12),
                const _IndentedDivider(indent: 30),
                const SizedBox(height: 12),
              ],
            ],
          );
        }),
      ),
    );
  }

  // ── 四季保养 ─────────────────────────────────────────────────────
  Widget _buildSeasonalCareContent(BuildContext context) {
    final l10n = context.l10n;
    final seasons = [
      _SeasonData(
        name: l10n.reportSeasonSpring,
        color: Color(0xFF2D6A4F),
        lightColor: Color(0xFFE8F5EE),
        advice: l10n.reportSeasonSpringAdvice,
        avoid: l10n.reportSeasonSpringAvoid,
      ),
      _SeasonData(
        name: l10n.reportSeasonSummer,
        color: Color(0xFFD4794A),
        lightColor: Color(0xFFFAEDE7),
        advice: l10n.reportSeasonSummerAdvice,
        avoid: l10n.reportSeasonSummerAvoid,
      ),
      _SeasonData(
        name: l10n.reportSeasonAutumn,
        color: Color(0xFFC9A84C),
        lightColor: Color(0xFFFAF3E0),
        advice: l10n.reportSeasonAutumnAdvice,
        avoid: l10n.reportSeasonAutumnAvoid,
      ),
      _SeasonData(
        name: l10n.reportSeasonWinter,
        color: Color(0xFF4A7FA8),
        lightColor: Color(0xFFE4EDF5),
        advice: l10n.reportSeasonWinterAdvice,
        avoid: l10n.reportSeasonWinterAvoid,
      ),
    ];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...seasons.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: s.lightColor.withValues(alpha: 0.36),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2, right: 12),
                        child: Text(
                          s.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: s.color.withValues(alpha: 0.92),
                            letterSpacing: 1,
                            fontFamily: 'serif',
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.advice,
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(
                                  0xFF1E1810,
                                ).withValues(alpha: 0.8),
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '○',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: s.color.withValues(alpha: 0.58),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    s.avoid,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: s.color.withValues(alpha: 0.68),
                                      height: 1.5,
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
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 选项卡四：建议
// ══════════════════════════════════════════════════════════════════
