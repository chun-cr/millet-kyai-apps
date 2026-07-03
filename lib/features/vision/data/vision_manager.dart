// 视觉能力管理器。统一协调原生视觉 SDK 的初始化、调用和原始识别结果回传。

import 'package:flutter/services.dart';

import '../domain/models/vision_models.dart';

class VisionManager {
  VisionManager();

  static const EventChannel _faceChannel = EventChannel('face/landmarkStream');
  static const EventChannel _gestureChannel = EventChannel('gesture/resultStream');
  static const EventChannel _tongueChannel = EventChannel('tongue/detectionStream');

  static const MethodChannel _methodChannel = MethodChannel('face/channel');
  static const MethodChannel _tongueCaptureChannel = MethodChannel('tongue/capture');

  Stream<FaceLandmarkData> get faceLandmarkStream => _faceChannel
      .receiveBroadcastStream()
      .map(_parseFaceEvent)
      .where((event) => event != null)
      .cast<FaceLandmarkData>();

  Stream<GestureResult> get gestureStream => _gestureChannel
      .receiveBroadcastStream()
      .map(_parseGestureEvent)
      .where((event) => event != null)
      .cast<GestureResult>();

  Stream<TongueDetectionResult> get tongueStream => _tongueChannel
      .receiveBroadcastStream()
      .map(_parseTongueEvent)
      .where((event) => event != null)
      .cast<TongueDetectionResult>();

  Future<void> startDetection(VisionMode mode) async {
    switch (mode) {
      case VisionMode.faceOnly:
        await _methodChannel.invokeMethod<void>('face/startDetection');
        break;
      case VisionMode.gestureOnly:
        await _methodChannel.invokeMethod<void>('gesture/startDetection');
        break;
      case VisionMode.tongueScan:
        await _methodChannel.invokeMethod<void>('tongue/startDetection');
        break;
      case VisionMode.all:
        await _methodChannel.invokeMethod<void>('face/startDetection');
        await _methodChannel.invokeMethod<void>('gesture/startDetection');
        await _methodChannel.invokeMethod<void>('tongue/startDetection');
        break;
    }
  }

  Future<void> stopDetection(VisionMode mode) async {
    switch (mode) {
      case VisionMode.faceOnly:
        await _methodChannel.invokeMethod<void>('face/stopDetection');
        break;
      case VisionMode.gestureOnly:
        await _methodChannel.invokeMethod<void>('gesture/stopDetection');
        break;
      case VisionMode.tongueScan:
        await _methodChannel.invokeMethod<void>('tongue/stopDetection');
        break;
      case VisionMode.all:
        await _methodChannel.invokeMethod<void>('face/stopDetection');
        await _methodChannel.invokeMethod<void>('gesture/stopDetection');
        await _methodChannel.invokeMethod<void>('tongue/stopDetection');
        break;
    }
  }

  Future<String?> captureTongue() async {
    try {
      final result = await _tongueCaptureChannel.invokeMethod<String>('tongue/capture');
      return result;
    } on PlatformException {
      return null;
    }
  }

  FaceLandmarkData? _parseFaceEvent(dynamic event) {
    if (event is Map) {
      return FaceLandmarkData.fromEvent(Map<String, dynamic>.from(event));
    }
    return null;
  }

  GestureResult? _parseGestureEvent(dynamic event) {
    if (event is Map) {
      return GestureResult.fromEvent(Map<String, dynamic>.from(event));
    }
    return null;
  }

  TongueDetectionResult? _parseTongueEvent(dynamic event) {
    if (event is Map) {
      return TongueDetectionResult.fromEvent(Map<String, dynamic>.from(event));
    }
    return null;
  }
}
