import 'package:flutter/material.dart';

import 'widgets/data_source_bottom_sheet.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _openDataSourcePicker(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const DataSourceBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.bar_chart_rounded, size: 38),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Easy Data',
                        textAlign: TextAlign.center,
                        style: textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Crie gráficos profissionais em menos de 30 segundos.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF525252),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 36),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: FilledButton.icon(
                          onPressed: () => _openDataSourcePicker(context),
                          icon: const Icon(Icons.add_chart_rounded),
                          label: const Text('Criar gráfico'),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 40),
                      const _HomeFooter(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomeFooter extends StatelessWidget {
  const _HomeFooter();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(color: const Color(0xFF737373));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Sobre', style: style),
        const SizedBox(width: 28),
        Text('Configurações', style: style),
      ],
    );
  }
}
