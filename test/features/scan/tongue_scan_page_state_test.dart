import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/features/scan/presentation/pages/tongue_scan_page.dart';

void main() {
  group('describeTongueScanBlockers', () {
    test('reports mouth missing before other blockers', () {
      expect(
        describeTongueScanBlockers(
          mouthPresent: false,
          protrusionCandidate: false,
          protrusionConfirmed: false,
          isFramed: false,
          pauseAutoScanUntilReset: false,
        ),
        ['mouth_missing'],
      );
    });

    test('reports candidate-not-confirmed and framing blockers together', () {
      expect(
        describeTongueScanBlockers(
          mouthPresent: true,
          protrusionCandidate: true,
          protrusionConfirmed: false,
          isFramed: false,
          pauseAutoScanUntilReset: false,
        ),
        ['protrusion_unconfirmed', 'framing_failed'],
      );
    });

    test(
      'reports pause blocker even after confirmation and framing succeed',
      () {
        expect(
          describeTongueScanBlockers(
            mouthPresent: true,
            protrusionCandidate: true,
            protrusionConfirmed: true,
            isFramed: true,
            pauseAutoScanUntilReset: true,
          ),
          ['paused_after_failure'],
        );
      },
    );

    test('reports hold_ready when no blockers remain', () {
      expect(
        describeTongueScanBlockers(
          mouthPresent: true,
          protrusionCandidate: true,
          protrusionConfirmed: true,
          isFramed: true,
          pauseAutoScanUntilReset: false,
        ),
        ['hold_ready'],
      );
    });
  });

  group('shouldKeepTongueHoldAlive', () {
    test('starts hold when a protrusion candidate is present', () {
      expect(
        shouldKeepTongueHoldAlive(
          protrusionCandidate: true,
          protrusionConfirmed: false,
        ),
        isTrue,
      );
    });

    test('also stays alive when only confirmed signal is present', () {
      expect(
        shouldKeepTongueHoldAlive(
          protrusionCandidate: false,
          protrusionConfirmed: true,
        ),
        isTrue,
      );
    });

    test('stops hold when both candidate and confirmation disappear', () {
      expect(
        shouldKeepTongueHoldAlive(
          protrusionCandidate: false,
          protrusionConfirmed: false,
        ),
        isFalse,
      );
    });
  });

  group('shouldTrackTongueHold', () {
    test('does not start hold from candidate-only frames', () {
      expect(
        shouldTrackTongueHold(
          holdInProgress: false,
          protrusionCandidate: true,
          protrusionConfirmed: false,
          isFramed: true,
          pauseAutoScanUntilReset: false,
        ),
        isFalse,
      );
    });

    test('starts hold once protrusion is confirmed inside the frame', () {
      expect(
        shouldTrackTongueHold(
          holdInProgress: false,
          protrusionCandidate: true,
          protrusionConfirmed: true,
          isFramed: true,
          pauseAutoScanUntilReset: false,
        ),
        isTrue,
      );
    });

    test('keeps an active hold alive while candidate frames continue', () {
      expect(
        shouldTrackTongueHold(
          holdInProgress: true,
          protrusionCandidate: true,
          protrusionConfirmed: false,
          isFramed: true,
          pauseAutoScanUntilReset: false,
        ),
        isTrue,
      );
    });

    test('stops tracking when framing is lost', () {
      expect(
        shouldTrackTongueHold(
          holdInProgress: true,
          protrusionCandidate: true,
          protrusionConfirmed: true,
          isFramed: false,
          pauseAutoScanUntilReset: false,
        ),
        isFalse,
      );
    });
  });

  group('isTongueHoldEligible', () {
    test(
      'returns true only when the current frame is a candidate, confirmed, framed, and not paused',
      () {
        expect(
          isTongueHoldEligible(
            protrusionCandidate: true,
            protrusionConfirmed: true,
            isFramed: true,
            pauseAutoScanUntilReset: false,
          ),
          isTrue,
        );
      },
    );

    test(
      'returns false when the current frame is not a protrusion candidate',
      () {
        expect(
          isTongueHoldEligible(
            protrusionCandidate: false,
            protrusionConfirmed: true,
            isFramed: true,
            pauseAutoScanUntilReset: false,
          ),
          isFalse,
        );
      },
    );

    test('returns false when protrusion is not confirmed', () {
      expect(
        isTongueHoldEligible(
          protrusionCandidate: true,
          protrusionConfirmed: false,
          isFramed: true,
          pauseAutoScanUntilReset: false,
        ),
        isFalse,
      );
    });

    test('returns false when mouth is not framed', () {
      expect(
        isTongueHoldEligible(
          protrusionCandidate: true,
          protrusionConfirmed: true,
          isFramed: false,
          pauseAutoScanUntilReset: false,
        ),
        isFalse,
      );
    });

    test('returns false while auto scan is paused after upload failure', () {
      expect(
        isTongueHoldEligible(
          protrusionCandidate: true,
          protrusionConfirmed: true,
          isFramed: true,
          pauseAutoScanUntilReset: true,
        ),
        isFalse,
      );
    });
  });

  group('isTongueHoldAliveWithinGrace', () {
    test('returns true while the current frame is still hold-alive', () {
      expect(
        isTongueHoldAliveWithinGrace(
          holdAliveNow: true,
          holdInProgress: true,
          lastHoldAliveAt: null,
          gracePeriod: const Duration(milliseconds: 300),
          now: DateTime(2026),
        ),
        isTrue,
      );
    });

    test('keeps hold alive briefly after a single lost frame', () {
      final now = DateTime(2026, 1, 1, 12);

      expect(
        isTongueHoldAliveWithinGrace(
          holdAliveNow: false,
          holdInProgress: true,
          lastHoldAliveAt: now.subtract(const Duration(milliseconds: 180)),
          gracePeriod: const Duration(milliseconds: 300),
          now: now,
        ),
        isTrue,
      );
    });

    test('stops hold after the grace window expires', () {
      final now = DateTime(2026, 1, 1, 12);

      expect(
        isTongueHoldAliveWithinGrace(
          holdAliveNow: false,
          holdInProgress: true,
          lastHoldAliveAt: now.subtract(const Duration(milliseconds: 301)),
          gracePeriod: const Duration(milliseconds: 300),
          now: now,
        ),
        isFalse,
      );
    });

    test('does not preserve hold without an active countdown', () {
      final now = DateTime(2026, 1, 1, 12);

      expect(
        isTongueHoldAliveWithinGrace(
          holdAliveNow: false,
          holdInProgress: false,
          lastHoldAliveAt: now.subtract(const Duration(milliseconds: 100)),
          gracePeriod: const Duration(milliseconds: 300),
          now: now,
        ),
        isFalse,
      );
    });
  });
}
