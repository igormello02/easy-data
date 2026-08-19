import 'dart:typed_data';

import 'package:easy_data/features/export/chart_export_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates a friendly timestamped PNG file name', () {
    final name = ChartExportService.createFileName(
      DateTime(2026, 8, 19, 10, 30),
    );

    expect(name, 'easy_data_grafico_2026-08-19_1030.png');
    expect(
      name,
      matches(RegExp(r'^easy_data_grafico_\d{4}-\d{2}-\d{2}_\d{4}\.png$')),
    );
  });

  test('forwards valid captured PNG bytes to the saver', () async {
    final png = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
    Uint8List? savedBytes;
    String? savedName;
    final service = ChartExportService(
      capturePng: (_) async => png,
      savePng: (bytes, fileName) async {
        savedBytes = bytes;
        savedName = fileName;
        return true;
      },
    );

    await service.export(
      boundaryKey: GlobalKey(),
      fileName: 'easy_data_grafico_2026-08-19_1030.png',
    );

    expect(savedBytes, png);
    expect(savedName, 'easy_data_grafico_2026-08-19_1030.png');
  });

  test('rejects an empty capture before trying to save', () async {
    var saveCalled = false;
    final service = ChartExportService(
      capturePng: (_) async => Uint8List(0),
      savePng: (_, _) async {
        saveCalled = true;
        return true;
      },
    );

    await expectLater(
      service.export(boundaryKey: GlobalKey(), fileName: 'grafico.png'),
      throwsStateError,
    );
    expect(saveCalled, isFalse);
  });
}
