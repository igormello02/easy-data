import 'chart_data.dart';

enum ChartSortOrder {
  original('Ordem original'),
  alphabeticalAsc('Alfabética A–Z'),
  alphabeticalDesc('Alfabética Z–A'),
  valueAsc('Valor crescente'),
  valueDesc('Valor decrescente');

  const ChartSortOrder(this.label);

  final String label;

  ChartData applyTo(ChartData data) {
    if (this == ChartSortOrder.original) return data;

    final indexedPoints = data.points.indexed.toList();
    indexedPoints.sort((left, right) {
      final comparison = switch (this) {
        ChartSortOrder.alphabeticalAsc => _alphabeticalComparison(
          left.$2,
          right.$2,
        ),
        ChartSortOrder.alphabeticalDesc => _alphabeticalComparison(
          right.$2,
          left.$2,
        ),
        ChartSortOrder.valueAsc => left.$2.value.compareTo(right.$2.value),
        ChartSortOrder.valueDesc => right.$2.value.compareTo(left.$2.value),
        ChartSortOrder.original => 0,
      };
      return comparison != 0 ? comparison : left.$1.compareTo(right.$1);
    });

    return ChartData(points: [for (final entry in indexedPoints) entry.$2]);
  }

  static int _alphabeticalComparison(
    ChartDataPoint left,
    ChartDataPoint right,
  ) {
    return _normalizedCategory(
      left.category,
    ).compareTo(_normalizedCategory(right.category));
  }

  static String _normalizedCategory(String value) {
    const replacements = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };
    final lowerCase = value.trim().toLowerCase();
    return lowerCase.split('').map((character) {
      return replacements[character] ?? character;
    }).join();
  }
}
