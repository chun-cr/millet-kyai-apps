// 扫描模块展示层桥接：`FaceScanStatusBridge`。负责把底层能力、状态机或上传流程整理成页面可直接消费的结果。

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

abstract class VisionChannelBridge {
  Stream<bool> facePresenceStream();  //人脸是否存在的流

  Future<void> initialize();

  Future<void> startMonitoring();

  Future<void> stopMonitoring();

  Future<void> toggleCamera();
}

class FaceScanStatusBridge implements VisionChannelBridge {
  static const EventChannel _iosStatusChannel = EventChannel(
    'face/landmarkStream',
  );
  static const EventChannel _androidEventsChannel = EventChannel(
    'face/landmarkStream',
  );
  static const MethodChannel _androidMethodChannel = MethodChannel(
    'face/channel',
  );
  static const MethodChannel _iosMethodChannel = MethodChannel(
    'face/channel',
  );

  @override
  Stream<bool> facePresenceStream() {
    if (Platform.isIOS) {
      return _iosStatusChannel
          .receiveBroadcastStream()
          .map((event) => _extractHasFace(event))
          .distinct();
    }

    if (Platform.isAndroid) {
      return _androidEventsChannel
          .receiveBroadcastStream()
          .map((event) => _extractHasFace(event))
          .distinct();
    }

    return const Stream<bool>.empty();
  }

  Stream<Map<String, dynamic>> landmarkStream() {
    if (Platform.isIOS) {
      return _iosStatusChannel
          .receiveBroadcastStream()
          .map((event) => _extractPayload(event))
          .where((event) => event.isNotEmpty);
    }

    if (Platform.isAndroid) {
      return _androidEventsChannel
          .receiveBroadcastStream()
          .map((event) => _extractPayload(event))
          .where((event) => event.isNotEmpty);
    }

    return const Stream<Map<String, dynamic>>.empty();
  }

  @override
  Future<void> initialize() async {
    if (Platform.isAndroid) {
      return;
    }

    if (Platform.isIOS) {
      return;
    }
  }

  @override
  Future<void> startMonitoring() async {
    if (Platform.isAndroid) {
      await _androidMethodChannel.invokeMethod<void>('face/startDetection');
      return;
    }

    if (Platform.isIOS) {
      await _iosMethodChannel.invokeMethod<void>('face/startDetection');
    }
  }

  @override
  Future<void> stopMonitoring() async {
    if (Platform.isAndroid) {
      await _androidMethodChannel.invokeMethod<void>('face/stopDetection');
      return;
    }

    if (Platform.isIOS) {
      await _iosMethodChannel.invokeMethod<void>('face/stopDetection');
    }
  }

  @override
  Future<void> toggleCamera() async {
    if (Platform.isAndroid) {
      await _androidMethodChannel.invokeMethod<void>('face/toggleCamera');
      return;
    }

    if (Platform.isIOS) {
      await _iosMethodChannel.invokeMethod<void>('face/toggleCamera');
    }
  }

  bool _extractHasFace(dynamic event) {
    if (event is bool) {
      return event;
    }

    if (event is Map) {
      final data = Map<dynamic, dynamic>.from(event);
      final detected = data['detected'];
      if (detected is bool) {
        return detected;
      }

      final landmarks = data['landmarks'];
      if (landmarks is List) {
        return landmarks.isNotEmpty;
      }
    }

    return false;
  }

  Map<String, dynamic> _extractPayload(dynamic event) {
    if (event is Map) {
      return Map<String, dynamic>.from(event);
    }

    return {};
  }
}
