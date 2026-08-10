import 'dart:convert';

import 'confidence.dart';
import 'jugaad_validator.dart';

class JwtDecodeResult {
  const JwtDecodeResult({
    required this.header,
    required this.payload,
    required this.signature,
    required this.confidence,
  });

  final Object? header;
  final Object? payload;
  final String signature;
  final Confidence confidence;
}

abstract final class JwtCodec {
  static JwtDecodeResult? tryDecode(String input) {
    final trimmed = input.trim();
    if (!JugaadValidator.looksLikeJwt(trimmed)) {
      return null;
    }

    final parts = trimmed.split('.');
    final header = _decodePart(parts[0]);
    final payload = _decodePart(parts[1]);
    if (header == null || payload == null) {
      return null;
    }

    return JwtDecodeResult(
      header: header,
      payload: payload,
      signature: parts[2],
      confidence: Confidence.high,
    );
  }

  static Object? _decodePart(String part) {
    try {
      final normalized = base64Url.normalize(part);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded);
    } on FormatException {
      return null;
    }
  }

  static Map<String, Object?> toDisplayMap(JwtDecodeResult jwt) {
    return {
      'jugaadDetected': 'JWT',
      'jugaadConfidence': jwt.confidence.label,
      'jugaadNote':
          'JWT detected and decoded. Signature was not verified.',
      'header': jwt.header,
      'payload': jwt.payload,
      'signature': jwt.signature,
    };
  }
}
