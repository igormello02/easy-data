import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../chart_editor/chart_editor_page.dart';
import '../chart_editor/models/chart_data.dart';
import 'models/data_table_model.dart';

class DataEditorPage extends StatefulWidget {
  const DataEditorPage({super.key});

  @override
  State<DataEditorPage> createState() => _DataEditorPageState();
}

class _DataEditorPageState extends State<DataEditorPage> {
  final DataTableModel _table = DataTableModel.initial();

  void _addRow() {
    setState(_table.addRow);
  }

  void _removeRow(int rowId) {
    setState(() => _table.removeRow(rowId));
  }

  void _addColumn() {
    setState(_table.addColumn);
  }

  void _removeColumn(int columnId) {
    if (!_table.canRemoveColumn) {
      _showMessage('A tabela deve ter pelo menos duas colunas.');
      return;
    }

    setState(() => _table.removeColumn(columnId));
  }

  void _generateChart() {
    FocusScope.of(context).unfocus();

    final validationMessage = _validationMessage();
    if (validationMessage != null) {
      _showMessage(validationMessage);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChartEditorPage(
          data: ChartData(
            points: [
              for (final row in _table.rows)
                ChartDataPoint(
                  category: row.values[_table.columns[0].id]!.trim(),
                  value: _parseNumber(row.values[_table.columns[1].id]!.trim()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validationMessage() {
    if (_table.columns.length < 2) {
      return 'A tabela deve ter pelo menos duas colunas.';
    }
    if (_table.rows.isEmpty) {
      return 'Adicione pelo menos uma linha de dados.';
    }
    if (_table.columns.any((column) => column.name.trim().isEmpty)) {
      return 'Preencha o nome de todas as colunas.';
    }

    for (final row in _table.rows) {
      final category = row.values[_table.columns[0].id]?.trim() ?? '';
      final value = row.values[_table.columns[1].id]?.trim() ?? '';
      if (category.isEmpty || value.isEmpty) {
        return 'Preencha Categoria e Valor em todas as linhas.';
      }
      if (!_isNumeric(value)) {
        return 'Use apenas números na coluna Valor.';
      }
    }

    return null;
  }

  bool _isNumeric(String value) {
    return double.tryParse(_normalizedNumber(value)) != null;
  }

  double _parseNumber(String value) {
    return double.parse(_normalizedNumber(value));
  }

  String _normalizedNumber(String value) {
    var normalized = value.replaceAll(' ', '');
    if (normalized.contains(',') && normalized.contains('.')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else {
      normalized = normalized.replaceAll(',', '.');
    }
    return normalized;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        leadingWidth: 96,
        leading: TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left_rounded, size: 24),
          label: const Text('Voltar'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF555555),
            padding: const EdgeInsets.only(left: 16, right: 8),
          ),
        ),
        title: const Text(
          'Dados',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: const [_ProgressIndicator(), SizedBox(width: 20)],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _EditableTable(
                    table: _table,
                    onRemoveRow: _removeRow,
                    onRemoveColumn: _removeColumn,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        TextButton.icon(
                          key: const ValueKey('add-row'),
                          onPressed: _addRow,
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text('Adicionar linha'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF777777),
                            minimumSize: const Size(48, 48),
                          ),
                        ),
                        TextButton.icon(
                          key: const ValueKey('add-column'),
                          onPressed: _addColumn,
                          icon: const Icon(
                            Icons.view_column_outlined,
                            size: 19,
                          ),
                          label: const Text('Adicionar coluna'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF777777),
                            minimumSize: const Size(48, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(28, 20, 28, 32),
                    child: _EditorHint(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _GenerateChartBar(onPressed: _generateChart),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF171717),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        ...List.generate(
          2,
          (_) => Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Container(
              width: 18,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD6D6D6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditableTable extends StatelessWidget {
  const _EditableTable({
    required this.table,
    required this.onRemoveRow,
    required this.onRemoveColumn,
  });

  final DataTableModel table;
  final ValueChanged<int> onRemoveRow;
  final ValueChanged<int> onRemoveColumn;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableForColumns =
            constraints.maxWidth - 40 - 44 - (8 * table.columns.length);
        final columnWidths = table.columns.length == 2
            ? [
                math.max(150.0, availableForColumns * 0.68),
                math.max(84.0, availableForColumns * 0.32),
              ]
            : [
                180.0,
                for (var index = 1; index < table.columns.length; index++)
                  112.0,
              ];
        final contentWidth =
            40 +
            44 +
            columnWidths.fold<double>(0, (sum, width) => sum + width + 8);
        final tableWidth = math.max(constraints.maxWidth, contentWidth);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              children: [
                Container(
                  height: 44,
                  color: const Color(0xFFF7F7F7),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      for (var index = 0; index < table.columns.length; index++)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: columnWidths[index],
                            child: _ColumnHeader(
                              column: table.columns[index],
                              canRemove: table.canRemoveColumn,
                              onRemove: () =>
                                  onRemoveColumn(table.columns[index].id),
                            ),
                          ),
                        ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
                const Divider(height: 1),
                for (final row in table.rows) ...[
                  Padding(
                    key: ValueKey('row-${row.id}'),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Row(
                      children: [
                        for (
                          var index = 0;
                          index < table.columns.length;
                          index++
                        )
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SizedBox(
                              width: columnWidths[index],
                              height: 48,
                              child: TextFormField(
                                key: ValueKey(
                                  'cell-${row.id}-${table.columns[index].id}',
                                ),
                                initialValue:
                                    row.values[table.columns[index].id] ?? '',
                                onChanged: (value) {
                                  row.values[table.columns[index].id] = value;
                                },
                                keyboardType: index == 1
                                    ? const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: true,
                                      )
                                    : TextInputType.text,
                                hintLocales: index == 1
                                    ? null
                                    : const [Locale('pt', 'BR')],
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  filled: true,
                                  fillColor: Color(0xFFFAFAFA),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFFE1E1E1),
                                    ),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF777777),
                                    ),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        SizedBox(
                          width: 44,
                          height: 48,
                          child: IconButton(
                            key: ValueKey('remove-row-${row.id}'),
                            onPressed: () => onRemoveRow(row.id),
                            tooltip: 'Remover linha',
                            icon: const Icon(Icons.remove_rounded, size: 20),
                            color: const Color(0xFFAAAAAA),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({
    required this.column,
    required this.canRemove,
    required this.onRemove,
  });

  final TableColumn column;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            key: ValueKey('header-${column.id}'),
            initialValue: column.name,
            onChanged: (value) => column.name = value,
            hintLocales: const [Locale('pt', 'BR')],
            textInputAction: TextInputAction.next,
            style: const TextStyle(
              color: Color(0xFF777777),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        if (canRemove)
          SizedBox(
            width: 32,
            height: 40,
            child: IconButton(
              key: ValueKey('remove-column-${column.id}'),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              tooltip: 'Remover coluna',
              icon: const Icon(Icons.close_rounded, size: 17),
              color: const Color(0xFFAAAAAA),
            ),
          ),
      ],
    );
  }
}

class _EditorHint extends StatelessWidget {
  const _EditorHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: const Color(0xFFD8D8D8)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 17, color: Color(0xFF999999)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Edite os dados diretamente na tabela.',
              style: TextStyle(
                color: Color(0xFF999999),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenerateChartBar extends StatelessWidget {
  const _GenerateChartBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(28, 16, 28, 16),
        child: FilledButton(
          key: const ValueKey('generate-chart'),
          onPressed: onPressed,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gerar gráfico'),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 19),
            ],
          ),
        ),
      ),
    );
  }
}
