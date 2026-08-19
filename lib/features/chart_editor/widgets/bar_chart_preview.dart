import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/chart_data.dart';
import '../models/chart_selection.dart';
import '../models/chart_style.dart';
import '../models/chart_type.dart';
import '../models/chart_type_styles.dart';

class BarChartPreview extends StatelessWidget {
  const BarChartPreview({
    super.key,
    required this.data,
    required this.style,
    required this.barStyle,
    required this.freeMode,
    required this.selection,
    required this.onSelectionChanged,
    required this.onClearSelection,
  });

  final ChartData data;
  final ChartStyle style;
  final ChartTypeStyles barStyle;
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
    final axisMinimum = minimum < 0 ? minimum * 1.15 : 0.0;
    final axisMaximum = maximum > 0 ? maximum * 1.15 : 1.0;
    final interval = _axisInterval(axisMinimum, axisMaximum);

    return GestureDetector(
      onTap: freeMode ? onClearSelection : null,
      behavior: HitTestBehavior.translucent,
      child: Container(
        key: const ValueKey('bar-chart-preview'),
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
                          chartType: ChartType.bar,
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
                  final categoryWidth = math.max(
                    labelWidth,
                    barStyle.barWidth + 24,
                  );
                  final chartWidth = math.max(
                    constraints.maxWidth,
                    data.points.length * categoryWidth,
                  );

                  return SingleChildScrollView(
                    key: const ValueKey('chart-horizontal-scroll'),
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: chartWidth,
                      child: BarChart(
                        BarChartData(
                          minY: axisMinimum,
                          maxY: axisMaximum,
                          alignment: BarChartAlignment.spaceAround,
                          barTouchData: BarTouchData(
                            enabled: freeMode,
                            touchCallback: (event, response) {
                              if (event is! FlTapUpEvent) return;
                              final index =
                                  response?.spot?.touchedBarGroupIndex;
                              if (index == null ||
                                  index < 0 ||
                                  index >= data.points.length) {
                                onClearSelection();
                                return;
                              }
                              final point = data.points[index];
                              onSelectionChanged(
                                ChartSelection(
                                  elementType: ChartElementType.dataElement,
                                  chartType: ChartType.bar,
                                  index: index,
                                  category: point.category,
                                  value: point.value,
                                ),
                              );
                            },
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) => Colors.transparent,
                              tooltipPadding: EdgeInsets.zero,
                              tooltipMargin: 4,
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                    return BarTooltipItem(
                                      _formatValue(rod.toY),
                                      const TextStyle(
                                        color: Color(0xFF555555),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  },
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
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 ||
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
                                                chartType: ChartType.bar,
                                                index: index,
                                                category:
                                                    data.points[index].category,
                                                value: data.points[index].value,
                                              ),
                                            )
                                          : null,
                                      child: Container(
                                        width: categoryWidth - 8,
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
                          barGroups: [
                            for (
                              var index = 0;
                              index < data.points.length;
                              index++
                            )
                              BarChartGroupData(
                                x: index,
                                showingTooltipIndicators: style.showValues
                                    ? const [0]
                                    : const [],
                                barRods: [
                                  BarChartRodData(
                                    toY: data.points[index].value,
                                    width: barStyle.barWidth,
                                    color: Color(style.primaryColor),
                                    borderSide:
                                        _isSelected(
                                          ChartElementType.dataElement,
                                          index,
                                        )
                                        ? const BorderSide(
                                            color: Color(0xFF111111),
                                            width: 3,
                                          )
                                        : BorderSide.none,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(5),
                                    ),
                                  ),
                                ],
                              ),
                          ],
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
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
