import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/features/scan/presentation/services/tongue_scan_confirmation_policy.dart';
import 'package:millet_kyai_apps/features/scan/presentation/services/tongue_scan_status_bridge.dart';

void main() {
  group('platform tuning helpers', () {
    test('uses android tongue tuning on android', () {
      expect(
        resolveTongueDetectionTuning(isAndroid: true),
        TongueDetectionTuning.android,
      );
    });

    test('keeps standard tongue tuning off android', () {
      expect(
        resolveTongueDetectionTuning(isAndroid: false),
        TongueDetectionTuning.standard,
      );
    });

    test('uses a shorter confirmation window on android', () {
      final window = buildTongueConfirmationWindow(isAndroid: true);

      expect(window.windowSize, 6);
      expect(window.requiredEligibleFrames, 4);
    });

    test('keeps the stricter confirmation window off android', () {
      final window = buildTongueConfirmationWindow(isAndroid: false);

      expect(window.windowSize, 8);
      expect(window.requiredEligibleFrames, 6);
    });
  });

  group('TongueScanStatus', () {
    test('parses explicit face landmarks payload', () {
      final status = TongueScanStatus.fromEvent({
        'faceLandmarks': const [
          {'x': 0.25, 'y': 0.36},
        ],
        'mouthLandmarks': const [
          {'x': 0.2, 'y': 0.3},
          {'x': 0.3, 'y': 0.35},
        ],
        'mouthCenter': const {'x': 0.25, 'y': 0.325},
        'imageWidth': 640,
        'imageHeight': 480,
      });

      expect(status.mouthPresent, isTrue);
      expect(status.protrusionConfirmed, isFalse);
      expect(status.mouthCenter?.dx, closeTo(0.25, 0.0001));
      expect(status.mouthCenter?.dy, closeTo(0.325, 0.0001));
      expect(status.faceLandmarks, const [Offset(0.25, 0.36)]);
      expect(status.blendshapes, isEmpty);
    });

    test('falls back to mouth bounds center when native center is absent', () {
      final status = TongueScanStatus.fromEvent({
        'mouthLandmarks': const [
          {'x': 0.20, 'y': 0.30},
          {'x': 0.30, 'y': 0.36},
          {'x': 0.80, 'y': 0.34},
        ],
      });

      expect(status.mouthCenter?.dx, closeTo(0.50, 0.0001));
      expect(status.mouthCenter?.dy, closeTo(0.33, 0.0001));
    });

    test('keeps legacy landmarks as fallback alias during migration', () {
      final status = TongueScanStatus.fromEvent({
        'landmarks': const [
          {'x': 0.11, 'y': 0.22},
          {'x': 0.33, 'y': 0.44},
        ],
        'mouthLandmarks': const [
          {'x': 0.20, 'y': 0.30},
          {'x': 0.40, 'y': 0.30},
        ],
      });

      expect(status.faceLandmarks, const [
        Offset(0.11, 0.22),
        Offset(0.33, 0.44),
      ]);
    });

    test('parses additive blendshapes payload for tongue v2', () {
      final status = TongueScanStatus.fromEvent({
        'mouthLandmarks': const [
          {'x': 0.20, 'y': 0.30},
          {'x': 0.40, 'y': 0.30},
        ],
        'blendshapes': const {'jawOpen': 0.24, 'mouthFunnel': 0.12},
      });

      expect(status.blendshapes, {'jawOpen': 0.24, 'mouthFunnel': 0.12});
    });

    test('stores Flutter protrusion flags explicitly', () {
      const status = TongueScanStatus(
        mouthLandmarkCount: 8,
        blendshapes: {'jawOpen': 0.3},
        protrusionCandidate: true,
        protrusionConfirmed: true,
      );

      expect(status.blendshapes['jawOpen'], 0.3);
      expect(status.protrusionCandidate, isTrue);
      expect(status.protrusionConfirmed, isTrue);
    });

    test('parses stored-frame metadata from native events', () {
      final status = TongueScanStatus.fromEvent({
        'generationId': 101,
        'timestampMs': 202,
        'isBackCamera': false,
        'mirrored': true,
        'imageWidth': 640,
        'imageHeight': 480,
        'faceLandmarks': [
          {'x': 0.25, 'y': 0.25},
          {'x': 0.75, 'y': 0.75},
        ],
        'mouthLandmarks': [
          {'x': 0.45, 'y': 0.55},
          {'x': 0.55, 'y': 0.55},
        ],
      });

      expect(status.generationId, 101);
      expect(status.timestampMs, 202);
      expect(status.isBackCamera, isFalse);
      expect(status.mirrored, isTrue);
      expect(status.analysisImageSize, const Size(640, 480));
      expect(status.hasStoredFrameMetadata, isTrue);
    });

    test(
      'does not report stored-frame metadata when required fields are missing',
      () {
        final status = TongueScanStatus.fromEvent({
          'imageWidth': 640,
          'imageHeight': 480,
          'mouthLandmarks': [
            {'x': 0.45, 'y': 0.55},
          ],
        });

        expect(status.hasStoredFrameMetadata, isFalse);
      },
    );
  });
}
