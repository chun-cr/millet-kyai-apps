// 面部描点图渲染器。负责把面部关键点绘制到快照上，并生成上传或调试使用的覆盖图。

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../../../core/utils/logger.dart';
import '../widgets/face_landmark_overlay.dart';

const _photoOverlayInitialJpegQuality = 90;
const _photoOverlayMinJpegQuality = 72;
const _photoOverlayTargetMaxBytes = 450 * 1024;
const _photoOverlayMinDimension = 720;

bool shouldMirrorFaceFrameMask({
  required TargetPlatform platform,
  required bool isBackCamera,
}) {
  return platform == TargetPlatform.android && !isBackCamera;
}

Future<String> renderFaceFrameMaskFile({
  required String sourceImagePath,
  required List<Offset> normalizedLandmarks,
  required Size analysisImageSize,
  required bool mirrored,
  Size? outputImageSize,
  bool includeSourceImage = true,
  int? targetMaxBytes,
}) async {
  if (normalizedLandmarks.isEmpty) {
    return sourceImagePath;
  }

  final sourceFile = File(sourceImagePath);

  ui.Codec? codec;
  ui.Image? sourceImage;
  ui.Image? renderedImage;

  try {
    late final Size canvasSize;
    if (includeSourceImage) {
      final sourceBytes = await sourceFile.readAsBytes();
      codec = await ui.instantiateImageCodec(sourceBytes);
      final frame = await codec.getNextFrame();
      sourceImage = frame.image;
      canvasSize = Size(
        sourceImage.width.toDouble(),
        sourceImage.height.toDouble(),
      );
    } else {
      final resolvedSize = outputImageSize ?? analysisImageSize;
      if (resolvedSize.width <= 0 || resolvedSize.height <= 0) {
        throw const FileSystemException(
          'Failed to resolve face frame landmark mask size.',
        );
      }
      canvasSize = resolvedSize;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    if (sourceImage != null) {
      canvas.drawImage(sourceImage, Offset.zero, Paint());
    }
    FaceLandmarkPainter(
      normalizedLandmarks: normalizedLandmarks,
      imageSize: analysisImageSize.width > 0 && analysisImageSize.height > 0
          ? analysisImageSize
          : canvasSize,
      mirrored: mirrored,
      emphasized: includeSourceImage,
    ).paint(canvas, canvasSize);

    renderedImage = await recorder.endRecording().toImage(
      canvasSize.width.round(),
      canvasSize.height.round(),
    );
    final outputFile = File(
      includeSourceImage
          ? _buildPhotoOverlayOutputPath(sourceFile)
          : _buildMaskOutputPath(sourceFile),
    );
    final outputBytes = includeSourceImage
        ? await _writePhotoOverlayJpeg(
            image: renderedImage,
            outputFile: outputFile,
            targetMaxBytes: targetMaxBytes ?? _photoOverlayTargetMaxBytes,
          )
        : await _writeMaskPng(image: renderedImage, outputFile: outputFile);
    AppLogger.log(
      includeSourceImage
          ? 'Rendered face frame overlay JPEG: path=${outputFile.path}, bytes=$outputBytes'
          : 'Rendered face frame mask PNG: path=${outputFile.path}, bytes=$outputBytes',
    );
    return outputFile.path;
  } finally {
    codec?.dispose();
    sourceImage?.dispose();
    renderedImage?.dispose();
  }
}

String _buildMaskOutputPath(File sourceFile) {
  final fileName = sourceFile.uri.pathSegments.isNotEmpty
      ? sourceFile.uri.pathSegments.last
      : sourceFile.path.split(Platform.pathSeparator).last;
  final extensionIndex = fileName.lastIndexOf('.');
  final stem = extensionIndex > 0
      ? fileName.substring(0, extensionIndex)
      : fileName;
  return '${sourceFile.parent.path}${Platform.pathSeparator}${stem}_mask.png';
}

String _buildPhotoOverlayOutputPath(File sourceFile) {
  final fileName = sourceFile.uri.pathSegments.isNotEmpty
      ? sourceFile.uri.pathSegments.last
      : sourceFile.path.split(Platform.pathSeparator).last;
  final extensionIndex = fileName.lastIndexOf('.');
  final stem = extensionIndex > 0
      ? fileName.substring(0, extensionIndex)
      : fileName;
  return '${sourceFile.parent.path}${Platform.pathSeparator}${stem}_overlay.jpg';
}

Future<int> _writeMaskPng({
  required ui.Image image,
  required File outputFile,
}) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw const FileSystemException(
      'Failed to encode face frame landmark mask image.',
    );
  }
  await outputFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
  return outputFile.length();
}

Future<int> _writePhotoOverlayJpeg({
  required ui.Image image,
  required File outputFile,
  required int targetMaxBytes,
}) async {
  final byteData = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  if (byteData == null) {
    throw const FileSystemException(
      'Failed to encode face frame landmark overlay image.',
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
    // 先压 JPEG 质量，再退一步缩小尺寸，尽量在文件大小和可读性之间取平衡。
    for (
      var quality = _photoOverlayInitialJpegQuality;
      quality >= _photoOverlayMinJpegQuality;
      quality -= 4
    ) {
      final encoded = img.encodeJpg(workingImage, quality: quality);
      if (encoded.length <= targetMaxBytes ||
          (workingImage.width <= _photoOverlayMinDimension &&
              workingImage.height <= _photoOverlayMinDimension &&
              quality <= _photoOverlayMinJpegQuality)) {
        await outputFile.writeAsBytes(encoded, flush: true);
        return outputFile.length();
      }
    }

    final nextWidth = (workingImage.width * 0.9).round();
    final nextHeight = (workingImage.height * 0.9).round();
    if (nextWidth >= workingImage.width ||
        nextHeight >= workingImage.height ||
        (nextWidth <= _photoOverlayMinDimension &&
            nextHeight <= _photoOverlayMinDimension)) {
      final fallback = img.encodeJpg(
        workingImage,
        quality: _photoOverlayMinJpegQuality,
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
