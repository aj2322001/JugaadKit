enum ProcessingMode {
  auto,
  json,
  curl,
  httpHeaders,
  url,
  csv,
  yaml,
  xml,
  httpResponse,
  urlDecode,
  base64,
  hex,
  unicode,
  htmlDecode,
  jwt,
  ndjson,
  cookie,
  authorization,
  multipart,
  httpError,
}

extension ProcessingModeLabel on ProcessingMode {
  String get label {
    switch (this) {
      case ProcessingMode.auto:
        return 'Auto';
      case ProcessingMode.json:
        return 'JSON';
      case ProcessingMode.curl:
        return 'cURL';
      case ProcessingMode.httpHeaders:
        return 'HTTP Headers';
      case ProcessingMode.url:
        return 'URL';
      case ProcessingMode.csv:
        return 'CSV';
      case ProcessingMode.yaml:
        return 'YAML';
      case ProcessingMode.xml:
        return 'XML';
      case ProcessingMode.httpResponse:
        return 'HTTP Response';
      case ProcessingMode.urlDecode:
        return 'URL Decode';
      case ProcessingMode.base64:
        return 'Base64';
      case ProcessingMode.hex:
        return 'Hex';
      case ProcessingMode.unicode:
        return 'Unicode';
      case ProcessingMode.htmlDecode:
        return 'HTML Decode';
      case ProcessingMode.jwt:
        return 'JWT';
      case ProcessingMode.ndjson:
        return 'NDJSON';
      case ProcessingMode.cookie:
        return 'Cookie';
      case ProcessingMode.authorization:
        return 'Authorization Header';
      case ProcessingMode.multipart:
        return 'Multipart Request';
      case ProcessingMode.httpError:
        return 'HTTP Error';
    }
  }

  String get menuLabel {
    switch (this) {
      case ProcessingMode.auto:
        return '✨ Auto';
      default:
        return label;
    }
  }

  /// Lowercase terms used by the mode picker search field.
  String get searchKeywords {
    switch (this) {
      case ProcessingMode.auto:
        return 'auto detect magic';
      case ProcessingMode.json:
        return 'json object array';
      case ProcessingMode.curl:
        return 'curl command request';
      case ProcessingMode.httpHeaders:
        return 'http headers header';
      case ProcessingMode.url:
        return 'url link uri';
      case ProcessingMode.csv:
        return 'csv comma separated table';
      case ProcessingMode.yaml:
        return 'yaml yml config';
      case ProcessingMode.xml:
        return 'xml markup';
      case ProcessingMode.httpResponse:
        return 'http response status headers body';
      case ProcessingMode.urlDecode:
        return 'url decode percent encoded';
      case ProcessingMode.base64:
        return 'base64 b64 encoded';
      case ProcessingMode.hex:
        return 'hex hexadecimal bytes';
      case ProcessingMode.unicode:
        return 'unicode escape u';
      case ProcessingMode.htmlDecode:
        return 'html decode entity entities';
      case ProcessingMode.jwt:
        return 'jwt token json web';
      case ProcessingMode.ndjson:
        return 'ndjson json lines newline delimited';
      case ProcessingMode.cookie:
        return 'cookie set-cookie session';
      case ProcessingMode.authorization:
        return 'authorization auth bearer basic digest header';
      case ProcessingMode.multipart:
        return 'multipart form-data boundary upload file';
      case ProcessingMode.httpError:
        return 'http error dio exception status code 4xx 5xx';
    }
  }

  bool matchesSearch(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    return menuLabel.toLowerCase().contains(normalized) ||
        label.toLowerCase().contains(normalized) ||
        name.toLowerCase().contains(normalized) ||
        searchKeywords.contains(normalized);
  }

  static const selectableModes = [
    ProcessingMode.auto,
    ProcessingMode.json,
    ProcessingMode.curl,
    ProcessingMode.httpHeaders,
    ProcessingMode.url,
    ProcessingMode.csv,
    ProcessingMode.yaml,
    ProcessingMode.xml,
    ProcessingMode.httpResponse,
    ProcessingMode.urlDecode,
    ProcessingMode.base64,
    ProcessingMode.hex,
    ProcessingMode.unicode,
    ProcessingMode.htmlDecode,
    ProcessingMode.jwt,
    ProcessingMode.ndjson,
    ProcessingMode.cookie,
    ProcessingMode.authorization,
    ProcessingMode.multipart,
    ProcessingMode.httpError,
  ];
}
