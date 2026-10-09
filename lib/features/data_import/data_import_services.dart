import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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

abstract interface class ExcelFilePicker {
  Future<PickedLocalFile?> pickFile();
}

class PickedLocalFile {
  const PickedLocalFile({
    required this.name,
    required this.extension,
    required this.bytes,
  });

  final String name;
  final String? extension;
  final Uint8List bytes;
}

class NativeExcelFilePicker implements ExcelFilePicker {
  const NativeExcelFilePicker();

  @override
  Future<PickedLocalFile?> pickFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
    );
    if (file == null) return null;
    debugPrint('Excel file selected: ${file.name}');
    debugPrint('Excel file extension: ${file.extension ?? '(unknown)'}');
    final bytes = await file.readAsBytes();
    debugPrint('Excel readAsBytes succeeded: ${bytes.length} bytes');
    return PickedLocalFile(
      name: file.name,
      extension: file.extension,
      bytes: bytes,
    );
  }
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
