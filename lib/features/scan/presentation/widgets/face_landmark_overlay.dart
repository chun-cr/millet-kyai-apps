// 扫描模块共享组件：`FaceLandmarkOverlay`。封装反复使用的界面结构与交互片段，减少页面重复代码。

import 'package:flutter/material.dart';

class FaceLandmarkOverlay extends StatelessWidget {
  const FaceLandmarkOverlay({
    super.key,
    required this.normalizedLandmarks,
    required this.imageSize,
    this.mirrored = false,
    this.emphasized = false,
  });

  final List<Offset> normalizedLandmarks;
  final Size imageSize;
  final bool mirrored;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    if (normalizedLandmarks.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: FaceLandmarkPainter(
            normalizedLandmarks: normalizedLandmarks,
            imageSize: imageSize,
            mirrored: mirrored,
            emphasized: emphasized,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class FaceLandmarkPainter extends CustomPainter {
  FaceLandmarkPainter({
    required this.normalizedLandmarks,
    required this.imageSize,
    required this.mirrored,
    this.emphasized = false,
  }) : _pointPaint = Paint()
         ..style = PaintingStyle.fill
         ..color = emphasized
             ? const Color(0xFFFFF27A).withValues(alpha: 0.98)
             : const Color(0xFFD7EEFF).withValues(alpha: 0.92),
       _glowPaint = Paint()
         ..style = PaintingStyle.fill
         ..color = emphasized
             ? const Color(0xFF0E0F10).withValues(alpha: 0.34)
             : const Color(0xFF7ECFFF).withValues(alpha: 0.18)
         ..maskFilter = MaskFilter.blur(
           BlurStyle.normal,
           emphasized ? 4.2 : 2.4,
         ),
       _meshPaint = Paint()
         ..style = PaintingStyle.stroke
         ..strokeWidth = emphasized ? 1.35 : 0.7
         ..strokeCap = StrokeCap.round
         ..strokeJoin = StrokeJoin.round
         ..color = emphasized
             ? const Color(0xFF16C784).withValues(alpha: 0.82)
             : const Color(0xFF7ECFFF).withValues(alpha: 0.28),
       _outlinePaint = Paint()
         ..style = PaintingStyle.stroke
         ..strokeWidth = emphasized ? 2.3 : 1.15
         ..strokeCap = StrokeCap.round
         ..strokeJoin = StrokeJoin.round
         ..color = emphasized
             ? const Color(0xFF00E48A).withValues(alpha: 0.96)
             : const Color(0xFF8FD8FF).withValues(alpha: 0.72),
       _featurePaint = Paint()
         ..style = PaintingStyle.stroke
         ..strokeWidth = emphasized ? 2.0 : 1.0
         ..strokeCap = StrokeCap.round
         ..strokeJoin = StrokeJoin.round
         ..color = emphasized
             ? const Color(0xFFFFF27A).withValues(alpha: 0.98)
             : const Color(0xFFC8E9FF).withValues(alpha: 0.82);

  final List<Offset> normalizedLandmarks;
  final Size imageSize;
  final bool mirrored;
  final bool emphasized;

  final Paint _pointPaint;
  final Paint _glowPaint;
  final Paint _meshPaint;
  final Paint _outlinePaint;
  final Paint _featurePaint;

  @override
  void paint(Canvas canvas, Size size) {
    if (normalizedLandmarks.isEmpty) return;

    final mapped = _mapToView(size);
    final visibleEntries = emphasized
        ? mapped.asMap().entries.toList(growable: false)
        : mapped
              .asMap()
              .entries
              .where(
                (entry) =>
                    !FaceMeshContours.hiddenPointIndices.contains(entry.key),
              )
              .toList(growable: false);

    _drawSoftMesh(canvas, size, visibleEntries);

    for (final entry in visibleEntries) {
      final point = entry.value;
      canvas.drawCircle(point, emphasized ? 2.8 : 1.7, _glowPaint);
      canvas.drawCircle(point, emphasized ? 1.55 : 0.9, _pointPaint);
    }

    _drawSegments(canvas, mapped, _outlinePaint, FaceMeshContours.faceOutline);
    _drawSegments(canvas, mapped, _featurePaint, FaceMeshContours.lipsOuter);
    _drawSegments(canvas, mapped, _featurePaint, FaceMeshContours.lipsInner);
    _drawSegments(canvas, mapped, _featurePaint, FaceMeshContours.noseBridge);
  }

  void _drawSoftMesh(
    Canvas canvas,
    Size size,
    List<MapEntry<int, Offset>> visibleEntries,
  ) {
    if (visibleEntries.length < 2) {
      return;
    }

    final maxDistance = (size.shortestSide * 0.085).clamp(18.0, 42.0);
    final maxDistanceSquared = maxDistance * maxDistance;
    final drawnSegments = <String>{};

    for (var i = 0; i < visibleEntries.length; i++) {
      final origin = visibleEntries[i].value;
      final neighbors = <({int index, double distanceSquared})>[];

      for (var j = i + 1; j < visibleEntries.length; j++) {
        final target = visibleEntries[j].value;
        final dx = origin.dx - target.dx;
        final dy = origin.dy - target.dy;
        final distanceSquared = dx * dx + dy * dy;
        if (distanceSquared > maxDistanceSquared || distanceSquared < 6) {
          continue;
        }
        neighbors.add((index: j, distanceSquared: distanceSquared));
      }

      neighbors.sort((a, b) => a.distanceSquared.compareTo(b.distanceSquared));
      for (final neighbor in neighbors.take(3)) {
        final startIndex = visibleEntries[i].key;
        final endIndex = visibleEntries[neighbor.index].key;
        final segmentKey = startIndex < endIndex
            ? '$startIndex-$endIndex'
            : '$endIndex-$startIndex';
        if (!drawnSegments.add(segmentKey)) {
          continue;
        }
        canvas.drawLine(
          origin,
          visibleEntries[neighbor.index].value,
          _meshPaint,
        );
      }
    }
  }

  List<Offset> _mapToView(Size viewSize) {
    final sourceWidth = imageSize.width;
    final sourceHeight = imageSize.height;

    if (sourceWidth <= 0 || sourceHeight <= 0) {
      return normalizedLandmarks
          .map((p) {
            final x =
                (mirrored ? 1 - p.dx : p.dx).clamp(0.0, 1.0) * viewSize.width;
            final y = p.dy.clamp(0.0, 1.0) * viewSize.height;
            return Offset(x, y);
          })
          .toList(growable: false);
    }

    final scale = _mathMax(
      viewSize.width / sourceWidth,
      viewSize.height / sourceHeight,
    );
    final scaledWidth = sourceWidth * scale;
    final scaledHeight = sourceHeight * scale;
    final dx = (viewSize.width - scaledWidth) / 2;
    final dy = (viewSize.height - scaledHeight) / 2;

    return normalizedLandmarks
        .map((p) {
          final normalizedX = mirrored ? 1 - p.dx : p.dx;
          final rawX = normalizedX.clamp(0.0, 1.0) * sourceWidth;
          final rawY = p.dy.clamp(0.0, 1.0) * sourceHeight;
          return Offset(dx + rawX * scale, dy + rawY * scale);
        })
        .toList(growable: false);
  }

  void _drawSegments(
    Canvas canvas,
    List<Offset> points,
    Paint paint,
    List<List<int>> segments,
  ) {
    for (final segment in segments) {
      if (segment.length < 2) continue;
      final firstIndex = segment.first;
      if (firstIndex >= points.length) continue;

      final path = Path()..moveTo(points[firstIndex].dx, points[firstIndex].dy);
      for (final index in segment.skip(1)) {
        if (index >= points.length) continue;
        path.lineTo(points[index].dx, points[index].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(FaceLandmarkPainter oldDelegate) {
    return oldDelegate.normalizedLandmarks != normalizedLandmarks ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.mirrored != mirrored ||
        oldDelegate.emphasized != emphasized;
  }
}

class FaceMeshContours {
  static const Set<int> hiddenPointIndices = {
    ...eyeRegion,
    ...noseSparseRegion,
  };

  static const Set<int> eyeRegion = {
    362,
    382,
    381,
    380,
    374,
    373,
    390,
    249,
    263,
    466,
    388,
    387,
    386,
    385,
    384,
    398,
    33,
    7,
    163,
    144,
    145,
    153,
    154,
    155,
    133,
    173,
    157,
    158,
    159,
    160,
    161,
    246,
  };

  static const Set<int> noseSparseRegion = {
    1,
    2,
    4,
    5,
    6,
    19,
    45,
    48,
    49,
    64,
    94,
    97,
    98,
    99,
    114,
    115,
    122,
    129,
    168,
    195,
    197,
    209,
    217,
    218,
    219,
    236,
    237,
    238,
    239,
    240,
    241,
    242,
    248,
    274,
    275,
    278,
    279,
    294,
    305,
    309,
    326,
    327,
    328,
    331,
    344,
    354,
    358,
    360,
    370,
    371,
    419,
    438,
    439,
    440,
    455,
    456,
    457,
    458,
    459,
    460,
  };

  static const List<List<int>> faceOutline = [
    [
      10,
      338,
      297,
      332,
      284,
      251,
      389,
      356,
      454,
      323,
      361,
      288,
      397,
      365,
      379,
      378,
      400,
      377,
      152,
      148,
      176,
      149,
      150,
      136,
      172,
      58,
      132,
      93,
      234,
      127,
      162,
      21,
      54,
      103,
      67,
      109,
    ],
  ];

  static const List<List<int>> leftEye = [
    [
      362,
      382,
      381,
      380,
      374,
      373,
      390,
      249,
      263,
      466,
      388,
      387,
      386,
      385,
      384,
      398,
      362,
    ],
  ];

  static const List<List<int>> rightEye = [
    [
      33,
      7,
      163,
      144,
      145,
      153,
      154,
      155,
      133,
      173,
      157,
      158,
      159,
      160,
      161,
      246,
      33,
    ],
  ];

  static const List<List<int>> leftEyebrow = [
    [276, 283, 282, 295, 285],
  ];

  static const List<List<int>> rightEyebrow = [
    [46, 53, 52, 65, 55],
  ];

  static const List<List<int>> lipsOuter = [
    [
      61,
      146,
      91,
      181,
      84,
      17,
      314,
      405,
      321,
      375,
      291,
      409,
      270,
      269,
      267,
      0,
      37,
      39,
      40,
      185,
      61,
    ],
  ];

  static const List<List<int>> lipsInner = [
    [
      78,
      95,
      88,
      178,
      87,
      14,
      317,
      402,
      318,
      324,
      308,
      415,
      310,
      311,
      312,
      13,
      82,
      81,
      80,
      191,
      78,
    ],
  ];

  static const List<List<int>> noseBridge = [
    [6, 197, 195, 5, 4],
  ];
}

double _mathMax(double a, double b) => a > b ? a : b;
