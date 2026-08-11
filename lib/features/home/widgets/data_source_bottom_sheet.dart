import 'package:flutter/material.dart';

import '../../data_editor/data_editor_page.dart';

class DataSourceBottomSheet extends StatelessWidget {
  const DataSourceBottomSheet({super.key});

  void _openEditor(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const DataEditorPage()));
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
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          _DataSourceTile(
            icon: Icons.assignment_outlined,
            title: 'Colar do Excel',
            subtitle: 'Cole dados copiados da planilha',
            onTap: () => _openEditor(context),
          ),
          const Divider(height: 1, indent: 24, endIndent: 24),
          _DataSourceTile(
            icon: Icons.upload_file_outlined,
            title: 'Importar CSV',
            subtitle: 'Selecione um arquivo do dispositivo',
            onTap: () => _openEditor(context),
          ),
          const Divider(height: 1, indent: 24, endIndent: 24),
          _DataSourceTile(
            icon: Icons.add_box_outlined,
            title: 'Digitar manualmente',
            subtitle: 'Insira os dados linha por linha',
            onTap: () => _openEditor(context),
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
  final VoidCallback onTap;

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
