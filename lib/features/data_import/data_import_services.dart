import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

abstract interface class ClipboardReader {
  Future<String?> readText();
}

class SystemClipboardReader implements ClipboardReader {
  const SystemClipboardReader();

  @override
  Future<String?> readText() async {
    return (await Clipboard.getData(Clipboard.kTextPlain))?.text;
  }
}

abstract interface class CsvFilePicker {
  Future<Uint8List?> pickBytes();
}

class NativeCsvFilePicker implements CsvFilePicker {
  const NativeCsvFilePicker();

  @override
  Future<Uint8List?> pickBytes() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    return file == null ? null : await file.readAsBytes();
  }
}
