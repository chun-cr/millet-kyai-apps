// 报告模块页面：`ReportPainters`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

part of 'report_page.dart';

class _ScoreRingPainter extends CustomPainter {
  const _ScoreRingPainter({
    required this.progress,
    this.strokeWidth = 5.5,
    this.trackColor = const Color(0x1F2D6A4F),
    this.colors = const [Color(0xFF2D6A4F), Color(0xFF7EC8A0)],
  });

  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final clampedProgress = progress.clamp(0.0, 1.0);

    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (clampedProgress <= 0) {
      return;
    }

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * clampedProgress,
      false,
      Paint()
        ..shader = LinearGradient(colors: colors).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor ||
        !listEquals(oldDelegate.colors, colors);
  }
}

class _RiskIndexRingPainter extends CustomPainter {
  const _RiskIndexRingPainter({required this.progress, required this.colors});

  final double progress;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6.5;
    const strokeWidth = 4.0;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final clampedProgress = progress.clamp(0.0, 1.0);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = colors.first.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (clampedProgress <= 0) {
      return;
    }

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * clampedProgress,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: colors,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RiskIndexRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        !listEquals(oldDelegate.colors, colors);
  }
}
