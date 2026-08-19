import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/chart_data.dart';
import '../models/chart_selection.dart';
import '../models/chart_style.dart';
import '../models/chart_type.dart';
import '../models/chart_type_styles.dart';

class PieChartPreview extends StatelessWidget {
  const PieChartPreview({
    super.key,
    required this.data,
    required this.style,
    required this.pieStyle,
    required this.freeMode,
    required this.selection,
    required this.onSelectionChanged,
    required this.onClearSelection,
  });

  static const palette = [
    Color(0xFF2563EB),
    Color(0xFF0F766E),
    Color(0xFF7C3AED),
    Color(0xFFDC5A3A),
    Color(0xFFD49A22),
    Color(0xFF64748B),
  ];

  final ChartData data;
  final ChartStyle style;
  final ChartTypeStyles pieStyle;
  final bool freeMode;
  final ChartSelection? selection;
  final ValueChanged<ChartSelection> onSelectionChanged;
  final VoidCallback onClearSelection;

  bool _isSelected(ChartElementType type, [int? index]) {
    return selection?.elementType == type &&
        (index == null || selection?.index == index);
  }

  bool get _hasValidData =>
      data.points.isNotEmpty && data.points.every((point) => point.value > 0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: freeMode ? onClearSelection : null,
      behavior: HitTestBehavior.translucent,
      child: Container(
        key: const ValueKey('pie-chart-preview'),
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
                          chartType: ChartType.pie,
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
              const SizedBox(height: 8),
            ],
            if (!_hasValidData)
              const Expanded(
                child: Center(
                  child: Text(
                    'O gráfico de pizza requer valores maiores que zero.',
                    key: ValueKey('invalid-pie-data'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF666666), height: 1.4),
                  ),
                ),
              )
            else
              Expanded(child: _buildChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    final total = data.points.fold<double>(
      0,
      (sum, point) => sum + point.value,
    );
    const radius = 62.0;

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              centerSpaceRadius: radius * pieStyle.pieHolePercent / 100,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                enabled: freeMode,
                touchCallback: (event, response) {
                  if (event is! FlTapUpEvent) return;
                  final index = response?.touchedSection?.touchedSectionIndex;
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
                      chartType: ChartType.pie,
                      index: index,
                      category: point.category,
                      value: point.value,
                    ),
                  );
                },
              ),
              sections: [
                for (var index = 0; index < data.points.length; index++)
                  PieChartSectionData(
                    value: data.points[index].value,
                    color: palette[index % palette.length],
                    radius: _isSelected(ChartElementType.dataElement, index)
                        ? radius + 7
                        : radius,
                    title: style.showValues
                        ? '${(data.points[index].value / total * 100).toStringAsFixed(0)}%'
                        : '',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            duration: const Duration(milliseconds: 200),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 5,
          children: [
            for (var index = 0; index < data.points.length; index++)
              _LegendItem(
                key: ValueKey('select-legend-$index'),
                color: palette[index % palette.length],
                category: data.points[index].category,
                selected: _isSelected(ChartElementType.legendItem, index),
                onTap: freeMode
                    ? () {
                        final point = data.points[index];
                        onSelectionChanged(
                          ChartSelection(
                            elementType: ChartElementType.legendItem,
                            chartType: ChartType.pie,
                            index: index,
                            category: point.category,
                            value: point.value,
                          ),
                        );
                      }
                    : null,
              ),
          ],
        ),
      ],
    );
  }

  BoxDecoration? _selectionDecoration(bool selected) {
    if (!selected) return null;
    return BoxDecoration(
      border: Border.all(color: const Color(0xFF111111), width: 1.5),
      borderRadius: BorderRadius.circular(4),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    super.key,
    required this.color,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String category;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: selected
            ? BoxDecoration(
                border: Border.all(color: const Color(0xFF111111), width: 1.5),
                borderRadius: BorderRadius.circular(4),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Color(0xFF666666)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
