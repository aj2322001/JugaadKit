import '../models/processing_mode.dart';
import '../models/transformation_step.dart';
import 'detected_format.dart';

abstract final class DetectionSummary {
  static String build({
    required List<TransformationStep> steps,
    required DetectedFormat detectedFormat,
    required ProcessingMode processingMode,
    required bool isAutomatic,
  }) {
    if (!isAutomatic) {
      return processingMode.label;
    }

    if (detectedFormat == DetectedFormat.jwt) {
      return 'JWT';
    }
    if (detectedFormat == DetectedFormat.ndjson) {
      return 'JSON Lines / NDJSON';
    }
    if (detectedFormat == DetectedFormat.queryString) {
      return 'Query string';
    }

    final chain = <String>[];
    for (final step in steps) {
      final label = _stepLabel(step.type);
      if (label != null && (chain.isEmpty || chain.last != label)) {
        chain.add(label);
      }
    }

    if (chain.isEmpty) {
      return detectedFormat == DetectedFormat.unknown
          ? 'Unknown'
          : detectedFormat.label;
    }

    if (chain.length == 1) {
      return chain.first;
    }

    return chain.join(' → ');
  }

  static String? _stepLabel(TransformationType type) {
    return switch (type) {
      TransformationType.urlDecoded => 'URL Encoded JSON',
      TransformationType.base64Decoded => 'Base64',
      TransformationType.hexDecoded => 'Hex',
      TransformationType.htmlEntitiesDecoded => 'HTML entities',
      TransformationType.decodedEscaped => 'Escaped JSON',
      TransformationType.jsonExtracted => 'JSON in text',
      TransformationType.jsonpExtracted => 'JSONP',
      TransformationType.removedWrapper => 'Wrapped JSON',
      TransformationType.trailingCommaRemoved ||
      TransformationType.commentRemoved =>
        'Loose JSON',
      TransformationType.parsedJson => 'JSON',
      TransformationType.parsedNdjson => 'NDJSON',
      TransformationType.detectedJwt => 'JWT',
      TransformationType.extractedNestedJson => 'Nested JSON',
      _ => null,
    };
  }
}
