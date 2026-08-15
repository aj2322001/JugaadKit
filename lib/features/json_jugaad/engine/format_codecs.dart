import '../models/json_repair_highlight.dart';
import 'json_repair_engine.dart';
import 'jugaad_validator.dart';

class LooseJsonRepairResult {
  const LooseJsonRepairResult({
    required this.repaired,
    required this.description,
    required this.highlights,
    required this.kind,
  });

  final String repaired;
  final String description;
  final List<JsonRepairHighlight> highlights;
  final JsonRepairKind kind;
}

abstract final class LooseJsonRepair {
  static LooseJsonRepairResult? tryRepair(String input) {
    final attempt = JsonRepairEngine.tryRepair(input);
    if (attempt == null) {
      return null;
    }

    return LooseJsonRepairResult(
      repaired: attempt.repaired,
      description: attempt.description,
      highlights: attempt.highlights,
      kind: attempt.kind,
    );
  }
}

class QueryStringParseResult {
  const QueryStringParseResult(this.values);

  final Map<String, String> values;
}

abstract final class QueryStringCodec {
  static QueryStringParseResult? tryParse(String input) {
    if (!JugaadValidator.looksLikeQueryString(input)) {
      return null;
    }

    final values = <String, String>{};
    for (final pair in input.split('&')) {
      final index = pair.indexOf('=');
      if (index <= 0) {
        continue;
      }
      final key = Uri.decodeQueryComponent(pair.substring(0, index));
      final value = Uri.decodeQueryComponent(pair.substring(index + 1));
      values[key] = value;
    }

    if (values.length < 2) {
      return null;
    }

    return QueryStringParseResult(values);
  }

  static Map<String, Object?> toDisplayMap(QueryStringParseResult parsed) {
    final result = <String, Object?>{};
    for (final entry in parsed.values.entries) {
      result[entry.key] = _parseNestedValue(entry.value);
    }
    return result;
  }

  static Object? _parseNestedValue(String value) {
    String decoded = value;
    try {
      decoded = Uri.decodeQueryComponent(value);
    } on FormatException {
      decoded = value;
    }

    final parsed = JugaadValidator.tryParseJson(decoded);
    if (parsed != null) {
      return parsed.value;
    }

    if (decoded == 'true') {
      return true;
    }
    if (decoded == 'false') {
      return false;
    }

    return decoded;
  }
}

class NdjsonParseResult {
  const NdjsonParseResult(this.lines);

  final List<Object?> lines;
}

abstract final class NdjsonCodec {
  static NdjsonParseResult? tryParse(String input) {
    if (!JugaadValidator.looksLikeNdjson(input)) {
      return null;
    }

    final lines = <Object?>[];
    for (final line in input.split(RegExp(r'\r?\n'))) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final parsed = JugaadValidator.tryParseJson(trimmed);
      if (parsed == null) {
        return null;
      }
      lines.add(parsed.value);
    }

    return NdjsonParseResult(lines);
  }
}

abstract final class JsonExtractor {
  static final _objectPattern = RegExp(r'(\{[\s\S]*\})');
  static final _arrayPattern = RegExp(r'(\[[\s\S]*\])');

  static String? extractFromText(String input) {
    if (JugaadValidator.looksLikeJsonRepairCandidate(input.trim())) {
      return null;
    }

    for (final pattern in [_objectPattern, _arrayPattern]) {
      final match = pattern.firstMatch(input);
      if (match == null) {
        continue;
      }
      final candidate = match.group(1)!;
      if (JugaadValidator.tryParseJson(candidate) != null) {
        return candidate;
      }
      final repaired = LooseJsonRepair.tryRepair(candidate);
      if (repaired != null &&
          JugaadValidator.tryParseJson(repaired.repaired) != null) {
        return repaired.repaired;
      }
    }

    return null;
  }
}

class WrapperMatch {
  const WrapperMatch({required this.inner, required this.description});

  final String inner;
  final String description;
}

abstract final class WrapperCodec {
  static final _patterns = <_WrapperPattern>[
    _WrapperPattern(
      RegExp(r'^Optional\("([\s\S]*)"\)$'),
      'Removed Swift Optional(...) wrapper',
    ),
    _WrapperPattern(
      RegExp(r"^Optional\('([\s\S]*)'\)$"),
      'Removed Swift Optional(...) wrapper',
    ),
    _WrapperPattern(
      RegExp(r'^Optional\(([\s\S]+)\)$'),
      'Removed Swift Optional(...) wrapper',
    ),
    _WrapperPattern(
      RegExp(r'^Result\.success\(([\s\S]+)\)$'),
      'Removed Result.success(...) wrapper',
    ),
    _WrapperPattern(
      RegExp(r'^data:\s*([\s\S]+)$', caseSensitive: false),
      'Removed data: wrapper',
    ),
    _WrapperPattern(
      RegExp(r'^response\s*=\s*([\s\S]+)$', caseSensitive: false),
      'Removed response = wrapper',
    ),
  ];

  static WrapperMatch? tryUnwrap(String input) {
    for (final pattern in _patterns) {
      final match = pattern.regex.firstMatch(input);
      if (match == null) {
        continue;
      }
      final inner = match.group(1)!.trim();
      if (JugaadValidator.isMeaningfulDecodedString(inner) ||
          JugaadValidator.tryParseJson(inner) != null) {
        return WrapperMatch(inner: inner, description: pattern.description);
      }
    }
    return null;
  }
}

class _WrapperPattern {
  const _WrapperPattern(this.regex, this.description);

  final RegExp regex;
  final String description;
}

abstract final class JsonpCodec {
  static final _pattern = RegExp(r'^[A-Za-z_$][\w$]*\(([\s\S]*)\);?$');

  static String? tryExtract(String input) {
    final trimmed = input.trim();
    if (trimmed.startsWith('Optional(') ||
        trimmed.startsWith('Result.') ||
        trimmed.startsWith('data:') ||
        RegExp(r'^response\s*=', caseSensitive: false).hasMatch(trimmed)) {
      return null;
    }

    final match = _pattern.firstMatch(trimmed);
    if (match == null) {
      return null;
    }
    final inner = match.group(1)!.trim();
    if (JugaadValidator.tryParseJson(inner) != null) {
      return inner;
    }
    return null;
  }
}

/// Placeholder for future gzip/deflate support without faking behavior.
abstract interface class CompressedPayloadDecoder {
  String? tryDecompress(String input);
}

final class UnsupportedCompressedPayloadDecoder
    implements CompressedPayloadDecoder {
  const UnsupportedCompressedPayloadDecoder();

  @override
  String? tryDecompress(String input) => null;
}
