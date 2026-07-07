part of '../face_scan_page.dart';

// ── 颜色系（与 scan_guide_page 绿色体系一致）
const _kGreen = Color(0xFF2D6A4F);
const _kGreenLight = Color(0xFF3DAB78);
const _kFaceStrictMinArea = 0.026;
const _kFaceStrictMaxArea = 0.70;
const _kFaceStrictGuideOverflowFactor = 0.08;
const _kFaceIosStrictMinArea = 0.024;
const _kFaceIosStrictMaxArea = 0.74;
const _kFaceIosStrictGuideOverflowFactor = 0.10;
const _kFaceRelaxedMinArea = 0.022;
const _kFaceRelaxedMaxArea = 0.76;
const _kFaceRelaxedGuideOverflowFactor = 0.12;
const _kFaceIosRelaxedMinArea = 0.020;
const _kFaceIosRelaxedMaxArea = 0.80;
const _kFaceIosRelaxedGuideOverflowFactor = 0.14;

enum FaceSubmitStage { idle, capturing, processing, uploading, analyzing }

@visibleForTesting
const Duration faceScanHoldDuration = Duration(milliseconds: 800);

@visibleForTesting
const Duration transientFaceTrackingGraceDuration = Duration(milliseconds: 250);

@visibleForTesting
const Duration faceScanPostSuccessDelay = Duration(milliseconds: 450);

@visibleForTesting
Duration faceScanHoldDurationForPlatform(TargetPlatform platform) {
  return faceScanHoldDuration;
}

@visibleForTesting
bool isFaceHoldEligible({
  required bool hasPermission,
  required bool hasFaceDetected,
  required bool isFramed,
}) {
  return hasPermission && hasFaceDetected && isFramed;
}

@visibleForTesting
bool shouldKeepFaceHoldAlive({
  required bool hasPermission,
  required bool hasFaceDetected,
  required bool isFramed,
  required bool isRelaxedFramed,
  required bool holdInProgress,
}) {
  if (!hasPermission || !hasFaceDetected) {
    return false;
  }

  return holdInProgress ? isRelaxedFramed : isFramed;
}

@visibleForTesting
bool shouldAutoStartFaceScan({
  required TargetPlatform platform,
  required bool hasPermission,
  required bool hasFaceDetected,
  required bool isFramed,
  required bool hasAcceptedSnapshot,
  required bool isScanning,
  required bool isTransitioning,
}) {
  if (isScanning ||
      isTransitioning ||
      !hasPermission ||
      !hasFaceDetected ||
      !hasAcceptedSnapshot) {
    return false;
  }

  return isFramed;
}

@visibleForTesting
bool shouldBeginFaceScan({
  required TargetPlatform platform,
  required bool hasPermission,
  required bool hasFaceDetected,
  required bool isFramed,
  required bool isBusy,
  required bool isTransitioning,
  required bool isPaused,
}) {
  if (isBusy ||
      isTransitioning ||
      isPaused ||
      !hasPermission ||
      !hasFaceDetected) {
    return false;
  }

  return isFramed;
}

@visibleForTesting
bool shouldRetainPreviousFaceTracking({
  required bool holdInProgress,
  required bool hasFaceDetected,
  required bool hasLandmarks,
  required Duration timeSinceLastTrackedFace,
}) {
  if (!holdInProgress || hasFaceDetected || hasLandmarks) {
    return false;
  }

  return timeSinceLastTrackedFace <= transientFaceTrackingGraceDuration;
}

@visibleForTesting
bool shouldShowFaceReadyStatus({
  required bool hasPermission,
  required bool hasFaceDetected,
  required String faceDirection,
}) {
  return hasPermission && hasFaceDetected && faceDirection.isEmpty;
}

@visibleForTesting
bool isFaceFramedForUploadBounds({
  required Rect bounds,
  required Rect guideRect,
  required double area,
  required bool allowHoldDrift,
  TargetPlatform? platform,
}) {
  final isIos = platform == TargetPlatform.iOS;
  final minArea = allowHoldDrift
      ? (isIos ? _kFaceIosRelaxedMinArea : _kFaceRelaxedMinArea)
      : (isIos ? _kFaceIosStrictMinArea : _kFaceStrictMinArea);
  final maxArea = allowHoldDrift
      ? (isIos ? _kFaceIosRelaxedMaxArea : _kFaceRelaxedMaxArea)
      : (isIos ? _kFaceIosStrictMaxArea : _kFaceStrictMaxArea);
  final guideOverflowFactor = allowHoldDrift
      ? (isIos
            ? _kFaceIosRelaxedGuideOverflowFactor
            : _kFaceRelaxedGuideOverflowFactor)
      : (isIos
            ? _kFaceIosStrictGuideOverflowFactor
            : _kFaceStrictGuideOverflowFactor);
  final tolerantGuideRect = expandFaceGuideRect(
    guideRect,
    overflowFactor: guideOverflowFactor,
  );

  return area >= minArea &&
      area <= maxArea &&
      isNormalizedBoundsInsideGuide(
        bounds: bounds,
        guideRect: tolerantGuideRect,
      );
}

@visibleForTesting
Rect expandFaceGuideRect(Rect guideRect, {required double overflowFactor}) {
  if (guideRect == Rect.zero || guideRect.isEmpty) {
    return Rect.zero;
  }

  final shortestSide = guideRect.width < guideRect.height
      ? guideRect.width
      : guideRect.height;
  final padding = shortestSide * overflowFactor.clamp(0.0, 1.0).toDouble();
  return Rect.fromLTRB(
    guideRect.left - padding,
    guideRect.top - padding,
    guideRect.right + padding,
    guideRect.bottom + padding,
  );
}

@visibleForTesting
bool shouldMirrorFaceUploadMask({
  required TargetPlatform platform,
  required bool isBackCamera,
}) {
  return shouldMirrorFaceFrameMask(
    platform: platform,
    isBackCamera: isBackCamera,
  );
}

@immutable
class AcceptedFaceSnapshot {
  AcceptedFaceSnapshot({
    required this.guideRect,
    required List<Offset> normalizedLandmarks,
    required this.analysisImageSize,
    required this.isBackCamera,
    required this.mirrored,
    this.generationId,
    this.timestampMs,
  }) : normalizedLandmarks = List<Offset>.unmodifiable(normalizedLandmarks);

  final Rect guideRect;
  final List<Offset> normalizedLandmarks;
  final Size analysisImageSize;
  final bool isBackCamera;
  final bool mirrored;
  final int? generationId;
  final int? timestampMs;

  ScanCaptureGuide toCaptureGuide() {
    final rect = buildFaceCaptureRect(
      guideRect: guideRect,
      faceBounds: normalizedBoundingRect(normalizedLandmarks),
    );
    return ScanCaptureGuide(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
    );
  }
}

@visibleForTesting
AcceptedFaceSnapshot? buildAcceptedFaceSnapshot({
  required Rect guideRect,
  required List<Offset> normalizedLandmarks,
  required Size analysisImageSize,
  required bool isBackCamera,
  required TargetPlatform platform,
  int? generationId,
  int? timestampMs,
  bool? mirrored,
}) {
  if (guideRect.isEmpty || normalizedLandmarks.isEmpty) {
    return null;
  }

  return AcceptedFaceSnapshot(
    guideRect: guideRect,
    normalizedLandmarks: normalizedLandmarks,
    analysisImageSize: analysisImageSize,
    isBackCamera: isBackCamera,
    mirrored:
        mirrored ??
        shouldMirrorFaceUploadMask(
          platform: platform,
          isBackCamera: isBackCamera,
        ),
    generationId: generationId,
    timestampMs: timestampMs,
  );
}

@visibleForTesting
AcceptedFaceSnapshot? latchAcceptedFaceSnapshot({
  required AcceptedFaceSnapshot? currentLatchedSnapshot,
  required AcceptedFaceSnapshot? nextSnapshot,
}) {
  return currentLatchedSnapshot ?? nextSnapshot;
}

@visibleForTesting
List<Offset> remapLandmarksToCaptureGuide({
  required Iterable<Offset> normalizedLandmarks,
  required Rect guideRect,
}) {
  if (guideRect.isEmpty || guideRect.width <= 0 || guideRect.height <= 0) {
    return const <Offset>[];
  }

  return normalizedLandmarks
      .map((point) {
        final dx = (point.dx - guideRect.left) / guideRect.width;
        final dy = (point.dy - guideRect.top) / guideRect.height;
        return Offset(dx, dy);
      })
      .toList(growable: false);
}

@visibleForTesting
bool hasRenderableFaceFrameUpload({
  required List<Offset> normalizedLandmarks,
  required String sourceImagePath,
  required String faceFrameFilePath,
}) {
  if (normalizedLandmarks.isEmpty ||
      sourceImagePath.isEmpty ||
      faceFrameFilePath.isEmpty) {
    return false;
  }

  return sourceImagePath != faceFrameFilePath;
}
