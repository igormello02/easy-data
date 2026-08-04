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
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Criar gráfico',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Como deseja inserir os dados?',
            style: textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF525252),
            ),
          ),
          const SizedBox(height: 20),
          _DataSourceTile(
            icon: Icons.content_paste_rounded,
            title: 'Colar do Excel',
            subtitle: 'Cole dados copiados da planilha',
            onTap: () => _openEditor(context),
          ),
          const SizedBox(height: 10),
          _DataSourceTile(
            icon: Icons.upload_file_rounded,
            title: 'Importar CSV',
            subtitle: 'Selecione um arquivo do dispositivo',
            onTap: () => _openEditor(context),
          ),
          const SizedBox(height: 10),
          _DataSourceTile(
            icon: Icons.edit_note_rounded,
            title: 'Digitar manualmente',
            subtitle: 'Insira os dados linha por linha',
            onTap: () => _openEditor(context),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
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
    return Material(
      color: const Color(0xFFF7F7F7),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
