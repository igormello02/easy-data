import 'dart:convert';
import 'dart:typed_data';

import 'package:easy_data/features/data_editor/data_editor_page.dart';
import 'package:easy_data/features/data_import/data_import_services.dart';
import 'package:easy_data/features/home/widgets/data_source_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeClipboard implements ClipboardReader {
  _FakeClipboard(this.value);

  final String? value;

  @override
  Future<String?> readText() async => value;
}

class _FakePicker implements CsvFilePicker {
  _FakePicker(this.value);

  final Uint8List? value;

  @override
  Future<Uint8List?> pickBytes() async => value;
}

void main() {
  Widget buildSheet({String? clipboard, Uint8List? csvBytes}) {
    return MaterialApp(
      home: Scaffold(
        body: DataSourceBottomSheet(
          clipboardReader: _FakeClipboard(clipboard),
          csvFilePicker: _FakePicker(csvBytes),
        ),
      ),
    );
  }

  testWidgets('clipboard data reaches the editable data editor', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSheet(clipboard: 'Cidade\tValor\nSão Paulo\t120,50'),
    );

    await tester.tap(find.text('Colar do Excel'));
    await tester.pumpAndSettle();

    expect(find.byType(DataEditorPage), findsOneWidget);
    expect(find.text('Cidade'), findsOneWidget);
    expect(find.text('São Paulo'), findsOneWidget);
    expect(find.text('120,50'), findsOneWidget);
  });

  testWidgets('invalid clipboard keeps the picker open and shows a message', (
    tester,
  ) async {
    await tester.pumpWidget(buildSheet(clipboard: 'texto'));

    await tester.tap(find.text('Colar do Excel'));
    await tester.pump();

    expect(find.text('Como deseja inserir os dados?'), findsOneWidget);
    expect(
      find.text('Não encontramos uma tabela válida na área de transferência.'),
      findsOneWidget,
    );
  });

  testWidgets('CSV data reaches the same editable data editor', (tester) async {
    await tester.pumpWidget(
      buildSheet(
        csvBytes: Uint8List.fromList(utf8.encode('Categoria;Valor\nAção;30')),
      ),
    );

    await tester.tap(find.text('Importar CSV'));
    await tester.pumpAndSettle();

    expect(find.byType(DataEditorPage), findsOneWidget);
    expect(find.text('Ação'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
  });

  testWidgets('canceling the file picker does not show an error', (
    tester,
  ) async {
    await tester.pumpWidget(buildSheet());

    await tester.tap(find.text('Importar CSV'));
    await tester.pump();

    expect(find.text('Como deseja inserir os dados?'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('invalid CSV shows a clear message', (tester) async {
    await tester.pumpWidget(
      buildSheet(csvBytes: Uint8List.fromList(utf8.encode('texto'))),
    );

    await tester.tap(find.text('Importar CSV'));
    await tester.pump();

    expect(
      find.text('Não encontramos uma tabela válida no arquivo CSV.'),
      findsOneWidget,
    );
  });
}
