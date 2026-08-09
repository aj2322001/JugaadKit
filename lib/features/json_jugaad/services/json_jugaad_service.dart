import 'dart:convert';

import 'package:jugaadkit/features/json_jugaad/constants/json_jugaad_constants.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_error.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_result.dart';
import 'package:jugaadkit/features/json_jugaad/models/transformation_step.dart';

/// Client-side JSON processing service. Independent of Flutter UI.
class JsonJugaadService {
  const JsonJugaadService();

  JsonJugaadResult process(String rawInput) {
    final steps = <TransformationStep>[];
    var current = rawInput;
    var transformCount = 0;

    if (current.trim().isEmpty) {
      throw const JsonJugaadError(message: 'Input is empty.');
    }

    final normalized = current.trim();
    if (normalized != current) {
      steps.add(
        const TransformationStep(
          type: TransformationType.normalized,
          description: 'Trimmed leading and trailing whitespace',
        ),
      );
      current = normalized;
      transformCount++;
    }

    for (var i = 0; i < JsonJugaadConstants.maxTransformIterations; i++) {
      var changed = false;

      final optionalResult = _tryRemoveSwiftOptional(current);
      if (optionalResult != null) {
        steps.add(
          const TransformationStep(
            type: TransformationType.removedWrapper,
            description: 'Removed Swift Optional(...) wrapper',
          ),
        );
        current = optionalResult;
        transformCount++;
        changed = true;
        continue;
      }

      final urlDecoded = _tryUrlDecode(current);
      if (urlDecoded != null) {
        steps.add(
          const TransformationStep(
            type: TransformationType.urlDecoded,
            description: 'URL-decoded input',
          ),
        );
        current = urlDecoded;
        transformCount++;
        changed = true;
        continue;
      }

      final unescaped = _tryUnescapeJsonString(current);
      if (unescaped != null) {
        steps.add(
          TransformationStep(
            type: TransformationType.decodedEscaped,
            description: 'Decoded escaped JSON string',
            detail: _preview(unescaped),
          ),
        );
        current = unescaped;
        transformCount++;
        changed = true;
        continue;
      }

      final parsed = _tryParseJson(current);
      if (parsed != null) {
        final nested = _extractNestedJson(parsed.value, steps);
        if (nested.changed) {
          transformCount += nested.transformCount;
          return JsonJugaadResult.fromValue(
            value: nested.value,
            steps: steps,
            transformCount: transformCount,
          );
        }

        if (!changed && steps.isEmpty) {
          steps.add(
            const TransformationStep(
              type: TransformationType.parsedJson,
              description: 'Parsed valid JSON',
            ),
          );
        } else {
          steps.add(
            const TransformationStep(
              type: TransformationType.parsedJson,
              description: 'Parsed JSON successfully',
            ),
          );
        }

        transformCount++;
        return JsonJugaadResult.fromValue(
          value: parsed.value,
          steps: steps,
          transformCount: transformCount,
        );
      }

      if (!changed) {
        break;
      }
    }

    throw JsonJugaadError(
      message: 'Unable to parse input as JSON.',
      detail: 'The input could not be transformed into valid JSON.',
      partialSteps: List.unmodifiable(steps),
      lastAttempt: _preview(current),
    );
  }

  String? _tryRemoveSwiftOptional(String input) {
    final patterns = <RegExp>[
      RegExp(r'^Optional\("([\s\S]*)"\)$'),
      RegExp(r"^Optional\('([\s\S]*)'\)$"),
      RegExp(r'^Optional\(([\s\S]+)\)$'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(input);
      if (match == null) {
        continue;
      }

      final inner = match.group(1)!;
      if (_looksLikeJsonCandidate(inner) || _isJsonStringLiteral(inner)) {
        return inner;
      }
    }

    return null;
  }

  String? _tryUrlDecode(String input) {
    if (!_looksUrlEncoded(input)) {
      return null;
    }

    try {
      final decoded = Uri.decodeComponent(input);
      if (decoded == input) {
        return null;
      }
      if (_looksLikeJsonCandidate(decoded) || _isJsonStringLiteral(decoded)) {
        return decoded;
      }
    } on FormatException {
      return null;
    }

    return null;
  }

  String? _tryUnescapeJsonString(String input) {
    if (_tryParseJson(input) != null) {
      return null;
    }

    if (_isJsonStringLiteral(input)) {
      try {
        final decoded = jsonDecode(input);
        if (decoded is String && decoded != input) {
          if (_looksLikeJsonCandidate(decoded) || _tryParseJson(decoded) != null) {
            return decoded;
          }
        }
      } on FormatException {
        // Fall through to wrapped-string attempt.
      }
    }

    if (!input.contains(r'\') && !input.contains(r'\"')) {
      return null;
    }

    try {
      final decoded = jsonDecode('"$input"');
      if (decoded is String &&
          decoded != input &&
          (_looksLikeJsonCandidate(decoded) || _tryParseJson(decoded) != null)) {
        return decoded;
      }
    } on FormatException {
      return null;
    }

    return null;
  }

  _ParseAttempt? _tryParseJson(String input) {
    try {
      final value = jsonDecode(input);
      return _ParseAttempt(value);
    } on FormatException {
      return null;
    }
  }

  _NestedResult _extractNestedJson(
    Object? value,
    List<TransformationStep> steps,
  ) {
    var transformCount = 0;

    final processed = _processValue(value, steps, () => transformCount++);

    return _NestedResult(
      value: processed,
      changed: transformCount > 0,
      transformCount: transformCount,
    );
  }

  Object? _processValue(
    Object? value,
    List<TransformationStep> steps,
    void Function() onTransform,
  ) {
    if (value is String) {
      final nested = _tryParseNestedString(value);
      if (nested != null) {
        steps.add(
          TransformationStep(
            type: TransformationType.extractedNestedJson,
            description: 'Extracted nested JSON from string value',
            detail: _preview(value),
          ),
        );
        onTransform();
        return _processValue(nested, steps, onTransform);
      }
      return value;
    }

    if (value is Map) {
      return value.map((key, entryValue) {
        return MapEntry(key, _processValue(entryValue, steps, onTransform));
      });
    }

    if (value is List) {
      return value
          .map((item) => _processValue(item, steps, onTransform))
          .toList();
    }

    return value;
  }

  Object? _tryParseNestedString(String value) {
    final trimmed = value.trim();
    if (!_looksLikeJsonCandidate(trimmed)) {
      return null;
    }

    final parsed = _tryParseJson(trimmed);
    if (parsed != null) {
      return parsed.value;
    }

    final unescaped = _tryUnescapeJsonString(trimmed);
    if (unescaped != null) {
      final reparsed = _tryParseJson(unescaped);
      if (reparsed != null) {
        return reparsed.value;
      }
    }

    return null;
  }

  bool _looksLikeJsonCandidate(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    final first = trimmed[0];
    final last = trimmed[trimmed.length - 1];
    return (first == '{' && last == '}') || (first == '[' && last == ']');
  }

  bool _isJsonStringLiteral(String input) {
    return input.length >= 2 &&
        input.startsWith('"') &&
        input.endsWith('"');
  }

  bool _looksUrlEncoded(String input) {
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

  String _preview(String value, {int maxLength = 80}) {
    final singleLine = value.replaceAll(RegExp(r'\s+'), ' ');
    if (singleLine.length <= maxLength) {
      return singleLine;
    }
    return '${singleLine.substring(0, maxLength)}…';
  }
}

class _ParseAttempt {
  const _ParseAttempt(this.value);

  final Object? value;
}

class _NestedResult {
  const _NestedResult({
    required this.value,
    required this.changed,
    required this.transformCount,
  });

  final Object? value;
  final bool changed;
  final int transformCount;
}
