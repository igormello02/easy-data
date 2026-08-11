import 'package:easy_data/features/data_editor/data_editor_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildEditor() {
    return const MaterialApp(home: DataEditorPage());
  }

  testWidgets('edits a cell directly', (tester) async {
    await tester.pumpWidget(buildEditor());

    await tester.enterText(find.byKey(const ValueKey('cell-0-0')), 'Janeiro');

    expect(find.text('Janeiro'), findsOneWidget);
  });

  testWidgets('edits a column name', (tester) async {
    await tester.pumpWidget(buildEditor());

    await tester.enterText(find.byKey(const ValueKey('header-0')), 'Produto');

    expect(find.text('Produto'), findsOneWidget);
  });

  testWidgets('preserves Portuguese Unicode in headers and text cells', (
    tester,
  ) async {
    await tester.pumpWidget(buildEditor());
    await tester.tap(find.byKey(const ValueKey('add-column')));
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey('header-0')),
      'Preço médio',
    );
    await tester.enterText(
      find.byKey(const ValueKey('header-2')),
      'Variação (%)',
    );
    await tester.enterText(find.byKey(const ValueKey('cell-0-0')), 'São Paulo');
    await tester.enterText(find.byKey(const ValueKey('cell-0-1')), '42');
    await tester.enterText(find.byKey(const ValueKey('cell-0-2')), 'Produção');

    await tester.tap(find.byKey(const ValueKey('generate-chart')));
    await tester.pumpAndSettle();

    expect(find.text('Preço médio'), findsOneWidget);
    expect(find.text('Variação (%)'), findsOneWidget);
    expect(find.text('São Paulo'), findsOneWidget);
    expect(find.text('Produção'), findsOneWidget);
  });

  testWidgets('requests a Brazilian Portuguese IME for text fields', (
    tester,
  ) async {
    await tester.pumpWidget(buildEditor());

    TextField innerTextField(String key) {
      return tester.widget<TextField>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(TextField),
        ),
      );
    }

    final header = innerTextField('header-0');
    final category = innerTextField('cell-0-0');
    final value = innerTextField('cell-0-1');

    expect(header.hintLocales, const [Locale('pt', 'BR')]);
    expect(category.hintLocales, const [Locale('pt', 'BR')]);
    expect(value.hintLocales, isNull);
  });

  testWidgets('adds a row', (tester) async {
    await tester.pumpWidget(buildEditor());

    await tester.tap(find.byKey(const ValueKey('add-row')));
    await tester.pump();

    expect(find.byKey(const ValueKey('cell-1-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('cell-1-1')), findsOneWidget);
  });

  testWidgets('removes a row', (tester) async {
    await tester.pumpWidget(buildEditor());
    await tester.tap(find.byKey(const ValueKey('add-row')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('remove-row-0')));
    await tester.pump();

    expect(find.byKey(const ValueKey('cell-0-0')), findsNothing);
    expect(find.byKey(const ValueKey('cell-1-0')), findsOneWidget);
  });

  testWidgets('adds a column', (tester) async {
    await tester.pumpWidget(buildEditor());

    await tester.tap(find.byKey(const ValueKey('add-column')));
    await tester.pump();

    expect(find.byKey(const ValueKey('header-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('cell-0-2')), findsOneWidget);
  });

  testWidgets('removes a column while preserving the minimum', (tester) async {
    await tester.pumpWidget(buildEditor());
    await tester.tap(find.byKey(const ValueKey('add-column')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('remove-column-2')));
    await tester.pump();

    expect(find.byKey(const ValueKey('header-2')), findsNothing);
    expect(find.byKey(const ValueKey('header-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('header-1')), findsOneWidget);
  });

  testWidgets('shows a message for invalid data', (tester) async {
    await tester.pumpWidget(buildEditor());

    await tester.tap(find.byKey(const ValueKey('generate-chart')));
    await tester.pump();

    expect(
      find.text('Preencha Categoria e Valor em todas as linhas.'),
      findsOneWidget,
    );
  });

  testWidgets('rejects a non-numeric value', (tester) async {
    await tester.pumpWidget(buildEditor());
    await tester.enterText(find.byKey(const ValueKey('cell-0-0')), 'Janeiro');
    await tester.enterText(
      find.byKey(const ValueKey('cell-0-1')),
      'quatro mil',
    );

    await tester.tap(find.byKey(const ValueKey('generate-chart')));
    await tester.pump();

    expect(find.text('Use apenas números na coluna Valor.'), findsOneWidget);
  });

  testWidgets('navigates and passes valid data to the chart editor', (
    tester,
  ) async {
    await tester.pumpWidget(buildEditor());
    await tester.enterText(find.byKey(const ValueKey('cell-0-0')), 'Janeiro');
    await tester.enterText(find.byKey(const ValueKey('cell-0-1')), '4200');

    await tester.tap(find.byKey(const ValueKey('generate-chart')));
    await tester.pumpAndSettle();

    expect(find.text('Gráfico'), findsOneWidget);
    expect(find.text('Dados recebidos'), findsOneWidget);
    expect(find.text('1 linha(s) • 2 coluna(s)'), findsOneWidget);
    expect(find.text('Janeiro'), findsOneWidget);
    expect(find.text('4200'), findsOneWidget);
  });
}
