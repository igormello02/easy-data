import 'package:easy_data/features/chart_editor/chart_editor_page.dart';
import 'package:easy_data/features/chart_editor/models/chart_data.dart';
import 'package:easy_data/features/chart_editor/models/chart_type_styles.dart';
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

    expect(
      currentChart(tester).data.barGroups.first.showingTooltipIndicators,
      isEmpty,
    );
    await tapOption(tester, 'show-values');
    expect(currentChart(tester).data.barGroups.first.showingTooltipIndicators, [
      0,
    ]);
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
