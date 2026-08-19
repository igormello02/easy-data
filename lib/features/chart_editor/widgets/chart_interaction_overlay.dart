import 'package:flutter/material.dart';

import '../models/chart_element_overrides.dart';
import '../models/chart_selection.dart';
import '../models/chart_type.dart';

class ChartDataLabel extends StatelessWidget {
  const ChartDataLabel({
    super.key,
    required this.text,
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final ChartElementStyleOverride style;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 36, minHeight: 28),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: selected
            ? BoxDecoration(
                color: const Color(0xFFFFE9A8),
                borderRadius: BorderRadius.circular(4),
              )
            : null,
        child: Text(
          text,
          maxLines: 1,
          style: TextStyle(
            color: Color(style.color ?? 0xFF555555),
            fontSize: style.size ?? 10,
            fontWeight: chartFontWeight(style.fontWeight, FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class CartesianInteractionOverlay extends StatelessWidget {
  const CartesianInteractionOverlay({
    super.key,
    required this.chartType,
    required this.freeMode,
    required this.plotLeft,
    required this.plotBottom,
    required this.gridLineFractions,
    required this.showXAxis,
    required this.showYAxis,
    required this.showGrid,
    required this.onSelectionChanged,
  });

  final ChartType chartType;
  final bool freeMode;
  final double plotLeft;
  final double plotBottom;
  final List<double> gridLineFractions;
  final bool showXAxis;
  final bool showYAxis;
  final bool showGrid;
  final ValueChanged<ChartSelection> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    if (!freeMode) return const SizedBox.shrink();
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            if (showGrid)
              for (final fraction in gridLineFractions)
                Positioned(
                  key: ValueKey('select-grid-${(fraction * 1000).round()}'),
                  left: plotLeft,
                  right: 0,
                  top: (constraints.maxHeight - plotBottom) * fraction - 5,
                  height: 10,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => onSelectionChanged(
                      ChartSelection(
                        elementType: ChartElementType.gridLines,
                        chartType: chartType,
                      ),
                    ),
                  ),
                ),
            if (showXAxis)
              Positioned(
                key: const ValueKey('select-x-axis-line'),
                left: plotLeft,
                right: 0,
                bottom: plotBottom - 6,
                height: 12,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => onSelectionChanged(
                    ChartSelection(
                      elementType: ChartElementType.xAxisLine,
                      chartType: chartType,
                    ),
                  ),
                ),
              ),
            if (showYAxis)
              Positioned(
                key: const ValueKey('select-y-axis-line'),
                left: plotLeft - 6,
                top: 0,
                bottom: plotBottom,
                width: 12,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => onSelectionChanged(
                    ChartSelection(
                      elementType: ChartElementType.yAxisLine,
                      chartType: chartType,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

FontWeight chartFontWeight(ChartFontWeight? weight, FontWeight fallback) =>
    switch (weight) {
      ChartFontWeight.normal => FontWeight.w400,
      ChartFontWeight.semibold => FontWeight.w600,
      ChartFontWeight.bold => FontWeight.w700,
      null => fallback,
    };
