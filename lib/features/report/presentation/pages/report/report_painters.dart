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

class _ConstitutionRadarPainter extends CustomPainter {
  const _ConstitutionRadarPainter({
    required this.scores,
    required this.progress,
  });

  final List<(String, double, Color, bool)> scores;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 9;
    final sides = math.max(3, scores.length);
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
    final dominantColor = scores.isNotEmpty
        ? scores.first.$3
        : const Color(0xFF2D6A4F);

    canvas.drawCircle(
      center,
      r * 0.72,
      Paint()
        ..shader = RadialGradient(
          colors: [
            dominantColor.withValues(alpha: 0.16),
            const Color(0xFFC9A84C).withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.58, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r * 0.9)),
    );

    for (int ring = 1; ring <= 4; ring++) {
      final rr = r * ring / 4;
      final path = Path();
      for (int i = 0; i < sides; i++) {
        final point = _axisPoint(center, rr, i, sides);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = dominantColor.withValues(alpha: 0.07)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    for (int i = 0; i < sides; i++) {
      canvas.drawLine(
        center,
        _axisPoint(center, r, i, sides),
        Paint()
          ..color = dominantColor.withValues(alpha: 0.1)
          ..strokeWidth = 0.8,
      );
    }

    final dataPath = Path();
    for (int i = 0; i < sides; i++) {
      final value = i < scores.length
          ? scores[i].$2.clamp(0.0, 1.0).toDouble()
          : 0.0;
      final point = _axisPoint(center, r * value * clampedProgress, i, sides);
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();

    canvas.drawPath(
      dataPath,
      Paint()
        ..shader = RadialGradient(
          colors: [
            dominantColor.withValues(alpha: 0.2),
            dominantColor.withValues(alpha: 0.08),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r))
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = dominantColor.withValues(alpha: 0.66)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  Offset _axisPoint(Offset center, double radius, int index, int sides) {
    final angle = index * 2 * math.pi / sides - math.pi / 2;
    return Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
  }

  @override
  bool shouldRepaint(covariant _ConstitutionRadarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        !listEquals(oldDelegate.scores, scores);
  }
}
