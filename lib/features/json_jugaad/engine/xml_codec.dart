import 'package:xml/xml.dart';

import 'jugaad_validator.dart';

abstract final class XmlCodec {
  static String? tryFormat(String input) {
    if (!JugaadValidator.looksLikeXml(input)) {
      return null;
    }

    try {
      final document = XmlDocument.parse(input.trim());
      return document.toXmlString(pretty: true, indent: '  ');
    } on XmlException {
      return null;
    }
  }
}
