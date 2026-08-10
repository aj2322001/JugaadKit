import '../models/processing_mode.dart';
import 'jugaad_validator.dart';

abstract final class ProcessingModeSuggestions {
  static List<ProcessingMode> forInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    final suggestions = <ProcessingMode>[];

    if (JugaadValidator.tryParseJson(trimmed) != null ||
        JugaadValidator.looksLikeJsonCandidate(trimmed) ||
        JugaadValidator.looksLikeEscapedJson(trimmed)) {
      suggestions.add(ProcessingMode.json);
    }
    if (JugaadValidator.looksUrlEncoded(trimmed)) {
      suggestions.add(ProcessingMode.urlDecode);
    }
    if (JugaadValidator.looksLikeBase64(trimmed)) {
      suggestions.add(ProcessingMode.base64);
    }
    if (JugaadValidator.looksLikeHex(trimmed)) {
      suggestions.add(ProcessingMode.hex);
    }
    if (JugaadValidator.containsHtmlEntities(trimmed)) {
      suggestions.add(ProcessingMode.htmlDecode);
    }
    if (JugaadValidator.looksLikeEscapedJson(trimmed) &&
        !suggestions.contains(ProcessingMode.unicode)) {
      suggestions.add(ProcessingMode.unicode);
    }
    if (JugaadValidator.looksLikeJwt(trimmed)) {
      suggestions.add(ProcessingMode.jwt);
    }
    if (JugaadValidator.looksLikeNdjson(trimmed) ||
        JugaadValidator.looksLikeNdjsonAttempt(trimmed)) {
      suggestions.add(ProcessingMode.ndjson);
    }

    if (suggestions.isEmpty) {
      return const [
        ProcessingMode.json,
        ProcessingMode.base64,
        ProcessingMode.urlDecode,
      ];
    }

    return suggestions;
  }
}
