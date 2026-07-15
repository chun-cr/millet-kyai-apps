part of '../home_page.dart';

class _LastReportCard extends StatelessWidget {
  const _LastReportCard({
    required this.summary,
    this.report,
    this.isDetailLoading = false,
    this.onRetryDetail,
    required this.onOpenReport,
    required this.onCompareHistory,
  });

  final DiagnosisReportSummary summary;
  final HomeLatestReportData? report;
  final bool isDetailLoading;
  final VoidCallback? onRetryDetail;
  final VoidCallback onOpenReport;
  final VoidCallback onCompareHistory;

  @override
  Widget build(BuildContext context) {
    final viewData = report?.viewData;
    final recordedAt = _parseReportDate(
      viewData?.recordedAt ?? summary.testTime,
    );
    final checkedDaysAgo = recordedAt == null
        ? null
        : math
              .max(
                0,
                DateUtils.dateOnly(
                  DateTime.now(),
                ).difference(DateUtils.dateOnly(recordedAt.toLocal())).inDays,
              )
              .toInt();
    final primaryConstitution = _firstReportText([
      viewData?.primaryConstitution,
      summary.physiqueName,
    ]);
    final constitutionSummary = viewData == null
        ? null
        : _firstReportText([viewData.summary, viewData.heroTherapySummary]);
    final liveScores =
        viewData?.constitutionScores
            .where((item) => item.hasScore)
            .take(6)
            .toList(growable: false) ??
        const [];
    final radarScores = [
      for (var index = 0; index < liveScores.length; index++)
        (
          _compactConstitutionName(liveScores[index].name),
          liveScores[index].scoreFraction,
          _constitutionColor(
            id: liveScores[index].id,
            name: liveScores[index].name,
            index: index,
          ),
          index == 0,
        ),
    ];

    return Material(
      key: const ValueKey('home_latest_report_card'),
      color: Colors.white,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: _LatestReportHeader(
                recordedAt: recordedAt,
                checkedDaysAgo: checkedDaysAgo,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final overview = _LatestReportOverview(
                    primaryConstitution: primaryConstitution == null
                        ? null
                        : _compactConstitutionName(primaryConstitution),
                    summary: constitutionSummary,
                    isLoading: isDetailLoading,
                  );
                  final radar = _LatestReportRadar(
                    scores: radarScores,
                    isLoading: isDetailLoading,
                    onRetry: onRetryDetail,
                  );

                  if (constraints.maxWidth < 280) {
                    return Column(
                      key: const ValueKey('home_latest_report_stacked'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        overview,
                        const SizedBox(height: 20),
                        Divider(
                          height: 1,
                          color: AppColors.primary.withValues(alpha: 0.08),
                        ),
                        const SizedBox(height: 18),
                        radar,
                      ],
                    );
                  }

                  return SizedBox(
                    height: 220,
                    child: Row(
                      key: const ValueKey('home_latest_report_split'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 9, child: overview),
                        const SizedBox(width: 16),
                        VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: AppColors.primary.withValues(alpha: 0.08),
                        ),
                        const SizedBox(width: 4),
                        Expanded(flex: 11, child: radar),
                      ],
                    ),
                  );
                },
              ),
            ),
            _LatestReportActions(
              onOpenReport: onOpenReport,
              onCompareHistory: onCompareHistory,
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestReportHeader extends StatelessWidget {
  const _LatestReportHeader({
    required this.recordedAt,
    required this.checkedDaysAgo,
  });

  final DateTime? recordedAt;
  final int? checkedDaysAgo;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.assignment_outlined,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              context.l10n.homeLatestReportTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        if (recordedAt != null || checkedDaysAgo != null) ...[
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (recordedAt != null)
                Text(
                  formatShortDate(context, recordedAt!),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              if (checkedDaysAgo != null) ...[
                const SizedBox(height: 3),
                Text(
                  checkedDaysAgo == 0
                      ? context.l10n.homeLatestReportCheckedToday
                      : context.l10n.homeLatestReportCheckedDays(
                          checkedDaysAgo!,
                        ),
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _LatestReportOverview extends StatelessWidget {
  const _LatestReportOverview({
    required this.primaryConstitution,
    required this.summary,
    required this.isLoading,
  });

  final String? primaryConstitution;
  final String? summary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final title = primaryConstitution ?? context.l10n.homeLatestReportNoResult;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.spa_outlined,
                color: AppColors.primary,
                size: 15,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        if (summary != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.inputBg.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              summary!,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
                height: 1.7,
              ),
            ),
          ),
        ] else if (isLoading) ...[
          const SizedBox(height: 10),
          AppShimmer(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLine(height: 10),
                  SizedBox(height: 8),
                  SkeletonLine(width: 150, height: 10),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LatestReportRadar extends StatelessWidget {
  const _LatestReportRadar({
    required this.scores,
    required this.isLoading,
    required this.onRetry,
  });

  final List<(String, double, Color, bool)> scores;
  final bool isLoading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                context.l10n.homeLatestReportRadarTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Tooltip(
              message: context.l10n.homeLatestReportRadarHint,
              child: Icon(
                Icons.info_outline,
                size: 15,
                color: AppColors.textHint.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const _LatestReportRadarSkeleton()
        else if (scores.isEmpty && onRetry != null)
          SizedBox(
            height: 148,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: 22,
                    color: AppColors.textHint,
                  ),
                  SizedBox(height: 4),
                  TextButton(
                    onPressed: onRetry,
                    child: Text(context.l10n.commonRetry),
                  ),
                ],
              ),
            ),
          )
        else if (scores.isEmpty)
          SizedBox(
            height: 148,
            child: Center(
              child: Text(
                context.l10n.homeLatestReportNoRadarData,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ),
          )
        else
          _ConstitutionRadarWithLabels(scores: scores),
        if (scores.isNotEmpty) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 13,
                height: 2,
                color: scores.first.$3.withValues(alpha: 0.72),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  context.l10n.homeLatestReportRadarHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LatestReportRadarSkeleton extends StatelessWidget {
  const _LatestReportRadarSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('home_latest_report_detail_loading'),
      height: 158,
      child: Center(
        child: AppShimmer(
          child: Stack(
            alignment: Alignment.center,
            children: [
              const SkeletonCircle(size: 84),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.softBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConstitutionRadarWithLabels extends StatelessWidget {
  const _ConstitutionRadarWithLabels({required this.scores});

  final List<(String, double, Color, bool)> scores;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, 360.0);
        const height = 158.0;
        final chartSize = math.min(120.0, width * 0.68);
        final center = Offset(width / 2, height / 2 + 5);
        final labelRadius = chartSize / 2 + 8;

        return Center(
          child: SizedBox(
            key: const ValueKey('home_constitution_radar'),
            width: width,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: center.dx - chartSize / 2,
                  top: center.dy - chartSize / 2,
                  child: CustomPaint(
                    size: Size.square(chartSize),
                    painter: ConstitutionRadarPainter(
                      scores: scores,
                      progress: 1,
                    ),
                  ),
                ),
                for (var index = 0; index < scores.length; index++)
                  _radarLabel(
                    score: scores[index],
                    center: center,
                    radius: labelRadius,
                    index: index,
                    count: scores.length,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _radarLabel({
    required (String, double, Color, bool) score,
    required Offset center,
    required double radius,
    required int index,
    required int count,
  }) {
    const labelWidth = 34.0;
    const labelHeight = 28.0;
    final angle = index * 2 * math.pi / count - math.pi / 2;
    final x = center.dx + math.cos(angle) * radius - labelWidth / 2;
    final y = center.dy + math.sin(angle) * radius - labelHeight / 2;

    return Positioned(
      left: x,
      top: y,
      width: labelWidth,
      height: labelHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            score.$1,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: score.$4 ? FontWeight.w700 : FontWeight.w500,
              color: score.$4 ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '${(score.$2 * 100).round()}',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: score.$4 ? score.$3 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestReportActions extends StatelessWidget {
  const _LatestReportActions({
    required this.onOpenReport,
    required this.onCompareHistory,
  });

  final VoidCallback onOpenReport;
  final VoidCallback onCompareHistory;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.025),
        border: Border(
          top: BorderSide(color: AppColors.primary.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _LatestReportAction(
              icon: Icons.assignment_outlined,
              title: context.l10n.homeLatestReportViewFull,
              subtitle: context.l10n.homeLatestReportViewFullSubtitle,
              onTap: onOpenReport,
            ),
          ),
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(vertical: 14),
            color: AppColors.primary.withValues(alpha: 0.09),
          ),
          Expanded(
            child: _LatestReportAction(
              key: const ValueKey('home_compare_history'),
              icon: Icons.query_stats_outlined,
              title: context.l10n.homeLatestReportCompareHistory,
              subtitle: context.l10n.homeLatestReportCompareHistorySubtitle,
              onTap: onCompareHistory,
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestReportAction extends StatelessWidget {
  const _LatestReportAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 78),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 6, 12),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 15, color: AppColors.primary),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 8.5,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LastReportLoadingCard extends StatelessWidget {
  const _LastReportLoadingCard();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 316;
        return Container(
          key: const ValueKey('home_latest_report_loading'),
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
          ),
          child: AppShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    SkeletonCircle(size: 34),
                    SizedBox(width: 10),
                    Expanded(child: SkeletonLine(width: 150, height: 14)),
                    SizedBox(width: 28),
                    SkeletonLine(width: 62, height: 10),
                  ],
                ),
                const SizedBox(height: 22),
                if (isCompact)
                  const Column(
                    children: [
                      SkeletonLine(width: 126, height: 18),
                      SizedBox(height: 14),
                      SkeletonBlock(
                        height: 62,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      SizedBox(height: 24),
                      SkeletonCircle(size: 84),
                    ],
                  )
                else
                  const SizedBox(
                    height: 160,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SkeletonLine(width: 126, height: 18),
                              SizedBox(height: 14),
                              SkeletonBlock(
                                height: 62,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 32),
                        Expanded(
                          child: Center(child: SkeletonCircle(size: 84)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                const Row(
                  children: [
                    Expanded(
                      child: SkeletonBlock(
                        height: 58,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: SkeletonBlock(
                        height: 58,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LastReportEmptyCard extends StatelessWidget {
  const _LastReportEmptyCard({required this.onStartScan});

  final VoidCallback onStartScan;

  @override
  Widget build(BuildContext context) {
    return _LastReportStateCard(
      icon: Icons.assignment_outlined,
      title: context.l10n.homeLatestReportEmptyTitle,
      subtitle: context.l10n.homeLatestReportEmptySubtitle,
      actionLabel: context.l10n.homeStartFullScan,
      onAction: onStartScan,
    );
  }
}

class _LastReportErrorCard extends StatelessWidget {
  const _LastReportErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _LastReportStateCard(
      icon: Icons.error_outline,
      title: context.l10n.homeLatestReportLoadFailed,
      actionLabel: context.l10n.commonRetry,
      onAction: onRetry,
    );
  }
}

class _LastReportStateCard extends StatelessWidget {
  const _LastReportStateCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 21, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 10),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

DateTime? _parseReportDate(String? rawValue) {
  final value = rawValue?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }
  final parsed = DateTime.tryParse(value);
  if (parsed != null) {
    return parsed;
  }
  final timestamp = int.tryParse(value);
  if (timestamp == null) {
    return null;
  }
  final milliseconds = value.length <= 10 ? timestamp * 1000 : timestamp;
  return DateTime.fromMillisecondsSinceEpoch(milliseconds);
}

String? _firstReportText(Iterable<String?> values) {
  for (final value in values) {
    final normalized = value?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
  }
  return null;
}

String _compactConstitutionName(String value) {
  final normalized = value.trim();
  return normalized.endsWith('体质')
      ? '${normalized.substring(0, normalized.length - 2)}质'
      : normalized;
}

Color _constitutionColor({
  required String id,
  required String name,
  required int index,
}) {
  final key = '$id $name'.toLowerCase();
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
  if (key.contains('special') || key.contains('特禀')) {
    return const Color(0xFF909080);
  }

  const fallback = [
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
  return fallback[index % fallback.length];
}
