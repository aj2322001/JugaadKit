import 'dart:convert';

import 'jugaad_validator.dart';

abstract final class HexCodecUtil {
  static String? tryDecode(String input) {
    final trimmed = input.trim();
    if (!JugaadValidator.looksLikeHex(trimmed)) {
      return null;
    }

    try {
      final bytes = <int>[];
      for (var i = 0; i < trimmed.length; i += 2) {
        bytes.add(int.parse(trimmed.substring(i, i + 2), radix: 16));
      }
      final decoded = utf8.decode(bytes);
      if (JugaadValidator.isMeaningfulDecodedString(decoded)) {
        return decoded;
      }
    } on FormatException {
      return null;
    }

    return null;
  }
}
