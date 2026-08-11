import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data_editor/models/data_table_model.dart';

class ChartEditorPage extends StatelessWidget {
  const ChartEditorPage({super.key, required this.data});

  final DataTableModel data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gráfico',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dados recebidos',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              '${data.rows.length} linha(s) • ${data.columns.length} coluna(s)',
              key: const ValueKey('data-summary'),
              style: const TextStyle(color: Color(0xFF737373)),
            ),
            const SizedBox(height: 20),
            Expanded(child: _DataPreview(data: data)),
            const SizedBox(height: 16),
            const Text(
              'A geração do gráfico será implementada em uma próxima sprint.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF737373), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataPreview extends StatelessWidget {
  const _DataPreview({required this.data});

  final DataTableModel data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = math.max(
          120.0,
          constraints.maxWidth / data.columns.length,
        );

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: columnWidth * data.columns.length,
            child: ListView(
              children: [
                Row(
                  children: [
                    for (final column in data.columns)
                      _PreviewCell(
                        width: columnWidth,
                        text: column.name,
                        isHeader: true,
                      ),
                  ],
                ),
                for (final row in data.rows)
                  Row(
                    children: [
                      for (final column in data.columns)
                        _PreviewCell(
                          width: columnWidth,
                          text: row.values[column.id] ?? '',
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PreviewCell extends StatelessWidget {
  const _PreviewCell({
    required this.width,
    required this.text,
    this.isHeader = false,
  });

  final double width;
  final String text;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHeader ? const Color(0xFFF3F3F3) : Colors.white,
        border: Border.all(color: const Color(0xFFE2E2E2), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: isHeader ? FontWeight.w600 : null),
      ),
    );
  }
}
