class ChartTypeStyles {
  const ChartTypeStyles({
    this.barWidth = 20,
    this.lineWidth = 3,
    this.pieHolePercent = 35,
  });

  final double barWidth;
  final double lineWidth;
  final double pieHolePercent;

  ChartTypeStyles copyWith({
    double? barWidth,
    double? lineWidth,
    double? pieHolePercent,
  }) {
    return ChartTypeStyles(
      barWidth: barWidth ?? this.barWidth,
      lineWidth: lineWidth ?? this.lineWidth,
      pieHolePercent: pieHolePercent ?? this.pieHolePercent,
    );
  }
}
