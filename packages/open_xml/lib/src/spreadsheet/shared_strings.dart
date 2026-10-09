import 'package:open_xml/src/package/package.dart';
import 'package:xml/xml.dart';

class SharedStrings {
  final List<String> _strings = [];

  List<String> get strings => _strings;

  static Future<SharedStrings> parse(OoxmlPackage package) async {
    final ss = SharedStrings();
    if (await package.hasPart('xl/sharedStrings.xml')) {
      final xml = await package.readPartAsString('xl/sharedStrings.xml');
      final document = XmlDocument.parse(xml);
      final sst = document.descendants
          .whereType<XmlElement>()
          .where((element) => element.name.local == 'sst')
          .firstOrNull;
      if (sst != null) {
        for (final si in sst.descendants.whereType<XmlElement>().where(
          (element) => element.name.local == 'si',
        )) {
          final textElements = si.descendants.whereType<XmlElement>().where(
            (element) => element.name.local == 't',
          );
          final t = textElements.firstOrNull;
          if (t != null) {
            ss._strings.add(t.innerText);
          } else {
            // Handle simpler case or rich text fallback if needed,
            // but usually <si><t>... is the structure.
            // Sometimes it's <si><r><t>... for rich text.
            final buffer = StringBuffer();
            for (final t in textElements) {
              buffer.write(t.innerText);
            }
            ss._strings.add(buffer.toString());
          }
        }
      }
    }
    return ss;
  }

  String operator [](int index) {
    if (index < 0 || index >= _strings.length) return '';
    return _strings[index];
  }
}
