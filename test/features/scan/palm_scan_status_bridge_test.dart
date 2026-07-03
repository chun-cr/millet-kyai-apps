import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/features/scan/presentation/pages/palm_scan_page.dart';
import 'package:millet_kyai_apps/features/scan/presentation/services/palm_scan_status_bridge.dart';

void main() {
  test('uses an 800ms stable hold before palm upload', () {
    expect(palmScanHoldDuration, const Duration(milliseconds: 800));
  });

  group('PalmScanStatus', () {
    test(
      'treats detected open palm as ready even if straightness is false',
      () {
        const status = PalmScanStatus(
          handPresent: true,
          gestureDetected: true,
          handStraight: false,
          gestureName: 'Open_Palm',
          score: 0.81,
        );

        expect(status.readyToScan, isTrue);
      },
    );

    test('is not ready when hand is absent', () {
      const status = PalmScanStatus(
        handPresent: false,
        gestureDetected: true,
        handStraight: true,
        gestureName: 'Open_Palm',
        score: 0.81,
      );

      expect(status.readyToScan, isFalse);
    });

    test('parses event payload with landmarks safely', () {
      final status = PalmScanStatus.fromEvent({
        'gestureDetected': true,
        'handStraight': false,
        'gestureName': 'Open_Palm',
        'score': 0.9,
        'imageWidth': 640,
        'imageHeight': 480,
        'handLandmarks': const [
          {'x': 0.2, 'y': 0.3},
          {'x': 0.4, 'y': 0.5},
        ],
      });

      expect(status.handPresent, isTrue);
      expect(status.readyToScan, isTrue);
      expect(status.landmarks, const [Offset(0.2, 0.3), Offset(0.4, 0.5)]);
    });

    test(
      'accepts strong open palm score even before native debounce flips',
      () {
        const status = PalmScanStatus(
          handPresent: true,
          gestureDetected: false,
          handStraight: false,
          gestureName: 'Open_Palm',
          score: 0.72,
        );

        expect(status.readyToScan, isTrue);
      },
    );

    test(
      'accepts nearly straight open palm at score 0.58 without native flags',
      () {
        const status = PalmScanStatus(
          handPresent: true,
          gestureDetected: false,
          handStraight: false,
          gestureName: 'Open_Palm',
          score: 0.58,
        );

        expect(status.readyToScan, isTrue);
      },
    );

    test('rejects open palm below score 0.58 when native flags are absent', () {
      const status = PalmScanStatus(
        handPresent: true,
        gestureDetected: false,
        handStraight: false,
        gestureName: 'Open_Palm',
        score: 0.57,
      );

      expect(status.readyToScan, isFalse);
    });

    test('keeps detecting stage visible before any hand is present', () {
      final stage = resolvePalmScanFeedbackStage(
        hasPermission: true,
        isMonitoring: true,
        handPresent: false,
        readyToScan: false,
        scanState: PalmScanState.scanning,
      );

      expect(stage, PalmScanFeedbackStage.detecting);
    });

    test('reports hand detected stage before ready-to-hold', () {
      final stage = resolvePalmScanFeedbackStage(
        hasPermission: true,
        isMonitoring: true,
        handPresent: true,
        readyToScan: false,
        scanState: PalmScanState.scanning,
      );

      expect(stage, PalmScanFeedbackStage.handDetected);
    });

    test('renders palm overlay only with complete drawable input', () {
      final canRender = shouldRenderPalmOverlay(
        handLandmarks: List<Offset>.generate(
          21,
          (index) => Offset(index / 20, 0.5),
        ),
        imageSize: const Size(640, 480),
      );

      final cannotRender = shouldRenderPalmOverlay(
        handLandmarks: const [Offset(0.2, 0.3), Offset(0.4, 0.5)],
        imageSize: const Size(640, 480),
      );

      final invalidImageSize = shouldRenderPalmOverlay(
        handLandmarks: List<Offset>.generate(
          21,
          (index) => Offset(index / 20, 0.5),
        ),
        imageSize: Size.zero,
      );

      expect(canRender, isTrue);
      expect(cannotRender, isFalse);
      expect(invalidImageSize, isFalse);
    });

    test('shows palm hint only when drawable palm data is complete', () {
      final shouldShow = shouldShowPalmHint(
        handPresent: true,
        handLandmarks: List<Offset>.generate(
          21,
          (index) => Offset(index / 20, 0.5),
        ),
        imageSize: const Size(640, 480),
      );

      final shouldHideForPartialLandmarks = shouldShowPalmHint(
        handPresent: true,
        handLandmarks: const [Offset(0.2, 0.3), Offset(0.4, 0.5)],
        imageSize: const Size(640, 480),
      );

      final shouldHideWithoutHand = shouldShowPalmHint(
        handPresent: false,
        handLandmarks: List<Offset>.generate(
          21,
          (index) => Offset(index / 20, 0.5),
        ),
        imageSize: const Size(640, 480),
      );

      expect(shouldShow, isTrue);
      expect(shouldHideForPartialLandmarks, isFalse);
      expect(shouldHideWithoutHand, isFalse);
    });

    test('remaps palm landmarks into the capture guide coordinate space', () {
      final remapped = remapPalmLandmarksToCaptureGuide(
        normalizedLandmarks: const [
          Offset(0.20, 0.10),
          Offset(0.45, 0.40),
          Offset(0.70, 0.70),
        ],
        guideRect: const Rect.fromLTWH(0.20, 0.10, 0.50, 0.60),
      );

      expect(remapped, hasLength(3));
      expect(remapped[0].dx, closeTo(0, 1e-9));
      expect(remapped[0].dy, closeTo(0, 1e-9));
      expect(remapped[1].dx, closeTo(0.5, 1e-9));
      expect(remapped[1].dy, closeTo(0.5, 1e-9));
      expect(remapped[2].dx, closeTo(1, 1e-9));
      expect(remapped[2].dy, closeTo(1, 1e-9));
    });
  });

  group('isPalmHoldEligible', () {
    test('requires a visible ready palm inside the guide', () {
      expect(
        isPalmHoldEligible(
          handPresent: true,
          readyToScan: true,
          isFramed: true,
          pauseAutoScanUntilReset: false,
        ),
        isTrue,
      );
    });

    test('stays blocked while auto scan is paused after a failure', () {
      expect(
        isPalmHoldEligible(
          handPresent: true,
          readyToScan: true,
          isFramed: true,
          pauseAutoScanUntilReset: true,
        ),
        isFalse,
      );
    });
  });

  group('shouldTrackPalmHold', () {
    test('starts hold with relaxed framing when palm is ready', () {
      expect(
        shouldTrackPalmHold(
          holdInProgress: false,
          handPresent: true,
          readyToScan: true,
          isFramed: false,
          isRelaxedFramed: true,
          pauseAutoScanUntilReset: false,
        ),
        isTrue,
      );
    });

    test('does not start hold outside relaxed framing', () {
      expect(
        shouldTrackPalmHold(
          holdInProgress: false,
          handPresent: true,
          readyToScan: true,
          isFramed: false,
          isRelaxedFramed: false,
          pauseAutoScanUntilReset: false,
        ),
        isFalse,
      );
    });

    test(
      'does not start hold under relaxed framing when palm is not ready',
      () {
        expect(
          shouldTrackPalmHold(
            holdInProgress: false,
            handPresent: true,
            readyToScan: false,
            isFramed: false,
            isRelaxedFramed: true,
            pauseAutoScanUntilReset: false,
          ),
          isFalse,
        );
      },
    );

    test(
      'keeps hold alive with relaxed framing once countdown has started and palm stays ready',
      () {
        expect(
          shouldTrackPalmHold(
            holdInProgress: true,
            handPresent: true,
            readyToScan: true,
            isFramed: false,
            isRelaxedFramed: true,
            pauseAutoScanUntilReset: false,
          ),
          isTrue,
        );
      },
    );

    test(
      'keeps hold alive after countdown starts while palm remains ready even if framing drifts away',
      () {
        expect(
          shouldTrackPalmHold(
            holdInProgress: true,
            handPresent: true,
            readyToScan: true,
            isFramed: false,
            isRelaxedFramed: false,
            pauseAutoScanUntilReset: false,
          ),
          isTrue,
        );
      },
    );

    test(
      'stops active hold once the palm is no longer ready even if framing is still good',
      () {
        expect(
          shouldTrackPalmHold(
            holdInProgress: true,
            handPresent: true,
            readyToScan: false,
            isFramed: true,
            isRelaxedFramed: true,
            pauseAutoScanUntilReset: false,
          ),
          isFalse,
        );
      },
    );

    test('stops hold when the hand disappears', () {
      expect(
        shouldTrackPalmHold(
          holdInProgress: true,
          handPresent: false,
          readyToScan: true,
          isFramed: true,
          isRelaxedFramed: true,
          pauseAutoScanUntilReset: false,
        ),
        isFalse,
      );
    });
  });

  group('shouldShowPalmProgressFeedback', () {
    test('shows progress while ready-to-hold countdown is active', () {
      expect(
        shouldShowPalmProgressFeedback(
          scanState: PalmScanState.scanning,
          readyToScan: true,
        ),
        isTrue,
      );
    });

    test('keeps progress visible while palm upload is running', () {
      expect(
        shouldShowPalmProgressFeedback(
          scanState: PalmScanState.uploading,
          readyToScan: false,
        ),
        isTrue,
      );
    });

    test('keeps full progress visible during completed dwell', () {
      expect(
        shouldShowPalmProgressFeedback(
          scanState: PalmScanState.completed,
          readyToScan: false,
        ),
        isTrue,
      );
    });

    test('hides progress before the palm is ready', () {
      expect(
        shouldShowPalmProgressFeedback(
          scanState: PalmScanState.scanning,
          readyToScan: false,
        ),
        isFalse,
      );
    });
  });

  group('isPalmFramedForUploadBounds', () {
    const guideRect = Rect.fromLTWH(0.15, 0.05, 0.70, 0.90);

    test(
      'accepts a fully stretched palm inside the visible guide under relaxed framing',
      () {
        const bounds = Rect.fromLTRB(0.155, 0.06, 0.688, 0.80);

        expect(
          isPalmFramedForUploadBounds(
            bounds: bounds,
            guideRect: guideRect,
            allowHoldDrift: true,
          ),
          isTrue,
        );
      },
    );

    test(
      'still rejects a palm that is too close even under relaxed framing',
      () {
        const bounds = Rect.fromLTRB(0.17, 0.06, 0.70, 0.83);

        expect(
          isPalmFramedForUploadBounds(
            bounds: bounds,
            guideRect: guideRect,
            allowHoldDrift: true,
          ),
          isFalse,
        );
      },
    );
  });
}
