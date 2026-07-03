// 舌象识别覆盖层组件。负责把舌象引导框、关键轮廓和调试可视化绘制到界面上。

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/vision_models.dart';

class TongueOverlay extends StatelessWidget {
  const TongueOverlay({super.key, required this.result});

  final TongueDetectionResult? result;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TonguePainter(result: result),
      size: Size.infinite,
    );
  }
}

class _TonguePainter extends CustomPainter {
  _TonguePainter({required this.result});

  final TongueDetectionResult? result;

  final Paint _fillPaint = Paint()
    ..color = Colors.red.withValues(alpha: 0.6)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final result = this.result;
    if (result == null || !result.tongueDetected || result.mouthLandmarks.isEmpty) {
      return;
    }

    final points = result.mouthLandmarks
        .map((p) => Offset((1 - p.dx) * size.width, p.dy * size.height))
        .toList();

    final bounds = _boundingBox(points);
    final center = bounds.center;
    final rx = bounds.width * 0.48;
    final ry = bounds.height * 0.42;

    final rect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);
    canvas.drawOval(rect, _fillPaint);
  }

  Rect _boundingBox(List<Offset> points) {
    var minX = double.infinity;
    var maxX = -double.infinity;
    var minY = double.infinity;
    var maxY = -double.infinity;

    for (final p in points) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  bool shouldRepaint(_TonguePainter oldDelegate) => oldDelegate.result != result;
}
