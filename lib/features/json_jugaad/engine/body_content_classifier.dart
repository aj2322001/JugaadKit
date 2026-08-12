import '../models/jugaad_body_content.dart';
import 'jugaad_validator.dart';
import 'xml_codec.dart';

abstract final class BodyContentClassifier {
  static JugaadBodyContent classify(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return const JugaadBodyContent.plain('');
    }

    final parsedJson = JugaadValidator.tryParseJson(trimmed);
    if (parsedJson != null) {
      return JugaadBodyContent.json(parsedJson.value);
    }

    if (JugaadValidator.looksLikeXml(trimmed)) {
      final formatted = XmlCodec.tryFormat(trimmed);
      if (formatted != null) {
        return JugaadBodyContent.xml(formatted);
      }
    }

    return JugaadBodyContent.plain(body);
  }
}
