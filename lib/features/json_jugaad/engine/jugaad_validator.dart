import 'dart:convert';

import 'confidence.dart';

class JsonParseResult {
  const JsonParseResult(this.value);

  final Object? value;
}

abstract final class JugaadValidator {
  static JsonParseResult? tryParseJson(String input) {
    try {
      return JsonParseResult(jsonDecode(input));
    } on FormatException {
      return null;
    }
  }

  static bool looksLikeJsonCandidate(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    final first = trimmed[0];
    final last = trimmed[trimmed.length - 1];
    return (first == '{' && last == '}') || (first == '[' && last == ']');
  }

  static bool isJsonStringLiteral(String input) {
    return input.length >= 2 && input.startsWith('"') && input.endsWith('"');
  }

  static bool looksUrlEncoded(String input) {
    if (!input.contains('%')) {
      return false;
    }

    final encodedPattern = RegExp(r'%[0-9A-Fa-f]{2}');
    final matches = encodedPattern.allMatches(input).length;
    if (matches < 2) {
      return false;
    }

    return input.contains('%7B') ||
        input.contains('%7D') ||
        input.contains('%22') ||
        input.contains('%5B') ||
        input.contains('%5D') ||
        matches >= 4;
  }

  static bool looksLikeBase64(String input) {
    final trimmed = input.trim();
    if (trimmed.length < 8 || trimmed.length % 4 != 0) {
      return false;
    }

    if (!RegExp(r'^[A-Za-z0-9+/_-]+={0,2}$').hasMatch(trimmed)) {
      return false;
    }

    final hasPadding = trimmed.contains('=');
    final hasBase64Chars =
        trimmed.contains(RegExp(r'[+/]')) || trimmed.contains(RegExp(r'[-_]'));
    if (!hasPadding && !hasBase64Chars && trimmed.length < 16) {
      return false;
    }

    return true;
  }

  static bool looksLikeHex(String input) {
    final trimmed = input.trim();
    if (trimmed.length < 8 || trimmed.length.isOdd) {
      return false;
    }

    if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(trimmed)) {
      return false;
    }

    return trimmed.length >= 16;
  }

  static bool containsHtmlEntities(String input) {
    return input.contains('&quot;') ||
        input.contains('&#') ||
        input.contains('&amp;') ||
        input.contains('&lt;') ||
        input.contains('&gt;');
  }

  static bool looksLikeQueryString(String input) {
    if (!input.contains('=')) {
      return false;
    }

    if (looksLikeJsonCandidate(input)) {
      return false;
    }

    final pairs = input.split('&');
    if (pairs.length < 2) {
      return false;
    }

    var validPairs = 0;
    for (final pair in pairs) {
      final index = pair.indexOf('=');
      if (index <= 0 || index >= pair.length - 1) {
        continue;
      }
      validPairs++;
    }

    return validPairs >= 2;
  }

  static bool looksLikeNdjsonAttempt(String input) {
    final lines = input
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.length < 2) {
      return false;
    }

    var jsonishLines = 0;
    for (final line in lines) {
      if (looksLikeJsonCandidate(line) ||
          line.startsWith('{') ||
          line.startsWith('[')) {
        jsonishLines++;
      }
    }

    return jsonishLines >= 2;
  }

  static bool looksLikeNdjson(String input) {
    final lines = input
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.length < 2) {
      return false;
    }

    var validLines = 0;
    for (final line in lines) {
      if (tryParseJson(line) != null) {
        validLines++;
      }
    }

    return validLines >= 2 && validLines == lines.length;
  }

  static bool looksLikeJwt(String input) {
    final trimmed = input.trim();
    final parts = trimmed.split('.');
    if (parts.length != 3) {
      return false;
    }

    for (final part in parts) {
      if (part.isEmpty || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(part)) {
        return false;
      }
    }

    return parts[0].length >= 4 && parts[1].length >= 4;
  }

  static Confidence confidenceForJsonParse(String input) {
    if (tryParseJson(input) != null) {
      return Confidence.high;
    }
    return Confidence.none;
  }

  static bool isMeaningfulDecodedString(String decoded) {
    if (decoded.trim().isEmpty) {
      return false;
    }

    return looksLikeJsonCandidate(decoded) ||
        isJsonStringLiteral(decoded) ||
        looksLikeEscapedJson(decoded) ||
        tryParseJson(decoded) != null ||
        looksLikeQueryString(decoded);
  }

  static bool looksLikeEscapedJson(String input) {
    return input.contains(r'\"') ||
        input.contains(r'\\') ||
        RegExp(r'\\u[0-9a-fA-F]{4}').hasMatch(input);
  }
}
