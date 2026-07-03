import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/features/scan/presentation/utils/scan_capture_geometry.dart';

void main() {
  group('buildViewportGuideRect', () {
    test('maps centered guide into viewport coordinates', () {
      final rect = buildViewportGuideRect(
        const Size(200, 400),
        alignment: Alignment.center,
        guideWidth: 100,
        guideHeight: 200,
      );

      expect(rect.left, closeTo(50, 0.0001));
      expect(rect.top, closeTo(100, 0.0001));
      expect(rect.width, closeTo(100, 0.0001));
      expect(rect.height, closeTo(200, 0.0001));
    });
  });

  group('buildNormalizedGuideRect', () {
    test('maps centered guide into normalized viewport coordinates', () {
      final rect = buildNormalizedGuideRect(
        const Size(200, 400),
        alignment: Alignment.center,
        guideWidth: 100,
        guideHeight: 200,
      );

      expect(rect.left, closeTo(0.25, 0.0001));
      expect(rect.top, closeTo(0.25, 0.0001));
      expect(rect.width, closeTo(0.5, 0.0001));
      expect(rect.height, closeTo(0.5, 0.0001));
    });

    test('returns zero rect when viewport or guide size is invalid', () {
      expect(
        buildNormalizedGuideRect(
          Size.zero,
          alignment: Alignment.center,
          guideWidth: 100,
          guideHeight: 100,
        ),
        Rect.zero,
      );
    });
  });

  group('mapNormalizedRectToViewport', () {
    test('accounts for cover-crop mapping into the visible viewport', () {
      final rect = mapNormalizedRectToViewport(
        normalizedRect: const Rect.fromLTWH(0.25, 0.25, 0.5, 0.5),
        viewportSize: const Size(200, 400),
        imageSize: const Size(100, 100),
      );

      expect(rect.left, closeTo(0, 0.0001));
      expect(rect.top, closeTo(100, 0.0001));
      expect(rect.right, closeTo(200, 0.0001));
      expect(rect.bottom, closeTo(300, 0.0001));
    });

    test('mirrors the horizontal bounds when requested', () {
      final rect = mapNormalizedRectToViewport(
        normalizedRect: const Rect.fromLTWH(0.10, 0.20, 0.30, 0.40),
        viewportSize: const Size(100, 200),
        imageSize: const Size(100, 200),
        mirrored: true,
      );

      expect(rect.left, closeTo(60, 0.0001));
      expect(rect.right, closeTo(90, 0.0001));
      expect(rect.top, closeTo(40, 0.0001));
      expect(rect.bottom, closeTo(120, 0.0001));
    });
  });

  group('buildTongueAnalysisRect', () {
    test(
      'expands beyond the visible guide when face and mouth bounds are known',
      () {
        final guideRect = const Rect.fromLTWH(0.32, 0.46, 0.24, 0.20);
        final faceBounds = const Rect.fromLTWH(0.22, 0.12, 0.56, 0.72);
        final mouthBounds = const Rect.fromLTWH(0.38, 0.46, 0.18, 0.12);

        final rect = buildTongueAnalysisRect(
          guideRect: guideRect,
          faceBounds: faceBounds,
          mouthBounds: mouthBounds,
          mouthCenter: const Offset(0.47, 0.52),
        );

        expect(rect.width, greaterThan(guideRect.width));
        expect(rect.width, greaterThan(faceBounds.width));
        expect(rect.left, lessThan(0.38));
        expect(rect.right, greaterThan(0.56));
        expect(rect.top, lessThan(faceBounds.top));
        expect(rect.bottom, greaterThan(faceBounds.bottom));
        expect(rect.bottom, greaterThan(mouthBounds.bottom));
        expect(rect.width, greaterThan(0.85));
      },
    );

    test(
      'keeps the forehead visible instead of centering only on the mouth',
      () {
        const guideRect = Rect.fromLTWH(0.323, 0.449, 0.354, 0.422);
        const faceBounds = Rect.fromLTWH(0.25, 0.16, 0.50, 0.58);
        const mouthBounds = Rect.fromLTWH(0.42, 0.53, 0.16, 0.10);

        final rect = buildTongueAnalysisRect(
          guideRect: guideRect,
          faceBounds: faceBounds,
          mouthBounds: mouthBounds,
          mouthCenter: const Offset(0.50, 0.57),
        );

        expect(rect.top, lessThanOrEqualTo(0.02));
        expect(rect.bottom, greaterThan(faceBounds.bottom));
        expect(rect.height, greaterThan(0.82));
        expect(rect.width, greaterThan(0.76));
      },
    );

    test(
      'falls back to an expanded guide when tongue landmarks are missing',
      () {
        final guideRect = const Rect.fromLTWH(0.30, 0.45, 0.20, 0.18);
        final rect = buildTongueAnalysisRect(guideRect: guideRect);

        expect(rect.width, greaterThan(guideRect.width));
        expect(rect.height, greaterThan(guideRect.height));
        expect(rect.center.dx, closeTo(guideRect.center.dx, 0.0001));
        expect(rect.center.dy, greaterThan(guideRect.center.dy));
      },
    );

    test('clamps the analysis rect to normalized bounds near screen edges', () {
      final rect = buildTongueAnalysisRect(
        guideRect: const Rect.fromLTWH(0.82, 0.80, 0.24, 0.22),
        mouthBounds: const Rect.fromLTWH(0.86, 0.84, 0.10, 0.08),
        mouthCenter: const Offset(0.95, 0.92),
      );

      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(1));
      expect(rect.bottom, lessThanOrEqualTo(1));
    });
  });

  group('buildFaceCaptureRect', () {
    test(
      'expands around detected face bounds to keep the whole face visible',
      () {
        final rect = buildFaceCaptureRect(
          guideRect: const Rect.fromLTWH(0.28, 0.14, 0.44, 0.60),
          faceBounds: const Rect.fromLTWH(0.34, 0.24, 0.26, 0.36),
        );

        expect(rect.left, lessThan(0.34));
        expect(rect.top, lessThan(0.24));
        expect(rect.right, greaterThan(0.60));
        expect(rect.bottom, greaterThan(0.60));
        expect(rect.width, greaterThan(0.37));
        expect(rect.height, greaterThan(0.52));
      },
    );

    test('falls back to the guide rect when face bounds are unavailable', () {
      const guideRect = Rect.fromLTWH(0.28, 0.14, 0.44, 0.60);
      final rect = buildFaceCaptureRect(guideRect: guideRect);

      expect(rect, guideRect);
    });
  });

  group('buildPalmCaptureRect', () {
    test(
      'expands beyond the visible guide to preserve fingertips and wrist',
      () {
        const guideRect = Rect.fromLTWH(0.18, 0.10, 0.64, 0.72);
        const handBounds = Rect.fromLTWH(0.28, 0.16, 0.34, 0.54);

        final rect = buildPalmCaptureRect(
          guideRect: guideRect,
          handBounds: handBounds,
        );

        expect(rect.left, lessThan(handBounds.left));
        expect(rect.top, lessThan(handBounds.top));
        expect(rect.right, greaterThan(handBounds.right));
        expect(rect.bottom, greaterThan(handBounds.bottom));
        expect(rect.width, greaterThan(guideRect.width));
        expect(rect.height, greaterThan(guideRect.height));
      },
    );

    test(
      'falls back to an expanded guide when hand bounds are unavailable',
      () {
        const guideRect = Rect.fromLTWH(0.18, 0.10, 0.64, 0.72);

        final rect = buildPalmCaptureRect(guideRect: guideRect);

        expect(rect.left, lessThan(guideRect.left));
        expect(rect.top, lessThan(guideRect.top));
        expect(rect.right, greaterThan(guideRect.right));
        expect(rect.bottom, greaterThan(guideRect.bottom));
      },
    );

    test('clamps palm capture rect near screen edges', () {
      final rect = buildPalmCaptureRect(
        guideRect: const Rect.fromLTWH(0.78, 0.02, 0.24, 0.88),
        handBounds: const Rect.fromLTWH(0.83, 0.05, 0.14, 0.78),
      );

      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(1));
      expect(rect.bottom, lessThanOrEqualTo(1));
    });
  });

  group('isNormalizedBoundsInsideGuide', () {
    test('accepts bounds fully inside the guide safe area', () {
      expect(
        isNormalizedBoundsInsideGuide(
          bounds: const Rect.fromLTWH(0.25, 0.25, 0.3, 0.3),
          guideRect: const Rect.fromLTWH(0.2, 0.2, 0.5, 0.5),
          guideInsetFactor: 0.05,
        ),
        isTrue,
      );
    });

    test('rejects bounds that cross outside the guide', () {
      expect(
        isNormalizedBoundsInsideGuide(
          bounds: const Rect.fromLTWH(0.1, 0.25, 0.3, 0.3),
          guideRect: const Rect.fromLTWH(0.2, 0.2, 0.5, 0.5),
        ),
        isFalse,
      );
    });
  });

  group('progress mapping', () {
    test('clamps hold progress into the pre-upload visual range', () {
      expect(mapHoldProgressToVisualProgress(-0.5), 0);
      expect(mapHoldProgressToVisualProgress(0.5), closeTo(0.31, 0.0001));
      expect(mapHoldProgressToVisualProgress(2), closeTo(0.62, 0.0001));
    });

    test('clamps upload progress into the upload visual range', () {
      expect(mapUploadProgressToVisualProgress(-1), closeTo(0.68, 0.0001));
      expect(mapUploadProgressToVisualProgress(0.5), closeTo(0.83, 0.0001));
      expect(mapUploadProgressToVisualProgress(2), closeTo(0.98, 0.0001));
    });
  });
}
