// 扫描模块展示层桥接：`ScanCaptureBridge`。负责把底层能力、状态机或上传流程整理成页面可直接消费的结果。

import 'dart:io';

import 'package:flutter/services.dart';

enum ScanCaptureTarget { face, tongue, palm }

class ScanCaptureGuide {
  const ScanCaptureGuide({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  Map<String, dynamic> toJson() => {
    'left': left,
    'top': top,
    'width': width,
    'height': height,
  };
}

class ScanCaptureResult {
  const ScanCaptureResult({
    required this.stage,
    required this.sourcePath,
    required this.croppedPath,
    required this.framePath,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.cropLeft,
    required this.cropTop,
    required this.cropWidth,
    required this.cropHeight,
  });

  factory ScanCaptureResult.fromMap(Map<Object?, Object?> payload) {
    String readString(String key) {
      final value = payload[key];
      if (value is! String || value.isEmpty) {
        throw FormatException('Missing capture field: $key');
      }
      return value;
    }

    double readDouble(String key) {
      final value = payload[key];
      if (value is num) {
        return value.toDouble();
      }
      throw FormatException('Invalid capture numeric field: $key');
    }

    return ScanCaptureResult(
      stage: readString('stage'),
      sourcePath: readString('sourcePath'),
      croppedPath: readString('croppedPath'),
      framePath: readString('framePath'),
      sourceWidth: readDouble('sourceWidth'),
      sourceHeight: readDouble('sourceHeight'),
      cropLeft: readDouble('cropLeft'),
      cropTop: readDouble('cropTop'),
      cropWidth: readDouble('cropWidth'),
      cropHeight: readDouble('cropHeight'),
    );
  }

  final String stage;
  final String sourcePath;
  final String croppedPath;
  final String framePath;
  final double sourceWidth;
  final double sourceHeight;
  final double cropLeft;
  final double cropTop;
  final double cropWidth;
  final double cropHeight;
}

class ScanCaptureException implements Exception {
  const ScanCaptureException({
    required this.stage,
    required this.code,
    required this.message,
    this.details,
  });

  factory ScanCaptureException.fromPlatformException({
    required ScanCaptureTarget target,
    required PlatformException exception,
  }) {
    return ScanCaptureException(
      stage: target.name,
      code: exception.code,
      message: exception.message ?? 'Unknown platform capture error',
      details: exception.details,
    );
  }

  final String stage;
  final String code;
  final String message;
  final Object? details;

  String get debugDescription {
    final buffer = StringBuffer()
      ..writeln('stage: $stage')
      ..writeln('platformCode: $code')
      ..writeln('message: $message');
    if (details != null) {
      buffer.writeln('details: $details');
    }
    return buffer.toString().trimRight();
  }

  @override
  String toString() => debugDescription;
}

class ScanCaptureBridge {
  static const MethodChannel _channel = MethodChannel('face/channel');

  Future<ScanCaptureResult> capture({
    required ScanCaptureTarget target,
    required ScanCaptureGuide guide,
    int? generationId,
    List<Offset>? landmarks,
    Size? analysisImageSize,
    bool? isBackCamera,
    bool? mirrored,
    int? timestampMs,
    bool preferVisibleRegion = false,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw ScanCaptureException(
        stage: target.name,
        code: 'UNSUPPORTED_PLATFORM',
        message: 'Scan capture is only supported on Android and iOS.',
      );
    }

    try {
      final payload = await _channel.invokeMapMethod<Object?, Object?>(
        'scan/capture',
        {
          'stage': target.name,
          'guideRect': guide.toJson(),
          ...?((generationId == null) ? null : {'generationId': generationId}),
          ...?((landmarks == null)
              ? null
              : {
                  'landmarks': landmarks
                      .map((point) => {'x': point.dx, 'y': point.dy, 'z': 0.0})
                      .toList(growable: false),
                }),
          ...?((analysisImageSize == null)
              ? null
              : {
                  'analysisImageWidth': analysisImageSize.width.round(),
                  'analysisImageHeight': analysisImageSize.height.round(),
                }),
          ...?((isBackCamera == null) ? null : {'isBackCamera': isBackCamera}),
          ...?((mirrored == null) ? null : {'mirrored': mirrored}),
          ...?((timestampMs == null) ? null : {'timestampMs': timestampMs}),
          if (preferVisibleRegion) 'preferVisibleRegion': true,
        },
      );

      if (payload == null) {
        throw const FormatException('Capture payload is empty.');
      }

      return ScanCaptureResult.fromMap(payload);
    } on PlatformException catch (error) {
      throw ScanCaptureException.fromPlatformException(
        target: target,
        exception: error,
      );
    }
  }
}
