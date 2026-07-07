part of '../palm_scan_page.dart';

// ── 颜色（手掌用偏紫的藤萝色，兼容米色背景）
const _kAccent = Color(0xFF6B5B95); // 沉稳紫（主色）
const _kAccentLight = Color(0xFF9B8EF0); // 亮紫色（点缀）
const _kBgColor = Color(0xFFF4F1EB); // 宣纸米色

enum PalmScanState { idle, scanning, uploading, completed }

enum PalmScanFeedbackStage {
  waitingPermission,
  detecting,
  handDetected,
  readyToHold,
  completed,
}

@visibleForTesting
const Duration palmScanHoldDuration = Duration(milliseconds: 800);

@visibleForTesting
bool shouldRenderPalmOverlay({
  required List<Offset> handLandmarks,
  required Size? imageSize,
}) {
  return handLandmarks.length >= 21 &&
      imageSize != null &&
      imageSize.width > 0 &&
      imageSize.height > 0;
}

@visibleForTesting
bool shouldShowPalmHint({
  required bool handPresent,
  required List<Offset> handLandmarks,
  required Size? imageSize,
}) {
  return handPresent &&
      shouldRenderPalmOverlay(
        handLandmarks: handLandmarks,
        imageSize: imageSize,
      );
}

@visibleForTesting
bool isPalmHoldEligible({
  required bool handPresent,
  required bool readyToScan,
  required bool isFramed,
  required bool pauseAutoScanUntilReset,
}) {
  return handPresent && readyToScan && isFramed && !pauseAutoScanUntilReset;
}

@visibleForTesting
bool shouldTrackPalmHold({
  required bool holdInProgress,
  required bool handPresent,
  required bool readyToScan,
  required bool isFramed,
  required bool isRelaxedFramed,
  required bool pauseAutoScanUntilReset,
}) {
  if (pauseAutoScanUntilReset || !handPresent) {
    return false;
  }

  if (holdInProgress) {
    return readyToScan;
  }

  return isPalmHoldEligible(
    handPresent: handPresent,
    readyToScan: readyToScan,
    isFramed: isRelaxedFramed,
    pauseAutoScanUntilReset: pauseAutoScanUntilReset,
  );
}

@visibleForTesting
bool isPalmFramedForUploadBounds({
  required Rect bounds,
  required Rect guideRect,
  required bool allowHoldDrift,
}) {
  final area = normalizedRectArea(bounds);
  final minArea = allowHoldDrift ? 0.04 : 0.05;
  final maxArea = allowHoldDrift ? 0.40 : 0.32;
  final guideInsetFactor = allowHoldDrift ? 0.0 : 0.02;

  return area >= minArea &&
      area <= maxArea &&
      isNormalizedBoundsInsideGuide(
        bounds: bounds,
        guideRect: guideRect,
        guideInsetFactor: guideInsetFactor,
      );
}

@visibleForTesting
PalmScanFeedbackStage resolvePalmScanFeedbackStage({
  required bool hasPermission,
  required bool isMonitoring,
  required bool handPresent,
  required bool readyToScan,
  required PalmScanState scanState,
}) {
  if (!hasPermission) {
    return PalmScanFeedbackStage.waitingPermission;
  }
  if (scanState == PalmScanState.completed) {
    return PalmScanFeedbackStage.completed;
  }
  if (readyToScan) {
    return PalmScanFeedbackStage.readyToHold;
  }
  if (handPresent) {
    return PalmScanFeedbackStage.handDetected;
  }
  if (isMonitoring) {
    return PalmScanFeedbackStage.detecting;
  }
  return PalmScanFeedbackStage.waitingPermission;
}

@visibleForTesting
bool shouldShowPalmProgressFeedback({
  required PalmScanState scanState,
  required bool readyToScan,
}) {
  return scanState == PalmScanState.uploading ||
      scanState == PalmScanState.completed ||
      (scanState == PalmScanState.scanning && readyToScan);
}

@visibleForTesting
List<Offset> remapPalmLandmarksToCaptureGuide({
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
