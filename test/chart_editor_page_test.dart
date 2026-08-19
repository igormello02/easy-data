import 'dart:async';
import 'dart:typed_data';

import 'package:easy_data/features/chart_editor/chart_editor_page.dart';
import 'package:easy_data/features/chart_editor/models/chart_data.dart';
import 'package:easy_data/features/chart_editor/models/chart_element_overrides.dart';
import 'package:easy_data/features/chart_editor/models/chart_sort_order.dart';
import 'package:easy_data/features/chart_editor/models/chart_selection.dart';
import 'package:easy_data/features/chart_editor/models/chart_type.dart';
import 'package:easy_data/features/chart_editor/models/chart_type_styles.dart';
import 'package:easy_data/features/chart_editor/widgets/bar_chart_preview.dart';
import 'package:easy_data/features/chart_editor/widgets/line_chart_preview.dart';
import 'package:easy_data/features/chart_editor/widgets/pie_chart_preview.dart';
import 'package:easy_data/features/export/chart_export_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const data = ChartData(
    points: [
      ChartDataPoint(category: 'Janeiro', value: 4200),
      ChartDataPoint(category: 'Fevereiro', value: 5800),
      ChartDataPoint(category: 'Março', value: 5100),
    ],
  );

  Widget buildEditor() {
    return const MaterialApp(home: ChartEditorPage(data: data));
  }

  ChartExportService successfulExport({VoidCallback? onCapture}) {
    return ChartExportService(
      capturePng: (_) async {
        onCapture?.call();
        return Uint8List.fromList([137, 80, 78, 71]);
      },
      savePng: (_, _) async => true,
    );
  }

  Future<void> expandOptions(WidgetTester tester) async {
    final button = find.byKey(const ValueKey('more-options'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  BarChart currentChart(WidgetTester tester) {
    return tester.widget<BarChart>(find.byType(BarChart));
  }

  Future<void> selectType(WidgetTester tester, String type) async {
    final button = find.byKey(ValueKey('chart-type-$type'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> tapOption(WidgetTester tester, String key) async {
    final option = find.byKey(ValueKey(key));
    await tester.ensureVisible(option);
    await tester.tap(option);
    await tester.pump();
  }

  Future<void> selectSortOrder(
    WidgetTester tester,
    ChartSortOrder order,
  ) async {
    final dropdown = find.byKey(const ValueKey('category-sort-order'));
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(order.label).last);
    await tester.pumpAndSettle();
  }

  Future<void> setFreeMode(WidgetTester tester, bool enabled) async {
    final switchTile = find.byKey(const ValueKey('free-mode-switch'));
    await tester.ensureVisible(switchTile);
    final tile = tester.widget<SwitchListTile>(switchTile);
    tile.onChanged!(enabled);
    await tester.pump();
  }

  void selectElement(WidgetTester tester, ChartSelection selection) {
    switch (selection.chartType) {
      case ChartType.bar:
        tester
            .widget<BarChartPreview>(find.byType(BarChartPreview))
            .onSelectionChanged(selection);
      case ChartType.line:
        tester
            .widget<LineChartPreview>(find.byType(LineChartPreview))
            .onSelectionChanged(selection);
      case ChartType.pie:
        tester
            .widget<PieChartPreview>(find.byType(PieChartPreview))
            .onSelectionChanged(selection);
    }
  }

  void chooseContextColor(WidgetTester tester, int paletteIndex) {
    tester
        .widget<IconButton>(find.byKey(ValueKey('context-color-$paletteIndex')))
        .onPressed!();
  }

  void changeContextSize(WidgetTester tester, double value) {
    tester
        .widget<Slider>(find.byKey(const ValueKey('context-size-slider')))
        .onChanged!(value);
  }

  void applyContextToAll(WidgetTester tester) {
    tester
        .widget<SegmentedButton<bool>>(
          find.byKey(const ValueKey('selection-scope')),
        )
        .onSelectionChanged!({true});
  }

  testWidgets('renders a bar chart with valid data', (tester) async {
    await tester.pumpWidget(buildEditor());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('bar-chart-preview')), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('Janeiro'), findsOneWidget);
    expect(find.text('Fevereiro'), findsOneWidget);
    expect(find.text('Março'), findsOneWidget);

    final chart = tester.widget<BarChart>(find.byType(BarChart));
    final values = chart.data.barGroups
        .map((group) => group.barRods.single.toY)
        .toList();
    expect(values, [4200, 5800, 5100]);
  });

  testWidgets('enables Exportar and triggers chart capture', (tester) async {
    var captureCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ChartEditorPage(
          data: data,
          exportService: successfulExport(
            onCapture: () => captureCalled = true,
          ),
        ),
      ),
    );

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('export-chart')),
    );
    expect(button.onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('export-chart')));
    await tester.pumpAndSettle();

    expect(captureCalled, isTrue);
    expect(find.text('Gráfico exportado com sucesso.'), findsOneWidget);
  });

  testWidgets('handles export failures without crashing', (tester) async {
    final service = ChartExportService(
      capturePng: (_) async => throw StateError('capture failed'),
      savePng: (_, _) async => true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ChartEditorPage(data: data, exportService: service),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('export-chart')));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível exportar o gráfico.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('export-chart')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('export boundary contains the selected chart type', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChartEditorPage(data: data, exportService: successfulExport()),
      ),
    );
    await selectType(tester, 'lines');

    final canvas = find.byKey(const ValueKey('chart-export-canvas'));
    expect(
      find.descendant(of: canvas, matching: find.byType(LineChart)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: canvas, matching: find.byType(BarChart)),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('export-chart')));
    await tester.pumpAndSettle();
    expect(find.text('Gráfico exportado com sucesso.'), findsOneWidget);
  });

  testWidgets('shows and immediately updates the chart title', (tester) async {
    await tester.pumpWidget(buildEditor());

    expect(find.text('Meu gráfico'), findsNWidgets(2));

    await tester.enterText(
      find.byKey(const ValueKey('chart-title-field')),
      'Vendas mensais',
    );
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('bar-chart-preview')),
        matching: find.text('Vendas mensais'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('expands and collapses more options', (tester) async {
    await tester.pumpWidget(buildEditor());

    expect(find.byKey(const ValueKey('advanced-options')), findsNothing);
    await expandOptions(tester);
    expect(find.byKey(const ValueKey('advanced-options')), findsOneWidget);

    final button = find.byKey(const ValueKey('more-options'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('advanced-options')), findsNothing);
  });

  testWidgets('activates and deactivates free mode', (tester) async {
    await tester.pumpWidget(buildEditor());
    var tile = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('free-mode-switch')),
    );
    expect(tile.value, isFalse);

    await setFreeMode(tester, true);
    tile = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('free-mode-switch')),
    );
    expect(tile.value, isTrue);
    expect(
      find.text('Toque em um elemento do gráfico para editá-lo.'),
      findsOneWidget,
    );

    tester
        .widget<BarChartPreview>(find.byType(BarChartPreview))
        .onSelectionChanged(
          const ChartSelection(
            elementType: ChartElementType.dataElement,
            chartType: ChartType.bar,
            index: 0,
            category: 'Janeiro',
            value: 4200,
          ),
        );
    await tester.pump();
    expect(find.byKey(const ValueKey('selection-panel')), findsOneWidget);

    await setFreeMode(tester, false);
    expect(find.byKey(const ValueKey('selection-panel')), findsNothing);
  });

  testWidgets('normal mode does not accept a selection', (tester) async {
    await tester.pumpWidget(buildEditor());
    tester
        .widget<BarChartPreview>(find.byType(BarChartPreview))
        .onSelectionChanged(
          const ChartSelection(
            elementType: ChartElementType.dataElement,
            chartType: ChartType.bar,
            index: 0,
            category: 'Janeiro',
            value: 4200,
          ),
        );
    await tester.pump();

    expect(find.byKey(const ValueKey('selection-panel')), findsNothing);
  });

  testWidgets('selects a bar, changes selection and clears it', (tester) async {
    await tester.pumpWidget(buildEditor());
    await setFreeMode(tester, true);
    var preview = tester.widget<BarChartPreview>(find.byType(BarChartPreview));

    preview.onSelectionChanged(
      const ChartSelection(
        elementType: ChartElementType.dataElement,
        chartType: ChartType.bar,
        index: 0,
        category: 'Janeiro',
        value: 4200,
      ),
    );
    await tester.pump();
    expect(find.text('Barra selecionada'), findsOneWidget);
    expect(find.text('Categoria: Janeiro'), findsOneWidget);
    expect(find.text('Valor: 4200'), findsOneWidget);

    preview = tester.widget<BarChartPreview>(find.byType(BarChartPreview));
    preview.onSelectionChanged(
      const ChartSelection(
        elementType: ChartElementType.xAxisLabel,
        chartType: ChartType.bar,
        index: 1,
        category: 'Fevereiro',
        value: 5800,
      ),
    );
    await tester.pump();
    expect(find.text('Label selecionado'), findsOneWidget);
    expect(find.text('Categoria: Fevereiro'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('close-selection')));
    await tester.pump();
    expect(find.byKey(const ValueKey('selection-panel')), findsNothing);
  });

  testWidgets('selects a line point and a pie slice', (tester) async {
    await tester.pumpWidget(buildEditor());
    await setFreeMode(tester, true);
    await selectType(tester, 'lines');
    tester
        .widget<LineChartPreview>(find.byType(LineChartPreview))
        .onSelectionChanged(
          const ChartSelection(
            elementType: ChartElementType.dataElement,
            chartType: ChartType.line,
            index: 1,
            category: 'Fevereiro',
            value: 5800,
          ),
        );
    await tester.pump();
    expect(find.text('Ponto selecionado'), findsOneWidget);
    expect(find.text('Categoria: Fevereiro'), findsOneWidget);

    await selectType(tester, 'pie');
    expect(find.byKey(const ValueKey('selection-panel')), findsNothing);
    tester
        .widget<PieChartPreview>(find.byType(PieChartPreview))
        .onSelectionChanged(
          const ChartSelection(
            elementType: ChartElementType.dataElement,
            chartType: ChartType.pie,
            index: 2,
            category: 'Março',
            value: 5100,
          ),
        );
    await tester.pump();
    expect(find.text('Fatia selecionada'), findsOneWidget);
    expect(find.text('Categoria: Março'), findsOneWidget);
  });

  testWidgets('selects title by touch and preserves source data', (
    tester,
  ) async {
    final original = data.points.toList();
    await tester.pumpWidget(buildEditor());
    await setFreeMode(tester, true);

    final title = find.byKey(const ValueKey('select-chart-title'));
    await tester.ensureVisible(title);
    await tester.tap(title);
    await tester.pump();

    expect(find.text('Título do gráfico'), findsOneWidget);
    expect(data.points, orderedEquals(original));
  });

  testWidgets('edits one bar and then applies properties to all bars', (
    tester,
  ) async {
    await tester.pumpWidget(buildEditor());
    await setFreeMode(tester, true);
    selectElement(
      tester,
      const ChartSelection(
        elementType: ChartElementType.dataElement,
        chartType: ChartType.bar,
        index: 1,
        category: 'Fevereiro',
        value: 5800,
      ),
    );
    await tester.pump();

    chooseContextColor(tester, 4);
    changeContextSize(tester, 30);
    await tester.pump();
    var rods = currentChart(
      tester,
    ).data.barGroups.map((group) => group.barRods.single).toList();
    expect(rods[0].color, const Color(0xFF171717));
    expect(rods[1].color, const Color(0xFFDC5A3A));
    expect(rods[1].width, 30);
    expect(rods[2].width, 20);

    applyContextToAll(tester);
    await tester.pump();
    chooseContextColor(tester, 1);
    changeContextSize(tester, 26);
    await tester.pump();
    rods = currentChart(
      tester,
    ).data.barGroups.map((group) => group.barRods.single).toList();
    expect(rods.map((rod) => rod.color), everyElement(const Color(0xFF2563EB)));
    expect(rods.map((rod) => rod.width), everyElement(26));
  });

  testWidgets('edits one label and all X axis labels', (tester) async {
    await tester.pumpWidget(buildEditor());
    await setFreeMode(tester, true);
    selectElement(
      tester,
      const ChartSelection(
        elementType: ChartElementType.xAxisLabel,
        chartType: ChartType.bar,
        index: 0,
        category: 'Janeiro',
        value: 4200,
      ),
    );
    await tester.pump();
    chooseContextColor(tester, 4);
    changeContextSize(tester, 14);
    await tester.pump();

    Text label(int index) => tester.widget<Text>(
      find.descendant(
        of: find.byKey(ValueKey('select-x-label-$index')),
        matching: find.byType(Text),
      ),
    );
    expect(label(0).style?.color, const Color(0xFFDC5A3A));
    expect(label(0).style?.fontSize, 14);
    expect(label(1).style?.color, const Color(0xFF777777));

    applyContextToAll(tester);
    await tester.pump();
    chooseContextColor(tester, 2);
    await tester.pump();
    expect(label(0).style?.color, const Color(0xFF0F766E));
    expect(label(1).style?.color, const Color(0xFF0F766E));
  });

  testWidgets('edits title size color weight and alignment', (tester) async {
    await tester.pumpWidget(buildEditor());
    await setFreeMode(tester, true);
    selectElement(
      tester,
      const ChartSelection(
        elementType: ChartElementType.title,
        chartType: ChartType.bar,
      ),
    );
    await tester.pump();
    chooseContextColor(tester, 4);
    changeContextSize(tester, 24);
    tester
        .widget<SegmentedButton<ChartFontWeight>>(
          find.byKey(const ValueKey('context-font-weight')),
        )
        .onSelectionChanged!({ChartFontWeight.bold});
    tester
        .widget<SegmentedButton<ChartTextAlignment>>(
          find.byKey(const ValueKey('context-alignment')),
        )
        .onSelectionChanged!({ChartTextAlignment.left});
    await tester.pump();

    final title = tester.widget<Text>(
      find.byKey(const ValueKey('chart-preview-title')),
    );
    expect(title.style?.color, const Color(0xFFDC5A3A));
    expect(title.style?.fontSize, 24);
    expect(title.style?.fontWeight, FontWeight.w700);
    expect(title.textAlign, TextAlign.left);
  });

  testWidgets('edits line points individually and globally', (tester) async {
    await tester.pumpWidget(buildEditor());
    await setFreeMode(tester, true);
    await selectType(tester, 'lines');
    selectElement(
      tester,
      const ChartSelection(
        elementType: ChartElementType.dataElement,
        chartType: ChartType.line,
        index: 1,
        category: 'Fevereiro',
        value: 5800,
      ),
    );
    await tester.pump();
    chooseContextColor(tester, 4);
    changeContextSize(tester, 8);
    await tester.pump();

    FlDotCirclePainter pointPainter(int index) {
      final line = tester
          .widget<LineChart>(find.byType(LineChart))
          .data
          .lineBarsData
          .single;
      return line.dotData.getDotPainter(line.spots[index], 1, line, index)
          as FlDotCirclePainter;
    }

    expect(pointPainter(0).radius, 4);
    expect(pointPainter(1).radius, 11);
    expect(pointPainter(1).color, const Color(0xFFDC5A3A));

    applyContextToAll(tester);
    await tester.pump();
    chooseContextColor(tester, 1);
    changeContextSize(tester, 6);
    await tester.pump();
    expect(pointPainter(0).color, const Color(0xFF2563EB));
    expect(pointPainter(2).color, const Color(0xFF2563EB));
  });

  testWidgets('edits a pie slice and one legend item', (tester) async {
    await tester.pumpWidget(buildEditor());
    await setFreeMode(tester, true);
    await selectType(tester, 'pie');
    selectElement(
      tester,
      const ChartSelection(
        elementType: ChartElementType.dataElement,
        chartType: ChartType.pie,
        index: 1,
        category: 'Fevereiro',
        value: 5800,
      ),
    );
    await tester.pump();
    chooseContextColor(tester, 4);
    changeContextSize(tester, 10);
    await tester.pump();
    var sections = tester.widget<PieChart>(find.byType(PieChart)).data.sections;
    expect(sections[0].color, const Color(0xFF2563EB));
    expect(sections[1].color, const Color(0xFFDC5A3A));
    expect(sections[1].radius, 79);

    selectElement(
      tester,
      const ChartSelection(
        elementType: ChartElementType.legendItem,
        chartType: ChartType.pie,
        index: 0,
        category: 'Janeiro',
        value: 4200,
      ),
    );
    await tester.pump();
    chooseContextColor(tester, 2);
    changeContextSize(tester, 16);
    await tester.pump();
    final legendText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('select-legend-0')),
        matching: find.text('Janeiro'),
      ),
    );
    expect(legendText.style?.color, const Color(0xFF0F766E));
    expect(legendText.style?.fontSize, 16);
    sections = tester.widget<PieChart>(find.byType(PieChart)).data.sections;
    expect(sections[1].color, const Color(0xFFDC5A3A));
  });

  testWidgets('preserves type-specific overrides while switching charts', (
    tester,
  ) async {
    await tester.pumpWidget(buildEditor());
    await setFreeMode(tester, true);
    selectElement(
      tester,
      const ChartSelection(
        elementType: ChartElementType.dataElement,
        chartType: ChartType.bar,
        index: 0,
        category: 'Janeiro',
        value: 4200,
      ),
    );
    await tester.pump();
    chooseContextColor(tester, 4);
    await tester.pump();

    await selectType(tester, 'lines');
    final line = tester
        .widget<LineChart>(find.byType(LineChart))
        .data
        .lineBarsData
        .single;
    final linePoint =
        line.dotData.getDotPainter(line.spots[0], 1, line, 0)
            as FlDotCirclePainter;
    expect(linePoint.color, const Color(0xFF171717));

    await selectType(tester, 'bars');
    expect(
      currentChart(tester).data.barGroups.first.barRods.single.color,
      const Color(0xFFDC5A3A),
    );
  });

  testWidgets('export keeps overrides and hides selection feedback', (
    tester,
  ) async {
    final captureCompleter = Completer<Uint8List>();
    final service = ChartExportService(
      capturePng: (_) => captureCompleter.future,
      savePng: (_, _) async => true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ChartEditorPage(data: data, exportService: service),
      ),
    );
    await expandOptions(tester);
    await tapOption(tester, 'show-values');
    await setFreeMode(tester, true);
    final xAxisTarget = find.byKey(const ValueKey('select-x-axis-line'));
    await tester.ensureVisible(xAxisTarget);
    await tester.tap(xAxisTarget);
    await tester.pump();
    chooseContextColor(tester, 1);
    changeContextSize(tester, 4);
    await tester.pump();
    selectElement(
      tester,
      const ChartSelection(
        elementType: ChartElementType.dataLabel,
        chartType: ChartType.bar,
        index: 0,
        category: 'Janeiro',
        value: 4200,
        text: '4200',
      ),
    );
    await tester.pump();
    chooseContextColor(tester, 4);
    await tester.pump();

    final export = find.byKey(const ValueKey('export-chart'));
    await tester.ensureVisible(export);
    await tester.tap(export);
    await tester.pump();

    final preview = tester.widget<BarChartPreview>(
      find.byType(BarChartPreview),
    );
    expect(preview.selection, isNull);
    final exportedLabel = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('select-data-label-0')),
        matching: find.text('4200'),
      ),
    );
    expect(exportedLabel.style?.color, const Color(0xFFDC5A3A));
    final labelContainer = tester.widget<Container>(
      find
          .descendant(
            of: find.byKey(const ValueKey('select-data-label-0')),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(labelContainer.decoration, isNull);
    final exportedBorder = currentChart(tester).data.borderData.border;
    expect(exportedBorder.bottom.color, const Color(0xFF2563EB));
    expect(exportedBorder.bottom.width, 4);

    await tester.runAsync(() async {
      captureCompleter.complete(Uint8List.fromList([137, 80, 78, 71]));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
  });

  testWidgets('edits one Y axis label and then all Y axis labels', (
    tester,
  ) async {
    await tester.pumpWidget(buildEditor());
    await setFreeMode(tester, true);
    selectElement(
      tester,
      const ChartSelection(
        elementType: ChartElementType.yAxisLabel,
        chartType: ChartType.bar,
        index: 1,
        value: 2000,
        text: '2.0k',
      ),
    );
    await tester.pump();
    chooseContextColor(tester, 4);
    changeContextSize(tester, 14);
    tester
        .widget<SegmentedButton<ChartFontWeight>>(
          find.byKey(const ValueKey('context-font-weight')),
        )
        .onSelectionChanged!({ChartFontWeight.bold});
    await tester.pump();

    Text yLabel(int index) => tester.widget<Text>(
      find.descendant(
        of: find.byKey(ValueKey('select-y-label-$index')),
        matching: find.byType(Text),
      ),
    );
    expect(yLabel(1).style?.color, const Color(0xFFDC5A3A));
    expect(yLabel(1).style?.fontSize, 14);
    expect(yLabel(1).style?.fontWeight, FontWeight.w700);
    expect(yLabel(0).style?.color, const Color(0xFF8A8A8A));

    applyContextToAll(tester);
    await tester.pump();
    chooseContextColor(tester, 2);
    await tester.pump();
    expect(yLabel(0).style?.color, const Color(0xFF0F766E));
    expect(yLabel(1).style?.color, const Color(0xFF0F766E));
  });

  testWidgets('edits one bar data label and all bar data labels', (
    tester,
  ) async {
    await tester.pumpWidget(buildEditor());
    await expandOptions(tester);
    await tapOption(tester, 'show-values');
    await setFreeMode(tester, true);
    selectElement(
      tester,
      const ChartSelection(
        elementType: ChartElementType.dataLabel,
        chartType: ChartType.bar,
        index: 1,
        category: 'Fevereiro',
        value: 5800,
        text: '5800',
      ),
    );
    await tester.pump();
    chooseContextColor(tester, 4);
    changeContextSize(tester, 16);
    await tester.pump();

    TextStyle dataLabelStyle(int index) {
      final chart = currentChart(tester).data;
      final group = chart.barGroups[index];
      return chart.barTouchData.touchTooltipData
          .getTooltipItem(group, index, group.barRods.single, 0)!
          .textStyle;
    }

    expect(dataLabelStyle(0).color, const Color(0xFF555555));
    expect(dataLabelStyle(1).color, const Color(0xFFDC5A3A));
    expect(dataLabelStyle(1).fontSize, 16);

    applyContextToAll(tester);
    await tester.pump();
    chooseContextColor(tester, 1);
    await tester.pump();
    expect(dataLabelStyle(0).color, const Color(0xFF2563EB));
    expect(dataLabelStyle(2).color, const Color(0xFF2563EB));
  });

  testWidgets('keeps data label overrides separate for line and pie', (
    tester,
  ) async {
    await tester.pumpWidget(buildEditor());
    await expandOptions(tester);
    await tapOption(tester, 'show-values');
    await setFreeMode(tester, true);

    await selectType(tester, 'lines');
    selectElement(
      tester,
      const ChartSelection(
        elementType: ChartElementType.dataLabel,
        chartType: ChartType.line,
        index: 0,
        category: 'Janeiro',
        value: 4200,
        text: '4200',
      ),
    );
    await tester.pump();
    chooseContextColor(tester, 4);
    await tester.pump();
    final lineChart = tester.widget<LineChart>(find.byType(LineChart)).data;
    final lineLabel = lineChart.lineTouchData.touchTooltipData.getTooltipItems([
      LineBarSpot(lineChart.lineBarsData.single, 0, const FlSpot(0, 4200)),
    ]).single;
    expect(lineLabel?.textStyle.color, const Color(0xFFDC5A3A));

    await selectType(tester, 'pie');
    var sections = tester.widget<PieChart>(find.byType(PieChart)).data.sections;
    expect(sections[0].titleStyle?.color, Colors.white);
    selectElement(
      tester,
      const ChartSelection(
        elementType: ChartElementType.dataLabel,
        chartType: ChartType.pie,
        index: 0,
        category: 'Janeiro',
        value: 4200,
        text: '28%',
      ),
    );
    await tester.pump();
    chooseContextColor(tester, 2);
    await tester.pump();
    sections = tester.widget<PieChart>(find.byType(PieChart)).data.sections;
    expect(sections[0].titleStyle?.color, const Color(0xFF0F766E));

    await selectType(tester, 'lines');
    final restoredLine = tester.widget<LineChart>(find.byType(LineChart)).data;
    final restoredLabel = restoredLine.lineTouchData.touchTooltipData
        .getTooltipItems([
          LineBarSpot(
            restoredLine.lineBarsData.single,
            0,
            const FlSpot(0, 4200),
          ),
        ])
        .single;
    expect(restoredLabel?.textStyle.color, const Color(0xFFDC5A3A));
  });

  testWidgets('data labels have real tap targets in bar line and pie', (
    tester,
  ) async {
    await tester.pumpWidget(buildEditor());
    await expandOptions(tester);
    await tapOption(tester, 'show-values');
    await setFreeMode(tester, true);

    Future<void> tapDataLabel(String expectedPanelLabel) async {
      final target = find.byKey(const ValueKey('select-data-label-0'));
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pump();
      expect(find.text(expectedPanelLabel), findsOneWidget);
      expect(find.text('Categoria: Janeiro'), findsOneWidget);
      expect(find.text('Valor: 4200'), findsOneWidget);
    }

    await tapDataLabel('Rótulo de dado selecionado');
    expect(
      tester
          .widget<BarChartPreview>(find.byType(BarChartPreview))
          .selection
          ?.elementType,
      ChartElementType.dataLabel,
    );

    await selectType(tester, 'lines');
    expect(find.byKey(const ValueKey('select-data-label-0')), findsOneWidget);
    await tapDataLabel('Rótulo de dado selecionado');
    expect(
      tester
          .widget<LineChartPreview>(find.byType(LineChartPreview))
          .selection
          ?.elementType,
      ChartElementType.dataLabel,
    );

    await selectType(tester, 'pie');
    await tapDataLabel('Rótulo de dado selecionado');
    expect(
      tester
          .widget<PieChartPreview>(find.byType(PieChartPreview))
          .selection
          ?.elementType,
      ChartElementType.dataLabel,
    );
  });

  testWidgets('line values are positioned widgets above the chart points', (
    tester,
  ) async {
    await tester.pumpWidget(buildEditor());
    await expandOptions(tester);
    await tapOption(tester, 'show-values');
    await selectType(tester, 'lines');

    expect(find.byKey(const ValueKey('select-data-label-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('select-data-label-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('select-data-label-2')), findsOneWidget);
    for (var index = 0; index < 3; index++) {
      final positioned = tester.widget<Positioned>(
        find.byKey(ValueKey('data-label-position-$index')),
      );
      expect(positioned.top, isNotNull);
      expect(positioned.height, 28);
    }
  });

  testWidgets('axis and grid lines are selectable and editable', (
    tester,
  ) async {
    await tester.pumpWidget(buildEditor());
    await setFreeMode(tester, true);

    final xAxis = find.byKey(const ValueKey('select-x-axis-line'));
    await tester.ensureVisible(xAxis);
    await tester.tap(xAxis);
    await tester.pump();
    expect(find.text('Linha do eixo X'), findsOneWidget);
    chooseContextColor(tester, 4);
    changeContextSize(tester, 4);
    await tester.pump();
    var border = currentChart(tester).data.borderData.border;
    expect(border.bottom.color, const Color(0xFFDC5A3A));
    expect(border.bottom.width, 5);

    final yAxis = find.byKey(const ValueKey('select-y-axis-line'));
    await tester.ensureVisible(yAxis);
    await tester.tap(yAxis);
    await tester.pump();
    expect(find.text('Linha do eixo Y'), findsOneWidget);
    chooseContextColor(tester, 2);
    changeContextSize(tester, 3);
    await tester.pump();
    border = currentChart(tester).data.borderData.border;
    expect(border.left.color, const Color(0xFF0F766E));
    expect(border.left.width, 4);

    final gridTargets = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> && key.value.startsWith('select-grid-');
    });
    expect(gridTargets, findsWidgets);
    final middleGrid = gridTargets.at(1);
    await tester.ensureVisible(middleGrid);
    await tester.tap(middleGrid);
    await tester.pump();
    expect(find.text('Linhas de grade'), findsOneWidget);
    chooseContextColor(tester, 1);
    changeContextSize(tester, 2);
    await tester.pump();
    final gridLine = currentChart(
      tester,
    ).data.gridData.getDrawingHorizontalLine(0);
    expect(gridLine.color, const Color(0xFF2563EB));
    expect(gridLine.strokeWidth, 2.75);
    tester
        .widget<Switch>(
          find.descendant(
            of: find.byKey(const ValueKey('context-visibility')),
            matching: find.byType(Switch),
          ),
        )
        .onChanged!(false);
    await tester.pump();
    expect(currentChart(tester).data.gridData.show, isFalse);
  });

  testWidgets('sorts categories without losing their values', (tester) async {
    const sortableData = ChartData(
      points: [
        ChartDataPoint(category: 'C', value: 30),
        ChartDataPoint(category: 'A', value: 10),
        ChartDataPoint(category: 'B', value: 20),
      ],
    );
    await tester.pumpWidget(
      const MaterialApp(home: ChartEditorPage(data: sortableData)),
    );
    await expandOptions(tester);

    var preview = tester.widget<BarChartPreview>(find.byType(BarChartPreview));
    expect(preview.data.points.map((point) => point.category), ['C', 'A', 'B']);

    await selectSortOrder(tester, ChartSortOrder.alphabeticalAsc);
    preview = tester.widget<BarChartPreview>(find.byType(BarChartPreview));
    expect(preview.data.points.map((point) => point.category), ['A', 'B', 'C']);
    expect(preview.data.points.map((point) => point.value), [10, 20, 30]);

    await selectSortOrder(tester, ChartSortOrder.valueDesc);
    preview = tester.widget<BarChartPreview>(find.byType(BarChartPreview));
    expect(preview.data.points.map((point) => point.category), ['C', 'B', 'A']);
    expect(preview.data.points.map((point) => point.value), [30, 20, 10]);
    expect(sortableData.points.map((point) => point.category), ['C', 'A', 'B']);
  });

  testWidgets('preserves sorting while switching among chart types', (
    tester,
  ) async {
    const sortableData = ChartData(
      points: [
        ChartDataPoint(category: 'C', value: 30),
        ChartDataPoint(category: 'A', value: 10),
        ChartDataPoint(category: 'B', value: 20),
      ],
    );
    await tester.pumpWidget(
      const MaterialApp(home: ChartEditorPage(data: sortableData)),
    );
    await expandOptions(tester);
    await selectSortOrder(tester, ChartSortOrder.valueAsc);

    await selectType(tester, 'lines');
    final line = tester.widget<LineChartPreview>(find.byType(LineChartPreview));
    expect(line.data.points.map((point) => point.category), ['A', 'B', 'C']);

    await selectType(tester, 'pie');
    final pie = tester.widget<PieChartPreview>(find.byType(PieChartPreview));
    expect(pie.data.points.map((point) => point.category), ['A', 'B', 'C']);
    expect(pie.data.points.map((point) => point.value), [10, 20, 30]);
  });

  testWidgets('returning to Dados leaves the original order intact', (
    tester,
  ) async {
    const source = ChartData(
      points: [
        ChartDataPoint(category: 'C', value: 30),
        ChartDataPoint(category: 'A', value: 10),
        ChartDataPoint(category: 'B', value: 20),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ChartEditorPage(data: source),
              ),
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await expandOptions(tester);
    await selectSortOrder(tester, ChartSortOrder.alphabeticalAsc);

    await tester.tap(find.byKey(const ValueKey('back-to-data')));
    await tester.pumpAndSettle();

    expect(source.points.map((point) => point.category), ['C', 'A', 'B']);
  });

  testWidgets('shows and hides the title', (tester) async {
    await tester.pumpWidget(buildEditor());
    await expandOptions(tester);

    await tapOption(tester, 'show-title');

    expect(find.byKey(const ValueKey('chart-preview-title')), findsNothing);
  });

  testWidgets('changes the title size', (tester) async {
    await tester.pumpWidget(buildEditor());
    await expandOptions(tester);

    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('title-size-slider')),
    );
    slider.onChanged!(28);
    await tester.pump();

    final title = tester.widget<Text>(
      find.byKey(const ValueKey('chart-preview-title')),
    );
    expect(title.style?.fontSize, 28);
  });

  testWidgets('uses the default bar width', (tester) async {
    await tester.pumpWidget(buildEditor());

    expect(const ChartTypeStyles().barWidth, 20);
    expect(currentChart(tester).data.barGroups.first.barRods.first.width, 20);
  });

  testWidgets('changes the bar width and updates the preview', (tester) async {
    await tester.pumpWidget(buildEditor());
    await expandOptions(tester);
    final sliderFinder = find.byKey(const ValueKey('bar-width-slider'));
    await tester.ensureVisible(sliderFinder);
    final slider = tester.widget<Slider>(sliderFinder);

    slider.onChanged!(30);
    await tester.pump();

    expect(currentChart(tester).data.barGroups.first.barRods.first.width, 30);
  });

  testWidgets('bar width slider exposes and applies its limits', (
    tester,
  ) async {
    await tester.pumpWidget(buildEditor());
    await expandOptions(tester);
    final sliderFinder = find.byKey(const ValueKey('bar-width-slider'));
    await tester.ensureVisible(sliderFinder);
    var slider = tester.widget<Slider>(sliderFinder);

    expect(slider.min, 8);
    expect(slider.max, 36);

    slider.onChanged!(8);
    await tester.pump();
    expect(currentChart(tester).data.barGroups.first.barRods.first.width, 8);

    slider = tester.widget<Slider>(sliderFinder);
    slider.onChanged!(36);
    await tester.pump();
    expect(currentChart(tester).data.barGroups.first.barRods.first.width, 36);
  });

  testWidgets('changes the primary color', (tester) async {
    await tester.pumpWidget(buildEditor());
    final color = find.byKey(const ValueKey('chart-color-1'));
    await tester.ensureVisible(color);
    await tester.tap(color);
    await tester.pump();

    expect(
      currentChart(tester).data.barGroups.first.barRods.first.color,
      const Color(0xFF2563EB),
    );
  });

  testWidgets('shows and hides bar values', (tester) async {
    await tester.pumpWidget(buildEditor());
    await expandOptions(tester);

    expect(find.byKey(const ValueKey('select-data-label-0')), findsNothing);
    await tapOption(tester, 'show-values');
    expect(find.byKey(const ValueKey('select-data-label-0')), findsOneWidget);
  });

  testWidgets('shows and hides the grid', (tester) async {
    await tester.pumpWidget(buildEditor());
    await expandOptions(tester);

    expect(currentChart(tester).data.gridData.show, isTrue);
    await tapOption(tester, 'show-grid');
    expect(currentChart(tester).data.gridData.show, isFalse);
  });

  testWidgets('shows and hides the X axis', (tester) async {
    await tester.pumpWidget(buildEditor());
    await expandOptions(tester);

    expect(
      currentChart(tester).data.titlesData.bottomTitles.sideTitles.showTitles,
      isTrue,
    );
    await tapOption(tester, 'show-x-axis');
    expect(
      currentChart(tester).data.titlesData.bottomTitles.sideTitles.showTitles,
      isFalse,
    );
  });

  testWidgets('shows and hides the Y axis', (tester) async {
    await tester.pumpWidget(buildEditor());
    await expandOptions(tester);

    expect(
      currentChart(tester).data.titlesData.leftTitles.sideTitles.showTitles,
      isTrue,
    );
    await tapOption(tester, 'show-y-axis');
    expect(
      currentChart(tester).data.titlesData.leftTitles.sideTitles.showTitles,
      isFalse,
    );
  });

  testWidgets('long labels wrap to at most two lines', (tester) async {
    const longLabel = 'Região Metropolitana de São Paulo';
    const longData = ChartData(
      points: [ChartDataPoint(category: longLabel, value: 100)],
    );
    await tester.pumpWidget(
      const MaterialApp(home: ChartEditorPage(data: longData)),
    );
    await tester.pumpAndSettle();

    final label = tester.widget<Text>(find.text(longLabel));
    expect(label.maxLines, 2);
    expect(label.overflow, TextOverflow.ellipsis);
  });

  testWidgets('many categories use horizontal scrolling in the preview', (
    tester,
  ) async {
    final manyPoints = List.generate(
      12,
      (index) => ChartDataPoint(category: 'Categoria ${index + 1}', value: 10),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ChartEditorPage(data: ChartData(points: manyPoints)),
      ),
    );
    await tester.pumpAndSettle();

    final scroll = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey('chart-horizontal-scroll')),
    );
    expect(scroll.scrollDirection, Axis.horizontal);
    expect(
      tester.getSize(find.byType(BarChart)).width,
      greaterThan(
        tester.getSize(find.byKey(const ValueKey('bar-chart-preview'))).width,
      ),
    );
  });

  testWidgets('starts with bars selected and enables all chart types', (
    tester,
  ) async {
    await tester.pumpWidget(buildEditor());

    final bars = tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byKey(const ValueKey('chart-type-bars')),
        matching: find.byType(OutlinedButton),
      ),
    );
    final lines = tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byKey(const ValueKey('chart-type-lines')),
        matching: find.byType(OutlinedButton),
      ),
    );
    final pie = tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byKey(const ValueKey('chart-type-pie')),
        matching: find.byType(OutlinedButton),
      ),
    );

    expect(bars.onPressed, isNotNull);
    expect(lines.onPressed, isNotNull);
    expect(pie.onPressed, isNotNull);
    expect(find.byKey(const ValueKey('bar-chart-preview')), findsOneWidget);
  });

  testWidgets(
    'switches between bars, lines and pie preserving data and title',
    (tester) async {
      await tester.pumpWidget(buildEditor());
      await tester.enterText(
        find.byKey(const ValueKey('chart-title-field')),
        'Vendas anuais',
      );

      await selectType(tester, 'lines');
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('Vendas anuais'), findsNWidgets(2));
      expect(find.text('Janeiro'), findsOneWidget);

      await selectType(tester, 'pie');
      expect(find.byType(PieChart), findsOneWidget);
      expect(find.text('Vendas anuais'), findsNWidgets(2));
      expect(find.text('Janeiro'), findsOneWidget);

      await selectType(tester, 'bars');
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.text('Vendas anuais'), findsNWidgets(2));
      expect(find.text('Janeiro'), findsOneWidget);
    },
  );

  testWidgets('line chart renders valid values', (tester) async {
    await tester.pumpWidget(buildEditor());
    await selectType(tester, 'lines');

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(
      chart.data.lineBarsData.single.spots.map((spot) => spot.y).toList(),
      [4200, 5800, 5100],
    );
  });

  testWidgets('pie chart renders proportional valid values', (tester) async {
    await tester.pumpWidget(buildEditor());
    await selectType(tester, 'pie');

    final chart = tester.widget<PieChart>(find.byType(PieChart));
    expect(chart.data.sections.map((section) => section.value).toList(), [
      4200,
      5800,
      5100,
    ]);
  });

  testWidgets('line width updates immediately', (tester) async {
    await tester.pumpWidget(buildEditor());
    await selectType(tester, 'lines');
    await expandOptions(tester);
    final sliderFinder = find.byKey(const ValueKey('line-width-slider'));
    await tester.ensureVisible(sliderFinder);
    final slider = tester.widget<Slider>(sliderFinder);

    slider.onChanged!(7);
    await tester.pump();

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.single.barWidth, 7);
  });

  testWidgets('pie hole size updates immediately', (tester) async {
    await tester.pumpWidget(buildEditor());
    await selectType(tester, 'pie');
    await expandOptions(tester);
    final sliderFinder = find.byKey(const ValueKey('pie-hole-slider'));
    await tester.ensureVisible(sliderFinder);
    final slider = tester.widget<Slider>(sliderFinder);

    slider.onChanged!(70);
    await tester.pump();

    final chart = tester.widget<PieChart>(find.byType(PieChart));
    expect(chart.data.centerSpaceRadius, closeTo(43.4, 0.01));
  });

  testWidgets('shows only controls relevant to the selected type', (
    tester,
  ) async {
    await tester.pumpWidget(buildEditor());
    await expandOptions(tester);
    expect(find.byKey(const ValueKey('bar-width-slider')), findsOneWidget);
    expect(find.byKey(const ValueKey('line-width-slider')), findsNothing);
    expect(find.byKey(const ValueKey('pie-hole-slider')), findsNothing);

    await selectType(tester, 'lines');
    expect(find.byKey(const ValueKey('bar-width-slider')), findsNothing);
    expect(find.byKey(const ValueKey('line-width-slider')), findsOneWidget);
    expect(find.byKey(const ValueKey('show-grid')), findsOneWidget);

    await selectType(tester, 'pie');
    expect(find.byKey(const ValueKey('line-width-slider')), findsNothing);
    expect(find.byKey(const ValueKey('pie-hole-slider')), findsOneWidget);
    expect(find.byKey(const ValueKey('show-grid')), findsNothing);
    expect(find.byKey(const ValueKey('show-x-axis')), findsNothing);
    expect(find.byKey(const ValueKey('show-y-axis')), findsNothing);
  });

  testWidgets('invalid pie values show a message without crashing', (
    tester,
  ) async {
    const invalidData = ChartData(
      points: [
        ChartDataPoint(category: 'A', value: 10),
        ChartDataPoint(category: 'B', value: 0),
        ChartDataPoint(category: 'C', value: -5),
      ],
    );
    await tester.pumpWidget(
      const MaterialApp(home: ChartEditorPage(data: invalidData)),
    );
    await selectType(tester, 'pie');

    expect(find.byKey(const ValueKey('invalid-pie-data')), findsOneWidget);
    expect(find.byType(PieChart), findsNothing);
  });

  testWidgets('returns to data when tapping Dados', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ChartEditorPage(data: data),
                ),
              ),
              child: const Text('Abrir gráfico'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir gráfico'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('back-to-data')));
    await tester.pumpAndSettle();

    expect(find.text('Abrir gráfico'), findsOneWidget);
    expect(find.byType(ChartEditorPage), findsNothing);
  });
}
