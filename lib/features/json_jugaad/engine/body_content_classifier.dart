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

    if (_isFormUrlEncoded(contentType)) {
      final form = _tryParseFormUrlEncoded(trimmed);
      if (form != null) {
        return JugaadBodyContent.json(form);
      }
    }

    if (JugaadValidator.looksLikeXml(trimmed)) {
      final formatted = XmlCodec.tryFormat(trimmed);
      if (formatted != null) {
        return JugaadBodyContent.xml(formatted);
      }
    }

    return JugaadBodyContent.plain(body);
  }

  static bool _isFormUrlEncoded(String? contentType) {
    return contentType != null &&
        contentType.toLowerCase().contains('application/x-www-form-urlencoded');
  }

  static Map<String, Object?>? _tryParseFormUrlEncoded(String body) {
    if (!body.contains('=')) {
      return null;
    }

    final collected = <String, List<Object?>>{};
    for (final pair in body.split('&')) {
      if (pair.isEmpty) {
        continue;
      }
      final index = pair.indexOf('=');
      final rawKey = index < 0 ? pair : pair.substring(0, index);
      final rawValue = index < 0 ? '' : pair.substring(index + 1);
      if (rawKey.isEmpty) {
        return null;
      }

      final String key;
      final String value;
      try {
        key = Uri.decodeQueryComponent(rawKey);
        value = Uri.decodeQueryComponent(rawValue);
      } on FormatException {
        return null;
      } on ArgumentError {
        return null;
      }

      (collected[key] ??= []).add(_parseFormValue(value));
    }

    if (collected.isEmpty) {
      return null;
    }

    return {
      for (final entry in collected.entries)
        entry.key: entry.value.length == 1 ? entry.value.first : entry.value,
    };
  }

  static Object? _parseFormValue(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      final parsed = JugaadValidator.tryParseJson(trimmed);
      if (parsed != null) {
        return parsed.value;
      }
    }
    return value;
  }
}
