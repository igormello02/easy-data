import 'package:flutter/material.dart';

import 'widgets/data_source_bottom_sheet.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _openDataSourcePicker(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: const Color(0x57000000),
      builder: (_) => const DataSourceBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F2),
                          border: Border.all(color: const Color(0xFFDEDEDE)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.bar_chart_rounded,
                          size: 27,
                          color: Color(0xFF656565),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Easy Data',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Crie gráficos profissionais em menos de 30 segundos.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF686868),
                          fontSize: 17,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 263),
                        child: FilledButton.icon(
                          onPressed: () => _openDataSourcePicker(context),
                          icon: const Icon(Icons.add_chart_rounded),
                          label: const Text('Criar gráfico'),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const _HomeFooter(),
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

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Sobre', style: style),
              const SizedBox(width: 36),
              Text('Configurações', style: style),
            ],
          ),
        ),
      ),
    );
  }
}
