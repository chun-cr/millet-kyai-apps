// 扫描模块展示层桥接：`PalmFrameRenderer`。负责把底层能力、状态机或上传流程整理成页面可直接消费的结果。

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../../../core/utils/logger.dart';
import '../widgets/hand_landmark_overlay.dart';

const _palmFrameInitialJpegQuality = 90;
const _palmFrameMinJpegQuality = 72;
const _palmFrameTargetMaxBytes = 450 * 1024;
const _palmFrameMinDimension = 720;

Future<String> renderPalmFrameFile({
  required String sourceImagePath,
  required List<Offset> normalizedLandmarks,
  required Size analysisImageSize,
  required bool mirrored,
  int? targetMaxBytes,
}) async {
  if (normalizedLandmarks.length < 21) {
    return sourceImagePath;
  }

  final sourceFile = File(sourceImagePath);

  ui.Codec? codec;
  ui.Image? sourceImage;
  ui.Image? renderedImage;

  try {
    final sourceBytes = await sourceFile.readAsBytes();
    codec = await ui.instantiateImageCodec(sourceBytes);
    final frame = await codec.getNextFrame();
    sourceImage = frame.image;
    final canvasSize = Size(
      sourceImage.width.toDouble(),
      sourceImage.height.toDouble(),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(sourceImage, Offset.zero, Paint());
    HandLandmarkPainter(
      normalizedLandmarks: normalizedLandmarks,
      imageSize: analysisImageSize.width > 0 && analysisImageSize.height > 0
          ? analysisImageSize
          : canvasSize,
      mirrored: mirrored,
    ).paint(canvas, canvasSize);

    renderedImage = await recorder.endRecording().toImage(
      canvasSize.width.round(),
      canvasSize.height.round(),
    );
    final outputFile = File(_buildPalmFrameOutputPath(sourceFile));
    final outputBytes = await _writePalmFrameJpeg(
      image: renderedImage,
      outputFile: outputFile,
      targetMaxBytes: targetMaxBytes ?? _palmFrameTargetMaxBytes,
    );
    AppLogger.log(
      'Rendered palm frame landmark overlay JPEG: '
      'path=${outputFile.path}, bytes=$outputBytes',
    );
    return outputFile.path;
  } finally {
    codec?.dispose();
    sourceImage?.dispose();
    renderedImage?.dispose();
  }
}

String _buildPalmFrameOutputPath(File sourceFile) {
  final fileName = sourceFile.uri.pathSegments.isNotEmpty
      ? sourceFile.uri.pathSegments.last
      : sourceFile.path.split(Platform.pathSeparator).last;
  final extensionIndex = fileName.lastIndexOf('.');
  final stem = extensionIndex > 0
      ? fileName.substring(0, extensionIndex)
      : fileName;
  return '${sourceFile.parent.path}${Platform.pathSeparator}${stem}_overlay.jpg';
}

Future<int> _writePalmFrameJpeg({
  required ui.Image image,
  required File outputFile,
  required int targetMaxBytes,
}) async {
  final byteData = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  if (byteData == null) {
    throw const FileSystemException(
      'Failed to encode palm frame landmark overlay image.',
    );
  }

  img.Image workingImage = img.Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: byteData.buffer,
    bytesOffset: byteData.offsetInBytes,
    rowStride: image.width * 4,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );

  for (;;) {
    for (
      var quality = _palmFrameInitialJpegQuality;
      quality >= _palmFrameMinJpegQuality;
      quality -= 4
    ) {
      final encoded = img.encodeJpg(workingImage, quality: quality);
      if (encoded.length <= targetMaxBytes ||
          (workingImage.width <= _palmFrameMinDimension &&
              workingImage.height <= _palmFrameMinDimension &&
              quality <= _palmFrameMinJpegQuality)) {
        await outputFile.writeAsBytes(encoded, flush: true);
        return outputFile.length();
      }
    }

    final nextWidth = (workingImage.width * 0.9).round();
    final nextHeight = (workingImage.height * 0.9).round();
    if (nextWidth >= workingImage.width ||
        nextHeight >= workingImage.height ||
        (nextWidth <= _palmFrameMinDimension &&
            nextHeight <= _palmFrameMinDimension)) {
      final fallback = img.encodeJpg(
        workingImage,
        quality: _palmFrameMinJpegQuality,
      );
      await outputFile.writeAsBytes(fallback, flush: true);
      return outputFile.length();
    }

    workingImage = img.copyResize(
      workingImage,
      width: nextWidth,
      height: nextHeight,
      interpolation: img.Interpolation.average,
    );
  }
}
