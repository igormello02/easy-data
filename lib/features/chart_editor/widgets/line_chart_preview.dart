import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/chart_data.dart';
import '../models/chart_element_overrides.dart';
import '../models/chart_selection.dart';
import '../models/chart_style.dart';
import '../models/chart_type.dart';
import '../models/chart_type_styles.dart';
import 'chart_interaction_overlay.dart';

class LineChartPreview extends StatelessWidget {
  const LineChartPreview({
    super.key,
    required this.data,
    required this.style,
    required this.lineStyle,
    required this.freeMode,
    required this.selection,
    required this.onSelectionChanged,
    required this.onClearSelection,
    required this.overrides,
  });

  final ChartData data;
  final ChartStyle style;
  final ChartTypeStyles lineStyle;
  final bool freeMode;
  final ChartSelection? selection;
  final ValueChanged<ChartSelection> onSelectionChanged;
  final VoidCallback onClearSelection;
  final ChartElementOverrides overrides;

  bool _isSelected(ChartElementType type, [int? index]) {
    return selection?.elementType == type &&
        (index == null || selection?.index == index);
  }

  @override
  Widget build(BuildContext context) {
    final titleOverride = overrides.resolve(
      chartType: ChartType.line,
      elementType: ChartElementType.title,
    );
    final values = data.points.map((point) => point.value).toList();
    final maximum = values.reduce(math.max);
    final minimum = values.reduce(math.min);
    final padding = math.max(
      math.max(
        (maximum - minimum).abs() * 0.2,
        maximum.abs() * (style.showValues ? 0.18 : 0.08),
      ),
      1.0,
    );
    final axisMinimum = minimum < 0 ? minimum - padding : 0.0;
    final axisMaximum = maximum > 0 ? maximum + padding : padding;
    final interval = _axisInterval(axisMinimum, axisMaximum);
    final xAxisStyle = overrides.resolve(
      chartType: ChartType.line,
      elementType: ChartElementType.xAxisLine,
    );
    final yAxisStyle = overrides.resolve(
      chartType: ChartType.line,
      elementType: ChartElementType.yAxisLine,
    );
    final gridStyle = overrides.resolve(
      chartType: ChartType.line,
      elementType: ChartElementType.gridLines,
    );
    final showXAxis = xAxisStyle.visible ?? style.showXAxis;
    final showYAxis = yAxisStyle.visible ?? style.showYAxis;
    final showGrid = gridStyle.visible ?? style.showGrid;
    final spots = [
      for (var index = 0; index < data.points.length; index++)
        FlSpot(index.toDouble(), data.points[index].value),
    ];
    final line = LineChartBarData(
      spots: spots,
      color: Color(style.primaryColor),
      barWidth: lineStyle.lineWidth,
      isCurved: false,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) {
          final pointOverride = overrides.resolve(
            chartType: ChartType.line,
            elementType: ChartElementType.dataElement,
            index: index,
          );
          final radius = pointOverride.size ?? 4;
          return FlDotCirclePainter(
            radius: _isSelected(ChartElementType.dataElement, index)
                ? radius + 3
                : radius,
            color: Color(pointOverride.color ?? style.primaryColor),
            strokeWidth: _isSelected(ChartElementType.dataElement, index)
                ? 3
                : 0,
            strokeColor: const Color(0xFF111111),
          );
        },
      ),
      belowBarData: BarAreaData(show: false),
    );

    return GestureDetector(
      onTap: freeMode ? onClearSelection : null,
      behavior: HitTestBehavior.translucent,
      child: Container(
        key: const ValueKey('line-chart-preview'),
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          border: Border.all(color: const Color(0xFFE5E5E5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (style.showTitle) ...[
              GestureDetector(
                key: const ValueKey('select-chart-title'),
                onTap: freeMode
                    ? () => onSelectionChanged(
                        const ChartSelection(
                          elementType: ChartElementType.title,
                          chartType: ChartType.line,
                        ),
                      )
                    : null,
                child: Container(
                  decoration: _selectionDecoration(
                    _isSelected(ChartElementType.title),
                  ),
                  child: Text(
                    style.title,
                    key: const ValueKey('chart-preview-title'),
                    textAlign: _textAlign(titleOverride.alignment),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(titleOverride.color ?? 0xFF171717),
                      fontSize: titleOverride.size ?? style.titleSize,
                      fontWeight: _fontWeight(
                        titleOverride.fontWeight,
                        FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final labelWidth = data.points
                      .map((point) => _categorySlotWidth(point.category))
                      .reduce(math.max);
                  final chartWidth = math.max(
                    constraints.maxWidth,
                    data.points.length * labelWidth,
                  );

                  return SingleChildScrollView(
                    key: const ValueKey('line-chart-horizontal-scroll'),
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: chartWidth,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: LineChart(
                              LineChartData(
                                minX: 0,
                                maxX: math
                                    .max(1, data.points.length - 1)
                                    .toDouble(),
                                minY: axisMinimum,
                                maxY: axisMaximum,
                                lineBarsData: [line],
                                showingTooltipIndicators: const [],
                                lineTouchData: LineTouchData(
                                  enabled: freeMode,
                                  touchCallback: (event, response) {
                                    if (event is! FlTapUpEvent) return;
                                    final spots = response?.lineBarSpots;
                                    if (spots == null || spots.isEmpty) {
                                      onClearSelection();
                                      return;
                                    }
                                    final index = spots.first.spotIndex;
                                    final point = data.points[index];
                                    final selectsDataLabel =
                                        style.showValues &&
                                        selection?.elementType ==
                                            ChartElementType.dataElement &&
                                        selection?.index == index;
                                    onSelectionChanged(
                                      ChartSelection(
                                        elementType: selectsDataLabel
                                            ? ChartElementType.dataLabel
                                            : ChartElementType.dataElement,
                                        chartType: ChartType.line,
                                        index: index,
                                        category: point.category,
                                        value: point.value,
                                        text: selectsDataLabel
                                            ? _formatValue(point.value)
                                            : null,
                                      ),
                                    );
                                  },
                                  touchTooltipData: LineTouchTooltipData(
                                    getTooltipColor: (_) => Colors.transparent,
                                    tooltipPadding: EdgeInsets.zero,
                                    tooltipMargin: 6,
                                    getTooltipItems: (spots) => [
                                      for (final spot in spots)
                                        LineTooltipItem(
                                          _formatValue(spot.y),
                                          TextStyle(
                                            color: Color(
                                              overrides
                                                      .resolve(
                                                        chartType:
                                                            ChartType.line,
                                                        elementType:
                                                            ChartElementType
                                                                .dataLabel,
                                                        index: spot.spotIndex,
                                                      )
                                                      .color ??
                                                  0xFF555555,
                                            ),
                                            fontSize:
                                                overrides
                                                    .resolve(
                                                      chartType: ChartType.line,
                                                      elementType:
                                                          ChartElementType
                                                              .dataLabel,
                                                      index: spot.spotIndex,
                                                    )
                                                    .size ??
                                                10,
                                            fontWeight: _fontWeight(
                                              overrides
                                                  .resolve(
                                                    chartType: ChartType.line,
                                                    elementType:
                                                        ChartElementType
                                                            .dataLabel,
                                                    index: spot.spotIndex,
                                                  )
                                                  .fontWeight,
                                              FontWeight.w600,
                                            ),
                                            backgroundColor:
                                                _isSelected(
                                                  ChartElementType.dataLabel,
                                                  spot.spotIndex,
                                                )
                                                ? const Color(0xFFFFE9A8)
                                                : null,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: showXAxis || showYAxis,
                                  border: Border(
                                    left: showYAxis
                                        ? BorderSide(
                                            color: Color(
                                              yAxisStyle.color ?? 0xFFD0D0D0,
                                            ),
                                            width:
                                                (yAxisStyle.size ?? 1) +
                                                (_isSelected(
                                                      ChartElementType
                                                          .yAxisLine,
                                                    )
                                                    ? 1
                                                    : 0),
                                          )
                                        : BorderSide.none,
                                    bottom: showXAxis
                                        ? BorderSide(
                                            color: Color(
                                              xAxisStyle.color ?? 0xFFD0D0D0,
                                            ),
                                            width:
                                                (xAxisStyle.size ?? 1) +
                                                (_isSelected(
                                                      ChartElementType
                                                          .xAxisLine,
                                                    )
                                                    ? 1
                                                    : 0),
                                          )
                                        : BorderSide.none,
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: showGrid,
                                  drawVerticalLine: false,
                                  horizontalInterval: interval,
                                  getDrawingHorizontalLine: (_) => FlLine(
                                    color: Color(gridStyle.color ?? 0xFFE8E8E8),
                                    strokeWidth:
                                        (gridStyle.size ?? 1) +
                                        (_isSelected(ChartElementType.gridLines)
                                            ? 0.75
                                            : 0),
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: showYAxis,
                                      reservedSize: 42,
                                      interval: interval,
                                      getTitlesWidget: (value, meta) {
                                        final tickIndex = (value / interval)
                                            .round();
                                        final labelOverride = overrides.resolve(
                                          chartType: ChartType.line,
                                          elementType:
                                              ChartElementType.yAxisLabel,
                                          index: tickIndex,
                                        );
                                        return SideTitleWidget(
                                          meta: meta,
                                          space: 6,
                                          child: GestureDetector(
                                            key: ValueKey(
                                              'select-y-label-$tickIndex',
                                            ),
                                            onTap: freeMode
                                                ? () => onSelectionChanged(
                                                    ChartSelection(
                                                      elementType:
                                                          ChartElementType
                                                              .yAxisLabel,
                                                      chartType: ChartType.line,
                                                      index: tickIndex,
                                                      value: value,
                                                      text: _formatAxisValue(
                                                        value,
                                                      ),
                                                    ),
                                                  )
                                                : null,
                                            child: Container(
                                              decoration: _selectionDecoration(
                                                _isSelected(
                                                  ChartElementType.yAxisLabel,
                                                  tickIndex,
                                                ),
                                              ),
                                              child: Text(
                                                _formatAxisValue(value),
                                                style: TextStyle(
                                                  color: Color(
                                                    labelOverride.color ??
                                                        0xFF8A8A8A,
                                                  ),
                                                  fontSize:
                                                      labelOverride.size ?? 10,
                                                  fontWeight: _fontWeight(
                                                    labelOverride.fontWeight,
                                                    FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: showXAxis,
                                      reservedSize: 46,
                                      interval: 1,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (value != index ||
                                            index < 0 ||
                                            index >= data.points.length) {
                                          return const SizedBox.shrink();
                                        }
                                        final labelOverride = overrides.resolve(
                                          chartType: ChartType.line,
                                          elementType:
                                              ChartElementType.xAxisLabel,
                                          index: index,
                                        );
                                        return SideTitleWidget(
                                          meta: meta,
                                          space: 8,
                                          child: GestureDetector(
                                            key: ValueKey(
                                              'select-x-label-$index',
                                            ),
                                            onTap: freeMode
                                                ? () => onSelectionChanged(
                                                    ChartSelection(
                                                      elementType:
                                                          ChartElementType
                                                              .xAxisLabel,
                                                      chartType: ChartType.line,
                                                      index: index,
                                                      category: data
                                                          .points[index]
                                                          .category,
                                                      value: data
                                                          .points[index]
                                                          .value,
                                                    ),
                                                  )
                                                : null,
                                            child: Container(
                                              width: labelWidth - 8,
                                              decoration: _selectionDecoration(
                                                _isSelected(
                                                  ChartElementType.xAxisLabel,
                                                  index,
                                                ),
                                              ),
                                              child: Text(
                                                data.points[index].category,
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Color(
                                                    labelOverride.color ??
                                                        0xFF777777,
                                                  ),
                                                  fontSize:
                                                      labelOverride.size ?? 10,
                                                  fontWeight: _fontWeight(
                                                    labelOverride.fontWeight,
                                                    FontWeight.normal,
                                                  ),
                                                  height: 1.15,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              duration: const Duration(milliseconds: 200),
                            ),
                          ),
                          CartesianInteractionOverlay(
                            chartType: ChartType.line,
                            freeMode: freeMode,
                            plotLeft: showYAxis ? 42 : 0,
                            plotBottom: showXAxis ? 46 : 0,
                            gridLineFractions: _gridFractions(
                              axisMinimum,
                              axisMaximum,
                              interval,
                            ),
                            showXAxis: showXAxis,
                            showYAxis: showYAxis,
                            showGrid: showGrid,
                            onSelectionChanged: onSelectionChanged,
                          ),
                          if (style.showValues)
                            for (
                              var index = 0;
                              index < data.points.length;
                              index++
                            )
                              _buildDataLabel(
                                constraints: constraints,
                                chartWidth: chartWidth,
                                showXAxis: showXAxis,
                                showYAxis: showYAxis,
                                axisMinimum: axisMinimum,
                                axisMaximum: axisMaximum,
                                index: index,
                              ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration? _selectionDecoration(bool selected) {
    if (!selected) return null;
    return BoxDecoration(
      border: Border.all(color: const Color(0xFF111111), width: 1.5),
      borderRadius: BorderRadius.circular(4),
    );
  }

  Widget _buildDataLabel({
    required BoxConstraints constraints,
    required double chartWidth,
    required bool showXAxis,
    required bool showYAxis,
    required double axisMinimum,
    required double axisMaximum,
    required int index,
  }) {
    final point = data.points[index];
    final plotLeft = showYAxis ? 42.0 : 0.0;
    final plotBottom = showXAxis ? 46.0 : 0.0;
    final plotWidth = chartWidth - plotLeft;
    final plotHeight = constraints.maxHeight - plotBottom;
    final divisor = math.max(1, data.points.length - 1);
    final x = plotLeft + plotWidth * index / divisor;
    final fraction = (axisMaximum - point.value) / (axisMaximum - axisMinimum);
    final y = (plotHeight * fraction).clamp(0.0, plotHeight - 4);
    final labelOverride = overrides.resolve(
      chartType: ChartType.line,
      elementType: ChartElementType.dataLabel,
      index: index,
    );
    return Positioned(
      key: ValueKey('data-label-position-$index'),
      left: (x - 30).clamp(0.0, chartWidth - 60),
      top: (y - 32).clamp(0.0, plotHeight - 28),
      width: 60,
      height: 28,
      child: ChartDataLabel(
        key: ValueKey('select-data-label-$index'),
        text: _formatValue(point.value),
        style: labelOverride,
        selected: _isSelected(ChartElementType.dataLabel, index),
        onTap: freeMode
            ? () => onSelectionChanged(
                ChartSelection(
                  elementType: ChartElementType.dataLabel,
                  chartType: ChartType.line,
                  index: index,
                  category: point.category,
                  value: point.value,
                  text: _formatValue(point.value),
                ),
              )
            : null,
      ),
    );
  }

  List<double> _gridFractions(double minimum, double maximum, double interval) {
    final fractions = <double>[];
    for (var value = minimum; value <= maximum; value += interval) {
      fractions.add((maximum - value) / (maximum - minimum));
    }
    return fractions;
  }

  FontWeight _fontWeight(ChartFontWeight? weight, FontWeight fallback) =>
      switch (weight) {
        ChartFontWeight.normal => FontWeight.w400,
        ChartFontWeight.semibold => FontWeight.w600,
        ChartFontWeight.bold => FontWeight.w700,
        null => fallback,
      };

  TextAlign _textAlign(ChartTextAlignment? alignment) => switch (alignment) {
    ChartTextAlignment.left => TextAlign.left,
    ChartTextAlignment.center || null => TextAlign.center,
    ChartTextAlignment.right => TextAlign.right,
  };

  double _categorySlotWidth(String category) {
    if (category.length <= 10) return 72;
    if (category.length <= 24) return 104;
    return 136;
  }

  double _axisInterval(double minimum, double maximum) {
    final range = maximum - minimum;
    if (range <= 0) return 1;
    final raw = range / 4;
    final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor());
    final normalized = raw / magnitude;
    final rounded = normalized <= 1
        ? 1
        : normalized <= 2
        ? 2
        : normalized <= 5
        ? 5
        : 10;
    return rounded * magnitude.toDouble();
  }

  String _formatAxisValue(double value) {
    final absolute = value.abs();
    if (absolute >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (absolute >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return _formatValue(value);
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
