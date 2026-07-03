// 历史报告模块页面：`HistoryRiskTrendChart`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

import 'dart:convert';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/features/history/presentation/pages/history/history_record.dart';
import 'package:millet_kyai_apps/features/history/presentation/pages/history/history_style.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HistoryRiskTrendChart extends StatefulWidget {
  const HistoryRiskTrendChart({super.key, required this.records});

  final List<DiagnosisRecord> records;

  @override
  State<HistoryRiskTrendChart> createState() => _HistoryRiskTrendChartState();
}

class _HistoryRiskTrendChartState extends State<HistoryRiskTrendChart> {
  static const bool _isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');
  static const bool _enableEmbeddedECharts = bool.fromEnvironment(
    'ENABLE_HISTORY_ECHARTS',
    defaultValue: false,
  );
  static const List<Color> _seriesPalette = <Color>[
    historyEarth,
    Color(0xFF5C8768),
    Color(0xFF8A5C7C),
    Color(0xFF4C7EA8),
    Color(0xFFB46B4D),
    Color(0xFF6A63A8),
  ];

  WebViewController? _controller;
  List<DiagnosisRecord> _records = const <DiagnosisRecord>[];
  List<_RiskTrendSeries> _series = const <_RiskTrendSeries>[];
  String? _focusedSeriesName;
  int? _touchedIndex;
  bool _chartLoadFailed = false;

  bool get _supportsEmbeddedECharts {
    if (!_enableEmbeddedECharts ||
        kIsWeb ||
        _isFlutterTest ||
        WebViewPlatform.instance == null) {
      return false;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => true,
      TargetPlatform.iOS => true,
      TargetPlatform.macOS => true,
      TargetPlatform.fuchsia => false,
      TargetPlatform.linux => false,
      TargetPlatform.windows => false,
    };
  }

  @override
  void initState() {
    super.initState();
    _applyRecords();
    if (_supportsEmbeddedECharts) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onWebResourceError: (_) {
              if (!mounted) {
                return;
              }
              setState(() {
                _chartLoadFailed = true;
              });
            },
          ),
        );
      _reloadECharts();
    }
  }

  @override
  void didUpdateWidget(covariant HistoryRiskTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.records != widget.records) {
      _applyRecords();
      _reloadECharts();
    }
  }

  void _applyRecords() {
    _records = widget.records.toList()
      ..sort((left, right) => left.date.compareTo(right.date));
    final nextSeries = _buildRiskTrendSeries(_records);
    _series = nextSeries;
    if (_focusedSeriesName != null &&
        nextSeries.every((series) => series.name != _focusedSeriesName)) {
      _focusedSeriesName = null;
    }
    _touchedIndex = null;
    _chartLoadFailed = false;
  }

  void _reloadECharts() {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    controller.loadHtmlString(_buildChartHtml());
  }

  @override
  Widget build(BuildContext context) {
    if (_series.isEmpty) {
      return SizedBox(
        height: 236,
        child: Center(
          child: Text(
            _emptyLabel(context),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: historyTextHint,
            ),
          ),
        ),
      );
    }

    if (_supportsEmbeddedECharts && !_chartLoadFailed && _controller != null) {
      return SizedBox(
        height: 268,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: WebViewWidget(controller: _controller!),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 236,
          child: LineChart(
            LineChartData(
              minX: _chartMinX,
              maxX: _chartMaxX,
              minY: 0,
              maxY: 100,
              lineTouchData: _buildTouchData(context),
              showingTooltipIndicators: _buildTooltipIndicators(),
              gridData: _buildGridData(),
              borderData: _buildBorderData(),
              titlesData: _buildTitlesData(),
              lineBarsData: _lineBarsData,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: _series
              .map((series) {
                final isFocused = _isSeriesFocused(series);
                final isMuted = _hasFocusedSeries && !isFocused;
                final chipFill = isFocused
                    ? series.color.withValues(alpha: 0.12)
                    : historyCardBg.withValues(alpha: isMuted ? 0.76 : 0.96);
                final chipBorder = isFocused
                    ? series.color.withValues(alpha: 0.34)
                    : const Color(
                        0xFF1E1810,
                      ).withValues(alpha: isMuted ? 0.06 : 0.12);
                final labelColor = isFocused
                    ? historyTextPrimary
                    : historyTextPrimary.withValues(
                        alpha: isMuted ? 0.52 : 0.78,
                      );
                final dotColor = series.color.withValues(
                  alpha: isMuted ? 0.35 : 1,
                );
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() {
                    _focusedSeriesName = isFocused ? null : series.name;
                    _touchedIndex = null;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: chipFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: chipBorder),
                    ),
                    child: DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isFocused
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: labelColor,
                        letterSpacing: 0.2,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: isFocused ? 9 : 8,
                              height: isFocused ? 9 : 8,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(series.name),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }

  List<_RiskTrendSeries> _buildRiskTrendSeries(List<DiagnosisRecord> records) {
    final valuesByName = <String, List<double?>>{};

    for (var index = 0; index < records.length; index++) {
      for (final values in valuesByName.values) {
        values.add(null);
      }

      for (final riskIndex in records[index].riskIndices) {
        final normalizedName = riskIndex.name.trim();
        if (normalizedName.isEmpty) {
          continue;
        }
        final values = valuesByName.putIfAbsent(
          normalizedName,
          () => List<double?>.filled(index + 1, null, growable: true),
        );
        values[index] = (riskIndex.value * 100).clamp(0, 100).toDouble();
      }
    }

    final series = <_RiskTrendSeries>[];
    var colorIndex = 0;
    for (final entry in valuesByName.entries) {
      series.add(
        _RiskTrendSeries(
          name: entry.key,
          values: List<double?>.unmodifiable(entry.value),
          color: _seriesPalette[colorIndex++ % _seriesPalette.length],
        ),
      );
    }
    series.sort(
      (left, right) => _seriesPriority(right).compareTo(_seriesPriority(left)),
    );
    return List<_RiskTrendSeries>.unmodifiable(series);
  }

  bool get _hasFocusedSeries => _focusedSeriesName != null;

  bool _isSeriesFocused(_RiskTrendSeries series) =>
      _focusedSeriesName == series.name;

  List<LineChartBarData> get _lineBarsData => _series
      .map(
        (series) => LineChartBarData(
          spots: [
            for (var index = 0; index < series.values.length; index++)
              series.values[index] == null
                  ? FlSpot.nullSpot
                  : FlSpot(index.toDouble(), series.values[index]!),
          ],
          isCurved: true,
          color: _lineColorFor(series),
          barWidth: _lineWidthFor(series),
          isStrokeCapRound: true,
          curveSmoothness: _curveSmoothnessFor(series),
          dotData: FlDotData(
            show: true,
            checkToShowDot: (spot, _) {
              if (spot == FlSpot.nullSpot) {
                return false;
              }
              if (_hasFocusedSeries) {
                return _isSeriesFocused(series);
              }
              return spot.x.toInt() == _records.length - 1;
            },
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                  radius: _isSeriesFocused(series) ? 3.4 : 3,
                  color: historyCardBg,
                  strokeWidth: _isSeriesFocused(series) ? 2.2 : 1.8,
                  strokeColor: _lineColorFor(series),
                ),
          ),
          belowBarData: BarAreaData(show: false),
        ),
      )
      .toList(growable: false);

  LineTouchData _buildTouchData(BuildContext context) {
    final lineBarsData = _lineBarsData;
    return LineTouchData(
      enabled: lineBarsData.isNotEmpty,
      handleBuiltInTouches: false,
      touchSpotThreshold: 24,
      touchCallback: (event, response) {
        if (event is FlTapUpEvent ||
            event is FlPanEndEvent ||
            event is FlLongPressEnd) {
          setState(() {
            _touchedIndex = null;
          });
          return;
        }

        final spots = response?.lineBarSpots;
        if (spots == null || spots.isEmpty) {
          return;
        }

        setState(() {
          _touchedIndex = spots.first.x.toInt();
        });
      },
      getTouchedSpotIndicator: (barData, spotIndexes) {
        final color = _lineColorOf(barData);
        return spotIndexes
            .map(
              (_) => TouchedSpotIndicatorData(
                FlLine(
                  color: color.withValues(alpha: 0.18),
                  strokeWidth: 1,
                  dashArray: [3, 4],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                        radius: 4.6,
                        color: color,
                        strokeWidth: 2.4,
                        strokeColor: Colors.white,
                      ),
                ),
              ),
            )
            .toList(growable: false);
      },
      touchTooltipData: LineTouchTooltipData(
        tooltipPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        tooltipMargin: 10,
        tooltipRoundedRadius: 14,
        tooltipBorder: BorderSide(
          color: const Color(0xFF1E1810).withValues(alpha: 0.08),
          width: 0.8,
        ),
        fitInsideHorizontally: true,
        fitInsideVertically: true,
        getTooltipColor: (_) => historyPageBg.withValues(alpha: 0.98),
        getTooltipItems: (touchedSpots) => touchedSpots
            .asMap()
            .entries
            .map((entry) {
              final item = entry.value;
              final itemDate = _dateLabel(_records[item.x.toInt()].date);
              final itemColor = _lineColorOf(item.bar);
              final itemSeries = _series[item.barIndex];
              final itemTitle = entry.key == 0 ? '$itemDate\n' : '';
              return LineTooltipItem(
                '$itemTitle${itemSeries.name}  ${context.l10n.percentValue(item.y.round())}',
                TextStyle(
                  color: itemColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              );
            })
            .toList(growable: false),
      ),
      distanceCalculator: (offset, spotOffset) {
        final dx = (offset.dx - spotOffset.dx).abs();
        final dy = (offset.dy - spotOffset.dy).abs() * 0.35;
        return dx + dy;
      },
    );
  }

  List<ShowingTooltipIndicators> _buildTooltipIndicators() {
    final index = _touchedIndex;
    final lineBarsData = _lineBarsData;
    if (index == null ||
        index < 0 ||
        index >= _records.length ||
        lineBarsData.isEmpty) {
      return const <ShowingTooltipIndicators>[];
    }

    final touchedSpots = <LineBarSpot>[];
    for (var lineIndex = 0; lineIndex < lineBarsData.length; lineIndex++) {
      if (_hasFocusedSeries && !_isSeriesFocused(_series[lineIndex])) {
        continue;
      }
      final barData = lineBarsData[lineIndex];
      if (index >= barData.spots.length) {
        continue;
      }
      final spot = barData.spots[index];
      if (spot == FlSpot.nullSpot) {
        continue;
      }
      touchedSpots.add(LineBarSpot(barData, lineIndex, spot));
    }

    if (touchedSpots.isEmpty) {
      return const <ShowingTooltipIndicators>[];
    }

    return <ShowingTooltipIndicators>[ShowingTooltipIndicators(touchedSpots)];
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: 25,
          getTitlesWidget: (value, meta) {
            if (value < meta.min || value > meta.max) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                '${value.round()}%',
                style: const TextStyle(
                  fontSize: 10,
                  color: historyTextHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: _shouldRotateBottomLabels ? 44 : 32,
          getTitlesWidget: (value, meta) {
            final roundedValue = value.roundToDouble();
            if ((value - roundedValue).abs() > 0.001) {
              return const SizedBox.shrink();
            }

            final index = roundedValue.toInt();
            if (index < 0 || index >= _records.length) {
              return const SizedBox.shrink();
            }
            if (!_xAxisLabelIndexes.contains(index)) {
              return const SizedBox.shrink();
            }

            return SideTitleWidget(
              axisSide: meta.axisSide,
              space: 8,
              child: Transform.rotate(
                angle: _shouldRotateBottomLabels ? -math.pi / 4 : 0,
                alignment: Alignment.topRight,
                child: Text(
                  _dateLabel(_records[index].date),
                  style: const TextStyle(
                    fontSize: 10,
                    color: historyTextHint,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: 25,
      getDrawingHorizontalLine: (value) => FlLine(
        color: const Color(0xFF1E1810).withValues(alpha: 0.07),
        strokeWidth: 0.8,
      ),
    );
  }

  FlBorderData _buildBorderData() {
    return FlBorderData(
      show: true,
      border: Border(
        bottom: BorderSide(
          color: const Color(0xFF1E1810).withValues(alpha: 0.12),
          width: 0.9,
        ),
      ),
    );
  }

  double get _chartMinX => _records.isEmpty ? 0 : -0.5;

  double get _chartMaxX => _records.length <= 1 ? 0.5 : _records.length - 0.5;

  bool get _shouldRotateBottomLabels => _records.length > 12;

  Set<int> get _xAxisLabelIndexes => _buildSparseLabelIndexes(_records.length);

  Set<int> _buildSparseLabelIndexes(int length) {
    if (length <= 0) {
      return const <int>{};
    }
    if (length == 1) {
      return const <int>{0};
    }
    return <int>{0, length ~/ 2, length - 1};
  }

  double _seriesPriority(_RiskTrendSeries series) {
    for (final value in series.values.reversed) {
      if (value != null) {
        return value;
      }
    }
    return -1;
  }

  double _lineWidthFor(_RiskTrendSeries series) {
    if (!_hasFocusedSeries) {
      return 1.6;
    }
    return _isSeriesFocused(series) ? 3 : 1.2;
  }

  double _curveSmoothnessFor(_RiskTrendSeries series) {
    if (!_hasFocusedSeries) {
      return 0.14;
    }
    return _isSeriesFocused(series) ? 0.16 : 0.08;
  }

  Color _lineColorFor(_RiskTrendSeries series) {
    if (!_hasFocusedSeries) {
      return series.color.withValues(alpha: 0.82);
    }
    if (_isSeriesFocused(series)) {
      return series.color;
    }
    return series.color.withValues(alpha: 0.18);
  }

  Color _lineColorOf(LineChartBarData barData) {
    return barData.gradient?.colors.last ??
        barData.color ??
        historyPrimaryGreen;
  }

  String _dateLabel(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month.$day';
  }

  String _emptyLabel(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'zh'
        ? '暂无风险指数趋势'
        : 'No risk trend yet';
  }

  String _buildChartHtml() {
    final labels = _records
        .map((record) => _dateLabel(record.date))
        .toList(growable: false);
    final labelsJson = jsonEncode(labels);
    final seriesJson = jsonEncode(
      _series
          .map(
            (series) => <String, dynamic>{
              'name': series.name,
              'color': _colorToHex(series.color),
              'values': series.values,
            },
          )
          .toList(growable: false),
    );

    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
    <style>
      html, body, #chart {
        margin: 0;
        padding: 0;
        width: 100%;
        background: transparent;
      }
      html, body {
        height: 100%;
      }
      body {
        display: flex;
        flex-direction: column;
        overflow: hidden;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      }
      #legend {
        display: flex;
        flex-wrap: wrap;
        gap: 8px;
        padding: 4px 2px 10px;
      }
      .legend-chip {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 7px 10px;
        border-radius: 10px;
        border: 1px solid rgba(30, 24, 16, 0.12);
        background: rgba(255, 255, 255, 0.96);
        color: rgba(30, 24, 16, 0.78);
        font-size: 11px;
        font-weight: 600;
        letter-spacing: 0.2px;
        cursor: pointer;
        transition: all 180ms ease;
      }
      .legend-chip.is-muted {
        color: rgba(30, 24, 16, 0.52);
        border-color: rgba(30, 24, 16, 0.06);
        background: rgba(255, 255, 255, 0.76);
      }
      .legend-chip.is-focused {
        color: #1E1810;
        font-weight: 700;
      }
      .legend-dot {
        width: 8px;
        height: 8px;
        border-radius: 999px;
        flex: 0 0 auto;
      }
      #chart {
        flex: 1;
        min-height: 0;
      }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/echarts@5/dist/echarts.min.js"></script>
  </head>
  <body>
    <div id="legend"></div>
    <div id="chart"></div>
    <script>
      const labels = $labelsJson;
      const seriesMeta = $seriesJson;
      let focusedSeries = null;
      const chart = echarts.init(document.getElementById('chart'), null, { renderer: 'canvas' });

      function buildSeriesOption(meta) {
        const hasFocus = focusedSeries !== null;
        const isFocused = focusedSeries === meta.name;
        return {
          name: meta.name,
          type: 'line',
          smooth: true,
          showSymbol: false,
          symbol: 'circle',
          symbolSize: 6,
          connectNulls: false,
          z: hasFocus ? (isFocused ? 3 : 1) : 2,
          lineStyle: {
            width: hasFocus ? (isFocused ? 3 : 1.2) : 2,
            opacity: hasFocus ? (isFocused ? 1 : 0.18) : 0.82,
          },
          itemStyle: {
            color: meta.color,
            opacity: hasFocus ? (isFocused ? 1 : 0.18) : 0.82,
          },
          data: meta.values,
        };
      }

      function renderLegend() {
        const legend = document.getElementById('legend');
        const hasFocus = focusedSeries !== null;
        legend.innerHTML = '';

        seriesMeta.forEach((meta) => {
          const isFocused = focusedSeries === meta.name;
          const isMuted = hasFocus && !isFocused;
          const chip = document.createElement('button');
          chip.type = 'button';
          chip.className = 'legend-chip' +
            (isFocused ? ' is-focused' : '') +
            (isMuted ? ' is-muted' : '');
          chip.style.borderColor = isFocused ? meta.color + '55' : '';
          chip.style.background = isFocused ? meta.color + '1F' : '';
          chip.onclick = function() {
            focusedSeries = isFocused ? null : meta.name;
            chart.setOption({ series: seriesMeta.map(buildSeriesOption) });
            renderLegend();
          };

          const dot = document.createElement('span');
          dot.className = 'legend-dot';
          dot.style.background = meta.color;
          dot.style.opacity = isMuted ? '0.35' : '1';

          const label = document.createElement('span');
          label.textContent = meta.name;

          chip.appendChild(dot);
          chip.appendChild(label);
          legend.appendChild(chip);
        });
      }

      const option = {
        backgroundColor: 'transparent',
        animationDuration: 300,
        grid: {
          left: 36,
          right: 12,
          top: 12,
          bottom: 28,
        },
        tooltip: {
          trigger: 'axis',
          backgroundColor: 'rgba(255,248,240,0.98)',
          borderColor: 'rgba(30,24,16,0.08)',
          borderWidth: 1,
          textStyle: {
            color: '#1E1810',
            fontSize: 11,
            fontWeight: 600,
          },
          axisPointer: {
            type: 'line',
            lineStyle: {
              color: 'rgba(30,24,16,0.15)',
              type: 'dashed',
            },
          },
          formatter: function(params) {
            if (!params || params.length === 0) {
              return '';
            }
            const visibleParams = focusedSeries
              ? params.filter((item) => item.seriesName === focusedSeries)
              : params;
            if (visibleParams.length === 0) {
              return '';
            }
            const lines = [visibleParams[0].axisValue];
            visibleParams.forEach(function(item) {
              const value = item.value == null ? '-' : Math.round(item.value) + '%';
              lines.push(item.marker + item.seriesName + '  ' + value);
            });
            return lines.join('<br/>');
          },
        },
        xAxis: {
          type: 'category',
          boundaryGap: false,
          data: labels,
          axisTick: { show: false },
          axisLine: {
            lineStyle: { color: 'rgba(30,24,16,0.12)' },
          },
          axisLabel: {
            color: '#8A8178',
            fontSize: 10,
            hideOverlap: true,
          },
        },
        yAxis: {
          type: 'value',
          min: 0,
          max: 100,
          interval: 25,
          splitLine: {
            lineStyle: { color: 'rgba(30,24,16,0.07)' },
          },
          axisLine: { show: false },
          axisTick: { show: false },
          axisLabel: {
            color: '#8A8178',
            fontSize: 10,
            formatter: '{value}%',
          },
        },
        series: seriesMeta.map(buildSeriesOption),
      };

      chart.setOption(option);
      renderLegend();
      window.addEventListener('resize', function() {
        chart.resize();
      });

      chart.on('click', function(params) {
        if (!params || !params.seriesName) {
          return '';
        }
        focusedSeries = focusedSeries === params.seriesName ? null : params.seriesName;
        chart.setOption({ series: seriesMeta.map(buildSeriesOption) });
        renderLegend();
      });
    </script>
  </body>
</html>
''';
  }

  String _colorToHex(Color color) {
    final red = color.r.round().toRadixString(16).padLeft(2, '0');
    final green = color.g.round().toRadixString(16).padLeft(2, '0');
    final blue = color.b.round().toRadixString(16).padLeft(2, '0');
    return '#$red$green$blue';
  }
}

class _RiskTrendSeries {
  const _RiskTrendSeries({
    required this.name,
    required this.values,
    required this.color,
  });

  final String name;
  final List<double?> values;
  final Color color;
}
