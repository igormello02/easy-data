import 'package:flutter/material.dart';

class DataEditorPage extends StatelessWidget {
  const DataEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editor de Dados')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.table_chart_outlined, size: 48),
              const SizedBox(height: 16),
              Text(
                'Editor de Dados',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A entrada de dados será implementada em uma próxima sprint.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF525252),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
