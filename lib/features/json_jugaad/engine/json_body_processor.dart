import 'dart:convert';

import '../constants/json_jugaad_constants.dart';
import '../models/json_repair_highlight.dart';
import 'format_codecs.dart';
import 'jugaad_validator.dart';

class JsonBodyProcessResult {
  const JsonBodyProcessResult({
    required this.value,
    required this.repairHighlights,
    required this.wasRepaired,
  });

  final Object? value;
  final List<JsonRepairHighlight> repairHighlights;
  final bool wasRepaired;
}

abstract final class JsonBodyProcessor {
  static JsonBodyProcessResult? tryProcess(
    String body, {
    String? contentType,
  }) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (!_shouldAttemptJson(trimmed, contentType)) {
      return null;
    }

    final parsed = JugaadValidator.tryParseJson(trimmed);
    if (parsed != null) {
      return JsonBodyProcessResult(
        value: parsed.value,
        repairHighlights: const [],
        wasRepaired: false,
      );
    }

    var working = trimmed;
    final highlights = <JsonRepairHighlight>[];
    for (var i = 0; i < JsonJugaadConstants.maxTransformIterations; i++) {
      final repair = LooseJsonRepair.tryRepair(working);
      if (repair == null) {
        break;
      }

      highlights.addAll(repair.highlights);
      working = repair.repaired;

      final reparsed = JugaadValidator.tryParseJson(working);
      if (reparsed != null) {
        return JsonBodyProcessResult(
          value: reparsed.value,
          repairHighlights: highlights,
          wasRepaired: true,
        );
      }
    }

    return null;
  }

  static String? formatPrettyJson(
    String body, {
    String? contentType,
  }) {
    final processed = tryProcess(body, contentType: contentType);
    if (processed == null) {
      return null;
    }

    return const JsonEncoder.withIndent('  ').convert(processed.value);
  }

  static String? contentTypeFromHeaders(List<MapEntry<String, String>> headers) {
    for (final header in headers) {
      if (header.key.toLowerCase() == 'content-type') {
        return header.value;
      }
    }
    return null;
  }

  static bool _shouldAttemptJson(String trimmed, String? contentType) {
    if (contentType != null &&
        contentType.toLowerCase().contains('application/json')) {
      return true;
    }

    return JugaadValidator.looksLikeJsonRepairCandidate(trimmed);
  }
}
