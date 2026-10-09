import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:easy_data/features/data_editor/data_editor_page.dart';
import 'package:easy_data/features/data_import/data_import_services.dart';
import 'package:easy_data/features/data_import/excel_table_parser.dart';
import 'package:easy_data/features/home/widgets/data_source_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCsvPicker implements CsvFilePicker {
  _FakeCsvPicker(this.value);
  final Uint8List? value;
  @override
  Future<Uint8List?> pickBytes() async => value;
}

class _FakeExcelPicker implements ExcelFilePicker {
  _FakeExcelPicker(this.value);
  final PickedLocalFile? value;
  @override
  Future<PickedLocalFile?> pickFile() async => value;
}

class _WorkbookWithEmptySheetParser extends ExcelTableParser {
  const _WorkbookWithEmptySheetParser();

  @override
  Future<ExcelWorkbookData> openWorkbook(Uint8List bytes) async {
    return const ExcelWorkbookData(
      sheets: [
        ExcelSheetData(name: 'Vazia', rows: []),
        ExcelSheetData(
          name: 'Produção',
          rows: [
            ['Categoria', 'Valor'],
            ['Ação', '10'],
          ],
        ),
      ],
    );
  }
}

void main() {
  final realWorkbookBytes = File(
    'test/fixtures/microsoft_excel_four_sheets.xlsx',
  ).readAsBytesSync();

  Widget buildSheet({
    Uint8List? excelBytes,
    Uint8List? csvBytes,
    ExcelTableParser excelParser = const ExcelTableParser(),
  }) {
    return MaterialApp(
      home: Scaffold(
        body: DataSourceBottomSheet(
          excelFilePicker: _FakeExcelPicker(
            excelBytes == null
                ? null
                : PickedLocalFile(
                    name: 'dados.xlsx',
                    extension: 'xlsx',
                    bytes: excelBytes,
                  ),
          ),
          excelParser: excelParser,
          csvFilePicker: _FakeCsvPicker(csvBytes),
        ),
      ),
    );
  }

  testWidgets('Excel data reaches the editable data editor', (tester) async {
    await tester.pumpWidget(buildSheet(excelBytes: realWorkbookBytes));
    await tester.tap(find.text('Importar Excel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('excel-sheet-Vendas')));
    await tester.pumpAndSettle();

    expect(find.byType(DataEditorPage), findsOneWidget);
    expect(find.text('São Paulo'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
  });

  testWidgets('canceling the Excel picker does not show an error', (
    tester,
  ) async {
    await tester.pumpWidget(buildSheet());
    await tester.tap(find.text('Importar Excel'));
    await tester.pump();

    expect(find.text('Como deseja inserir os dados?'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('lists all worksheets and imports the selected sheet', (
    tester,
  ) async {
    await tester.pumpWidget(buildSheet(excelBytes: realWorkbookBytes));

    await tester.tap(find.text('Importar Excel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Selecionar planilha'), findsOneWidget);
    expect(find.text('Resumo'), findsOneWidget);
    expect(find.text('Vendas'), findsOneWidget);
    expect(find.text('Regioes'), findsOneWidget);
    expect(find.text('Historico'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('excel-sheet-Vendas')));
    await tester.pumpAndSettle();

    expect(find.byType(DataEditorPage), findsOneWidget);
    expect(find.text('São Paulo'), findsOneWidget);
    expect(find.text('Curitiba'), findsOneWidget);
  });

  testWidgets('shows the specific message for an empty selected worksheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSheet(
        excelBytes: Uint8List.fromList([0x50, 0x4B, 0x03, 0x04]),
        excelParser: const _WorkbookWithEmptySheetParser(),
      ),
    );

    await tester.tap(find.text('Importar Excel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('excel-sheet-Vazia')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Esta planilha não contém dados para importar.'),
      findsOneWidget,
    );
  });

  testWidgets('invalid Excel shows a clear message', (tester) async {
    await tester.pumpWidget(
      buildSheet(excelBytes: Uint8List.fromList([1, 2, 3])),
    );
    await tester.tap(find.text('Importar Excel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Não foi possível ler este arquivo do Excel.'),
      findsOneWidget,
    );
  });

  testWidgets('CSV data reaches the same editable data editor', (tester) async {
    await tester.pumpWidget(
      buildSheet(
        csvBytes: Uint8List.fromList(utf8.encode('Categoria;Valor\nAção;30')),
      ),
    );
    await tester.tap(find.text('Importar CSV'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(DataEditorPage), findsOneWidget);
    expect(find.text('Ação'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
  });

  testWidgets('canceling the CSV picker does not show an error', (
    tester,
  ) async {
    await tester.pumpWidget(buildSheet());
    await tester.tap(find.text('Importar CSV'));
    await tester.pump();

    expect(find.text('Como deseja inserir os dados?'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('invalid CSV shows a clear message', (tester) async {
    await tester.pumpWidget(
      buildSheet(csvBytes: Uint8List.fromList(utf8.encode('texto'))),
    );
    await tester.tap(find.text('Importar CSV'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Não encontramos uma tabela válida no arquivo CSV.'),
      findsOneWidget,
    );
  });
}
