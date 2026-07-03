// 视觉识别领域模型。定义面部、手掌、舌象等检测结果在 Flutter 侧的稳定数据结构。

import 'package:flutter/material.dart';

enum VisionMode {
  faceOnly,
  gestureOnly,
  tongueScan,
  all,
}

class FaceLandmarkData {
  final bool detected;
  final List<Offset> landmarks;
  final Map<String, double> blendshapes;
  final Size? imageSize;

  const FaceLandmarkData({
    required this.detected,
    required this.landmarks,
    required this.blendshapes,
    required this.imageSize,
  });

  factory FaceLandmarkData.empty() => const FaceLandmarkData(
        detected: false,
        landmarks: [],
        blendshapes: {},
        imageSize: null,
      );

  factory FaceLandmarkData.fromEvent(Map<String, dynamic> event) {
    final detected = event['detected'] == true;
    final rawLandmarks = event['landmarks'];
    final landmarks = <Offset>[];
    if (rawLandmarks is List) {
      for (final entry in rawLandmarks) {
        if (entry is Map) {
          final x = entry['x'];
          final y = entry['y'];
          if (x is num && y is num) {
            landmarks.add(Offset(x.toDouble(), y.toDouble()));
          }
        }
      }
    }

    final blendshapes = <String, double>{};
    final rawBlendshapes = event['blendshapes'];
    if (rawBlendshapes is Map) {
      rawBlendshapes.forEach((key, value) {
        if (value is num && key is String) {
          blendshapes[key] = value.toDouble();
        }
      });
    }

    Size? imageSize;
    final imageWidth = event['imageWidth'];
    final imageHeight = event['imageHeight'];
    if (imageWidth is num && imageHeight is num && imageWidth > 0 && imageHeight > 0) {
      imageSize = Size(imageWidth.toDouble(), imageHeight.toDouble());
    }

    return FaceLandmarkData(
      detected: detected,
      landmarks: landmarks,
      blendshapes: blendshapes,
      imageSize: imageSize,
    );
  }
}

class GestureResult {
  final bool gestureDetected;
  final String gestureName;
  final double score;
  final List<Offset> handLandmarks;

  const GestureResult({
    required this.gestureDetected,
    required this.gestureName,
    required this.score,
    required this.handLandmarks,
  });

  factory GestureResult.empty() => const GestureResult(
        gestureDetected: false,
        gestureName: '',
        score: 0,
        handLandmarks: [],
      );

  factory GestureResult.fromEvent(Map<String, dynamic> event) {
    final gestureDetected = event['gestureDetected'] == true || event['detected'] == true;
    final gestureName = (event['gestureName'] as String?) ?? (event['name'] as String?) ?? '';
    final scoreValue = event['score'];
    final score = scoreValue is num ? scoreValue.toDouble() : 0.0;

    final rawLandmarks = event['handLandmarks'] ?? event['landmarks'];
    final landmarks = <Offset>[];
    if (rawLandmarks is List) {
      for (final entry in rawLandmarks) {
        if (entry is Map) {
          final x = entry['x'];
          final y = entry['y'];
          if (x is num && y is num) {
            landmarks.add(Offset(x.toDouble(), y.toDouble()));
          }
        }
      }
    }

    return GestureResult(
      gestureDetected: gestureDetected,
      gestureName: gestureName,
      score: score,
      handLandmarks: landmarks,
    );
  }
}

class TongueDetectionResult {
  final bool tongueDetected;
  final double tongueOutScore;
  final List<Offset> mouthLandmarks;

  const TongueDetectionResult({
    required this.tongueDetected,
    required this.tongueOutScore,
    required this.mouthLandmarks,
  });

  factory TongueDetectionResult.empty() => const TongueDetectionResult(
        tongueDetected: false,
        tongueOutScore: 0,
        mouthLandmarks: [],
      );

  factory TongueDetectionResult.fromEvent(Map<String, dynamic> event) {
    final tongueDetected = event['tongueDetected'] == true;
    final scoreValue = event['tongueOutScore'];
    final tongueOutScore = scoreValue is num ? scoreValue.toDouble() : 0.0;

    final rawLandmarks = event['mouthLandmarks'];
    final landmarks = <Offset>[];
    if (rawLandmarks is List) {
      for (final entry in rawLandmarks) {
        if (entry is Map) {
          final x = entry['x'];
          final y = entry['y'];
          if (x is num && y is num) {
            landmarks.add(Offset(x.toDouble(), y.toDouble()));
          }
        }
      }
    }

    return TongueDetectionResult(
      tongueDetected: tongueDetected,
      tongueOutScore: tongueOutScore,
      mouthLandmarks: landmarks,
    );
  }
}

class VisionState {
  final VisionMode mode;
  final bool isDetecting;

  const VisionState({
    required this.mode,
    required this.isDetecting,
  });

  VisionState copyWith({VisionMode? mode, bool? isDetecting}) {
    return VisionState(
      mode: mode ?? this.mode,
      isDetecting: isDetecting ?? this.isDetecting,
    );
  }
}






