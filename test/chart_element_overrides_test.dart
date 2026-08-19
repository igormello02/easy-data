import 'package:easy_data/features/chart_editor/models/chart_element_overrides.dart';
import 'package:easy_data/features/chart_editor/models/chart_selection.dart';
import 'package:easy_data/features/chart_editor/models/chart_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('combines global and individual overrides', () {
    var overrides = const ChartElementOverrides();
    overrides = overrides.update(
      chartType: ChartType.bar,
      elementType: ChartElementType.dataElement,
      index: null,
      applyToAll: true,
      color: 0xFF2563EB,
      size: 24,
    );
    overrides = overrides.update(
      chartType: ChartType.bar,
      elementType: ChartElementType.dataElement,
      index: 1,
      applyToAll: false,
      color: 0xFFDC5A3A,
    );

    final first = overrides.resolve(
      chartType: ChartType.bar,
      elementType: ChartElementType.dataElement,
      index: 0,
    );
    final second = overrides.resolve(
      chartType: ChartType.bar,
      elementType: ChartElementType.dataElement,
      index: 1,
    );
    expect(first.color, 0xFF2563EB);
    expect(first.size, 24);
    expect(second.color, 0xFFDC5A3A);
    expect(second.size, 24);
  });

  test(
    'applying a property to all supersedes only that individual property',
    () {
      var overrides = const ChartElementOverrides();
      overrides = overrides.update(
        chartType: ChartType.bar,
        elementType: ChartElementType.dataElement,
        index: 1,
        applyToAll: false,
        color: 0xFFDC5A3A,
        size: 30,
      );
      overrides = overrides.update(
        chartType: ChartType.bar,
        elementType: ChartElementType.dataElement,
        index: null,
        applyToAll: true,
        color: 0xFF2563EB,
      );

      final second = overrides.resolve(
        chartType: ChartType.bar,
        elementType: ChartElementType.dataElement,
        index: 1,
      );
      expect(second.color, 0xFF2563EB);
      expect(second.size, 30);
    },
  );

  test('keeps overrides isolated by chart type', () {
    final overrides = const ChartElementOverrides().update(
      chartType: ChartType.bar,
      elementType: ChartElementType.dataElement,
      index: 0,
      applyToAll: false,
      color: 0xFFDC5A3A,
    );

    expect(
      overrides
          .resolve(
            chartType: ChartType.line,
            elementType: ChartElementType.dataElement,
            index: 0,
          )
          .color,
      isNull,
    );
  });
}
