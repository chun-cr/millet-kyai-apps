import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../utils/scan_capture_geometry.dart';

enum TongueDetectionTuning { standard, android }

/// Flutter 侧的“舌头是否足够伸出”代理判定规则。
///
/// 需要注意：当前原生事件只有脸部和嘴部关键点，没有真正的舌头轮廓点。
/// 因此这里并不是直接识别舌头，而是基于嘴部几何关系做一层近似推断。
class TongueProtrusionProxy {
  static const double _minMouthAspectRatio = 0.16;
  static const double _maxMouthAspectRatio = 0.78;
  static const double _centerBandFactor = 0.18;
  static const double _sideBandFactor = 0.24;

  static bool isFrameEligible({
    required List<Offset> mouthLandmarks,
    required Offset? mouthCenter,
    List<Offset> faceLandmarks = const [],
    Map<String, double> blendshapes = const <String, double>{},
    TongueDetectionTuning tuning = TongueDetectionTuning.standard,
  }) {
    if (mouthLandmarks.length < 5 || mouthCenter == null) {
      return false;
    }

    final mouthBounds = normalizedBoundingRect(mouthLandmarks);
    if (mouthBounds == null || mouthBounds.isEmpty) {
      return false;
    }

    final mouthWidth = mouthBounds.width;
    final mouthHeight = mouthBounds.height;
    if (mouthWidth <= 0 || mouthHeight <= 0) {
      return false;
    }

    final mouthAspectRatio = mouthHeight / mouthWidth;
    if (mouthAspectRatio < _minMouthAspectRatio ||
        mouthAspectRatio > _maxMouthAspectRatio) {
      return false;
    }

    final center = mouthCenter;
    final centralPoints = mouthLandmarks
        .where((point) {
          return (point.dx - center.dx).abs() <= mouthWidth * _centerBandFactor;
        })
        .toList(growable: false);
    final sidePoints = mouthLandmarks
        .where((point) {
          return (point.dx - center.dx).abs() >= mouthWidth * _sideBandFactor;
        })
        .toList(growable: false);

    if (centralPoints.isEmpty || sidePoints.length < 2) {
      return false;
    }

    final lowerSidePoints = sidePoints
        .where((point) => point.dy >= center.dy)
        .toList(growable: false);
    final sideReferencePoints = lowerSidePoints.isNotEmpty
        ? lowerSidePoints
        : sidePoints;

    final centralLowerY = centralPoints
        .map((point) => point.dy)
        .reduce((current, next) => current > next ? current : next);
    final sideLowerEdgeY = sideReferencePoints
        .map((point) => point.dy)
        .reduce((current, next) => current > next ? current : next);

    final faceBounds = normalizedBoundingRect(faceLandmarks);
    final scaleWidth =
        (faceBounds != null && !faceBounds.isEmpty
                ? faceBounds.width
                : mouthWidth)
            .clamp(mouthWidth, 1.0);
    final centralDropRatio = (centralLowerY - sideLowerEdgeY) / scaleWidth;
    final centralDropToHeightRatio =
        (centralLowerY - sideLowerEdgeY) / mouthHeight;

    final thresholds = _TongueDetectionThresholds.forTuning(tuning);

    if (TongueBlendshapeSupport.hasDirectTongueSupport(
      blendshapes,
      tuning: tuning,
    )) {
      return true;
    }

    if (!TongueBlendshapeSupport.hasStrongSupport(
      blendshapes,
      tuning: tuning,
    )) {
      return false;
    }

    return centralDropRatio >= thresholds.minSupportedCentralDropRatio &&
        centralDropToHeightRatio >=
            thresholds.minSupportedCentralDropToHeightRatio;
  }
}

class TongueBlendshapeSupport {
  static bool hasDirectTongueSupport(
    Map<String, double> blendshapes, {
    TongueDetectionTuning tuning = TongueDetectionTuning.standard,
  }) {
    if (blendshapes.isEmpty) {
      return false;
    }

    final thresholds = _TongueDetectionThresholds.forTuning(tuning);
    final tongueOut = blendshapes['tongueOut'] ?? 0;
    final jawOpen = blendshapes['jawOpen'] ?? 0;
    return tongueOut >= thresholds.tongueOutThreshold &&
        jawOpen >= thresholds.directJawOpenThreshold;
  }

  static bool hasStrongSupport(
    Map<String, double> blendshapes, {
    TongueDetectionTuning tuning = TongueDetectionTuning.standard,
  }) {
    if (blendshapes.isEmpty) {
      return false;
    }

    final thresholds = _TongueDetectionThresholds.forTuning(tuning);
    final jawOpen = blendshapes['jawOpen'] ?? 0;
    final mouthFunnel = blendshapes['mouthFunnel'] ?? 0;
    final lowerLipDrop = _average(
      blendshapes['mouthLowerDownLeft'] ?? 0,
      blendshapes['mouthLowerDownRight'] ?? 0,
    );

    return jawOpen >= thresholds.jawOpenThreshold &&
        (mouthFunnel >= thresholds.mouthFunnelThreshold ||
            lowerLipDrop >= thresholds.lowerLipDropThreshold);
  }

  static double _average(double left, double right) => (left + right) / 2;
}

class _TongueDetectionThresholds {
  const _TongueDetectionThresholds({
    required this.minSupportedCentralDropRatio,
    required this.minSupportedCentralDropToHeightRatio,
    required this.tongueOutThreshold,
    required this.directJawOpenThreshold,
    required this.jawOpenThreshold,
    required this.mouthFunnelThreshold,
    required this.lowerLipDropThreshold,
  });

  final double minSupportedCentralDropRatio;
  final double minSupportedCentralDropToHeightRatio;
  final double tongueOutThreshold;
  final double directJawOpenThreshold;
  final double jawOpenThreshold;
  final double mouthFunnelThreshold;
  final double lowerLipDropThreshold;

  static const _TongueDetectionThresholds standard = _TongueDetectionThresholds(
    minSupportedCentralDropRatio: 0.03,
    minSupportedCentralDropToHeightRatio: 0.22,
    tongueOutThreshold: 0.20,
    directJawOpenThreshold: 0.10,
    jawOpenThreshold: 0.14,
    mouthFunnelThreshold: 0.08,
    lowerLipDropThreshold: 0.07,
  );

  static const _TongueDetectionThresholds android = _TongueDetectionThresholds(
    minSupportedCentralDropRatio: 0.026,
    minSupportedCentralDropToHeightRatio: 0.20,
    tongueOutThreshold: 0.20,
    directJawOpenThreshold: 0.08,
    jawOpenThreshold: 0.12,
    mouthFunnelThreshold: 0.07,
    lowerLipDropThreshold: 0.06,
  );

  static _TongueDetectionThresholds forTuning(TongueDetectionTuning tuning) {
    switch (tuning) {
      case TongueDetectionTuning.android:
        return android;
      case TongueDetectionTuning.standard:
        return standard;
    }
  }
}

class TongueConfirmationWindow {
  TongueConfirmationWindow({
    this.windowSize = 8,
    this.requiredEligibleFrames = 6,
  }) : assert(windowSize > 0),
       assert(requiredEligibleFrames > 0),
       assert(requiredEligibleFrames <= windowSize);

  final int windowSize;
  final int requiredEligibleFrames;
  final ListQueue<bool> _recentFrames = ListQueue<bool>();

  bool registerFrame({required bool eligible, bool hardReset = false}) {
    if (hardReset) {
      reset();
      return false;
    }

    _recentFrames.addLast(eligible);
    while (_recentFrames.length > windowSize) {
      _recentFrames.removeFirst();
    }

    if (_recentFrames.length < windowSize) {
      return false;
    }

    final eligibleCount = _recentFrames.where((frame) => frame).length;
    return eligibleCount >= requiredEligibleFrames;
  }

  void reset() {
    _recentFrames.clear();
  }
}
