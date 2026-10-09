import 'package:flutter/material.dart';

import '../../data_editor/data_editor_page.dart';
import '../../data_editor/models/data_table_model.dart';
import '../../data_import/data_import_services.dart';
import '../../data_import/excel_table_parser.dart';
import '../../data_import/table_import_parser.dart';

class DataSourceBottomSheet extends StatefulWidget {
  const DataSourceBottomSheet({
    super.key,
    this.excelFilePicker = const NativeExcelFilePicker(),
    this.csvFilePicker = const NativeCsvFilePicker(),
    this.excelParser = const ExcelTableParser(),
    this.tableParser = const TableImportParser(),
  });

  final ExcelFilePicker excelFilePicker;
  final CsvFilePicker csvFilePicker;
  final ExcelTableParser excelParser;
  final TableImportParser tableParser;

  @override
  State<DataSourceBottomSheet> createState() => _DataSourceBottomSheetState();
}

class _DataSourceBottomSheetState extends State<DataSourceBottomSheet> {
  bool _isLoading = false;

  void _openEditor([DataTableModel? table]) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => DataEditorPage(initialTable: table),
      ),
    );
  }

  Future<void> _importExcel() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final picked = await widget.excelFilePicker.pickFile();
      if (picked == null || !mounted) return;
      if (picked.name.trim().isEmpty ||
          picked.extension?.toLowerCase() != 'xlsx' ||
          picked.bytes.isEmpty) {
        throw const TableImportException(
          ExcelTableParser.couldNotReadFileMessage,
        );
      }

      final workbook = await widget.excelParser.openWorkbook(picked.bytes);
      ExcelSheetData? selectedSheet;
      if (workbook.sheets.length == 1) {
        selectedSheet = workbook.sheets.single;
      } else {
        final sheetName = await _selectSheet(workbook.sheets);
        if (sheetName == null || !mounted) return;
        selectedSheet = workbook.sheets.firstWhere(
          (sheet) => sheet.name == sheetName,
        );
      }

      final imported = widget.excelParser.parseSheet(selectedSheet);
      if (mounted) _openEditor(DataTableModel.fromImported(imported));
    } on TableImportException catch (error, stackTrace) {
      debugPrint('Excel import error: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) await _showMessage(error.message);
    } on Object catch (error, stackTrace) {
      debugPrint('Excel import error: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        await _showMessage(ExcelTableParser.couldNotReadFileMessage);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _selectSheet(List<ExcelSheetData> sheets) {
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Selecionar planilha'),
        children: [
          for (final sheet in sheets)
            SimpleDialogOption(
              key: ValueKey('excel-sheet-${sheet.name}'),
              onPressed: () => Navigator.of(context).pop(sheet.name),
              child: Row(
                children: [
                  const Icon(Icons.table_chart_outlined, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sheet.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _importCsv() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final bytes = await widget.csvFilePicker.pickBytes();
      if (bytes == null || !mounted) return;
      final imported = widget.tableParser.parseCsvBytes(bytes);
      _openEditor(DataTableModel.fromImported(imported));
    } on TableImportException catch (error) {
      if (mounted) await _showMessage(error.message);
    } on Object {
      if (mounted) {
        await _showMessage('Não foi possível importar o arquivo CSV.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showMessage(String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Criar gráfico',
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Como deseja inserir os dados?',
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF737373),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(
              key: ValueKey('data-import-loading'),
              minHeight: 2,
            ),
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          _DataSourceTile(
            icon: Icons.table_view_outlined,
            title: 'Importar Excel',
            subtitle: 'Selecione um arquivo .xlsx do dispositivo',
            onTap: _isLoading ? null : _importExcel,
          ),
          const Divider(height: 1, indent: 24, endIndent: 24),
          _DataSourceTile(
            icon: Icons.upload_file_outlined,
            title: 'Importar CSV',
            subtitle: 'Selecione um arquivo do dispositivo',
            onTap: _isLoading ? null : _importCsv,
          ),
          const Divider(height: 1, indent: 24, endIndent: 24),
          _DataSourceTile(
            icon: Icons.add_box_outlined,
            title: 'Digitar manualmente',
            subtitle: 'Insira os dados linha por linha',
            onTap: _isLoading ? null : _openEditor,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: SizedBox(
              height: 48,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF444444),
                  backgroundColor: const Color(0xFFF5F5F5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: const Text('Cancelar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataSourceTile extends StatelessWidget {
  const _DataSourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF555555)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8A8A8A),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: Color(0xFFB8B8B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
