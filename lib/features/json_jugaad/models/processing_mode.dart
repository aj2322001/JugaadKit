enum ProcessingMode {
  auto,
  json,
  urlDecode,
  base64,
  hex,
  unicode,
  htmlDecode,
  jwt,
  ndjson,
}

extension ProcessingModeLabel on ProcessingMode {
  String get label {
    switch (this) {
      case ProcessingMode.auto:
        return 'Auto';
      case ProcessingMode.json:
        return 'JSON';
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

  static const selectableModes = [
    ProcessingMode.auto,
    ProcessingMode.json,
    ProcessingMode.urlDecode,
    ProcessingMode.base64,
    ProcessingMode.hex,
    ProcessingMode.unicode,
    ProcessingMode.htmlDecode,
    ProcessingMode.jwt,
    ProcessingMode.ndjson,
  ];
}
