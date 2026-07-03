import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/features/scan/presentation/services/tongue_scan_confirmation_policy.dart';

void main() {
  group('TongueProtrusionProxy', () {
    test('rejects frames without enough mouth landmarks', () {
      expect(
        TongueProtrusionProxy.isFrameEligible(
          mouthLandmarks: const [Offset(0.5, 0.5)],
          mouthCenter: const Offset(0.5, 0.5),
        ),
        isFalse,
      );
    });

    test(
      'rejects pronounced mouth geometry when tongue-support blendshapes are absent',
      () {
        expect(
          TongueProtrusionProxy.isFrameEligible(
            mouthLandmarks: const [
              Offset(0.50, 0.40),
              Offset(0.50, 0.50),
              Offset(0.50, 0.62),
              Offset(0.34, 0.50),
              Offset(0.66, 0.50),
              Offset(0.38, 0.54),
              Offset(0.62, 0.54),
              Offset(0.70, 0.48),
            ],
            mouthCenter: const Offset(0.50, 0.50),
            faceLandmarks: const [
              Offset(0.20, 0.20),
              Offset(0.80, 0.20),
              Offset(0.20, 0.80),
              Offset(0.80, 0.80),
            ],
          ),
          isFalse,
        );
      },
    );

    test('accepts strong tongue geometry when blendshapes support it', () {
      expect(
        TongueProtrusionProxy.isFrameEligible(
          mouthLandmarks: const [
            Offset(0.50, 0.40),
            Offset(0.50, 0.50),
            Offset(0.50, 0.62),
            Offset(0.34, 0.50),
            Offset(0.66, 0.50),
            Offset(0.38, 0.54),
            Offset(0.62, 0.54),
            Offset(0.70, 0.48),
          ],
          mouthCenter: const Offset(0.50, 0.50),
          faceLandmarks: const [
            Offset(0.20, 0.20),
            Offset(0.80, 0.20),
            Offset(0.20, 0.80),
            Offset(0.80, 0.80),
          ],
          blendshapes: const {'jawOpen': 0.24, 'mouthFunnel': 0.12},
        ),
        isTrue,
      );
    });

    test(
      'accepts slightly weaker Android tongue support with android tuning',
      () {
        expect(
          TongueProtrusionProxy.isFrameEligible(
            mouthLandmarks: const [
              Offset(0.50, 0.40),
              Offset(0.50, 0.50),
              Offset(0.50, 0.62),
              Offset(0.34, 0.50),
              Offset(0.66, 0.50),
              Offset(0.38, 0.54),
              Offset(0.62, 0.54),
              Offset(0.70, 0.48),
            ],
            mouthCenter: const Offset(0.50, 0.50),
            faceLandmarks: const [
              Offset(0.20, 0.20),
              Offset(0.80, 0.20),
              Offset(0.20, 0.80),
              Offset(0.80, 0.80),
            ],
            blendshapes: const {'jawOpen': 0.12, 'mouthFunnel': 0.07},
            tuning: TongueDetectionTuning.android,
          ),
          isTrue,
        );
      },
    );

    test(
      'rejects near-threshold geometry even when blendshapes support it',
      () {
        expect(
          TongueProtrusionProxy.isFrameEligible(
            mouthLandmarks: const [
              Offset(0.50, 0.44),
              Offset(0.50, 0.50),
              Offset(0.50, 0.531),
              Offset(0.34, 0.50),
              Offset(0.66, 0.50),
              Offset(0.38, 0.52),
              Offset(0.62, 0.52),
              Offset(0.70, 0.49),
            ],
            mouthCenter: const Offset(0.50, 0.50),
            faceLandmarks: const [
              Offset(0.20, 0.20),
              Offset(0.80, 0.20),
              Offset(0.20, 0.80),
              Offset(0.80, 0.80),
            ],
            blendshapes: const {'jawOpen': 0.22, 'mouthFunnel': 0.14},
          ),
          isFalse,
        );
      },
    );

    test(
      'accepts direct tongueOut support when mouth geometry is otherwise borderline',
      () {
        expect(
          TongueProtrusionProxy.isFrameEligible(
            mouthLandmarks: const [
              Offset(0.50, 0.45),
              Offset(0.50, 0.50),
              Offset(0.50, 0.533),
              Offset(0.34, 0.50),
              Offset(0.66, 0.50),
              Offset(0.38, 0.52),
              Offset(0.62, 0.52),
              Offset(0.70, 0.49),
            ],
            mouthCenter: const Offset(0.50, 0.50),
            faceLandmarks: const [
              Offset(0.20, 0.20),
              Offset(0.80, 0.20),
              Offset(0.20, 0.80),
              Offset(0.80, 0.80),
            ],
            blendshapes: const {'tongueOut': 0.24, 'jawOpen': 0.18},
          ),
          isTrue,
        );
      },
    );

    test('rejects flat wide-open mouth geometry', () {
      expect(
        TongueProtrusionProxy.isFrameEligible(
          mouthLandmarks: const [
            Offset(0.50, 0.42),
            Offset(0.50, 0.54),
            Offset(0.50, 0.55),
            Offset(0.34, 0.50),
            Offset(0.66, 0.50),
            Offset(0.38, 0.54),
            Offset(0.62, 0.54),
            Offset(0.70, 0.50),
          ],
          mouthCenter: const Offset(0.50, 0.50),
          faceLandmarks: const [
            Offset(0.20, 0.20),
            Offset(0.80, 0.20),
            Offset(0.20, 0.80),
            Offset(0.80, 0.80),
          ],
        ),
        isFalse,
      );
    });

    test('accepts slightly shallower tongue geometry with android tuning', () {
      expect(
        TongueProtrusionProxy.isFrameEligible(
          mouthLandmarks: const [
            Offset(0.50, 0.46),
            Offset(0.50, 0.50),
            Offset(0.50, 0.535),
            Offset(0.34, 0.50),
            Offset(0.66, 0.50),
            Offset(0.38, 0.519),
            Offset(0.62, 0.519),
            Offset(0.70, 0.49),
          ],
          mouthCenter: const Offset(0.50, 0.50),
          faceLandmarks: const [
            Offset(0.20, 0.20),
            Offset(0.80, 0.20),
            Offset(0.20, 0.80),
            Offset(0.80, 0.80),
          ],
          blendshapes: const {'jawOpen': 0.20, 'mouthFunnel': 0.12},
          tuning: TongueDetectionTuning.android,
        ),
        isTrue,
      );
    });

    test('rejects isolated tongueOut signal when mouth is barely open', () {
      expect(
        TongueProtrusionProxy.isFrameEligible(
          mouthLandmarks: const [
            Offset(0.50, 0.48),
            Offset(0.50, 0.50),
            Offset(0.50, 0.505),
            Offset(0.34, 0.50),
            Offset(0.66, 0.50),
            Offset(0.38, 0.501),
            Offset(0.62, 0.501),
            Offset(0.70, 0.50),
          ],
          mouthCenter: const Offset(0.50, 0.50),
          faceLandmarks: const [
            Offset(0.20, 0.20),
            Offset(0.80, 0.20),
            Offset(0.20, 0.80),
            Offset(0.80, 0.80),
          ],
          blendshapes: const {'tongueOut': 0.30, 'jawOpen': 0.05},
        ),
        isFalse,
      );
    });

    test('rejects mouth-open false positives with strong blendshapes only', () {
      expect(
        TongueProtrusionProxy.isFrameEligible(
          mouthLandmarks: const [
            Offset(0.50, 0.42),
            Offset(0.50, 0.54),
            Offset(0.50, 0.548),
            Offset(0.34, 0.50),
            Offset(0.66, 0.50),
            Offset(0.38, 0.54),
            Offset(0.62, 0.54),
            Offset(0.70, 0.50),
          ],
          mouthCenter: const Offset(0.50, 0.50),
          faceLandmarks: const [
            Offset(0.20, 0.20),
            Offset(0.80, 0.20),
            Offset(0.20, 0.80),
            Offset(0.80, 0.80),
          ],
          blendshapes: const {
            'jawOpen': 0.45,
            'mouthFunnel': 0.20,
            'mouthLowerDownLeft': 0.22,
            'mouthLowerDownRight': 0.22,
          },
        ),
        isFalse,
      );
    });

    test(
      'keeps standard tuning strict for android-relaxed blendshape scores',
      () {
        expect(
          TongueProtrusionProxy.isFrameEligible(
            mouthLandmarks: const [
              Offset(0.50, 0.40),
              Offset(0.50, 0.50),
              Offset(0.50, 0.62),
              Offset(0.34, 0.50),
              Offset(0.66, 0.50),
              Offset(0.38, 0.54),
              Offset(0.62, 0.54),
              Offset(0.70, 0.48),
            ],
            mouthCenter: const Offset(0.50, 0.50),
            faceLandmarks: const [
              Offset(0.20, 0.20),
              Offset(0.80, 0.20),
              Offset(0.20, 0.80),
              Offset(0.80, 0.80),
            ],
            blendshapes: const {'jawOpen': 0.12, 'mouthFunnel': 0.07},
          ),
          isFalse,
        );
      },
    );
  });

  group('TongueConfirmationWindow', () {
    test('does not confirm on a single positive frame', () {
      final window = TongueConfirmationWindow();

      final results = <bool>[
        window.registerFrame(eligible: true),
        window.registerFrame(eligible: false),
        window.registerFrame(eligible: false),
        window.registerFrame(eligible: false),
        window.registerFrame(eligible: false),
        window.registerFrame(eligible: false),
        window.registerFrame(eligible: false),
        window.registerFrame(eligible: false),
      ];

      expect(results.last, isFalse);
    });

    test('confirms when six of the latest eight frames are eligible', () {
      final window = TongueConfirmationWindow();

      final sequence = [true, true, false, true, true, false, true, true];
      bool confirmed = false;
      for (final frame in sequence) {
        confirmed = window.registerFrame(eligible: frame);
      }

      expect(confirmed, isTrue);
    });

    test('hard reset clears rolling state', () {
      final window = TongueConfirmationWindow();

      for (var i = 0; i < 8; i++) {
        window.registerFrame(eligible: true);
      }

      expect(window.registerFrame(eligible: true, hardReset: true), isFalse);

      bool confirmed = false;
      for (var i = 0; i < 7; i++) {
        confirmed = window.registerFrame(eligible: true);
      }

      expect(confirmed, isFalse);
    });
  });
}
