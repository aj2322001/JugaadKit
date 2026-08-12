enum DetectedFormat {
  unknown,
  json,
  escapedJson,
  urlEncoded,
  base64,
  hex,
  htmlEntities,
  nestedJson,
  wrapper,
  jsonInText,
  jsonp,
  queryString,
  ndjson,
  looseJson,
  jwt,
  compressed,
  curl,
  httpHeaders,
  url,
  csv,
  yaml,
  xml,
  httpResponse,
}

extension DetectedFormatLabel on DetectedFormat {
  String get label {
    switch (this) {
      case DetectedFormat.unknown:
        return 'Unknown';
      case DetectedFormat.json:
        return 'JSON';
      case DetectedFormat.escapedJson:
        return 'Escaped JSON';
      case DetectedFormat.urlEncoded:
        return 'URL-encoded JSON';
      case DetectedFormat.base64:
        return 'Base64';
      case DetectedFormat.hex:
        return 'Hexadecimal';
      case DetectedFormat.htmlEntities:
        return 'HTML entities';
      case DetectedFormat.nestedJson:
        return 'Nested JSON';
      case DetectedFormat.wrapper:
        return 'Wrapped JSON';
      case DetectedFormat.jsonInText:
        return 'JSON in text';
      case DetectedFormat.jsonp:
        return 'JSONP';
      case DetectedFormat.queryString:
        return 'Query string';
      case DetectedFormat.ndjson:
        return 'JSON Lines / NDJSON';
      case DetectedFormat.looseJson:
        return 'Loose JSON';
      case DetectedFormat.jwt:
        return 'JWT';
      case DetectedFormat.compressed:
        return 'Compressed data';
      case DetectedFormat.curl:
        return 'cURL';
      case DetectedFormat.httpHeaders:
        return 'HTTP Headers';
      case DetectedFormat.url:
        return 'URL';
      case DetectedFormat.csv:
        return 'CSV';
      case DetectedFormat.yaml:
        return 'YAML';
      case DetectedFormat.xml:
        return 'XML';
      case DetectedFormat.httpResponse:
        return 'HTTP Response';
    }
  }
}
