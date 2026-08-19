class ChartDataPoint {
  const ChartDataPoint({required this.category, required this.value});

  final String category;
  final double value;
}

class ChartData {
  const ChartData({required this.points});

  final List<ChartDataPoint> points;
}
