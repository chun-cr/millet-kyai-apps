// 扫描模块共享组件：`HandLandmarkOverlay`。封装反复使用的界面结构与交互片段，减少页面重复代码。

import 'package:flutter/material.dart';

class HandLandmarkOverlay extends StatelessWidget {
  const HandLandmarkOverlay({
    super.key,
    required this.normalizedLandmarks,
    this.imageSize,
    this.mirrored = false,
  });

  final List<Offset> normalizedLandmarks;
  final Size? imageSize;
  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    if (normalizedLandmarks.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: HandLandmarkPainter(
            normalizedLandmarks: normalizedLandmarks,
            imageSize: imageSize,
            mirrored: mirrored,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class HandLandmarkPainter extends CustomPainter {
  HandLandmarkPainter({
    required this.normalizedLandmarks,
    this.imageSize,
    required this.mirrored,
  });

  final List<Offset> normalizedLandmarks;
  final Size? imageSize;
  final bool mirrored;

  final Paint _pointPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.white;

  final Paint _glowPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFF00E5FF).withValues(alpha: 0.3)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

  final Paint _bonePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = const Color(0xFF00E5FF).withValues(alpha: 0.85);

  final Paint _netPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    if (normalizedLandmarks.length < 21) return;

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    final points = _mapToView(size);

    // 1. 绘制基本骨架 (Standard bones)
    for (final connection in HandMeshConnections.all) {
      final start = connection.$1;
      final end = connection.$2;
      if (start >= points.length || end >= points.length) continue;
      canvas.drawLine(points[start], points[end], _bonePaint);
    }

    // 2. 将离得近的描点连起来 (Dynamic proximity mesh)
    final maxDist = size.width * 0.18; // 动态连接的阈值距离
    final maxDistSq = maxDist * maxDist;

    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        // 跳过已经是基本骨架的固定连接，避免重复绘制
        final isBone = HandMeshConnections.all.any((c) =>
            (c.$1 == i && c.$2 == j) || (c.$1 == j && c.$2 == i));
        if (isBone) continue;

        final distSq = (points[i] - points[j]).distanceSquared;
        if (distSq < maxDistSq) {
          // 根据距离渐变透明度，越近线越清晰
          final ratio = 1.0 - (distSq / maxDistSq);
          _netPaint.color = const Color(0xFF00E5FF).withValues(alpha: 0.6 * ratio);
          canvas.drawLine(points[i], points[j], _netPaint);
        }
      }
    }

    // 3. 绘制节点 (Landmark points)
    for (final point in points) {
      canvas.drawCircle(point, 4.0, _glowPaint);
      canvas.drawCircle(point, 1.8, _pointPaint);
    }

    canvas.restore();
  }

  List<Offset> _mapToView(Size viewSize) {
    if (imageSize == null || imageSize == Size.zero) {
      return normalizedLandmarks.map((p) {
        final x = (mirrored ? 1 - p.dx : p.dx).clamp(0.0, 1.0) * viewSize.width;
        final y = p.dy.clamp(0.0, 1.0) * viewSize.height;
        return Offset(x, y);
      }).toList(growable: false);
    }

    final double sourceWidth = imageSize!.width;
    final double sourceHeight = imageSize!.height;
    
    final double scaleX = viewSize.width / sourceWidth;
    final double scaleY = viewSize.height / sourceHeight;
    final double scale = scaleX > scaleY ? scaleX : scaleY;

    final double scaledWidth = sourceWidth * scale;
    final double scaledHeight = sourceHeight * scale;
    final double dx = (viewSize.width - scaledWidth) / 2;
    final double dy = (viewSize.height - scaledHeight) / 2;

    return normalizedLandmarks.map((p) {
      final double rawX = (mirrored ? 1 - p.dx : p.dx) * sourceWidth;
      final double rawY = p.dy * sourceHeight;
      return Offset(dx + rawX * scale, dy + rawY * scale);
    }).toList(growable: false);
  }

  @override
  bool shouldRepaint(HandLandmarkPainter oldDelegate) {
    return oldDelegate.normalizedLandmarks != normalizedLandmarks ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.mirrored != mirrored;
  }
}

class HandMeshConnections {
  static const wristToThumb = [(0, 1), (1, 2), (2, 3), (3, 4)];
  static const wristToIndex = [(0, 5), (5, 6), (6, 7), (7, 8)];
  static const wristToMiddle = [(0, 9), (9, 10), (10, 11), (11, 12)];
  static const wristToRing = [(0, 13), (13, 14), (14, 15), (15, 16)];
  static const wristToPinky = [(0, 17), (17, 18), (18, 19), (19, 20)];
  static const palm = [(5, 9), (9, 13), (13, 17), (5, 17)];

  static const all = [
    ...wristToThumb,
    ...wristToIndex,
    ...wristToMiddle,
    ...wristToRing,
    ...wristToPinky,
    ...palm,
  ];
}
