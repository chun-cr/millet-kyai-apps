// 扫描裁剪几何工具。负责把检测框、引导框和预览视口转换成上传时真正使用的裁剪区域。

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

Rect buildViewportGuideRect(
  Size viewportSize, {
  required Alignment alignment,
  required double guideWidth,
  required double guideHeight,
}) {
  if (viewportSize.width <= 0 ||
      viewportSize.height <= 0 ||
      guideWidth <= 0 ||
      guideHeight <= 0) {
    return Rect.zero;
  }

  final center = Offset(
    viewportSize.width * ((alignment.x + 1) / 2),
    viewportSize.height * ((alignment.y + 1) / 2),
  );

  return Rect.fromCenter(
    center: center,
    width: guideWidth,
    height: guideHeight,
  );
}

Rect buildNormalizedGuideRect(
  Size viewportSize, {
  required Alignment alignment,
  required double guideWidth,
  required double guideHeight,
}) {
  final rect = buildViewportGuideRect(
    viewportSize,
    alignment: alignment,
    guideWidth: guideWidth,
    guideHeight: guideHeight,
  );
  if (rect == Rect.zero) {
    return Rect.zero;
  }

  return Rect.fromLTWH(
    rect.left / viewportSize.width,
    rect.top / viewportSize.height,
    rect.width / viewportSize.width,
    rect.height / viewportSize.height,
  );
}

double _clamp01(double value) => value.clamp(0.0, 1.0).toDouble();

/// 把检测器返回的归一化矩形映射回当前可见预览区域。
/// 这里会同时考虑相机预览的 cover 裁切，避免页面上的框和真实截图区域对不齐。
Rect mapNormalizedRectToViewport({
  required Rect normalizedRect,
  required Size viewportSize,
  required Size imageSize,
  bool mirrored = false,
}) {
  final safeRect = clampNormalizedRect(normalizedRect);
  if (safeRect == Rect.zero ||
      viewportSize.width <= 0 ||
      viewportSize.height <= 0) {
    return Rect.zero;
  }

  if (imageSize.width <= 0 || imageSize.height <= 0) {
    final left =
        (mirrored ? 1 - safeRect.right : safeRect.left) * viewportSize.width;
    final right =
        (mirrored ? 1 - safeRect.left : safeRect.right) * viewportSize.width;
    return Rect.fromLTRB(
      left,
      safeRect.top * viewportSize.height,
      right,
      safeRect.bottom * viewportSize.height,
    );
  }

  final scale = math.max(
    viewportSize.width / imageSize.width,
    viewportSize.height / imageSize.height,
  );
  final scaledWidth = imageSize.width * scale;
  final scaledHeight = imageSize.height * scale;
  final dx = (viewportSize.width - scaledWidth) / 2;
  final dy = (viewportSize.height - scaledHeight) / 2;
  final leftNorm = mirrored ? 1 - safeRect.right : safeRect.left;
  final rightNorm = mirrored ? 1 - safeRect.left : safeRect.right;

  return Rect.fromLTRB(
    dx + leftNorm * imageSize.width * scale,
    dy + safeRect.top * imageSize.height * scale,
    dx + rightNorm * imageSize.width * scale,
    dy + safeRect.bottom * imageSize.height * scale,
  );
}

Rect clampNormalizedRect(Rect rect) {
  if (rect.isEmpty) {
    return Rect.zero;
  }

  final left = _clamp01(rect.left);
  final top = _clamp01(rect.top);
  final right = _clamp01(rect.right);
  final bottom = _clamp01(rect.bottom);

  if (right <= left || bottom <= top) {
    return Rect.zero;
  }

  return Rect.fromLTRB(left, top, right, bottom);
}

Rect buildTongueAnalysisRect({
  required Rect guideRect,
  Rect? faceBounds,
  Rect? mouthBounds,
  Offset? mouthCenter,
}) {
  final safeGuideRect = clampNormalizedRect(guideRect);
  if (safeGuideRect == Rect.zero) {
    return Rect.zero;
  }

  final fallbackRect = clampNormalizedRect(
    Rect.fromCenter(
      center: Offset(
        safeGuideRect.center.dx,
        _clamp01(safeGuideRect.center.dy + safeGuideRect.height * 0.10),
      ),
      width: math.min(safeGuideRect.width * 1.45, 1.0),
      height: math.min(safeGuideRect.height * 1.65, 1.0),
    ),
  );

  final safeMouthCenter = mouthCenter == null
      ? null
      : Offset(_clamp01(mouthCenter.dx), _clamp01(mouthCenter.dy));
  if (safeMouthCenter == null) {
    return fallbackRect;
  }

  final safeFaceBounds = faceBounds == null
      ? Rect.zero
      : clampNormalizedRect(faceBounds);
  final safeMouthBounds = mouthBounds == null
      ? Rect.zero
      : clampNormalizedRect(mouthBounds);

  if (safeFaceBounds != Rect.zero) {
    // 舌象上传不只要嘴部，还要尽量保留额头/下颌，给后续分析留足上下文。
    final widthCandidates = <double>[
      fallbackRect.width,
      safeFaceBounds.width * 1.56,
    ];
    if (safeMouthBounds != Rect.zero) {
      widthCandidates.add(safeMouthBounds.width * 4.0);
    }

    final width = widthCandidates
        .reduce(math.max)
        .clamp(fallbackRect.width, 1.0);
    final top = math.min(
      fallbackRect.top,
      safeFaceBounds.top - safeFaceBounds.height * 0.36,
    );
    var bottom = math.max(
      safeFaceBounds.bottom + safeFaceBounds.height * 0.28,
      safeMouthCenter.dy +
          math.max(safeGuideRect.height * 0.72, safeFaceBounds.height * 0.38),
    );

    if (safeMouthBounds != Rect.zero) {
      bottom = math.max(
        bottom,
        safeMouthBounds.bottom + safeMouthBounds.height * 3.2,
      );
    }

    return clampNormalizedRect(
      Rect.fromLTRB(
        safeFaceBounds.center.dx - width / 2,
        top,
        safeFaceBounds.center.dx + width / 2,
        bottom,
      ),
    );
  }

  var bottom = fallbackRect.bottom;
  if (safeMouthBounds != Rect.zero) {
    bottom = math.max(
      bottom,
      safeMouthBounds.bottom + safeMouthBounds.height * 3.2,
    );
  }

  return clampNormalizedRect(
    Rect.fromLTRB(
      fallbackRect.left,
      math.min(
        fallbackRect.top,
        safeMouthCenter.dy - fallbackRect.height * 0.50,
      ),
      fallbackRect.right,
      bottom,
    ),
  );
}

Rect buildFaceCaptureRect({required Rect guideRect, Rect? faceBounds}) {
  final safeGuideRect = clampNormalizedRect(guideRect);
  final safeFaceBounds = faceBounds == null
      ? Rect.zero
      : clampNormalizedRect(faceBounds);

  if (safeFaceBounds == Rect.zero) {
    return safeGuideRect;
  }

  final expandedFaceRect = Rect.fromLTRB(
    safeFaceBounds.left - safeFaceBounds.width * 0.24,
    safeFaceBounds.top - safeFaceBounds.height * 0.22,
    safeFaceBounds.right + safeFaceBounds.width * 0.24,
    safeFaceBounds.bottom + safeFaceBounds.height * 0.28,
  );
  final minWidth = safeGuideRect == Rect.zero
      ? 0.0
      : safeGuideRect.width * 1.10;
  final minHeight = safeGuideRect == Rect.zero
      ? 0.0
      : safeGuideRect.height * 1.14;
  final targetWidth = math.max(expandedFaceRect.width, minWidth);
  final targetHeight = math.max(expandedFaceRect.height, minHeight);
  // 人脸框会略向上提，避免额头被裁掉导致后续对齐不稳定。
  final centerY = _clamp01(
    expandedFaceRect.center.dy - math.min(safeFaceBounds.height * 0.04, 0.02),
  );

  return clampNormalizedRect(
    Rect.fromCenter(
      center: Offset(safeFaceBounds.center.dx, centerY),
      width: math.min(targetWidth, 1.0),
      height: math.min(targetHeight, 1.0),
    ),
  );
}

Rect buildPalmCaptureRect({required Rect guideRect, Rect? handBounds}) {
  final safeGuideRect = clampNormalizedRect(guideRect);
  final safeHandBounds = handBounds == null
      ? Rect.zero
      : clampNormalizedRect(handBounds);

  if (safeGuideRect == Rect.zero && safeHandBounds == Rect.zero) {
    return Rect.zero;
  }

  final fallbackBaseRect = safeGuideRect == Rect.zero
      ? safeHandBounds
      : safeGuideRect;
  final fallbackRect = clampNormalizedRect(
    Rect.fromCenter(
      center: fallbackBaseRect.center,
      width: math.min(fallbackBaseRect.width * 1.12, 1.0),
      height: math.min(fallbackBaseRect.height * 1.18, 1.0),
    ),
  );

  if (safeHandBounds == Rect.zero) {
    return fallbackRect;
  }

  final horizontalPadding = math.max(
    safeHandBounds.width * 0.16,
    fallbackBaseRect.width * 0.04,
  );
  final topPadding = math.max(
    safeHandBounds.height * 0.16,
    fallbackBaseRect.height * 0.04,
  );
  final bottomPadding = math.max(
    safeHandBounds.height * 0.24,
    fallbackBaseRect.height * 0.06,
  );
  final expandedHandRect = Rect.fromLTRB(
    // 手掌裁剪需要比可视引导框更宽，才能尽量保留指尖和手腕。
    safeHandBounds.left - horizontalPadding,
    safeHandBounds.top - topPadding,
    safeHandBounds.right + horizontalPadding,
    safeHandBounds.bottom + bottomPadding,
  );

  return clampNormalizedRect(expandedHandRect.expandToInclude(fallbackRect));
}

Rect? normalizedBoundingRect(Iterable<Offset> points) {
  double? minX;
  double? maxX;
  double? minY;
  double? maxY;

  for (final point in points) {
    final dx = point.dx.clamp(0.0, 1.0);
    final dy = point.dy.clamp(0.0, 1.0);
    minX = minX == null ? dx : math.min(minX, dx);
    maxX = maxX == null ? dx : math.max(maxX, dx);
    minY = minY == null ? dy : math.min(minY, dy);
    maxY = maxY == null ? dy : math.max(maxY, dy);
  }

  if (minX == null || maxX == null || minY == null || maxY == null) {
    return null;
  }

  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

bool isNormalizedBoundsInsideGuide({
  required Rect bounds,
  required Rect guideRect,
  double guideInsetFactor = 0,
}) {
  if (guideRect == Rect.zero || bounds.isEmpty) {
    return false;
  }

  final inset =
      math.min(guideRect.width, guideRect.height) *
      guideInsetFactor.clamp(0, 1);
  final safeGuide = Rect.fromLTRB(
    guideRect.left + inset,
    guideRect.top + inset,
    guideRect.right - inset,
    guideRect.bottom - inset,
  );

  return bounds.left >= safeGuide.left &&
      bounds.top >= safeGuide.top &&
      bounds.right <= safeGuide.right &&
      bounds.bottom <= safeGuide.bottom;
}

double normalizedRectArea(Rect rect) => rect.width * rect.height;

double mapHoldProgressToVisualProgress(double progress) {
  return progress.clamp(0.0, 1.0) * 0.62;
}

double mapUploadProgressToVisualProgress(double progress) {
  return 0.68 + progress.clamp(0.0, 1.0) * 0.30;
}
