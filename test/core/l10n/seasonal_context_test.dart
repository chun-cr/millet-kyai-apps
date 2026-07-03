import 'package:flutter_test/flutter_test.dart';
import 'package:millet_kyai_apps/core/l10n/seasonal_context.dart';

void main() {
  group('SeasonalContext.fromDate', () {
    test('keeps winter solstice before the minor-cold boundary', () {
      final context = SeasonalContext.fromDate(DateTime(2026, 1, 4));

      expect(context.season, Season.winter);
      expect(context.solarTerm, SolarTerm.winterSolstice);
      expect(context.element, FiveElement.water);
    });

    test('switches to the next solar term on the configured boundary', () {
      final context = SeasonalContext.fromDate(DateTime(2026, 1, 5));

      expect(context.season, Season.winter);
      expect(context.solarTerm, SolarTerm.minorCold);
      expect(context.element, FiveElement.water);
    });

    test('crosses from spring equinox to clear and bright in april', () {
      final beforeBoundary = SeasonalContext.fromDate(DateTime(2026, 4, 4));
      final onBoundary = SeasonalContext.fromDate(DateTime(2026, 4, 5));

      expect(beforeBoundary.solarTerm, SolarTerm.springEquinox);
      expect(onBoundary.solarTerm, SolarTerm.clearAndBright);
      expect(onBoundary.season, Season.spring);
      expect(onBoundary.element, FiveElement.wood);
    });

    test('resolves representative seasons and five-element labels', () {
      expect(
        SeasonalContext.fromDate(DateTime(2026, 6, 21)).season,
        Season.summer,
      );
      expect(
        SeasonalContext.fromDate(DateTime(2026, 6, 21)).element,
        FiveElement.fire,
      );
      expect(
        SeasonalContext.fromDate(DateTime(2026, 8, 8)).season,
        Season.autumn,
      );
      expect(
        SeasonalContext.fromDate(DateTime(2026, 8, 8)).element,
        FiveElement.metal,
      );
      expect(
        SeasonalContext.fromDate(DateTime(2026, 12, 22)).season,
        Season.winter,
      );
      expect(
        SeasonalContext.fromDate(DateTime(2026, 12, 22)).element,
        FiveElement.water,
      );
    });
  });
}
