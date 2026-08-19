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
    required this.overrides,
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
  final ChartElementOverrides overrides;

  bool _isSelected(ChartElementType type, [int? index]) {
    return selection?.elementType == type &&
        (index == null || selection?.index == index);
  }

  bool get _hasValidData =>
      data.points.isNotEmpty && data.points.every((point) => point.value > 0);

  @override
  Widget build(BuildContext context) {
    final titleOverride = overrides.resolve(
      chartType: ChartType.pie,
      elementType: ChartElementType.title,
    );
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
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Positioned.fill(
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: radius * pieStyle.pieHolePercent / 100,
                      sectionsSpace: 2,
                      pieTouchData: PieTouchData(
                        enabled: freeMode,
                        touchCallback: (event, response) {
                          if (event is! FlTapUpEvent) return;
                          final index =
                              response?.touchedSection?.touchedSectionIndex;
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
                            color: Color(
                              overrides
                                      .resolve(
                                        chartType: ChartType.pie,
                                        elementType:
                                            ChartElementType.dataElement,
                                        index: index,
                                      )
                                      .color ??
                                  palette[index % palette.length].toARGB32(),
                            ),
                            radius:
                                _isSelected(ChartElementType.dataElement, index)
                                ? radius + 7 + _sliceEmphasis(index)
                                : radius + _sliceEmphasis(index),
                            title: '',
                            titleStyle: TextStyle(
                              color: Color(
                                overrides
                                        .resolve(
                                          chartType: ChartType.pie,
                                          elementType:
                                              ChartElementType.dataLabel,
                                          index: index,
                                        )
                                        .color ??
                                    0xFFFFFFFF,
                              ),
                              fontSize:
                                  overrides
                                      .resolve(
                                        chartType: ChartType.pie,
                                        elementType: ChartElementType.dataLabel,
                                        index: index,
                                      )
                                      .size ??
                                  11,
                              fontWeight: _fontWeight(
                                overrides
                                    .resolve(
                                      chartType: ChartType.pie,
                                      elementType: ChartElementType.dataLabel,
                                      index: index,
                                    )
                                    .fontWeight,
                                FontWeight.w700,
                              ),
                              backgroundColor:
                                  _isSelected(ChartElementType.dataLabel, index)
                                  ? const Color(0x99000000)
                                  : null,
                            ),
                          ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 200),
                  ),
                ),
                if (style.showValues)
                  for (var index = 0; index < data.points.length; index++)
                    _buildPieDataLabel(index, total, constraints),
              ],
            ),
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
                textOverride: overrides.resolve(
                  chartType: ChartType.pie,
                  elementType: ChartElementType.legendItem,
                  index: index,
                ),
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

  double _sliceEmphasis(int index) =>
      overrides
          .resolve(
            chartType: ChartType.pie,
            elementType: ChartElementType.dataElement,
            index: index,
          )
          .size ??
      0;

  Widget _buildPieDataLabel(
    int index,
    double total,
    BoxConstraints constraints,
  ) {
    var start = -math.pi / 2;
    for (var current = 0; current < index; current++) {
      start += data.points[current].value / total * math.pi * 2;
    }
    final sweep = data.points[index].value / total * math.pi * 2;
    final angle = start + sweep / 2;
    const outerRadius = 62.0;
    final holeRadius = outerRadius * pieStyle.pieHolePercent / 100;
    final labelRadius = holeRadius + (outerRadius - holeRadius) * 0.58;
    final centerX = constraints.maxWidth / 2;
    final centerY = constraints.maxHeight / 2;
    final point = data.points[index];
    final text = '${(point.value / total * 100).toStringAsFixed(0)}%';
    final labelOverride = overrides.resolve(
      chartType: ChartType.pie,
      elementType: ChartElementType.dataLabel,
      index: index,
    );
    final effectiveStyle = const ChartElementStyleOverride(
      color: 0xFFFFFFFF,
      size: 11,
      fontWeight: ChartFontWeight.bold,
    ).merge(labelOverride);
    return Positioned(
      key: ValueKey('data-label-position-$index'),
      left: centerX + math.cos(angle) * labelRadius - 25,
      top: centerY + math.sin(angle) * labelRadius - 16,
      width: 50,
      height: 32,
      child: ChartDataLabel(
        key: ValueKey('select-data-label-$index'),
        text: text,
        style: effectiveStyle,
        selected: _isSelected(ChartElementType.dataLabel, index),
        onTap: freeMode
            ? () => onSelectionChanged(
                ChartSelection(
                  elementType: ChartElementType.dataLabel,
                  chartType: ChartType.pie,
                  index: index,
                  category: point.category,
                  value: point.value,
                  text: text,
                ),
              )
            : null,
      ),
    );
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
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    super.key,
    required this.color,
    required this.category,
    required this.selected,
    required this.onTap,
    required this.textOverride,
  });

  final Color color;
  final String category;
  final bool selected;
  final VoidCallback? onTap;
  final ChartElementStyleOverride textOverride;

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
                style: TextStyle(
                  fontSize: textOverride.size ?? 10,
                  color: Color(textOverride.color ?? 0xFF666666),
                  fontWeight: switch (textOverride.fontWeight) {
                    ChartFontWeight.normal => FontWeight.w400,
                    ChartFontWeight.semibold => FontWeight.w600,
                    ChartFontWeight.bold => FontWeight.w700,
                    null => FontWeight.normal,
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
