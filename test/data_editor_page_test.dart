import 'package:easy_data/features/data_editor/data_editor_page.dart';
import 'package:easy_data/features/chart_editor/chart_editor_page.dart';
import 'package:easy_data/features/data_editor/models/data_table_model.dart';
import 'package:easy_data/features/data_import/data_import_services.dart';
import 'package:easy_data/features/data_import/models/imported_table_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeClipboard implements ClipboardReader {
  _FakeClipboard(this.value);

  final String? value;

  @override
  Future<String?> readText() async => value;
}

void main() {
  Widget buildEditor() {
    return const MaterialApp(home: DataEditorPage());
  }

  testWidgets('edits a cell directly', (tester) async {
    await tester.pumpWidget(buildEditor());

    await tester.enterText(find.byKey(const ValueKey('cell-0-0')), 'Janeiro');

    expect(find.text('Janeiro'), findsOneWidget);
  });

  testWidgets('pastes a valid clipboard table into the empty editor', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DataEditorPage(
          clipboardReader: _FakeClipboard(
            'Categoria\tValor\nJaneiro\t10\nFevereiro\t20',
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('paste-data')));
    await tester.pumpAndSettle();

    expect(find.text('Janeiro'), findsOneWidget);
    expect(find.text('Fevereiro'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('Substituir dados?'), findsNothing);
  });

  testWidgets('shows a message for an invalid clipboard in the editor', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DataEditorPage(clipboardReader: _FakeClipboard('texto')),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('paste-data')));
    await tester.pump();

    expect(
      find.text('Não encontramos uma tabela válida na área de transferência.'),
      findsOneWidget,
    );
  });

  testWidgets('confirms before replacing existing data from clipboard', (
    tester,
  ) async {
    final table = DataTableModel.fromImported(
      const ImportedTableData(
        columns: ['Cidade', 'Valor'],
        rows: [
          ['Curitiba', '90'],
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DataEditorPage(
          initialTable: table,
          clipboardReader: _FakeClipboard('Cidade\tValor\nÉvora\t50'),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('paste-data')));
    await tester.pumpAndSettle();
    expect(
      find.text('Isso substituirá os dados atuais. Continuar?'),
      findsOneWidget,
    );
    expect(find.text('Curitiba'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('confirm-paste-data')));
    await tester.pumpAndSettle();

    expect(find.text('Curitiba'), findsNothing);
    expect(find.text('Évora'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
  });

  testWidgets('receives imported columns and rows and keeps them editable', (
    tester,
  ) async {
    final table = DataTableModel.fromImported(
      const ImportedTableData(
        columns: ['Cidade', 'Valor'],
        rows: [
          ['São Paulo', '120'],
          ['Curitiba', '90'],
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: DataEditorPage(initialTable: table)),
    );

    expect(find.text('Cidade'), findsOneWidget);
    expect(find.text('São Paulo'), findsOneWidget);
    expect(find.text('Curitiba'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('cell-0-0')), 'Santos');
    expect(find.text('Santos'), findsOneWidget);
  });

  testWidgets(
    'uses the selected value column when imported text exists in the middle',
    (tester) async {
      final table = DataTableModel.fromImported(
        const ImportedTableData(
          columns: ['Cidade', 'Descrição', 'Valor'],
          rows: [
            ['São Paulo', 'Região Sudeste', '120'],
            ['Rio de Janeiro', 'Capital, RJ', '90'],
          ],
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: DataEditorPage(initialTable: table)),
      );

      expect(
        find.byKey(const ValueKey('category-column-selector')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('value-column-selector')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('generate-chart')));
      await tester.pumpAndSettle();

      expect(find.text('Use apenas números na coluna Valor.'), findsNothing);
      final editor = tester.widget<ChartEditorPage>(
        find.byType(ChartEditorPage),
      );
      expect(editor.data.points.map((point) => point.category), [
        'São Paulo',
        'Rio de Janeiro',
      ]);
      expect(editor.data.points.map((point) => point.value), [120, 90]);
    },
  );

  testWidgets('allows choosing category and value columns explicitly', (
    tester,
  ) async {
    final table = DataTableModel.fromImported(
      const ImportedTableData(
        columns: ['Cidade', 'População', 'Índice'],
        rows: [
          ['São Paulo', '120', '8'],
          ['Curitiba', '90', '6'],
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: DataEditorPage(initialTable: table)),
    );

    await tester.tap(find.byKey(const ValueKey('value-column-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('População').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('generate-chart')));
    await tester.pumpAndSettle();

    final editor = tester.widget<ChartEditorPage>(find.byType(ChartEditorPage));
    expect(editor.data.points.map((point) => point.value), [120, 90]);
  });

  testWidgets('multiple columns scroll horizontally to the last full column', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final table = DataTableModel.fromImported(
      const ImportedTableData(
        columns: [
          'Cidade com nome longo',
          'Descrição detalhada',
          'Região metropolitana',
          'Observações adicionais',
          'Valor',
        ],
        rows: [
          [
            'Mogi das Cruzes',
            'Região Metropolitana',
            'Sudeste',
            'Texto maior para edição',
            '67',
          ],
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: DataEditorPage(initialTable: table)),
    );

    final scroll = find.byKey(const ValueKey('table-horizontal-scroll'));
    final content = find.byKey(const ValueKey('editable-table-content'));
    final lastCell = find.byKey(const ValueKey('cell-0-4'));
    expect(scroll, findsOneWidget);
    expect(tester.getSize(content).width, greaterThan(360));
    expect(tester.getRect(lastCell).left, greaterThan(360));

    final controller = tester.widget<SingleChildScrollView>(scroll).controller!;
    expect(controller.position.maxScrollExtent, greaterThan(0));
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();

    final visibleRect = tester.getRect(lastCell);
    expect(visibleRect.left, greaterThanOrEqualTo(0));
    expect(visibleRect.right, lessThanOrEqualTo(360));
    expect(tester.takeException(), isNull);
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
    final editor = tester.widget<ChartEditorPage>(find.byType(ChartEditorPage));
    expect(editor.data.points, hasLength(1));
    expect(editor.data.points.single.category, 'Janeiro');
    expect(editor.data.points.single.value, 4200);
    expect(find.text('Janeiro'), findsOneWidget);
  });
}
