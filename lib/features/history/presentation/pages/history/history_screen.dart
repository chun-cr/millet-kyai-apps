// 历史报告模块页面：`HistoryScreen`。负责组织当前场景的主要布局、交互事件以及与导航/状态层的衔接。

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:millet_kyai_apps/core/l10n/l10n.dart';
import 'package:millet_kyai_apps/features/history/presentation/pages/history/history_record.dart';
import 'package:millet_kyai_apps/features/history/presentation/pages/history/history_risk_trend_chart.dart';
import 'package:millet_kyai_apps/features/history/presentation/pages/history/history_style.dart';
import 'package:millet_kyai_apps/features/history/presentation/pages/history/history_widgets.dart';

class HistoryReportScreen extends StatefulWidget {
  const HistoryReportScreen({super.key, required this.records});

  final List<DiagnosisRecord> records;

  @override
  State<HistoryReportScreen> createState() => _HistoryReportScreenState();
}

class _HistoryReportScreenState extends State<HistoryReportScreen> {
  List<DiagnosisRecord> _records = const <DiagnosisRecord>[];
  Set<int> _xAxisLabelIndexes = const <int>{};
  int? _trendTouchedIndex;

  @override
  void initState() {
    super.initState();
    _applyRecords(widget.records);
  }

  @override
  void didUpdateWidget(covariant HistoryReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.records != widget.records) {
      _applyRecords(widget.records);
    }
  }

  void _applyRecords(List<DiagnosisRecord> records) {
    _records = records.toList()
      ..sort((left, right) => left.date.compareTo(right.date));
    _xAxisLabelIndexes = _buildSparseLabelIndexes(_records.length);
    _trendTouchedIndex = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: historyPageBg,
      appBar: AppBar(
        backgroundColor: historyPageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.historyReportTitle,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: historyTextPrimary,
            letterSpacing: 0.4,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: historyTextPrimary,
            ),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final visibleRecords = _records.reversed.toList(growable: false);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate(<Widget>[
              _buildTrendChart(context),
              const SizedBox(height: 24),
              _buildRiskChart(context),
              const SizedBox(height: 24),
              HistorySectionTitle(title: context.l10n.historyPastReports),
              const SizedBox(height: 12),
              if (_records.isEmpty) _buildEmptyState(context),
            ]),
          ),
        ),
        if (visibleRecords.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 278,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) => HistoryRecordCard(
                  record: visibleRecords[index],
                ),
                childCount: visibleRecords.length,
              ),
            ),
          ),
      ],
    );
  }
  Widget _buildEmptyState(BuildContext context) {
    final message = Localizations.localeOf(context).languageCode == 'zh'
        ? '暂无历史报告'
        : 'No report history yet';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: historyCardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.history_toggle_off_rounded,
            size: 28,
            color: historyTextHint,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: historyTextHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context) {
    final trendSpots = <FlSpot>[
      for (var index = 0; index < _records.length; index++)
        FlSpot(index.toDouble(), _records[index].healthTrend),
    ];

    return HistoryChartSectionCard(
      title: context.l10n.historyHealthTrend,
      child: SizedBox(
        height: 236,
        child: LineChart(
          LineChartData(
            minX: _chartMinX,
            maxX: _chartMaxX,
            minY: _trendMinY,
            maxY: _trendMaxY,
            lineTouchData: _buildTouchData(
              onTouchIndexChanged: (value) {
                if (_trendTouchedIndex == value) {
                  return;
                }
                setState(() => _trendTouchedIndex = value);
              },
              valueFormatter: (value) =>
                  context.l10n.scoreWithUnit(value.toInt()),
              lineNameResolver: (_) => context.l10n.historyHealthIndex,
            ),
            showingTooltipIndicators: _buildTrendTooltipIndicators(trendSpots),
            gridData: _buildGridData(
              horizontalInterval: _trendHorizontalInterval,
            ),
            borderData: _buildBorderData(),
            titlesData: _buildTitlesData(
              leftInterval: _trendHorizontalInterval,
              leftReservedSize: 38,
            ),
            lineBarsData: [
              LineChartBarData(
                spots: trendSpots,
                isCurved: true,
                // 橙金色渐变线条，与截图中的暖色标题呼应
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFFB8864E), Color(0xFFD4A55A)],
                  stops: [0.08, 0.92],
                ),
                barWidth: 2.0,
                isStrokeCapRound: true,
                curveSmoothness: 0.28,
                // 轻微橙金填充，兼顾面积图直观感与折线图简洁感
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFD4A55A).withValues(alpha: 0.16),
                      const Color(0xFFB8864E).withValues(alpha: 0.01),
                    ],
                  ),
                ),
                dotData: FlDotData(
                  show: true,
                  checkToShowDot: (spot, barData) =>
                  spot.x.toInt() == _records.length - 1,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                        radius: 3.5,
                        color: historyCardBg,
                        strokeWidth: 2.0,
                        strokeColor: const Color(0xFFD4A55A),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskChart(BuildContext context) {
    return HistoryChartSectionCard(
      title: context.l10n.historyRiskTrend,
      child: HistoryRiskTrendChart(records: _records),
    );
  }

  FlTitlesData _buildTitlesData({
    bool showLeftPercent = false,
    required double leftInterval,
    required double leftReservedSize,
  }) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: leftReservedSize,
          interval: leftInterval,
          getTitlesWidget: (value, meta) {
            if (value < meta.min || value > meta.max) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                showLeftPercent
                    ? '${(value * 100).round()}%'
                    : value.toInt().toString(),
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
          reservedSize: _bottomTitlesReservedSize,
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

  FlGridData _buildGridData({required double horizontalInterval}) {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: horizontalInterval,
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

  LineTouchData _buildTouchData({
    bool enabled = true,
    required ValueChanged<int?> onTouchIndexChanged,
    required String Function(double value) valueFormatter,
    required String Function(LineBarSpot touchedSpot) lineNameResolver,
  }) {
    return LineTouchData(
      enabled: enabled,
      handleBuiltInTouches: false,
      touchSpotThreshold: 24,
      touchCallback: (event, response) {
        if (event is FlTapUpEvent ||
            event is FlPanEndEvent ||
            event is FlLongPressEnd) {
          onTouchIndexChanged(null);
          return;
        }

        final spots = response?.lineBarSpots;
        if (spots == null || spots.isEmpty) {
          return;
        }

        onTouchIndexChanged(spots.first.x.toInt());
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
          final itemValueText = valueFormatter(item.y);
          final itemLineName = lineNameResolver(item);
          final itemTitle = entry.key == 0 ? '$itemDate\n' : '';
          return LineTooltipItem(
            '$itemTitle$itemLineName  $itemValueText',
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

  List<ShowingTooltipIndicators> _buildTrendTooltipIndicators(
      List<FlSpot> trendSpots,
      ) {
    final index = _trendTouchedIndex;
    if (index == null || index < 0 || index >= trendSpots.length) {
      return const <ShowingTooltipIndicators>[];
    }

    final barData = LineChartBarData(
      spots: trendSpots,
      gradient: const LinearGradient(
        colors: [historyPrimaryGreen, historyPrimaryGreenLight],
      ),
    );

    return <ShowingTooltipIndicators>[
      ShowingTooltipIndicators(<LineBarSpot>[
        LineBarSpot(barData, 0, barData.spots[index]),
      ]),
    ];
  }

  double get _chartMinX => _records.isEmpty ? 0 : -0.5;

  double get _chartMaxX => _records.length <= 1 ? 0.5 : _records.length - 0.5;

  bool get _shouldRotateBottomLabels => _records.length > 12;

  double get _bottomTitlesReservedSize => _shouldRotateBottomLabels ? 44 : 32;

  double get _trendHorizontalInterval {
    final range = _trendMaxY - _trendMinY;
    if (range <= 20) {
      return 5;
    }
    return 10;
  }

  double get _trendMinY => 40;

  double get _trendMaxY {
    if (_records.isEmpty) {
      return 100;
    }

    final values = _records
        .map((record) => record.healthTrend)
        .toList(growable: false);
    final rawMin = values.reduce(math.min);
    final rawMax = values.reduce(math.max);
    final paddedMin = math.max(0, rawMin - 5);
    final paddedMax = math.min(100, rawMax + 5);
    final range = paddedMax - paddedMin;

    if (range >= 12) {
      return paddedMax.toDouble();
    }

    final center = (rawMin + rawMax) / 2;
    return math.min(100, center + 6).toDouble();
  }

  Color _lineColorOf(LineChartBarData barData) {
    return barData.gradient?.colors.last ??
        barData.color ??
        const Color(0xFFD4A55A); // 橙金色兜底
  }

  Set<int> _buildSparseLabelIndexes(int length) {
    if (length <= 0) {
      return const <int>{};
    }
    if (length == 1) {
      return const <int>{0};
    }
    return <int>{0, length ~/ 2, length - 1};
  }

  String _dateLabel(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month.$day';
  }
}
