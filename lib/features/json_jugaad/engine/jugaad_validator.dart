import 'dart:convert';

import 'confidence.dart';
import 'jugaad_patterns.dart';
import 'json_string_control_char_repair.dart';

class JsonParseResult {
  const JsonParseResult(this.value);

  final Object? value;
}

/// Caches strict JSON parse results for the duration of one engine invocation.
class JsonParseSession {
  final Map<String, JsonParseResult?> _strictCache = {};

  JsonParseResult? tryParseJson(String input) {
    if (_strictCache.containsKey(input)) {
      return _strictCache[input];
    }

    final result = JugaadValidator.tryParseJson(input);
    _strictCache[input] = result;
    return result;
  }
}

abstract final class JugaadValidator {
  static JsonParseResult? tryParseJson(String input) {
    try {
      return JsonParseResult(jsonDecode(input));
    } on FormatException {
      return null;
    }
  }

  /// Strict JSON parse with a fallback that escapes literal control characters
  /// found inside JSON strings.
  ///
  /// This must run only after [tryDecodeEscapedJsonLayer] when the input is an
  /// escaped JSON document. Escaped documents use `\"` at the document layer,
  /// which is not the same as a JSON string delimiter.
  static JsonParseResult? tryParseJsonRepairingLiteralControlChars(
    String input, {
    JsonParseSession? session,
  }) {
    final parsed = _strictParse(input, session: session);
    if (parsed != null) {
      return parsed;
    }

    if (!looksLikeJsonRepairCandidate(input) ||
        looksLikeDocumentLevelEscapedJson(input)) {
      return null;
    }

    final repaired = JsonStringControlCharRepair.tryRepair(input);
    if (repaired == null) {
      return null;
    }

    return tryParseJson(repaired);
  }

  static JsonParseResult? _strictParse(
    String input, {
    JsonParseSession? session,
  }) {
    return session?.tryParseJson(input) ?? tryParseJson(input);
  }

  /// Attempts to parse a single JSON document, including escaped-layer decode
  /// and literal control-character repair when needed.
  static JsonParseResult? tryParseResolvableJsonDocument(String input) {
    final trimmed = input.trim();
    if (!looksLikeJsonDocument(trimmed)) {
      return null;
    }

    final direct = tryParseJson(trimmed) ??
        tryParseJsonRepairingLiteralControlChars(trimmed);
    if (direct != null) {
      return direct;
    }

    final unescaped = tryDecodeEscapedJsonLayer(trimmed);
    if (unescaped == null) {
      return null;
    }

    return tryParseJson(unescaped) ??
        tryParseJsonRepairingLiteralControlChars(unescaped);
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

  /// True when input appears intended as a single JSON value, including
  /// truncated documents missing closing braces/brackets.
  static bool looksLikeJsonDocument(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    final first = trimmed[0];
    return first == '{' || first == '[';
  }

  /// Guard for JSON repair and whole-document handling (not nested extraction).
  static bool looksLikeJsonRepairCandidate(String input) {
    return looksLikeJsonCandidate(input) || looksLikeJsonDocument(input);
  }

  static bool isJsonStringLiteral(String input) {
    return input.length >= 2 && input.startsWith('"') && input.endsWith('"');
  }

  static bool looksUrlEncoded(String input) {
    if (!input.contains('%')) {
      return false;
    }

    final matches = JugaadPatterns.percentEncoded.allMatches(input).length;
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

    if (!JugaadPatterns.base64.hasMatch(trimmed)) {
      return false;
    }

    final hasPadding = trimmed.contains('=');
    final hasBase64Chars = JugaadPatterns.base64SpecialChars.hasMatch(trimmed) ||
        JugaadPatterns.base64UrlSpecialChars.hasMatch(trimmed);
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

    if (!JugaadPatterns.hex.hasMatch(trimmed)) {
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

    if (looksLikeStandaloneUrl(input)) {
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

  static bool looksLikeNdjsonAttempt(
    String input, {
    JsonParseSession? session,
  }) {
    final trimmed = input.trim();
    if (_strictParse(trimmed, session: session) != null) {
      return false;
    }

    // Pretty-printed JSON with a literal newline inside a string value can look
    // like NDJSON because multiple lines start with `{` or `[`.
    if (tryParseResolvableJsonDocument(trimmed) != null) {
      return false;
    }

    final lines = trimmed
        .split(JugaadPatterns.newline)
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

  static bool looksLikeNdjson(
    String input, {
    JsonParseSession? session,
  }) {
    final trimmed = input.trim();
    if (_strictParse(trimmed, session: session) != null) {
      return false;
    }

    final lines = trimmed
        .split(JugaadPatterns.newline)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.length < 2) {
      return false;
    }

    var validLines = 0;
    for (final line in lines) {
      if (_strictParse(line, session: session) != null) {
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
      if (part.isEmpty || !JugaadPatterns.jwtPart.hasMatch(part)) {
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
        JugaadPatterns.escapedUnicode.hasMatch(input);
  }

  /// True when input looks like a JSON object/array with escaped quotes.
  static bool looksLikeEscapedJsonDocument(String input) {
    final trimmed = input.trim();
    if (!looksLikeJsonDocument(trimmed)) {
      return false;
    }

    return looksLikeEscapedJson(trimmed);
  }

  /// True when quotes appear escaped at the JSON document layer, e.g.
  /// `{\"key\":\"value\"}` rather than normal `{"key":"value"}`.
  static bool looksLikeDocumentLevelEscapedJson(String input) {
    final trimmed = input.trim();
    if (!looksLikeJsonDocument(trimmed)) {
      return false;
    }

    var index = 0;
    final first = trimmed[index];
    if (first == '{') {
      index = 1;
    } else if (first == '[') {
      index = 1;
      while (index < trimmed.length && _isJsonWhitespace(trimmed.codeUnitAt(index))) {
        index++;
      }
      if (index < trimmed.length && trimmed[index] == '{') {
        index++;
      }
    } else {
      return false;
    }

    while (index < trimmed.length && _isJsonWhitespace(trimmed.codeUnitAt(index))) {
      index++;
    }

    if (index + 1 >= trimmed.length) {
      return false;
    }

    return trimmed[index] == r'\' && trimmed[index + 1] == '"';
  }

  static bool _isJsonWhitespace(int codeUnit) {
    return codeUnit == 0x20 ||
        codeUnit == 0x09 ||
        codeUnit == 0x0A ||
        codeUnit == 0x0D;
  }

  /// Decodes one layer of JSON string escaping from text such as
  /// `{\"key\":\"value\"}` or a JSON string literal containing that text.
  static String? tryDecodeEscapedJsonLayer(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final parsed = tryParseJson(trimmed);
    if (parsed != null) {
      final value = parsed.value;
      if (value is String) {
        return _decodeEscapedJsonStringValue(value);
      }
      return null;
    }

    if (isJsonStringLiteral(trimmed)) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is String) {
          return _decodeEscapedJsonStringValue(decoded);
        }
      } on FormatException {
        // Fall through.
      }
    }

    if (!looksLikeDocumentLevelEscapedJson(trimmed)) {
      return null;
    }

    return _decodeJsonStringContents(trimmed);
  }

  static String? _decodeEscapedJsonStringValue(String value) {
    if (looksLikeDocumentLevelEscapedJson(value)) {
      final unescaped = _unescapeQuotedJsonDocument(value);
      if (unescaped != null) {
        return unescaped;
      }
    }

    if (looksLikeJsonCandidate(value) || tryParseJson(value) != null) {
      return value;
    }

    return null;
  }

  /// Unescapes one layer of quote/backslash encoding from a JSON document
  /// that was copied without its outer quotes, e.g. `{\"key\":\"value\"}`.
  static String? _unescapeQuotedJsonDocument(String input) {
    if (!looksLikeEscapedJson(input)) {
      return null;
    }

    final buffer = StringBuffer();
    for (var index = 0; index < input.length; index++) {
      final char = input[index];
      if (char != r'\') {
        buffer.write(char);
        continue;
      }

      if (index + 1 >= input.length) {
        return null;
      }

      final next = input[++index];
      switch (next) {
        case '"':
          buffer.write('"');
        case r'\':
          buffer.write(r'\');
        default:
          buffer
            ..write(r'\')
            ..write(next);
      }
    }

    final unescaped = buffer.toString();
    if (unescaped == input) {
      return null;
    }

    return unescaped;
  }

  static String? _decodeJsonStringContents(String contents) {
    return _unescapeQuotedJsonDocument(contents);
  }

  static bool looksLikeCurl(String input) {
    final trimmed = input.trim();
    return JugaadPatterns.curlCommand.hasMatch(trimmed);
  }

  static bool looksLikeHttpResponse(String input) {
    final firstLine = input.trim().split(JugaadPatterns.newline).first.trim();
    return JugaadPatterns.httpStatusLine.hasMatch(firstLine);
  }

  static bool looksLikeHttpHeaders(String input) {
    if (looksLikeHttpResponse(input) ||
        looksLikeCurl(input) ||
        looksLikeCookie(input) ||
        looksLikeAuthorization(input)) {
      return false;
    }

    final lines = input
        .split(JugaadPatterns.newline)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.length < 2) {
      return false;
    }

    var headerLines = 0;
    for (final line in lines) {
      if (JugaadPatterns.httpHeaderLine.hasMatch(line)) {
        headerLines++;
      }
    }

    return headerLines >= 2 && headerLines == lines.length;
  }

  static bool looksLikeStandaloneUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.contains('\n') || looksLikeCurl(trimmed)) {
      return false;
    }

    if (looksLikeJsonCandidate(trimmed)) {
      return false;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return false;
    }

    return uri.scheme == 'http' ||
        uri.scheme == 'https' ||
        uri.scheme == 'ftp';
  }

  static bool looksLikeCsv(String input) {
    if (looksLikeJsonCandidate(input.trim())) {
      return false;
    }

    if (looksLikeXml(input) || looksLikeYaml(input)) {
      return false;
    }

    final lines = input
        .split(JugaadPatterns.newline)
        .map((line) => line.trimRight())
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.length < 2) {
      return false;
    }

    if (!lines.first.contains(',')) {
      return false;
    }

    return JugaadPatterns.csvHeader.hasMatch(lines.first);
  }

  static bool looksLikeInspectableUrl(String input) {
    final trimmed = input.trim();
    if (!looksLikeStandaloneUrl(trimmed)) {
      return false;
    }

    final uri = Uri.parse(trimmed);
    final hasNonDefaultPort =
        uri.hasPort && uri.port != 80 && uri.port != 443;
    final hasFragment = uri.fragment.isNotEmpty;
    final hasMultipleQueryParams = uri.queryParameters.length >= 2;
    final hasDeepPath = uri.pathSegments.length >= 2;
    final hasInspectableQueryValues = uri.queryParameters.values.any(
      _queryParameterValueLooksInspectable,
    );

    return hasNonDefaultPort ||
        hasFragment ||
        hasMultipleQueryParams ||
        hasDeepPath ||
        hasInspectableQueryValues;
  }

  static bool _queryParameterValueLooksInspectable(String value) {
    if (looksLikeJwt(value)) {
      return true;
    }

    if (looksLikeStandaloneUrl(value)) {
      return true;
    }

    if (!value.contains('%')) {
      return false;
    }

    try {
      final decoded = Uri.decodeComponent(value);
      return looksLikeStandaloneUrl(decoded);
    } on FormatException {
      return false;
    }
  }

  static bool looksLikeYaml(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty ||
        looksLikeJsonCandidate(trimmed) ||
        looksLikeXml(trimmed) ||
        looksLikeCurl(trimmed) ||
        looksLikeHttpResponse(trimmed)) {
      return false;
    }

    final lines = trimmed
        .split(JugaadPatterns.newline)
        .map((line) => line.trimRight())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return false;
    }

    var yamlLines = 0;
    for (final line in lines) {
      if (JugaadPatterns.yamlKeyValue.hasMatch(line) ||
          JugaadPatterns.yamlListItem.hasMatch(line)) {
        yamlLines++;
      }
    }

    return yamlLines >= 2;
  }

  static bool looksLikeXml(String input) {
    final trimmed = input.trim();
    if (!trimmed.startsWith('<')) {
      return false;
    }

    return trimmed.contains('</') || trimmed.contains('/>');
  }

  static bool looksLikeCookie(String input) {
    final trimmed = input.trim();
    if (looksLikeHttpResponse(trimmed) ||
        looksLikeCurl(trimmed) ||
        looksLikeAuthorization(trimmed) ||
        looksLikeMultipart(trimmed)) {
      return false;
    }

    if (JugaadPatterns.cookieHeader.hasMatch(trimmed)) {
      return true;
    }

    return JugaadPatterns.cookieAttributes.hasMatch(trimmed);
  }

  static bool looksLikeAuthorization(String input) {
    final trimmed = input.trim();
    if (trimmed.contains('\n')) {
      return false;
    }

    if (JugaadPatterns.authorizationHeader.hasMatch(trimmed)) {
      return true;
    }

    return JugaadPatterns.authorizationScheme.hasMatch(trimmed);
  }

  static bool looksLikeMultipart(String input) {
    final trimmed = input.trim();
    if (looksLikeHttpResponse(trimmed) || looksLikeCurl(trimmed)) {
      return false;
    }

    final firstLine = trimmed.split(JugaadPatterns.newline).first.trim();
    if (!firstLine.startsWith('--') || firstLine.length < 3) {
      return false;
    }

    return JugaadPatterns.multipartDisposition.hasMatch(trimmed);
  }

  static bool looksLikeHttpError(String input) {
    if (looksLikeHttpResponse(input) ||
        looksLikeMultipart(input) ||
        looksLikeCurl(input)) {
      return false;
    }

    final trimmed = input.trim();
    if (JugaadPatterns.dioHttpError.hasMatch(trimmed)) {
      return true;
    }

    final firstLine = trimmed.split(JugaadPatterns.newline).first.trim();
    if (JugaadPatterns.httpErrorStatusLine.hasMatch(firstLine)) {
      return true;
    }

    return false;
  }
}
