import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_router.dart';

class ScanGuidePage extends StatefulWidget {
  const ScanGuidePage({super.key});

  @override
  State<ScanGuidePage> createState() => _ScanGuidePageState();
}

class _ScanGuidePageState extends State<ScanGuidePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _cardAnimations;
  late Animation<double> _pageFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _cardAnimations = List.generate(3, (i) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.15 * i, 0.15 * i + 0.55, curve: Curves.easeOut),
        ),
      );
    });

    _pageFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.24, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EB),
      body: FadeTransition(
        opacity: _pageFade,
        child: ColoredBox(
          color: const Color(0xFFF4F1EB),
          child: Stack(
            children: [
              Positioned.fill(child: _buildBackground()),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 4),
                            _buildTitleSection(),
                            const SizedBox(height: 28),
                            _buildStepCards(),
                            const SizedBox(height: 24),
                            _buildInfoBanner(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomSection(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Background ──────────────────────────────────────────────────────────

  Widget _buildBackground() {
    return CustomPaint(painter: _BgPainter());
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 18, color: Color(0xFF3A3028)),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Center(
              child: Text(
                l10n.scanGuideHeaderTitle,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2A2018),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ─── Title Section ────────────────────────────────────────────────────────

  Widget _buildTitleSection() {
    final l10n = context.l10n;
    return Column(
      children: [
        // Decorative top ornament
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildOrnamentLine(),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF2D6A4F).withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Text(
                l10n.authInspectionMotto,
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 3,
                  color: Color(0xFF2D6A4F),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildOrnamentLine(),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.scanGuideHeroTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E1810),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.scanGuideHeroSubtitle,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.7,
            color: const Color(0xFF3A3028).withValues(alpha: 0.6),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildOrnamentLine() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 1,
          color: const Color(0xFF2D6A4F).withValues(alpha: 0.3),
        ),
        const SizedBox(width: 4),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  // ─── Step Cards ──────────────────────────────────────────────────────────

  Widget _buildStepCards() {
    final l10n = context.l10n;
    final steps = [
      _StepData(
        step: 1,
        title: l10n.scanGuideStep1Title,
        desc: l10n.scanGuideStep1Desc,
        detail: l10n.scanGuideStep1Detail,
        icon: Icons.face_retouching_natural_outlined,
        tcmLabel: l10n.scanFaceTag,
        color: const Color(0xFF2D6A4F),
        lightColor: const Color(0xFFE8F5EE),
      ),
      _StepData(
        step: 2,
        title: l10n.scanGuideStep2Title,
        desc: l10n.scanGuideStep2Desc,
        detail: l10n.scanGuideStep2Detail,
        icon: Icons.sentiment_satisfied_alt_outlined,
        tcmLabel: l10n.scanTongueTag,
        color: const Color(0xFF0D7A5A),
        lightColor: const Color(0xFFE4F7F1),
      ),
      _StepData(
        step: 3,
        title: l10n.scanGuideStep3Title,
        desc: l10n.scanGuideStep3Desc,
        detail: l10n.scanGuideStep3Detail,
        icon: Icons.back_hand_outlined,
        tcmLabel: l10n.scanPalmTag,
        color: const Color(0xFF6B5B95),
        lightColor: const Color(0xFFF0EDF8),
      ),
    ];

    return Column(
      children: List.generate(steps.length, (i) {
        return AnimatedBuilder(
          animation: _cardAnimations[i],
          builder: (context, child) {
            final v = _cardAnimations[i].value;
            return Opacity(
              opacity: v,
              child: Transform.translate(
                offset: Offset(0, 24 * (1 - v)),
                child: child,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepCard(steps[i]),
              if (i < steps.length - 1) _buildConnector(steps[i].color),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepCard(_StepData data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: data.color.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: data.color.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          const BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: data.lightColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: data.color.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(data.icon, size: 28, color: data.color),
                      // Step number badge
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: data.color,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${data.step}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              context.l10n.scanGuideStepLabel(data.step, data.title),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E1810),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // TCM label tag
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: data.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              data.tcmLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: data.color,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF3A3028).withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.check_circle_rounded,
                  size: 22,
                  color: const Color(0xFFD0C8B8),
                ),
              ],
            ),
          ),
          // Detail strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: data.lightColor.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome,
                    size: 12,
                    color: data.color.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    data.detail,
                    style: TextStyle(
                      fontSize: 11,
                      color: data.color.withValues(alpha: 0.75),
                      letterSpacing: 0.2,
                      height: 1.4,
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

  Widget _buildConnector(Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 45, top: 0),
      child: SizedBox(
        height: 22,
        child: CustomPaint(
          painter: _DashedLinePainter(color: color),
        ),
      ),
    );
  }

  // ─── Info Banner ──────────────────────────────────────────────────────────

  Widget _buildInfoBanner() {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2D6A4F).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF2D6A4F).withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_outlined,
                size: 18, color: Color(0xFF2D6A4F)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.scanGuideWarmPromptTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D6A4F),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.scanGuideWarmPromptContent,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.5,
                    color: const Color(0xFF3A3028).withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Section ───────────────────────────────────────────────────────

  Widget _buildBottomSection(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EB),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF2D6A4F).withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Time estimate
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined,
                  size: 13,
                  color: const Color(0xFF3A3028).withValues(alpha: 0.4)),
              const SizedBox(width: 5),
              Text(
                l10n.scanGuideEstimate,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF3A3028).withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // CTA Button
          GestureDetector(
            onTap: () => context.push(AppRoutes.scanFace),
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D5E40), Color(0xFF2D8A5E), Color(0xFF3DAB78)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D6A4F).withValues(alpha: 0.38),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_outline,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.scanGuideStartButton,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.scanGuidePrivacyNote,
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF3A3028).withValues(alpha: 0.35),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data Model ───────────────────────────────────────────────────────────────

class _StepData {
  final int step;
  final String title;
  final String desc;
  final String detail;
  final IconData icon;
  final String tcmLabel;
  final Color color;
  final Color lightColor;

  const _StepData({
    required this.step,
    required this.title,
    required this.desc,
    required this.detail,
    required this.icon,
    required this.tcmLabel,
    required this.color,
    required this.lightColor,
  });
}

// ─── Background Painter ───────────────────────────────────────────────────────

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Top-right subtle radial wash
    final topPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(1.2, -0.8),
        radius: 0.9,
        colors: [
          const Color(0xFF2D6A4F).withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), topPaint);

    // Bottom-left wash
    final bottomPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-1.1, 1.3),
        radius: 0.85,
        colors: [
          const Color(0xFF6B5B95).withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bottomPaint);

    // Subtle circular watermark (like a seal/chop) top-right corner
    final sealPaint = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(size.width - 20, 60), 52, sealPaint);
    canvas.drawCircle(Offset(size.width - 20, 60), 42, sealPaint);

    // Fine grid texture (very subtle)
    final gridPaint = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.025)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Dashed Line Painter ──────────────────────────────────────────────────────

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + 4), paint);
      y += 8;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}
