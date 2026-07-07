part of '../palm_scan_page.dart';

// ── 共用小组件 ─────────────────────────────────────────────────────────────

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TipItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F0F7),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF6B5B95).withValues(alpha: 0.15),
          ),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF6B5B95)),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: const Color(0xFF3A3028).withValues(alpha: 0.6),
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool detected;
  const _StatusPill({required this.label, required this.detected});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: detected
            ? const Color(0xFF6B5B95).withValues(alpha: 0.5)
            : const Color(0xFF6B5B95).withValues(alpha: 0.25),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: detected
            ? const Color(0xFF6B5B95)
            : const Color(0xFF3A3028).withValues(alpha: 0.6),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

class _ScanProgressBar extends StatelessWidget {
  final double progress;
  const _ScanProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Container(
        height: 4,
        decoration: BoxDecoration(
          color: _kAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      FractionallySizedBox(
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kAccent, _kAccentLight]),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: _kAccent.withValues(alpha: 0.45), blurRadius: 6),
            ],
          ),
        ),
      ),
    ],
  );
}

class _PalmHoldFeedback extends StatelessWidget {
  final String label;
  final double progress;

  const _PalmHoldFeedback({required this.label, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusPill(label: label, detected: true),
        const SizedBox(height: 8),
        SizedBox(width: 132, child: _ScanProgressBar(progress: progress)),
      ],
    );
  }
}

class _TiltedPalmGuidePainter extends CustomPainter {
  final Color color;
  final Color accentColor;
  final bool isAligned;
  final double scanLineT;
  // 新增：检测到手掌时隐藏轮廓，避免与 landmark 线条交叠
  final bool handPresent;

  const _TiltedPalmGuidePainter({
    required this.color,
    required this.accentColor,
    required this.isAligned,
    required this.scanLineT,
    this.handPresent = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // SVG 路径已含真实坐标（viewBox 451×511），
    // _buildRightPalmUpPath 内部完成缩放居中，无需再做 translate/rotate

    // ── 仅在未检测到手掌时绘制引导轮廓
    if (!handPresent) {
      final glowPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      final outlinePaint = Paint()
        ..color = color.withValues(alpha: isAligned ? 0.95 : 0.72)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final palmPath = _buildRightPalmUpPath(size);
      canvas.drawPath(palmPath, glowPaint);
      canvas.drawPath(palmPath, outlinePaint);
    }

    // ── 扫描线（未检测到手时显示，表示系统正在检测）
    if (!handPresent) {
      final scanY =
          size.height * 0.05 + size.height * 0.90 * scanLineT.clamp(0.0, 1.0);
      final scanPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            accentColor.withValues(alpha: isAligned ? 0.80 : 0.45),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, scanY - 1, size.width, 2))
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(size.width * 0.08, scanY),
        Offset(size.width * 0.92, scanY),
        scanPaint,
      );
    }
  }

  /// 右手手心朝上的轮廓路径
  /// 从 Figma 导出的真实右手手心朝上 SVG 轮廓
  /// 原始 viewBox: 451 × 511，缩放居中后适配 canvas
  Path _buildRightPalmUpPath(Size size) {
    final p = Path();
    p.moveTo(16.07, 243.27);
    p.cubicTo(6.61, 242.67, 5.64, 249.29, 5.64, 249.29);
    p.lineTo(1.09, 263.51);
    p.lineTo(6.61, 273.07);
    p.lineTo(49.70, 301.51);
    p.lineTo(95.54, 330.69);
    p.lineTo(142.11, 357.12);
    p.lineTo(166.71, 399.72);
    p.lineTo(195.11, 430.84);
    p.lineTo(228.41, 468.42);
    p.lineTo(277.76, 503.68);
    p.lineTo(316.77, 508.98);
    p.lineTo(342.86, 493.91);
    p.lineTo(376.01, 468.97);
    p.lineTo(402.01, 459.76);
    p.lineTo(428.97, 444.19);
    p.lineTo(444.29, 414.48);
    p.lineTo(448.46, 341.37);
    p.lineTo(448.22, 284.71);
    p.lineTo(439.55, 207.42);
    p.lineTo(436.81, 176.55);
    p.lineTo(441.52, 142.53);
    p.lineTo(446.07, 128.31);
    p.lineTo(449.51, 118.21);
    p.lineTo(445.50, 111.25);
    p.cubicTo(440.66, 106.37, 436.64, 104.84, 426.66, 104.74);
    p.cubicTo(418.59, 106.26, 414.86, 108.21, 410.14, 114.28);
    p.cubicTo(397.62, 124.95, 393.77, 131.26, 390.70, 142.89);
    p.lineTo(384.78, 186.88);
    p.lineTo(374.32, 245.08);
    p.lineTo(343.44, 217.70);
    p.lineTo(326.87, 189.02);
    p.lineTo(317.84, 173.37);
    p.lineTo(289.29, 109.87);
    p.lineTo(251.65, 44.66);
    p.lineTo(231.57, 9.89);
    p.lineTo(219.46, 2.97);
    p.cubicTo(210.05, -0.43, 205.43, 0.55, 198.05, 6.06);
    p.cubicTo(190.80, 11.15, 188.06, 15.14, 187.55, 26.04);
    p.lineTo(211.64, 67.77);
    p.lineTo(239.41, 125.91);
    p.lineTo(257.15, 166.68);
    p.lineTo(272.71, 193.63);
    p.cubicTo(271.34, 204.60, 266.66, 206.09, 254.44, 204.17);
    p.lineTo(205.76, 119.85);
    p.cubicTo(187.16, 98.42, 177.57, 83.93, 161.02, 56.42);
    p.lineTo(142.45, 24.25);
    p.cubicTo(136.99, 19.67, 132.73, 18.25, 121.37, 17.88);
    p.cubicTo(111.74, 18.59, 108.26, 21.17, 103.97, 27.92);
    p.cubicTo(99.02, 31.61, 98.34, 35.82, 101.57, 47.86);
    p.lineTo(128.67, 94.80);
    p.lineTo(155.78, 141.75);
    p.lineTo(180.87, 185.21);
    p.lineTo(207.47, 231.29);
    p.cubicTo(208.50, 231.91, 209.56, 242.96, 197.81, 242.67);
    p.lineTo(151.87, 189.21);
    p.lineTo(103.78, 130.04);
    p.cubicTo(103.78, 130.04, 84.30, 103.20, 79.36, 97.77);
    p.cubicTo(74.41, 92.34, 70.25, 91.69, 60.29, 94.87);
    p.lineTo(48.38, 106.39);
    p.cubicTo(48.38, 106.39, 46.44, 116.04, 47.08, 122.21);
    p.cubicTo(48.49, 135.85, 64.64, 152.63, 64.64, 152.63);
    p.cubicTo(86.32, 180.82, 98.14, 196.49, 115.64, 222.88);
    p.lineTo(167.73, 289.01);
    p.cubicTo(166.88, 299.41, 163.69, 303.42, 154.49, 308.25);
    p.cubicTo(116.94, 292.59, 95.40, 282.75, 53.88, 258.53);
    p.lineTo(32.40, 245.43);
    p.cubicTo(32.40, 245.43, 25.54, 243.87, 16.07, 243.27);
    p.close();

    // 缩放并居中到 canvas
    const svgW = 451.0;
    const svgH = 511.0;
    final scale = math.min(size.width / svgW, size.height / svgH) * 0.98;
    final offsetX = (size.width - svgW * scale) / 2;
    final offsetY = (size.height - svgH * scale) / 2;
    final m = Matrix4.identity()
      ..translateByDouble(offsetX, offsetY, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
    return p.transform(m.storage);
  }

  @override
  bool shouldRepaint(covariant _TiltedPalmGuidePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isAligned != isAligned ||
        oldDelegate.scanLineT != scanLineT ||
        oldDelegate.handPresent != handPresent;
  }
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
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
    final sealPaint = Paint()
      ..color = const Color(0xFF2D6A4F).withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(size.width - 20, 60), 52, sealPaint);
    canvas.drawCircle(Offset(size.width - 20, 60), 42, sealPaint);
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
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── 手绘画笔：手掌轮廓引导图 ─────────────────────────────────────────────────────

// ── 手掌方向/距离提示气泡 ─────────────────────────────────────────────────────

class _PalmDirectionPill extends StatelessWidget {
  final String hint;
  const _PalmDirectionPill({required this.hint});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(hint),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFF8C42).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8C42).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          hint,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
