import 'dart:convert';
import 'dart:typed_data';

import 'package:easy_data/features/data_import/table_import_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = TableImportParser();

  group('clipboard', () {
    test('parses a tabular clipboard', () {
      final table = parser.parseClipboard('Categoria\tValor\r\nA\t10\r\nB\t20');

      expect(table.columns, ['Categoria', 'Valor']);
      expect(table.rows, [
        ['A', '10'],
        ['B', '20'],
      ]);
    });

    test('preserves Unicode and decimal comma', () {
      final table = parser.parseClipboard(
        'Cidade\tPreço médio\nSão Paulo\t120,50\nMogi das Cruzes\t95,30',
      );

      expect(table.columns, ['Cidade', 'Preço médio']);
      expect(table.rows.first, ['São Paulo', '120,50']);
    });

    test('rejects empty and single-cell clipboards', () {
      expect(
        () => parser.parseClipboard(null),
        throwsA(isA<TableImportException>()),
      );
      expect(
        () => parser.parseClipboard('Apenas texto'),
        throwsA(isA<TableImportException>()),
      );
    });

    test('rejects rows with an inconsistent number of columns', () {
      expect(
        () => parser.parseClipboard('A\tB\n1\t2\n3'),
        throwsA(isA<TableImportException>()),
      );
    });
  });

  group('CSV', () {
    Uint8List bytes(String value) => Uint8List.fromList(utf8.encode(value));

    test('detects comma delimiter', () {
      final table = parser.parseCsvBytes(bytes('Categoria,Valor\nA,10\nB,20'));
      expect(table.columns, ['Categoria', 'Valor']);
      expect(table.rows.last, ['B', '20']);
    });

    test('detects semicolon delimiter', () {
      final table = parser.parseCsvBytes(bytes('Categoria;Valor\nA;10\nB;20'));
      expect(table.columns, ['Categoria', 'Valor']);
      expect(table.rows.first, ['A', '10']);
    });

    test('supports quotes and separators inside fields', () {
      final table = parser.parseCsvBytes(
        bytes('Cidade;Descrição;Valor\n"São Paulo";"Região, Sudeste";120'),
      );
      expect(table.rows.single, ['São Paulo', 'Região, Sudeste', '120']);
    });

    test('supports quoted line breaks', () {
      final table = parser.parseCsvBytes(
        bytes('Categoria,Descrição\nA,"Linha 1\nLinha 2"'),
      );
      expect(table.rows.single, ['A', 'Linha 1\nLinha 2']);
    });

    test('removes UTF-8 BOM and preserves Unicode', () {
      final table = parser.parseCsvBytes(
        bytes('\uFEFFCategoria;Descrição\nAção;Produção agrícola'),
      );
      expect(table.columns, ['Categoria', 'Descrição']);
      expect(table.rows.single, ['Ação', 'Produção agrícola']);
    });

    test('rejects invalid UTF-8 and non-tabular CSV', () {
      expect(
        () => parser.parseCsvBytes(Uint8List.fromList([0xC3, 0x28])),
        throwsA(isA<TableImportException>()),
      );
      expect(
        () => parser.parseCsvBytes(bytes('apenas uma célula')),
        throwsA(isA<TableImportException>()),
      );
    });
  });
}
