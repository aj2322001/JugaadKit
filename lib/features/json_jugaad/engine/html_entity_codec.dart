import 'jugaad_validator.dart';

abstract final class HtmlEntityCodec {
  static const _entities = {
    '&quot;': '"',
    '&#34;': '"',
    '&#x22;': '"',
    '&amp;': '&',
    '&#38;': '&',
    '&lt;': '<',
    '&#60;': '<',
    '&gt;': '>',
    '&#62;': '>',
    '&#39;': "'",
    '&apos;': "'",
  };

  static String? tryDecode(String input) {
    if (!JugaadValidator.containsHtmlEntities(input)) {
      return null;
    }

    var decoded = input;
    for (final entry in _entities.entries) {
      decoded = decoded.replaceAll(entry.key, entry.value);
    }

    if (decoded == input) {
      return null;
    }

    if (JugaadValidator.isMeaningfulDecodedString(decoded) ||
        JugaadValidator.tryParseJson(decoded) != null) {
      return decoded;
    }

    return null;
  }
}
