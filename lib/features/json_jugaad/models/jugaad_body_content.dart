import 'json_repair_highlight.dart';

class JugaadBodyContent {
  const JugaadBodyContent.json(
    this.jsonValue, {
    this.repairHighlights = const [],
  })  : plainText = null,
        xmlText = null;

  const JugaadBodyContent.plain(this.plainText)
      : jsonValue = null,
        xmlText = null,
        repairHighlights = const [];

  const JugaadBodyContent.xml(this.xmlText)
      : jsonValue = null,
        plainText = null,
        repairHighlights = const [];

  final Object? jsonValue;
  final String? plainText;
  final String? xmlText;
  final List<JsonRepairHighlight> repairHighlights;

  bool get isJson => jsonValue != null;
  bool get isXml => xmlText != null;
  bool get isPlain => plainText != null;
}
