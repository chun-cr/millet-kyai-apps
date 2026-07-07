import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/features/scan/presentation/pages/face_scan_page.dart';

void main() {
  test('uses platform-specific face hold durations', () {
    expect(faceScanHoldDuration, const Duration(milliseconds: 800));
    expect(
      faceScanHoldDurationForPlatform(TargetPlatform.android),
      const Duration(milliseconds: 800),
    );
    expect(
      faceScanHoldDurationForPlatform(TargetPlatform.iOS),
      const Duration(milliseconds: 800),
    );
  });

  test('keeps full face progress visible briefly after upload succeeds', () {
    expect(faceScanPostSuccessDelay, const Duration(milliseconds: 450));
  });

  group('hasRenderableFaceFrameUpload', () {
    test(
      'returns false when no landmarks are available for the frame image',
      () {
        expect(
          hasRenderableFaceFrameUpload(
            normalizedLandmarks: const [],
            sourceImagePath: '/tmp/face_crop.jpg',
            faceFrameFilePath: '/tmp/face_crop_overlay.jpg',
          ),
          isFalse,
        );
      },
    );

    test(
      'returns false when the frame image falls back to the source image',
      () {
        expect(
          hasRenderableFaceFrameUpload(
            normalizedLandmarks: const [Offset(0.5, 0.5)],
            sourceImagePath: '/tmp/face_crop.jpg',
            faceFrameFilePath: '/tmp/face_crop.jpg',
          ),
          isFalse,
        );
      },
    );

    test(
      'returns true when landmarks exist and a distinct frame image is generated',
      () {
        expect(
          hasRenderableFaceFrameUpload(
            normalizedLandmarks: const [Offset(0.5, 0.5)],
            sourceImagePath: '/tmp/face_crop.jpg',
            faceFrameFilePath: '/tmp/face_crop_overlay.jpg',
          ),
          isTrue,
        );
      },
    );
  });

  group('isFaceHoldEligible', () {
    test(
      'returns true only when permission granted, face detected, and framed',
      () {
        expect(
          isFaceHoldEligible(
            hasPermission: true,
            hasFaceDetected: true,
            isFramed: true,
          ),
          isTrue,
        );
      },
    );

    test('returns false when face is lost', () {
      expect(
        isFaceHoldEligible(
          hasPermission: true,
          hasFaceDetected: false,
          isFramed: true,
        ),
        isFalse,
      );
    });

    test('returns false when face is not framed', () {
      expect(
        isFaceHoldEligible(
          hasPermission: true,
          hasFaceDetected: true,
          isFramed: false,
        ),
        isFalse,
      );
    });
  });

  group('shouldKeepFaceHoldAlive', () {
    test(
      'keeps hold alive with relaxed framing once countdown has started',
      () {
        expect(
          shouldKeepFaceHoldAlive(
            hasPermission: true,
            hasFaceDetected: true,
            isFramed: false,
            isRelaxedFramed: true,
            holdInProgress: true,
          ),
          isTrue,
        );
      },
    );

    test('stops hold when face landmarks are lost', () {
      expect(
        shouldKeepFaceHoldAlive(
          hasPermission: true,
          hasFaceDetected: false,
          isFramed: true,
          isRelaxedFramed: true,
          holdInProgress: true,
        ),
        isFalse,
      );
    });
  });

  group('shouldRetainPreviousFaceTracking', () {
    test('keeps a running hold alive through a brief tracking dropout', () {
      expect(
        shouldRetainPreviousFaceTracking(
          holdInProgress: true,
          hasFaceDetected: false,
          hasLandmarks: false,
          timeSinceLastTrackedFace: const Duration(milliseconds: 180),
        ),
        isTrue,
      );
    });

    test('does not retain tracking after the grace window expires', () {
      expect(
        shouldRetainPreviousFaceTracking(
          holdInProgress: true,
          hasFaceDetected: false,
          hasLandmarks: false,
          timeSinceLastTrackedFace: const Duration(milliseconds: 400),
        ),
        isFalse,
      );
    });

    test('does not retain tracking before a hold has started', () {
      expect(
        shouldRetainPreviousFaceTracking(
          holdInProgress: false,
          hasFaceDetected: false,
          hasLandmarks: false,
          timeSinceLastTrackedFace: const Duration(milliseconds: 100),
        ),
        isFalse,
      );
    });
  });

  group('shouldAutoStartFaceScan', () {
    test('requires framing on android before auto start', () {
      expect(
        shouldAutoStartFaceScan(
          platform: TargetPlatform.android,
          hasPermission: true,
          hasFaceDetected: true,
          isFramed: false,
          hasAcceptedSnapshot: true,
          isScanning: false,
          isTransitioning: false,
        ),
        isFalse,
      );
    });

    test('requires framing on ios before auto start', () {
      expect(
        shouldAutoStartFaceScan(
          platform: TargetPlatform.iOS,
          hasPermission: true,
          hasFaceDetected: true,
          isFramed: false,
          hasAcceptedSnapshot: true,
          isScanning: false,
          isTransitioning: false,
        ),
        isFalse,
      );
    });

    test('returns false when scan is already running', () {
      expect(
        shouldAutoStartFaceScan(
          platform: TargetPlatform.android,
          hasPermission: true,
          hasFaceDetected: true,
          isFramed: true,
          hasAcceptedSnapshot: true,
          isScanning: true,
          isTransitioning: false,
        ),
        isFalse,
      );
    });

    test('returns false when navigation is in progress', () {
      expect(
        shouldAutoStartFaceScan(
          platform: TargetPlatform.android,
          hasPermission: true,
          hasFaceDetected: true,
          isFramed: true,
          hasAcceptedSnapshot: true,
          isScanning: false,
          isTransitioning: true,
        ),
        isFalse,
      );
    });

    test('returns false when no accepted snapshot is available yet', () {
      expect(
        shouldAutoStartFaceScan(
          platform: TargetPlatform.android,
          hasPermission: true,
          hasFaceDetected: true,
          isFramed: true,
          hasAcceptedSnapshot: false,
          isScanning: false,
          isTransitioning: false,
        ),
        isFalse,
      );
    });
  });

  group('face ready indicator', () {
    test(
      'shows ready once a face is detected and no directional correction is needed',
      () {
        expect(
          shouldShowFaceReadyStatus(
            hasPermission: true,
            hasFaceDetected: true,
            faceDirection: '',
          ),
          isTrue,
        );
      },
    );

    test('does not show ready before a face is detected', () {
      expect(
        shouldShowFaceReadyStatus(
          hasPermission: true,
          hasFaceDetected: false,
          faceDirection: '',
        ),
        isFalse,
      );
    });

    test(
      'does not show ready while directional correction is still needed',
      () {
        expect(
          shouldShowFaceReadyStatus(
            hasPermission: true,
            hasFaceDetected: true,
            faceDirection: 'move left',
          ),
          isFalse,
        );
      },
    );
  });

  group('isFaceFramedForUploadBounds', () {
    const guideRect = Rect.fromLTWH(0.18, 0.10, 0.64, 0.78);

    test('expandFaceGuideRect adds tolerant overflow around the frame', () {
      final expanded = expandFaceGuideRect(guideRect, overflowFactor: 0.1);
      expect(expanded.left, closeTo(0.116, 0.0001));
      expect(expanded.top, closeTo(0.036, 0.0001));
      expect(expanded.right, closeTo(0.884, 0.0001));
      expect(expanded.bottom, closeTo(0.944, 0.0001));
    });

    test('accepts a moderately close face under strict framing', () {
      const bounds = Rect.fromLTRB(0.20, 0.12, 0.80, 0.86);

      expect(
        isFaceFramedForUploadBounds(
          bounds: bounds,
          guideRect: guideRect,
          area: 0.48,
          allowHoldDrift: false,
        ),
        isTrue,
      );
    });

    test('accepts a slightly closer face under strict framing', () {
      const bounds = Rect.fromLTRB(0.19, 0.11, 0.81, 0.88);

      expect(
        isFaceFramedForUploadBounds(
          bounds: bounds,
          guideRect: guideRect,
          area: 0.51,
          allowHoldDrift: false,
        ),
        isTrue,
      );
    });

    test('accepts a smaller but fully framed face under strict framing', () {
      const bounds = Rect.fromLTRB(0.25, 0.18, 0.75, 0.80);

      expect(
        isFaceFramedForUploadBounds(
          bounds: bounds,
          guideRect: guideRect,
          area: 0.31,
          allowHoldDrift: false,
        ),
        isTrue,
      );
    });

    test('still rejects an obviously too-close face under strict framing', () {
      const bounds = Rect.fromLTRB(0.10, 0.02, 0.90, 0.96);

      expect(
        isFaceFramedForUploadBounds(
          bounds: bounds,
          guideRect: guideRect,
          area: 0.75,
          allowHoldDrift: false,
        ),
        isFalse,
      );
    });

    test('allows the same closer face on iOS under strict framing', () {
      const bounds = Rect.fromLTRB(0.17, 0.08, 0.83, 0.90);

      expect(
        isFaceFramedForUploadBounds(
          bounds: bounds,
          guideRect: guideRect,
          area: 0.59,
          allowHoldDrift: false,
          platform: TargetPlatform.iOS,
        ),
        isTrue,
      );
    });

    test('keeps a slightly larger face alive under relaxed framing', () {
      const bounds = Rect.fromLTRB(0.19, 0.11, 0.81, 0.88);

      expect(
        isFaceFramedForUploadBounds(
          bounds: bounds,
          guideRect: guideRect,
          area: 0.53,
          allowHoldDrift: true,
        ),
        isTrue,
      );
    });

    test('still rejects an obviously too-close face under relaxed framing', () {
      const bounds = Rect.fromLTRB(0.08, 0.01, 0.92, 0.98);

      expect(
        isFaceFramedForUploadBounds(
          bounds: bounds,
          guideRect: guideRect,
          area: 0.82,
          allowHoldDrift: true,
        ),
        isFalse,
      );
    });
  });

  group('shouldBeginFaceScan', () {
    test('requires framing on Android before entering scan progress', () {
      expect(
        shouldBeginFaceScan(
          platform: TargetPlatform.android,
          hasPermission: true,
          hasFaceDetected: true,
          isFramed: false,
          isBusy: false,
          isTransitioning: false,
          isPaused: false,
        ),
        isFalse,
      );
    });

    test('requires framing on iOS before entering scan progress', () {
      expect(
        shouldBeginFaceScan(
          platform: TargetPlatform.iOS,
          hasPermission: true,
          hasFaceDetected: true,
          isFramed: false,
          isBusy: false,
          isTransitioning: false,
          isPaused: false,
        ),
        isFalse,
      );
    });

    test('returns false while a scan is already running or paused', () {
      expect(
        shouldBeginFaceScan(
          platform: TargetPlatform.android,
          hasPermission: true,
          hasFaceDetected: true,
          isFramed: true,
          isBusy: true,
          isTransitioning: false,
          isPaused: false,
        ),
        isFalse,
      );
      expect(
        shouldBeginFaceScan(
          platform: TargetPlatform.android,
          hasPermission: true,
          hasFaceDetected: true,
          isFramed: true,
          isBusy: false,
          isTransitioning: false,
          isPaused: true,
        ),
        isFalse,
      );
    });
  });

  group('shouldMirrorFaceUploadMask', () {
    test('mirrors front camera uploads on Android only', () {
      expect(
        shouldMirrorFaceUploadMask(
          platform: TargetPlatform.android,
          isBackCamera: false,
        ),
        isTrue,
      );
      expect(
        shouldMirrorFaceUploadMask(
          platform: TargetPlatform.android,
          isBackCamera: true,
        ),
        isFalse,
      );
      expect(
        shouldMirrorFaceUploadMask(
          platform: TargetPlatform.iOS,
          isBackCamera: false,
        ),
        isFalse,
      );
    });
  });

  group('accepted face snapshot latch', () {
    test('freezes upload inputs at hold completion', () {
      final liveLandmarks = <Offset>[
        const Offset(0.20, 0.25),
        const Offset(0.60, 0.70),
      ];
      final snapshot = buildAcceptedFaceSnapshot(
        guideRect: const Rect.fromLTWH(0.2, 0.1, 0.5, 0.6),
        normalizedLandmarks: liveLandmarks,
        analysisImageSize: const Size(640, 480),
        isBackCamera: false,
        platform: TargetPlatform.android,
        generationId: 42,
        timestampMs: 99,
      );

      expect(snapshot, isNotNull);
      expect(snapshot!.generationId, 42);
      expect(snapshot.timestampMs, 99);
      expect(snapshot.mirrored, isTrue);

      liveLandmarks[0] = const Offset(0.95, 0.95);
      expect(snapshot.normalizedLandmarks.first, const Offset(0.20, 0.25));
    });

    test('keeps the first latched snapshot when live state changes later', () {
      final firstSnapshot = buildAcceptedFaceSnapshot(
        guideRect: const Rect.fromLTWH(0.2, 0.1, 0.5, 0.6),
        normalizedLandmarks: const [Offset(0.20, 0.20), Offset(0.60, 0.70)],
        analysisImageSize: const Size(640, 480),
        isBackCamera: false,
        platform: TargetPlatform.android,
        generationId: 7,
        timestampMs: 700,
      );
      final laterLiveSnapshot = buildAcceptedFaceSnapshot(
        guideRect: const Rect.fromLTWH(0.1, 0.1, 0.7, 0.7),
        normalizedLandmarks: const [Offset(0.10, 0.10), Offset(0.80, 0.85)],
        analysisImageSize: const Size(800, 600),
        isBackCamera: true,
        platform: TargetPlatform.android,
        generationId: 8,
        timestampMs: 800,
      );

      final latched = latchAcceptedFaceSnapshot(
        currentLatchedSnapshot: firstSnapshot,
        nextSnapshot: laterLiveSnapshot,
      );

      expect(latched, same(firstSnapshot));
      expect(latched!.generationId, 7);
      expect(latched.analysisImageSize, const Size(640, 480));
      expect(latched.mirrored, isTrue);
    });
  });
}
