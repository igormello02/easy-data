import 'chart_type.dart';

enum ChartElementType { title, dataElement, xAxisLabel, legendItem }

class ChartSelection {
  const ChartSelection({
    required this.elementType,
    required this.chartType,
    this.index,
    this.category,
    this.value,
  });

  final ChartElementType elementType;
  final ChartType chartType;
  final int? index;
  final String? category;
  final double? value;
}
