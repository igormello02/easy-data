import 'dart:io';
import 'dart:typed_data';

import 'package:easy_data/features/data_import/excel_table_parser.dart';
import 'package:easy_data/features/data_import/table_import_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = ExcelTableParser();

  test('opens and extracts data from the real XLSX fixture', () async {
    final bytes = File('test/fixtures/import_workbook.xlsx').readAsBytesSync();

    final workbook = await parser.openWorkbook(bytes);
    expect(
      workbook.sheets.map((sheet) => sheet.name),
      containsAllInOrder(['Resumo', 'Vendas']),
    );

    final vendas = workbook.sheets.singleWhere(
      (sheet) => sheet.name == 'Vendas',
    );
    final imported = parser.parseSheet(vendas);
    expect(imported.columns, ['Categoria', 'Valor']);
    expect(imported.rows, [
      ['Janeiro', '10'],
      ['Fevereiro', '20'],
    ]);
  });

  test('opens a Strict Open XML workbook saved by Microsoft Excel', () async {
    final bytes = File(
      'test/fixtures/microsoft_excel_strict_workbook.xlsx',
    ).readAsBytesSync();

    final workbook = await parser.openWorkbook(bytes);

    expect(
      workbook.sheets.map((sheet) => sheet.name),
      containsAll(['Resumo', 'Vendas']),
    );
  });

  test(
    'discovers and imports a formatted four-sheet Microsoft Excel file',
    () async {
      final bytes = File(
        'test/fixtures/microsoft_excel_four_sheets.xlsx',
      ).readAsBytesSync();

      final workbook = await parser.openWorkbook(bytes);
      expect(workbook.sheets.map((sheet) => sheet.name), [
        'Resumo',
        'Vendas',
        'Regioes',
        'Historico',
      ]);

      final imported = parser.parseSheet(
        workbook.sheets.singleWhere((sheet) => sheet.name == 'Vendas'),
      );
      expect(imported.columns, ['Categoria', 'Descricao', 'Valor']);
      expect(imported.rows, [
        ['São Paulo', 'Região Sudeste', '120'],
        ['Curitiba', 'Produção agrícola', '75.5'],
        ['Évora', 'Unicode', '50'],
      ]);
    },
  );

  test('parses the selected sheet instead of assuming the first', () async {
    final bytes = File(
      'test/fixtures/microsoft_excel_four_sheets.xlsx',
    ).readAsBytesSync();
    final workbook = await parser.openWorkbook(bytes);

    final table = parser.parseSheet(
      workbook.sheets.singleWhere((sheet) => sheet.name == 'Vendas'),
    );

    expect(table.columns, ['Categoria', 'Descricao', 'Valor']);
    expect(table.rows, isNotEmpty);
  });

  test('removes empty rows and generates names for empty headers', () {
    const sheet = ExcelSheetData(
      name: 'Dados',
      rows: [
        ['Cidade', '', 'Valor'],
        ['', '', ''],
        ['Évora', 'Ação', '50'],
      ],
    );

    final table = parser.parseSheet(sheet);

    expect(table.columns, ['Cidade', 'Coluna 2', 'Valor']);
    expect(table.rows.single, ['Évora', 'Ação', '50']);
  });

  test('reports an empty selected sheet', () {
    expect(
      () => parser.parseSheet(const ExcelSheetData(name: 'Vazia', rows: [])),
      throwsA(
        isA<TableImportException>().having(
          (error) => error.message,
          'message',
          ExcelTableParser.emptySheetMessage,
        ),
      ),
    );
  });

  test('imports the exact Easy Data Excel regression fixture', () async {
    final bytes = File(
      'test/fixtures/easy_data_testes_excel.xlsx',
    ).readAsBytesSync();

    final workbook = await parser.openWorkbook(bytes);

    expect(workbook.sheets.map((sheet) => sheet.name), [
      'Teste_Simples',
      'Acentos_Nomes_Longos',
      'Decimais_Muitas_Categorias',
      'Clipboard_Textos',
    ]);

    final imported = parser.parseSheet(
      workbook.sheets.singleWhere((sheet) => sheet.name == 'Teste_Simples'),
    );
    expect(imported.columns, ['Categoria', 'Valor']);
    expect(imported.rows.take(2), [
      ['Janeiro', '4200'],
      ['Fevereiro', '5800'],
    ]);
  });

  test('reports unreadable XLSX bytes', () async {
    await expectLater(
      parser.openWorkbook(Uint8List.fromList([1, 2, 3])),
      throwsA(
        isA<TableImportException>().having(
          (error) => error.message,
          'message',
          ExcelTableParser.couldNotReadFileMessage,
        ),
      ),
    );
  });
}
