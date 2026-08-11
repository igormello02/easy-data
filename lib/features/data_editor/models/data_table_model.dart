class TableColumn {
  TableColumn({required this.id, required this.name});

  final int id;
  String name;
}

class TableRowData {
  TableRowData({required this.id, required this.values});

  final int id;
  final Map<int, String> values;
}

class DataTableModel {
  DataTableModel({required this.columns, required this.rows});

  factory DataTableModel.initial() {
    return DataTableModel(
      columns: [
        TableColumn(id: 0, name: 'Categoria'),
        TableColumn(id: 1, name: 'Valor'),
      ],
      rows: [
        TableRowData(id: 0, values: {0: '', 1: ''}),
      ],
    );
  }

  final List<TableColumn> columns;
  final List<TableRowData> rows;

  int _nextColumnId = 2;
  int _nextRowId = 1;

  bool get canRemoveColumn => columns.length > 2;

  void addRow() {
    rows.add(
      TableRowData(
        id: _nextRowId++,
        values: {for (final column in columns) column.id: ''},
      ),
    );
  }

  void removeRow(int rowId) {
    rows.removeWhere((row) => row.id == rowId);
  }

  void addColumn() {
    final id = _nextColumnId++;
    columns.add(TableColumn(id: id, name: 'Nova coluna'));
    for (final row in rows) {
      row.values[id] = '';
    }
  }

  void removeColumn(int columnId) {
    if (!canRemoveColumn) return;
    columns.removeWhere((column) => column.id == columnId);
    for (final row in rows) {
      row.values.remove(columnId);
    }
  }

  DataTableModel snapshot() {
    return DataTableModel(
      columns: [
        for (final column in columns)
          TableColumn(id: column.id, name: column.name),
      ],
      rows: [
        for (final row in rows)
          TableRowData(id: row.id, values: Map<int, String>.from(row.values)),
      ],
    );
  }
}
