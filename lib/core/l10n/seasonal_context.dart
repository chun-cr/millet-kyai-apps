import 'package:millet_kyai_apps/l10n/app_localizations.dart';

enum Season {
  spring,
  summer,
  autumn,
  winter,
}

enum FiveElement {
  wood,
  fire,
  metal,
  water,
}

enum SolarTerm {
  minorCold,
  majorCold,
  startOfSpring,
  rainWater,
  awakeningOfInsects,
  springEquinox,
  clearAndBright,
  grainRain,
  startOfSummer,
  grainFull,
  grainInEar,
  summerSolstice,
  minorHeat,
  majorHeat,
  startOfAutumn,
  endOfHeat,
  whiteDew,
  autumnEquinox,
  coldDew,
  frostDescent,
  startOfWinter,
  minorSnow,
  majorSnow,
  winterSolstice,
}

class SeasonalContext {
  final Season season;
  final SolarTerm solarTerm;
  final FiveElement element;

  const SeasonalContext({
    required this.season,
    required this.solarTerm,
    required this.element,
  });

  factory SeasonalContext.now() {
    return SeasonalContext.fromDate(DateTime.now());
  }

  factory SeasonalContext.fromDate(DateTime date) {
    final monthDay = date.month * 100 + date.day;
    final boundary = _solarTermBoundaries.lastWhere(
      (item) => monthDay >= item.monthDay,
      orElse: () => _solarTermBoundaries.last,
    );

    return SeasonalContext(
      season: boundary.season,
      solarTerm: boundary.term,
      element: boundary.element,
    );
  }
}

class _SolarTermBoundary {
  final int monthDay;
  final SolarTerm term;
  final Season season;
  final FiveElement element;

  const _SolarTermBoundary({
    required this.monthDay,
    required this.term,
    required this.season,
    required this.element,
  });
}

// 这里采用面向展示的轻量节气映射，基于常见公历交接日近似判断。
// 这样既不用额外引入节气依赖，也能保证页面上的季节标签会随年份自动更新。
const _solarTermBoundaries = <_SolarTermBoundary>[
  _SolarTermBoundary(
    monthDay: 105,
    term: SolarTerm.minorCold,
    season: Season.winter,
    element: FiveElement.water,
  ),
  _SolarTermBoundary(
    monthDay: 120,
    term: SolarTerm.majorCold,
    season: Season.winter,
    element: FiveElement.water,
  ),
  _SolarTermBoundary(
    monthDay: 204,
    term: SolarTerm.startOfSpring,
    season: Season.spring,
    element: FiveElement.wood,
  ),
  _SolarTermBoundary(
    monthDay: 219,
    term: SolarTerm.rainWater,
    season: Season.spring,
    element: FiveElement.wood,
  ),
  _SolarTermBoundary(
    monthDay: 306,
    term: SolarTerm.awakeningOfInsects,
    season: Season.spring,
    element: FiveElement.wood,
  ),
  _SolarTermBoundary(
    monthDay: 321,
    term: SolarTerm.springEquinox,
    season: Season.spring,
    element: FiveElement.wood,
  ),
  _SolarTermBoundary(
    monthDay: 405,
    term: SolarTerm.clearAndBright,
    season: Season.spring,
    element: FiveElement.wood,
  ),
  _SolarTermBoundary(
    monthDay: 420,
    term: SolarTerm.grainRain,
    season: Season.spring,
    element: FiveElement.wood,
  ),
  _SolarTermBoundary(
    monthDay: 506,
    term: SolarTerm.startOfSummer,
    season: Season.summer,
    element: FiveElement.fire,
  ),
  _SolarTermBoundary(
    monthDay: 521,
    term: SolarTerm.grainFull,
    season: Season.summer,
    element: FiveElement.fire,
  ),
  _SolarTermBoundary(
    monthDay: 606,
    term: SolarTerm.grainInEar,
    season: Season.summer,
    element: FiveElement.fire,
  ),
  _SolarTermBoundary(
    monthDay: 621,
    term: SolarTerm.summerSolstice,
    season: Season.summer,
    element: FiveElement.fire,
  ),
  _SolarTermBoundary(
    monthDay: 707,
    term: SolarTerm.minorHeat,
    season: Season.summer,
    element: FiveElement.fire,
  ),
  _SolarTermBoundary(
    monthDay: 723,
    term: SolarTerm.majorHeat,
    season: Season.summer,
    element: FiveElement.fire,
  ),
  _SolarTermBoundary(
    monthDay: 808,
    term: SolarTerm.startOfAutumn,
    season: Season.autumn,
    element: FiveElement.metal,
  ),
  _SolarTermBoundary(
    monthDay: 823,
    term: SolarTerm.endOfHeat,
    season: Season.autumn,
    element: FiveElement.metal,
  ),
  _SolarTermBoundary(
    monthDay: 908,
    term: SolarTerm.whiteDew,
    season: Season.autumn,
    element: FiveElement.metal,
  ),
  _SolarTermBoundary(
    monthDay: 923,
    term: SolarTerm.autumnEquinox,
    season: Season.autumn,
    element: FiveElement.metal,
  ),
  _SolarTermBoundary(
    monthDay: 1008,
    term: SolarTerm.coldDew,
    season: Season.autumn,
    element: FiveElement.metal,
  ),
  _SolarTermBoundary(
    monthDay: 1023,
    term: SolarTerm.frostDescent,
    season: Season.autumn,
    element: FiveElement.metal,
  ),
  _SolarTermBoundary(
    monthDay: 1107,
    term: SolarTerm.startOfWinter,
    season: Season.winter,
    element: FiveElement.water,
  ),
  _SolarTermBoundary(
    monthDay: 1122,
    term: SolarTerm.minorSnow,
    season: Season.winter,
    element: FiveElement.water,
  ),
  _SolarTermBoundary(
    monthDay: 1207,
    term: SolarTerm.majorSnow,
    season: Season.winter,
    element: FiveElement.water,
  ),
  _SolarTermBoundary(
    monthDay: 1222,
    term: SolarTerm.winterSolstice,
    season: Season.winter,
    element: FiveElement.water,
  ),
];

extension SeasonalContextL10nX on AppLocalizations {
  String seasonLabel(Season season) {
    return switch (season) {
      Season.spring => reportSeasonSpring,
      Season.summer => reportSeasonSummer,
      Season.autumn => reportSeasonAutumn,
      Season.winter => reportSeasonWinter,
    };
  }

  String fiveElementLabel(FiveElement element) {
    return switch (element) {
      FiveElement.wood => reportWuxingWood,
      FiveElement.fire => reportWuxingFire,
      FiveElement.metal => reportWuxingMetal,
      FiveElement.water => reportWuxingWater,
    };
  }

  String solarTermLabel(SolarTerm solarTerm) {
    return switch (solarTerm) {
      SolarTerm.minorCold => solarTermMinorCold,
      SolarTerm.majorCold => solarTermMajorCold,
      SolarTerm.startOfSpring => solarTermStartOfSpring,
      SolarTerm.rainWater => solarTermRainWater,
      SolarTerm.awakeningOfInsects => solarTermAwakeningOfInsects,
      SolarTerm.springEquinox => solarTermSpringEquinox,
      SolarTerm.clearAndBright => solarTermClearAndBright,
      SolarTerm.grainRain => solarTermGrainRain,
      SolarTerm.startOfSummer => solarTermStartOfSummer,
      SolarTerm.grainFull => solarTermGrainFull,
      SolarTerm.grainInEar => solarTermGrainInEar,
      SolarTerm.summerSolstice => solarTermSummerSolstice,
      SolarTerm.minorHeat => solarTermMinorHeat,
      SolarTerm.majorHeat => solarTermMajorHeat,
      SolarTerm.startOfAutumn => solarTermStartOfAutumn,
      SolarTerm.endOfHeat => solarTermEndOfHeat,
      SolarTerm.whiteDew => solarTermWhiteDew,
      SolarTerm.autumnEquinox => solarTermAutumnEquinox,
      SolarTerm.coldDew => solarTermColdDew,
      SolarTerm.frostDescent => solarTermFrostDescent,
      SolarTerm.startOfWinter => solarTermStartOfWinter,
      SolarTerm.minorSnow => solarTermMinorSnow,
      SolarTerm.majorSnow => solarTermMajorSnow,
      SolarTerm.winterSolstice => solarTermWinterSolstice,
    };
  }

  String seasonalTagLabel(SeasonalContext seasonalContext) {
    return seasonalSolarTermTag(
      solarTermLabel(seasonalContext.solarTerm),
      fiveElementLabel(seasonalContext.element),
    );
  }
}
