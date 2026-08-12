import 'jugaad_validator.dart';

class ParsedCookie {
  const ParsedCookie({
    required this.name,
    required this.value,
    required this.attributes,
  });

  final String name;
  final String value;
  final List<MapEntry<String, String>> attributes;
}

class CookieParseResult {
  const CookieParseResult({required this.cookies});

  final List<ParsedCookie> cookies;
}

abstract final class CookieCodec {
  static const _attributeNames = {
    'path',
    'domain',
    'expires',
    'max-age',
    'secure',
    'httponly',
    'samesite',
    'partitioned',
  };

  static CookieParseResult? tryParse(String input) {
    if (!JugaadValidator.looksLikeCookie(input)) {
      return null;
    }

    final lines = input
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return null;
    }

    final cookies = <ParsedCookie>[];
    for (final line in lines) {
      final prefixMatch = RegExp(
        r'^(Cookie|Set-Cookie)\s*:\s*(.*)$',
        caseSensitive: false,
      ).firstMatch(line);

      if (prefixMatch != null) {
        final headerName = prefixMatch.group(1)!.toLowerCase();
        final value = prefixMatch.group(2)!.trim();
        if (value.isEmpty) {
          return null;
        }

        if (headerName == 'set-cookie') {
          final cookie = _parseSetCookieValue(value);
          if (cookie == null) {
            return null;
          }
          cookies.add(cookie);
        } else {
          cookies.addAll(_parseCookieHeaderValue(value));
        }
        continue;
      }

      final cookie = _parseSetCookieValue(line);
      if (cookie == null) {
        return null;
      }
      cookies.add(cookie);
    }

    if (cookies.isEmpty) {
      return null;
    }

    return CookieParseResult(cookies: cookies);
  }

  static String format(CookieParseResult result) {
    final buffer = StringBuffer();
    for (var i = 0; i < result.cookies.length; i++) {
      if (i > 0) {
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
      }

      final cookie = result.cookies[i];
      buffer
        ..writeln('Cookie')
        ..writeln()
        ..writeln('Name:')
        ..writeln(cookie.name)
        ..writeln()
        ..writeln('Value:')
        ..writeln(cookie.value);

      if (cookie.attributes.isNotEmpty) {
        buffer
          ..writeln()
          ..writeln('Attributes:');
        for (final attribute in cookie.attributes) {
          buffer.writeln('${attribute.key.padRight(10)} ${attribute.value}');
        }
      }
    }

    return buffer.toString().trimRight();
  }

  static List<ParsedCookie> _parseCookieHeaderValue(String value) {
    final cookies = <ParsedCookie>[];
    for (final part in value.split(';')) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      final cookie = _parseNameValue(trimmed);
      if (cookie == null) {
        continue;
      }
      cookies.add(ParsedCookie(name: cookie.key, value: cookie.value, attributes: const []));
    }

    return cookies;
  }

  static ParsedCookie? _parseSetCookieValue(String value) {
    final parts = value.split(';');
    if (parts.isEmpty) {
      return null;
    }

    final nameValue = _parseNameValue(parts.first.trim());
    if (nameValue == null) {
      return null;
    }

    final attributes = <MapEntry<String, String>>[];
    for (var i = 1; i < parts.length; i++) {
      final part = parts[i].trim();
      if (part.isEmpty) {
        continue;
      }

      final attribute = _parseAttribute(part);
      if (attribute == null) {
        return null;
      }
      attributes.add(attribute);
    }

    return ParsedCookie(
      name: nameValue.key,
      value: nameValue.value,
      attributes: attributes,
    );
  }

  static MapEntry<String, String>? _parseNameValue(String part) {
    final index = part.indexOf('=');
    if (index <= 0) {
      return null;
    }

    final name = part.substring(0, index).trim();
    final value = part.substring(index + 1).trim();
    if (name.isEmpty) {
      return null;
    }

    return MapEntry(name, value);
  }

  static MapEntry<String, String>? _parseAttribute(String part) {
    final index = part.indexOf('=');
    if (index < 0) {
      final flag = part.trim();
      if (flag.isEmpty) {
        return null;
      }
      return MapEntry(_titleCase(flag), 'true');
    }

    final name = part.substring(0, index).trim();
    final value = part.substring(index + 1).trim();
    if (name.isEmpty || !_attributeNames.contains(name.toLowerCase())) {
      return null;
    }

    return MapEntry(_titleCase(name), value.isEmpty ? 'true' : value);
  }

  static String _titleCase(String value) {
    if (value.toLowerCase() == 'max-age') {
      return 'Max-Age';
    }
    if (value.toLowerCase() == 'httponly') {
      return 'HttpOnly';
    }
    if (value.toLowerCase() == 'samesite') {
      return 'SameSite';
    }
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }
}
