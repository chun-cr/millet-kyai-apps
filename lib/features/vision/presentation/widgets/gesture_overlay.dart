// 手势识别覆盖层组件。负责把关键点和轮廓结果绘制到扫描预览之上。

import 'package:flutter/material.dart';

import '../../domain/models/vision_models.dart';

class GestureOverlay extends StatelessWidget {
  const GestureOverlay({super.key, required this.result});

  final GestureResult? result;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GesturePainter(result: result),
      size: Size.infinite,
    );
  }
}

class _GesturePainter extends CustomPainter {
  _GesturePainter({required this.result});

  final GestureResult? result;

  final Paint _pointPaint = Paint()
    ..color = Colors.greenAccent
    ..style = PaintingStyle.fill
    ..strokeWidth = 2;

  final Paint _linePaint = Paint()
    ..color = Colors.greenAccent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final result = this.result;
    if (result == null || result.handLandmarks.isEmpty) return;

    final points = result.handLandmarks
        .map((p) => Offset((1 - p.dx) * size.width, p.dy * size.height))
        .toList();

    for (final point in points) {
      canvas.drawCircle(point, 4, _pointPaint);
    }

    for (final connection in _HandConnections.connections) {
      if (connection[0] >= points.length || connection[1] >= points.length) continue;
      canvas.drawLine(points[connection[0]], points[connection[1]], _linePaint);
    }
  }

  @override
  bool shouldRepaint(_GesturePainter oldDelegate) => oldDelegate.result != result;
}

class _HandConnections {
  static const List<List<int>> connections = [
    [0, 1], [1, 2], [2, 3], [3, 4],
    [0, 5], [5, 6], [6, 7], [7, 8],
    [0, 9], [9, 10], [10, 11], [11, 12],
    [0, 13], [13, 14], [14, 15], [15, 16],
    [0, 17], [17, 18], [18, 19], [19, 20],
    [5, 9], [9, 13], [13, 17],
  ];
}
