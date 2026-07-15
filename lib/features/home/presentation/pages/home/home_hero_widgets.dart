part of '../home_page.dart';

class _HeroFlexibleSpace extends StatelessWidget {
  final Widget collapsedHeader;
  final Widget greeting;
  final Widget scoreRing;

  const _HeroFlexibleSpace({
    required this.collapsedHeader,
    required this.greeting,
    required this.scoreRing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const expandedH = 228.0;
        final collapsedH = kToolbarHeight + MediaQuery.of(context).padding.top;

        // progress: 1.0 = 完全展开，0.0 = 完全收起
        final progress =
            ((constraints.maxHeight - collapsedH) / (expandedH - collapsedH))
                .clamp(0.0, 1.0);

        // ── 派生动画曲线 ──────────────────────────────────────────
        // Hero 整体：在 progress 0.3 到 1.0 区间淡入
        final heroOpacity = ((progress - 0.3) / 0.7).clamp(0.0, 1.0);

        // greeting 向上飞出：progress 0 到 0.5 区间，向下偏移 12px
        final greetingSlide = (1.0 - (progress / 0.5).clamp(0.0, 1.0)) * 12.0;
        final greetingOpacity = (progress / 0.6).clamp(0.0, 1.0);

        // scoreRing 轻微缩放 + 淡出：progress 0 到 0.6
        final ringScale = 0.88 + 0.12 * (progress / 0.6).clamp(0.0, 1.0);
        final ringOpacity = (progress / 0.6).clamp(0.0, 1.0);

        // 收起态标题：progress 0 到 0.3 淡入，从下方 6px 滑入
        final collapsedOpacity = ((0.3 - progress) / 0.3).clamp(0.0, 1.0);
        final collapsedSlide = (1.0 - collapsedOpacity) * 6.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            // 兜底背景色（始终存在）
            const ColoredBox(color: AppColors.softBg),

            // Hero 展开区域
            Opacity(
              opacity: heroOpacity,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.heroGradient,
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _HeroBgPainter()),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 46, 22, 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // greeting：向上位移 + 淡入
                              Expanded(
                                child: Transform.translate(
                                  offset: Offset(0, greetingSlide),
                                  child: Opacity(
                                    opacity: greetingOpacity,
                                    child: SingleChildScrollView(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      child: greeting,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // scoreRing：缩放 + 淡入
                              Transform.scale(
                                scale: ringScale,
                                child: Opacity(
                                  opacity: ringOpacity,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: scoreRing,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 收起态品牌标题：从下方滑入 + 淡入
            Positioned(
              left: 20,
              bottom: 14,
              child: Opacity(
                opacity: collapsedOpacity,
                child: Transform.translate(
                  offset: Offset(0, collapsedSlide),
                  child: collapsedHeader,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Hero Background Painter ──────────────────────────────────────
class _HeroBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * 0.85, -20),
      110,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35),
    );
    canvas.drawCircle(
      Offset(-20, size.height * 0.9),
      80,
      Paint()
        ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.07)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
    );
    final cx = size.width - 30.0;
    final cy = size.height * 0.52;
    const r = 62.0;
    final p = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(cx, cy), r, p);
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.82,
      p..color = const Color(0xFF2D6A4F).withValues(alpha: 0.055),
    );
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        Offset(cx + math.cos(a) * r * 0.82, cy + math.sin(a) * r * 0.82),
        Offset(cx + math.cos(a) * r, cy + math.sin(a) * r),
        Paint()
          ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.09)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Home Body Background Painter ─────────────────────────────────
class _HomeBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final g = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.02)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), g);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), g);
    }
    final seal = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(size.width - 14, 48), 44, seal);
    canvas.drawCircle(Offset(size.width - 14, 48), 34, seal);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Collapsed Header ─────────────────────────────────────────────
class _CollapsedHeader extends StatelessWidget {
  const _CollapsedHeader();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1D5E40), Color(0xFF3DAB78)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 1.2,
                  ),
                ),
              ),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          context.l10n.homeCollapsedTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// TCM Constitution Badge（浅色 Hero 版）
class _TcmConstitutionBadge extends StatelessWidget {
  final double progress;
  final int? score;
  final String? constitution;

  const _TcmConstitutionBadge({
    required this.progress,
    required this.score,
    required this.constitution,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(80, 80),
                  painter: _ScoreRingPainter(
                    progress: progress * ((score ?? 0) / 100),
                    trackColor: AppColors.primary.withValues(alpha: 0.12),
                    progressStart: const Color(0xFF2D6A4F),
                    progressEnd: const Color(0xFF7EC8A0),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      score == null ? '--' : '${(score! * progress).round()}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      context.l10n.homeHealthScoreLabel,
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.primaryMid,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (constitution != null) ...[
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                constitution!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Score Ring Painter ────────────────────────────────────────────
class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressStart;
  final Color progressEnd;

  const _ScoreRingPainter({
    required this.progress,
    this.trackColor = const Color(0x30FFFFFF),
    this.progressStart = const Color(0xFF7EC8A0),
    this.progressEnd = const Color(0xFFFFFFFF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const sw = 5.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..shader = LinearGradient(
          colors: [progressStart, progressEnd],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) => old.progress != progress;
}
