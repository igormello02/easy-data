import 'package:archive/archive.dart';
import 'package:file/memory.dart';
import 'package:flutter/foundation.dart';
import 'package:open_xml/open_xml.dart';

import 'models/imported_table_data.dart';
import 'table_import_parser.dart';

class ExcelWorkbookData {
  const ExcelWorkbookData({required this.sheets});

  final List<ExcelSheetData> sheets;
}

class ExcelSheetData {
  const ExcelSheetData({required this.name, required this.rows});

  final String name;
  final List<List<String>> rows;
}

class ExcelTableParser {
  const ExcelTableParser();

  Future<ExcelWorkbookData> openWorkbook(Uint8List bytes) async {
    if (bytes.isEmpty) {
      throw const TableImportException(couldNotReadFileMessage);
    }
    if (!_hasZipSignature(bytes)) {
      throw const TableImportException(couldNotReadFileMessage);
    }
    try {
      final fileSystem = MemoryFileSystem();
      final file = fileSystem.file('workbook.xlsx');
      await file.writeAsBytes(bytes, flush: true);
      final workbook = await Workbook.open(file);
      debugPrint('=== XLSX WORKBOOK DEBUG ===');
      debugPrint('library = open_xml 0.3.1+easydata.1');
      debugPrint('file opened successfully = true');
      debugPrint('worksheets found = ${workbook.worksheets.length}');
      late final List<ExcelSheetData> sheets;
      try {
        sheets = [
          for (final (index, worksheet) in workbook.worksheets.indexed)
            _readWorksheet(worksheet, index),
        ];
      } finally {
        await workbook.close();
      }
      if (sheets.isEmpty) {
        _logOoxmlWorksheetMappings(bytes);
        throw const TableImportException(noValidSheetMessage);
      }
      return ExcelWorkbookData(sheets: List.unmodifiable(sheets));
    } on TableImportException {
      rethrow;
    } on Object catch (error, stackTrace) {
      debugPrint('=== XLSX PARSER ERROR ===');
      debugPrint('Type: ${error.runtimeType}');
      debugPrint('Error: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  ExcelSheetData _readWorksheet(Worksheet worksheet, int index) {
    final rows = [
      for (final row in worksheet.rows)
        [for (final cell in row.cells) _cellText(cell.value)],
    ];
    final firstNonEmptyRow = rows.indexWhere(
      (row) => row.any((cell) => cell.isNotEmpty),
    );
    final nonEmptyCells = rows.fold<int>(
      0,
      (count, row) => count + row.where((cell) => cell.isNotEmpty).length,
    );

    debugPrint('Worksheet:');
    debugPrint('name = ${worksheet.name}');
    debugPrint('index = $index');
    debugPrint('identifier = ${worksheet.id}');
    debugPrint('visibility = unavailable from open_xml API');
    debugPrint('rows = ${rows.length}');
    debugPrint(
      'first non-empty row = '
      '${firstNonEmptyRow < 0 ? 'none' : firstNonEmptyRow + 1}',
    );
    debugPrint('non-empty cells = $nonEmptyCells');
    debugPrint('accepted = true');
    debugPrint('reason = discovered by open_xml high-level API');

    return ExcelSheetData(name: worksheet.name, rows: rows);
  }

  void _logOoxmlWorksheetMappings(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final entries = {for (final file in archive.files) file.name: file};
      final workbookXml = entries['xl/workbook.xml'];
      final relationshipsXml = entries['xl/_rels/workbook.xml.rels'];
      if (workbookXml == null || relationshipsXml == null) {
        debugPrint('OOXML mapping unavailable: workbook parts are missing.');
        return;
      }

      final workbookDocument = XmlDocument.parse(
        String.fromCharCodes(workbookXml.readBytes()!),
      );
      final relationshipsDocument = XmlDocument.parse(
        String.fromCharCodes(relationshipsXml.readBytes()!),
      );
      final targetsById = <String, String>{};
      for (final relationship
          in relationshipsDocument.descendants.whereType<XmlElement>()) {
        if (relationship.name.local != 'Relationship') continue;
        final id = relationship.getAttribute('Id');
        final target = relationship.getAttribute('Target');
        if (id != null && target != null) targetsById[id] = target;
      }

      final declaredSheets = workbookDocument.descendants
          .whereType<XmlElement>()
          .where((element) => element.name.local == 'sheet')
          .toList();
      debugPrint('OOXML worksheets declared = ${declaredSheets.length}');
      for (final (index, sheet) in declaredSheets.indexed) {
        final name = sheet.getAttribute('name') ?? 'Worksheet ${index + 1}';
        final relationshipId = sheet.attributes
            .where((attribute) => attribute.name.local == 'id')
            .map((attribute) => attribute.value)
            .firstOrNull;
        final rawTarget = relationshipId == null
            ? null
            : targetsById[relationshipId];
        final resolvedTarget = rawTarget == null
            ? null
            : _resolveWorksheetTarget(rawTarget);
        debugPrint('Worksheet:');
        debugPrint('name = $name');
        debugPrint('index = $index');
        debugPrint('identifier = $relationshipId');
        debugPrint('relationship target = $rawTarget');
        debugPrint('resolved target = $resolvedTarget');
        debugPrint(
          'target exists = '
          '${resolvedTarget != null && entries.containsKey(resolvedTarget)}',
        );
        debugPrint('accepted = false');
        debugPrint(
          'reason = not exposed by the open_xml high-level worksheet API',
        );
      }
    } on Object catch (error, stackTrace) {
      debugPrint('OOXML worksheet mapping diagnostic failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  String _resolveWorksheetTarget(String target) {
    final normalized = target.replaceAll('\\', '/');
    if (normalized.startsWith('/')) return normalized.substring(1);
    if (normalized.startsWith('xl/')) return normalized;
    return 'xl/$normalized';
  }

  String _cellText(Object? value) {
    if (value == null) return '';
    if (value is double &&
        value.isFinite &&
        value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toString().trim();
  }

  bool _hasZipSignature(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
      return false;
    }
    return (bytes[2] == 0x03 && bytes[3] == 0x04) ||
        (bytes[2] == 0x05 && bytes[3] == 0x06) ||
        (bytes[2] == 0x07 && bytes[3] == 0x08);
  }

  ImportedTableData parseSheet(ExcelSheetData sheet) {
    final rows = sheet.rows
        .where((row) => row.any((cell) => cell.isNotEmpty))
        .map(List<String>.from)
        .toList();
    if (rows.length < 2) {
      throw const TableImportException(emptySheetMessage);
    }

    var columnCount = rows.fold<int>(
      0,
      (maximum, row) => row.length > maximum ? row.length : maximum,
    );
    while (columnCount > 0 &&
        rows.every(
          (row) => row.length < columnCount || row[columnCount - 1].isEmpty,
        )) {
      columnCount--;
    }
    if (columnCount < 2) {
      throw const TableImportException(invalidSheetMessage);
    }

    final headers = [
      for (var index = 0; index < columnCount; index++)
        index < rows.first.length && rows.first[index].isNotEmpty
            ? rows.first[index]
            : 'Coluna ${index + 1}',
    ];
    final dataRows = [
      for (final row in rows.skip(1))
        [
          for (var index = 0; index < columnCount; index++)
            index < row.length ? row[index] : '',
        ],
    ];

    return ImportedTableData(
      columns: List.unmodifiable(headers),
      rows: List.unmodifiable([
        for (final row in dataRows) List<String>.unmodifiable(row),
      ]),
    );
  }

  static const couldNotReadFileMessage =
      'Não foi possível ler este arquivo do Excel.';
  static const noValidSheetMessage =
      'Não encontramos uma planilha válida neste arquivo.';
  static const emptySheetMessage =
      'Esta planilha não contém dados para importar.';
  static const invalidSheetMessage =
      'Não encontramos uma tabela válida nesta planilha.';
}
