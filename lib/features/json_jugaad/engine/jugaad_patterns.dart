/// Shared, compiled patterns used across JSON Jugaad engine code.
abstract final class JugaadPatterns {
  static final newline = RegExp(r'\r?\n');

  static final percentEncoded = RegExp(r'%[0-9A-Fa-f]{2}');
  static final base64 = RegExp(r'^[A-Za-z0-9+/_-]+={0,2}$');
  static final base64SpecialChars = RegExp(r'[+/]');
  static final base64UrlSpecialChars = RegExp(r'[-_]');
  static final hex = RegExp(r'^[0-9a-fA-F]+$');

  static final jwtPart = RegExp(r'^[A-Za-z0-9_-]+$');
  static final escapedUnicode = RegExp(r'\\u[0-9a-fA-F]{4}');

  static final curlCommand = RegExp(r'^curl(\s|$)', caseSensitive: false);
  static final httpStatusLine =
      RegExp(r'^HTTP/\d(?:\.\d)?\s+\d{3}\b', caseSensitive: false);
  static final httpHeaderLine =
      RegExp(r"^[!#$%&'*+.^_`|~0-9A-Za-z-]+:\s*.+$");
  static final csvHeader = RegExp(r'^[A-Za-z_][\w-]*(,|$)');
  static final yamlKeyValue = RegExp(r'^\s*[\w.-]+:\s*.+$');
  static final yamlListItem = RegExp(r'^\s*-\s+.+$');

  static final cookieHeader =
      RegExp(r'^(Cookie|Set-Cookie)\s*:', caseSensitive: false);
  static final cookieAttributes = RegExp(
    r"^[^=;\s]+=[^;]+;\s*(Path|Domain|Expires|Max-Age|Secure|HttpOnly|SameSite)\b",
    caseSensitive: false,
  );
  static final authorizationHeader =
      RegExp(r'^Authorization\s*:\s*\S+', caseSensitive: false);
  static final authorizationScheme = RegExp(
    r'^(Bearer|Basic|Digest)\s+\S+\s*$',
    caseSensitive: false,
  );
  static final multipartDisposition = RegExp(
    r'Content-Disposition:\s*form-data',
    caseSensitive: false,
  );
  static final dioHttpError = RegExp(
    r'DioException\b.*status code\s+[45]\d{2}',
    caseSensitive: false,
    dotAll: true,
  );
  static final httpErrorStatusLine =
      RegExp(r'^HTTP\s+[45]\d{2}\b', caseSensitive: false);
}
