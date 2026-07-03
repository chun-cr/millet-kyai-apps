import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/features/scan/presentation/services/palm_frame_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('palm_frame_renderer_test');
  });

  tearDownAll(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> createSourceImage(String name) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 160, 220),
      Paint()..color = const Color(0xFF171717),
    );
    final image = await recorder.endRecording().toImage(160, 220);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('${tempDir.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(
      bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    return file;
  }

  List<Offset> createPalmLandmarks() {
    return List<Offset>.generate(21, (index) {
      final column = index % 4;
      final row = index ~/ 4;
      return Offset(0.22 + column * 0.12, 0.12 + row * 0.13);
    });
  }

  test(
    'returns original frame path when palm landmarks are unavailable',
    () async {
      final sourceFile = await createSourceImage('palm-source.png');

      final outputPath = await renderPalmFrameFile(
        sourceImagePath: sourceFile.path,
        normalizedLandmarks: const [],
        analysisImageSize: const Size(160, 220),
        mirrored: false,
      );

      expect(outputPath, sourceFile.path);
    },
  );

  test(
    'renders a palm landmark overlay photo beside the source image',
    () async {
      final sourceFile = await createSourceImage(
        'palm-source-with-overlay.png',
      );

      final outputPath = await renderPalmFrameFile(
        sourceImagePath: sourceFile.path,
        normalizedLandmarks: createPalmLandmarks(),
        analysisImageSize: const Size(160, 220),
        mirrored: false,
      );

      expect(outputPath, isNot(sourceFile.path));
      expect(outputPath, endsWith('_overlay.jpg'));
      final outputFile = File(outputPath);
      expect(outputFile.existsSync(), isTrue);
      final outputBytes = outputFile.readAsBytesSync();
      expect(outputBytes.length, greaterThan(2));
      expect(outputBytes[0], 0xFF);
      expect(outputBytes[1], 0xD8);
    },
  );

  test(
    'renders mirrored palm landmark overlays as standalone JPEG files',
    () async {
      final sourceFile = await createSourceImage('palm-source-clamped.png');

      final outputPath = await renderPalmFrameFile(
        sourceImagePath: sourceFile.path,
        normalizedLandmarks: createPalmLandmarks(),
        analysisImageSize: const Size(160, 220),
        mirrored: true,
      );

      final outputFile = File(outputPath);
      expect(outputFile.existsSync(), isTrue);
      expect(outputFile.lengthSync(), greaterThan(2));
    },
  );
}
