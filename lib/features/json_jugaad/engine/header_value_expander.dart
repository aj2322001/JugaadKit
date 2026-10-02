import 'authorization_codec.dart';
import 'cookie_codec.dart';
import 'jugaad_validator.dart';

/// Turns request header values that hide structured data (JSON values,
/// cookie lists, decodable Authorization credentials) into JSON values.
abstract final class HeaderValueExpander {
  static List<MapEntry<String, Object?>> expandAll(
    List<MapEntry<String, String>> headers,
  ) {
    final expanded = <MapEntry<String, Object?>>[];
    for (final header in headers) {
      final value = tryExpand(header.key, header.value);
      if (value != null) {
        expanded.add(MapEntry(header.key, value));
      }
    }
    return expanded;
  }

  static Object? tryExpand(String name, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final json = _tryJsonContainer(trimmed);
    if (json != null) {
      return json;
    }

    switch (name.trim().toLowerCase()) {
      case 'cookie':
        return _tryCookie(trimmed);
      case 'authorization':
      case 'proxy-authorization':
        return _tryAuthorization(trimmed);
    }
    return null;
  }

  static Object? _tryJsonContainer(String value) {
    if (!value.startsWith('{') && !value.startsWith('[')) {
      return null;
    }
    final parsed = JugaadValidator.tryParseJson(value)?.value;
    return parsed is Map || parsed is List ? parsed : null;
  }

  static Object? _tryCookie(String value) {
    final parsed = CookieCodec.tryParse('Cookie: $value');
    if (parsed == null || parsed.cookies.length < 2) {
      return null;
    }
    return CookieCodec.toJsonMap(parsed);
  }

  static Object? _tryAuthorization(String value) {
    final data = AuthorizationCodec.tryParse('Authorization: $value');
    if (data == null) {
      return null;
    }

    final jwt = data.jwt;
    if (jwt != null) {
      return {
        'scheme': data.scheme,
        'header': jwt.header,
        'payload': jwt.payload,
      };
    }

    if (data.decodedUsername != null) {
      return {
        'scheme': data.scheme,
        'username': data.decodedUsername,
        'password': data.decodedPassword,
      };
    }

    return null;
  }
}
