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
    if (detectedFormat == DetectedFormat.curl) {
      return 'cURL';
    }
    if (detectedFormat == DetectedFormat.httpHeaders) {
      return 'HTTP Headers';
    }
    if (detectedFormat == DetectedFormat.url) {
      return 'URL Breakdown';
    }
    if (detectedFormat == DetectedFormat.csv) {
      return 'CSV';
    }
    if (detectedFormat == DetectedFormat.yaml) {
      return 'YAML';
    }
    if (detectedFormat == DetectedFormat.xml) {
      return 'XML';
    }
    if (detectedFormat == DetectedFormat.httpResponse) {
      return 'HTTP Response';
    }
    if (detectedFormat == DetectedFormat.cookie) {
      return 'Cookie';
    }
    if (detectedFormat == DetectedFormat.authorization) {
      return 'Authorization Header';
    }
    if (detectedFormat == DetectedFormat.multipart) {
      return 'Multipart Request';
    }
    if (detectedFormat == DetectedFormat.httpError) {
      return 'HTTP Error';
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
      TransformationType.parsedCurl => 'cURL',
      TransformationType.parsedHttpHeaders => 'HTTP Headers',
      TransformationType.parsedUrl => 'URL Breakdown',
      TransformationType.parsedCsv => 'CSV',
      TransformationType.parsedYaml => 'YAML',
      TransformationType.formattedXml => 'XML',
      TransformationType.parsedHttpResponse => 'HTTP Response',
      TransformationType.parsedCookie => 'Cookie',
      TransformationType.parsedAuthorization => 'Authorization Header',
      TransformationType.parsedMultipart => 'Multipart Request',
      TransformationType.parsedHttpError => 'HTTP Error',
      _ => null,
    };
  }
}
