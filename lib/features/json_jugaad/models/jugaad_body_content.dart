class JugaadBodyContent {
  const JugaadBodyContent.json(this.jsonValue)
      : plainText = null,
        xmlText = null;

  const JugaadBodyContent.plain(this.plainText)
      : jsonValue = null,
        xmlText = null;

  const JugaadBodyContent.xml(this.xmlText)
      : jsonValue = null,
        plainText = null;

  final Object? jsonValue;
  final String? plainText;
  final String? xmlText;

  bool get isJson => jsonValue != null;
  bool get isXml => xmlText != null;
  bool get isPlain => plainText != null;
}
