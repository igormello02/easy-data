import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

typedef PngCapture = Future<Uint8List> Function(GlobalKey boundaryKey);
typedef PngSaver = Future<bool> Function(Uint8List bytes, String fileName);

class ChartExportCancelled implements Exception {
  const ChartExportCancelled();
}

class ChartExportService {
  ChartExportService({PngCapture? capturePng, PngSaver? savePng})
    : _capturePng = capturePng ?? _captureBoundary,
      _savePng = savePng ?? _saveWithAndroid;

  static const _channel = MethodChannel('easy_data/chart_export');
  static const double targetWidth = 1920;
  static const double maximumPixelRatio = 6;

  final PngCapture _capturePng;
  final PngSaver _savePng;

  Future<void> export({
    required GlobalKey boundaryKey,
    required String fileName,
  }) async {
    final bytes = await _capturePng(boundaryKey);
    if (bytes.isEmpty) {
      throw StateError('A captura do gráfico ficou vazia.');
    }

    final saved = await _savePng(bytes, fileName);
    if (!saved) throw const ChartExportCancelled();
  }

  static String createFileName([DateTime? dateTime]) {
    final value = (dateTime ?? DateTime.now()).toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return 'easy_data_grafico_${value.year}-${twoDigits(value.month)}-'
        '${twoDigits(value.day)}_${twoDigits(value.hour)}${twoDigits(value.minute)}.png';
  }

  static Future<Uint8List> _captureBoundary(GlobalKey boundaryKey) async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary = boundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary || boundary.size.isEmpty) {
      throw StateError('A área do gráfico não está disponível.');
    }

    final pixelRatio = (targetWidth / boundary.size.width).clamp(
      1.0,
      maximumPixelRatio,
    );
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('Não foi possível gerar o PNG.');
      }
      return byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
    } finally {
      image.dispose();
    }
  }

  static Future<bool> _saveWithAndroid(Uint8List bytes, String fileName) async {
    final result = await _channel.invokeMethod<String>('savePng', {
      'bytes': bytes,
      'fileName': fileName,
    });
    return result == 'saved';
  }
}
