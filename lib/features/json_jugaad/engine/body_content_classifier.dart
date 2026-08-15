import '../models/jugaad_body_content.dart';
import 'json_body_processor.dart';
import 'jugaad_validator.dart';
import 'xml_codec.dart';

abstract final class BodyContentClassifier {
  static JugaadBodyContent classify(
    String body, {
    String? contentType,
  }) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return const JugaadBodyContent.plain('');
    }

    final processed = JsonBodyProcessor.tryProcess(
      body,
      contentType: contentType,
    );
    if (processed != null) {
      return JugaadBodyContent.json(
        processed.value,
        repairHighlights: processed.repairHighlights,
      );
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
