import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/chart_data.dart';
import '../models/chart_selection.dart';
import '../models/chart_style.dart';
import '../models/chart_type.dart';
import '../models/chart_type_styles.dart';

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
  });

  final ChartData data;
  final ChartStyle style;
  final ChartTypeStyles lineStyle;
  final bool freeMode;
  final ChartSelection? selection;
  final ValueChanged<ChartSelection> onSelectionChanged;
  final VoidCallback onClearSelection;

  bool _isSelected(ChartElementType type, [int? index]) {
    return selection?.elementType == type &&
        (index == null || selection?.index == index);
  }

  @override
  Widget build(BuildContext context) {
    final values = data.points.map((point) => point.value).toList();
    final maximum = values.reduce(math.max);
    final minimum = values.reduce(math.min);
    final padding = math.max((maximum - minimum).abs() * 0.15, 1.0);
    final axisMinimum = minimum < 0 ? minimum - padding : 0.0;
    final axisMaximum = maximum > 0 ? maximum + padding : padding;
    final interval = _axisInterval(axisMinimum, axisMaximum);
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
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: _isSelected(ChartElementType.dataElement, index) ? 7 : 4,
          color: Color(style.primaryColor),
          strokeWidth: _isSelected(ChartElementType.dataElement, index) ? 3 : 0,
          strokeColor: const Color(0xFF111111),
        ),
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
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: style.titleSize,
                      fontWeight: FontWeight.w600,
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
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: math.max(1, data.points.length - 1).toDouble(),
                          minY: axisMinimum,
                          maxY: axisMaximum,
                          lineBarsData: [line],
                          showingTooltipIndicators: style.showValues
                              ? [
                                  for (final spot in spots)
                                    ShowingTooltipIndicators([
                                      LineBarSpot(line, 0, spot),
                                    ]),
                                ]
                              : const [],
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
                              onSelectionChanged(
                                ChartSelection(
                                  elementType: ChartElementType.dataElement,
                                  chartType: ChartType.line,
                                  index: index,
                                  category: point.category,
                                  value: point.value,
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
                                    const TextStyle(
                                      color: Color(0xFF555555),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          borderData: FlBorderData(
                            show: style.showXAxis || style.showYAxis,
                            border: Border(
                              left: style.showYAxis
                                  ? const BorderSide(color: Color(0xFFD0D0D0))
                                  : BorderSide.none,
                              bottom: style.showXAxis
                                  ? const BorderSide(color: Color(0xFFD0D0D0))
                                  : BorderSide.none,
                            ),
                          ),
                          gridData: FlGridData(
                            show: style.showGrid,
                            drawVerticalLine: false,
                            horizontalInterval: interval,
                            getDrawingHorizontalLine: (_) => const FlLine(
                              color: Color(0xFFE8E8E8),
                              strokeWidth: 1,
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
                                showTitles: style.showYAxis,
                                reservedSize: 42,
                                interval: interval,
                                getTitlesWidget: (value, meta) =>
                                    SideTitleWidget(
                                      meta: meta,
                                      space: 6,
                                      child: Text(
                                        _formatAxisValue(value),
                                        style: const TextStyle(
                                          color: Color(0xFF8A8A8A),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: style.showXAxis,
                                reservedSize: 46,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (value != index ||
                                      index < 0 ||
                                      index >= data.points.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return SideTitleWidget(
                                    meta: meta,
                                    space: 8,
                                    child: GestureDetector(
                                      key: ValueKey('select-x-label-$index'),
                                      onTap: freeMode
                                          ? () => onSelectionChanged(
                                              ChartSelection(
                                                elementType:
                                                    ChartElementType.xAxisLabel,
                                                chartType: ChartType.line,
                                                index: index,
                                                category:
                                                    data.points[index].category,
                                                value: data.points[index].value,
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
                                          style: const TextStyle(
                                            color: Color(0xFF777777),
                                            fontSize: 10,
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
