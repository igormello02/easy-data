import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/chart_data.dart';
import '../models/chart_style.dart';
import '../models/chart_type_styles.dart';

class PieChartPreview extends StatelessWidget {
  const PieChartPreview({
    super.key,
    required this.data,
    required this.style,
    required this.pieStyle,
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

  bool get _hasValidData =>
      data.points.isNotEmpty && data.points.every((point) => point.value > 0);

  @override
  Widget build(BuildContext context) {
    return Container(
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
            Text(
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
              pieTouchData: PieTouchData(enabled: false),
              sections: [
                for (var index = 0; index < data.points.length; index++)
                  PieChartSectionData(
                    value: data.points[index].value,
                    color: palette[index % palette.length],
                    radius: radius,
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
                color: palette[index % palette.length],
                category: data.points[index].category,
              ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.category});

  final Color color;
  final String category;

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}
