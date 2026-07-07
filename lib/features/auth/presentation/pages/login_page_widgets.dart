part of 'login_page.dart';

class _LoginBgPainter extends CustomPainter {
  const _LoginBgPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final washPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.1),
          const Color(0xFFF0E8D8).withValues(alpha: 0.1),
          Colors.transparent,
        ],
        stops: const [0, 0.34, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, washPaint);

    _drawRippleCluster(
      canvas,
      center: Offset(size.width - 22, size.height * 0.28),
      radii: const <double>[16, 24, 32, 40],
      color: const Color(0xFFB6AA96),
      startAngle: math.pi * 0.4,
      sweepAngle: math.pi * 1.15,
    );
    _drawRippleCluster(
      canvas,
      center: Offset(10, size.height - 84),
      radii: const <double>[22, 32, 42, 54, 68],
      color: const Color(0xFFB6AA96),
      startAngle: -math.pi * 0.12,
      sweepAngle: math.pi * 1.2,
    );

    final softCirclePaint = Paint()
      ..color = const Color(0xFF8AA891).withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.5),
      68,
      softCirclePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.24, size.height * 0.72),
      86,
      Paint()
        ..color = const Color(0xFFD8C8AF).withValues(alpha: 0.03)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawRippleCluster(
    Canvas canvas, {
    required Offset center,
    required List<double> radii,
    required Color color,
    required double startAngle,
    required double sweepAngle,
  }) {
    final arcPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final radius in radii) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_LoginBgPainter oldDelegate) => false;
}

class _BaguaRingPainter extends CustomPainter {
  const _BaguaRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 4;
    final ringPaint = Paint()
      ..color = const Color(0xFF587464).withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    final innerRingPaint = Paint()
      ..color = const Color(0xFF587464).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawCircle(Offset(cx, cy), radius, ringPaint);
    canvas.drawCircle(Offset(cx, cy), radius - 12, innerRingPaint);
    for (int i = 0; i < 16; i++) {
      final angle = i * math.pi / 8;
      final tickStart = i.isEven ? radius - 9 : radius - 6;
      canvas.drawLine(
        Offset(
          cx + math.cos(angle) * tickStart,
          cy + math.sin(angle) * tickStart,
        ),
        Offset(cx + math.cos(angle) * radius, cy + math.sin(angle) * radius),
        ringPaint,
      );
    }

    for (int i = 0; i < 24; i++) {
      final angle = i * math.pi / 12;
      canvas.drawCircle(
        Offset(cx + math.cos(angle) * radius, cy + math.sin(angle) * radius),
        1.1,
        Paint()
          ..color = const Color(0xFF587464).withValues(alpha: 0.18)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerBrackets extends StatelessWidget {
  const _CornerBrackets({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(top: 12, left: 12, child: _Bracket(color: color, tl: true)),
        Positioned(top: 12, right: 12, child: _Bracket(color: color, tr: true)),
        Positioned(
          bottom: 12,
          left: 12,
          child: _Bracket(color: color, bl: true),
        ),
        Positioned(
          bottom: 12,
          right: 12,
          child: _Bracket(color: color, br: true),
        ),
      ],
    );
  }
}

class _Bracket extends StatelessWidget {
  const _Bracket({
    required this.color,
    this.tl = false,
    this.tr = false,
    this.bl = false,
    this.br = false,
  });

  final Color color;
  final bool tl;
  final bool tr;
  final bool bl;
  final bool br;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        border: Border(
          top: (tl || tr)
              ? BorderSide(color: color.withValues(alpha: 0.56), width: 1.6)
              : BorderSide.none,
          left: (tl || bl)
              ? BorderSide(color: color.withValues(alpha: 0.56), width: 1.6)
              : BorderSide.none,
          right: (tr || br)
              ? BorderSide(color: color.withValues(alpha: 0.56), width: 1.6)
              : BorderSide.none,
          bottom: (bl || br)
              ? BorderSide(color: color.withValues(alpha: 0.56), width: 1.6)
              : BorderSide.none,
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1.5,
            ),
          ),
        ),
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1F1A16).withValues(alpha: 0.88),
        letterSpacing: 0.2,
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    this.buttonKey,
    required this.icon,
    required this.iconColor,
    this.labelColor,
    required this.label,
    this.loading = false,
    required this.onTap,
  });

  final Key? buttonKey;
  final IconData icon;
  final Color iconColor;
  final Color? labelColor;
  final String label;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: buttonKey,
      onTap: loading ? null : onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFECE2D5), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14928B7A),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: iconColor,
                ),
              )
            else
              Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: labelColor ?? const Color(0xFF3A3028),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
