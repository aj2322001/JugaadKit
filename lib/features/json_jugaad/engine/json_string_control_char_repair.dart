import 'jugaad_validator.dart';

/// Repairs literal control characters that appear inside JSON string values.
///
/// Strict JSON requires control characters in strings to be escaped. Real-world
/// payloads sometimes contain raw newlines (or other control chars) inside quoted
/// values. This scanner only mutates characters inside JSON strings and leaves
/// structural whitespace outside strings untouched.
abstract final class JsonStringControlCharRepair {
  static String? tryRepair(String input) {
    if (input.isEmpty) {
      return null;
    }

    if (JugaadValidator.looksLikeDocumentLevelEscapedJson(input)) {
      return null;
    }

    final buffer = StringBuffer();
    var inString = false;
    var modified = false;

    for (var index = 0; index < input.length; index++) {
      final char = input[index];

      if (!inString) {
        if (char == '"') {
          inString = true;
        }
        buffer.write(char);
        continue;
      }

      if (char == '"') {
        if (_isQuoteEscaped(input, index)) {
          buffer.write(char);
          continue;
        }

        inString = false;
        buffer.write(char);
        continue;
      }

      if (char == r'\') {
        buffer.write(char);
        if (index + 1 < input.length) {
          index++;
          final next = input[index];
          buffer.write(next);
          if (next == 'u' && index + 4 < input.length) {
            for (var offset = 1; offset <= 4; offset++) {
              index++;
              buffer.write(input[index]);
            }
          }
        }
        continue;
      }

      final escaped = _escapeControlChar(char);
      if (escaped != null) {
        modified = true;
        buffer.write(escaped);
        continue;
      }

      buffer.write(char);
    }

    return modified ? buffer.toString() : null;
  }

  static bool _isQuoteEscaped(String input, int quoteIndex) {
    var backslashes = 0;
    for (var index = quoteIndex - 1; index >= 0 && input[index] == r'\'; index--) {
      backslashes++;
    }
    return backslashes.isOdd;
  }

  static String? _escapeControlChar(String char) {
    final code = char.codeUnitAt(0);
    if (code >= 0x20) {
      return null;
    }

    return switch (char) {
      '\n' => r'\n',
      '\r' => r'\r',
      '\t' => r'\t',
      '\b' => r'\b',
      '\f' => r'\f',
      _ => '\\u${code.toRadixString(16).padLeft(4, '0')}',
    };
  }
}
