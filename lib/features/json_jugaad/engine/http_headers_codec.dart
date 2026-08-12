import 'jugaad_validator.dart';

class HttpHeaderBlock {
  const HttpHeaderBlock({required this.headers});

  final List<MapEntry<String, String>> headers;
}

abstract final class HttpHeadersCodec {
  static HttpHeaderBlock? tryParse(String input) {
    if (!JugaadValidator.looksLikeHttpHeaders(input)) {
      return null;
    }

    final lines = input
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trimRight())
        .where((line) => line.trim().isNotEmpty)
        .toList();

    final headers = <MapEntry<String, String>>[];
    for (final line in lines) {
      final header = _parseHeaderLine(line.trim());
      if (header == null) {
        return null;
      }
      headers.add(header);
    }

    if (headers.length < 2) {
      return null;
    }

    return HttpHeaderBlock(headers: headers);
  }

  static String format(HttpHeaderBlock block) {
    final buffer = StringBuffer()..writeln('Headers:')..writeln();
    for (final header in block.headers) {
      buffer.writeln('${header.key}: ${header.value}');
    }
    return buffer.toString().trimRight();
  }

  static MapEntry<String, String>? _parseHeaderLine(String line) {
    final index = line.indexOf(':');
    if (index <= 0) {
      return null;
    }

    final name = line.substring(0, index).trim();
    final value = line.substring(index + 1).trim();
    if (name.isEmpty || !_isValidHeaderName(name)) {
      return null;
    }

    return MapEntry(name, value);
  }

  static bool _isValidHeaderName(String name) {
    return RegExp(r"^[!#$%&'*+.^_`|~0-9A-Za-z-]+$").hasMatch(name);
  }
}
