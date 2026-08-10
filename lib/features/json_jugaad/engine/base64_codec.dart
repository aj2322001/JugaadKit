import 'dart:convert';

import 'jugaad_validator.dart';

abstract final class Base64CodecUtil {
  static String? tryDecode(String input) {
    final trimmed = input.trim();
    if (!JugaadValidator.looksLikeBase64(trimmed)) {
      return null;
    }

    for (final decoder in [_decodeStandard, _decodeUrlSafe]) {
      final decoded = decoder(trimmed);
      if (decoded != null && JugaadValidator.isMeaningfulDecodedString(decoded)) {
        return decoded;
      }
    }

    return null;
  }

  static String? _decodeStandard(String input) {
    try {
      return utf8.decode(base64.decode(input));
    } on FormatException {
      return null;
    }
  }

  static String? _decodeUrlSafe(String input) {
    try {
      final normalized = base64Url.normalize(input);
      return utf8.decode(base64Url.decode(normalized));
    } on FormatException {
      return null;
    }
  }
}
