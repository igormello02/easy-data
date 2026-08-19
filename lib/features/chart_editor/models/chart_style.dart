class ChartStyle {
  const ChartStyle({
    this.title = 'Meu gráfico',
    this.showTitle = true,
    this.titleSize = 16,
    this.primaryColor = 0xFF171717,
    this.showValues = false,
    this.showGrid = true,
    this.showXAxis = true,
    this.showYAxis = true,
  });

  final String title;
  final bool showTitle;
  final double titleSize;
  final int primaryColor;
  final bool showValues;
  final bool showGrid;
  final bool showXAxis;
  final bool showYAxis;

  ChartStyle copyWith({
    String? title,
    bool? showTitle,
    double? titleSize,
    int? primaryColor,
    bool? showValues,
    bool? showGrid,
    bool? showXAxis,
    bool? showYAxis,
  }) {
    return ChartStyle(
      title: title ?? this.title,
      showTitle: showTitle ?? this.showTitle,
      titleSize: titleSize ?? this.titleSize,
      primaryColor: primaryColor ?? this.primaryColor,
      showValues: showValues ?? this.showValues,
      showGrid: showGrid ?? this.showGrid,
      showXAxis: showXAxis ?? this.showXAxis,
      showYAxis: showYAxis ?? this.showYAxis,
    );
  }
}
