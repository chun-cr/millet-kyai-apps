part of '../tongue_scan_page.dart';

class _ScanProgressBar extends StatelessWidget {
  final double progress;
  const _ScanProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Container(
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFE88080).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      FractionallySizedBox(
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE88080), Color(0xFFFF6B6B)],
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE88080).withValues(alpha: 0.5),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

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
          color: const Color(0xFFE4F7F1),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF0D7A5A).withValues(alpha: 0.15),
          ),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF0D7A5A)),
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
            ? const Color(0xFFE88080).withValues(alpha: 0.5)
            : const Color(0xFF0D7A5A).withValues(alpha: 0.25),
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
      style: TextStyle(
        color: detected
            ? const Color(0xFFE88080)
            : const Color(0xFF3A3028).withValues(alpha: 0.6),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
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

class _CircleMask extends StatelessWidget {
  final Offset center;
  final double radius;
  final Color bgColor;

  const _CircleMask({
    required this.center,
    required this.radius,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CircleMaskPainter(
        center: center,
        radius: radius,
        bgColor: bgColor,
      ),
    );
  }
}

class _CircleMaskPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color bgColor;

  _CircleMaskPainter({
    required this.center,
    required this.radius,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final maskPath = Path.combine(
      PathOperation.difference,
      fullPath,
      circlePath,
    );
    canvas.drawPath(maskPath, Paint()..color = bgColor); // 不透明边缘遮罩
  }

  @override
  bool shouldRepaint(_CircleMaskPainter old) =>
      old.center != center || old.radius != radius;
}

class _BionicTonguePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final Color? fillColor;
  final double scale;
  final bool drawNodes;
  final double nodeSize;
  final double haloOpacity;
  final Color haloColor;

  _BionicTonguePainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.fillColor,
    this.scale = 1.0,
    this.drawNodes = false,
    this.nodeSize = 4.0,
    this.haloOpacity = 0.0,
    this.haloColor = Colors.transparent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);
    canvas.translate(-cx, -cy);

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, h * 0.12);
    path.cubicTo(w * 0.65, h * 0.05, w * 0.85, h * 0.05, w * 0.9, h * 0.25);
    path.cubicTo(w * 0.95, h * 0.5, w * 0.9, h * 0.75, w * 0.75, h * 0.9);
    path.cubicTo(w * 0.6, h * 1.0, w * 0.4, h * 1.0, w * 0.25, h * 0.9);
    path.cubicTo(w * 0.1, h * 0.75, w * 0.05, h * 0.5, w * 0.1, h * 0.25);
    path.cubicTo(w * 0.15, h * 0.05, w * 0.35, h * 0.05, w * 0.5, h * 0.12);
    path.close();

    if (haloOpacity > 0) {
      final haloPaint = Paint()
        ..color = haloColor.withValues(alpha: haloOpacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      canvas.drawPath(path, haloPaint);
    }

    if (fillColor != null) {
      canvas.drawPath(path, Paint()..color = fillColor!);
    }

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    if (drawNodes) {
      final nodePaint = Paint()..color = color;
      final nodes = [
        Offset(w * 0.18, h * 0.18),
        Offset(w * 0.82, h * 0.18),
        Offset(w * 0.2, h * 0.8),
        Offset(w * 0.8, h * 0.8),
      ];
      for (final pt in nodes) {
        canvas.drawCircle(pt, nodeSize, nodePaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BionicTonguePainter old) => true;
}

class _TongueDirectionPill extends StatelessWidget {
  final String direction;
  const _TongueDirectionPill({required this.direction});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(direction),
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
          direction,
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
