import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

import 'models/imported_table_data.dart';

class TableImportException implements Exception {
  const TableImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TableImportParser {
  const TableImportParser();

  ImportedTableData parseClipboard(String? content) {
    final normalized = _normalizeText(content);
    if (normalized == null || !normalized.contains('\t')) {
      throw const TableImportException(_invalidClipboardMessage);
    }
    try {
      return _toTable(
        Csv(fieldDelimiter: '\t').decode(normalized),
        invalidMessage: _invalidClipboardMessage,
      );
    } on TableImportException {
      rethrow;
    } on Object {
      throw const TableImportException(_invalidClipboardMessage);
    }
  }

  ImportedTableData parseCsvBytes(Uint8List bytes) {
    late final String content;
    try {
      content = utf8.decode(bytes);
    } on FormatException {
      throw const TableImportException(
        'Não foi possível ler o CSV. Use um arquivo codificado em UTF-8.',
      );
    }
    final normalized = _normalizeText(content);
    if (normalized == null) {
      throw const TableImportException('O arquivo CSV está vazio.');
    }
    try {
      return _toTable(
        csv.decode(normalized),
        invalidMessage: 'Não encontramos uma tabela válida no arquivo CSV.',
      );
    } on TableImportException {
      rethrow;
    } on Object {
      throw const TableImportException(
        'Não encontramos uma tabela válida no arquivo CSV.',
      );
    }
  }

  ImportedTableData _toTable(
    List<List<dynamic>> decoded, {
    required String invalidMessage,
  }) {
    final rows = decoded
        .map(
          (row) => row.map((value) => value?.toString().trim() ?? '').toList(),
        )
        .where((row) => row.any((cell) => cell.isNotEmpty))
        .toList();
    if (rows.length < 2 || rows.first.length < 2) {
      throw TableImportException(invalidMessage);
    }
    final columnCount = rows.first.length;
    if (rows.any((row) => row.length != columnCount) ||
        rows.first.any((header) => header.isEmpty)) {
      throw TableImportException(invalidMessage);
    }
    return ImportedTableData(
      columns: List<String>.unmodifiable(rows.first),
      rows: List.unmodifiable([
        for (final row in rows.skip(1)) List<String>.unmodifiable(row),
      ]),
    );
  }

  String? _normalizeText(String? content) {
    if (content == null) return null;
    final withoutBom = content.startsWith('\uFEFF')
        ? content.substring(1)
        : content;
    final normalized = withoutBom
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();
    return normalized.isEmpty ? null : normalized;
  }

  static const _invalidClipboardMessage =
      'Não encontramos uma tabela válida na área de transferência.';
}
