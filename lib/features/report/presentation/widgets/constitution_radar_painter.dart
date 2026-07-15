import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ConstitutionRadarPainter extends CustomPainter {
  const ConstitutionRadarPainter({
    required this.scores,
    required this.progress,
  });

  final List<(String, double, Color, bool)> scores;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 9;
    final sides = math.max(3, scores.length);
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
    final dominantColor = scores.isNotEmpty
        ? scores.first.$3
        : const Color(0xFF2D6A4F);

    canvas.drawCircle(
      center,
      radius * 0.72,
      Paint()
        ..shader = RadialGradient(
          colors: [
            dominantColor.withValues(alpha: 0.16),
            const Color(0xFFC9A84C).withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.58, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 0.9)),
    );

    for (var ring = 1; ring <= 4; ring++) {
      final ringRadius = radius * ring / 4;
      final path = Path();
      for (var index = 0; index < sides; index++) {
        final point = _axisPoint(center, ringRadius, index, sides);
        if (index == 0) {
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

    for (var index = 0; index < sides; index++) {
      canvas.drawLine(
        center,
        _axisPoint(center, radius, index, sides),
        Paint()
          ..color = dominantColor.withValues(alpha: 0.1)
          ..strokeWidth = 0.8,
      );
    }

    final dataPath = Path();
    for (var index = 0; index < sides; index++) {
      final value = index < scores.length
          ? scores[index].$2.clamp(0.0, 1.0).toDouble()
          : 0.0;
      final point = _axisPoint(
        center,
        radius * value * clampedProgress,
        index,
        sides,
      );
      if (index == 0) {
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
        ).createShader(Rect.fromCircle(center: center, radius: radius))
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
  bool shouldRepaint(covariant ConstitutionRadarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        !listEquals(oldDelegate.scores, scores);
  }
}
