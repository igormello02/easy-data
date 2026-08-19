import 'package:easy_data/features/chart_editor/models/chart_data.dart';
import 'package:easy_data/features/chart_editor/models/chart_sort_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const data = ChartData(
    points: [
      ChartDataPoint(category: 'C', value: 30),
      ChartDataPoint(category: 'A', value: 10),
      ChartDataPoint(category: 'B', value: 20),
    ],
  );

  List<String> categories(ChartSortOrder order) {
    return order.applyTo(data).points.map((point) => point.category).toList();
  }

  test('keeps the original order by default', () {
    expect(categories(ChartSortOrder.original), ['C', 'A', 'B']);
  });

  test('sorts alphabetically from A to Z and Z to A', () {
    expect(categories(ChartSortOrder.alphabeticalAsc), ['A', 'B', 'C']);
    expect(categories(ChartSortOrder.alphabeticalDesc), ['C', 'B', 'A']);
  });

  test('sorts by decimal value while preserving category association', () {
    const decimalData = ChartData(
      points: [
        ChartDataPoint(category: 'Trinta', value: 30.5),
        ChartDataPoint(category: 'Dez', value: 10.25),
        ChartDataPoint(category: 'Vinte', value: 20.75),
      ],
    );

    final ascending = ChartSortOrder.valueAsc.applyTo(decimalData).points;
    expect(ascending.map((point) => point.category), [
      'Dez',
      'Vinte',
      'Trinta',
    ]);
    expect(ascending.map((point) => point.value), [10.25, 20.75, 30.5]);

    final descending = ChartSortOrder.valueDesc.applyTo(decimalData).points;
    expect(descending.map((point) => point.category), [
      'Trinta',
      'Vinte',
      'Dez',
    ]);
    expect(descending.map((point) => point.value), [30.5, 20.75, 10.25]);
  });

  test('keeps equal categories and values stable', () {
    const equalData = ChartData(
      points: [
        ChartDataPoint(category: 'Mesmo', value: 2),
        ChartDataPoint(category: 'mesmo', value: 1),
        ChartDataPoint(category: 'Outro', value: 2),
      ],
    );

    expect(
      ChartSortOrder.alphabeticalAsc
          .applyTo(equalData)
          .points
          .map((point) => point.value),
      [2, 1, 2],
    );
    expect(
      ChartSortOrder.valueDesc
          .applyTo(equalData)
          .points
          .map((point) => point.category),
      ['Mesmo', 'Outro', 'mesmo'],
    );
  });

  test('normalizes Portuguese accents without changing source data', () {
    const accented = ChartData(
      points: [
        ChartDataPoint(category: 'São Paulo', value: 50),
        ChartDataPoint(category: 'Água', value: 20),
        ChartDataPoint(category: 'Curitiba', value: 30),
        ChartDataPoint(category: 'Évora', value: 10),
      ],
    );

    final sorted = ChartSortOrder.alphabeticalAsc.applyTo(accented);
    expect(sorted.points.map((point) => point.category), [
      'Água',
      'Curitiba',
      'Évora',
      'São Paulo',
    ]);
    expect(accented.points.map((point) => point.category), [
      'São Paulo',
      'Água',
      'Curitiba',
      'Évora',
    ]);
  });
}
