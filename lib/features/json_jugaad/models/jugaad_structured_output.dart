import 'jugaad_body_content.dart';

enum JugaadSectionType {
  httpStatus,
  headers,
  methodUrl,
  keyValueList,
  body,
  xmlDocument,
}

class JugaadOutputSection {
  const JugaadOutputSection({
    required this.title,
    required this.type,
    this.statusCode,
    this.statusText,
    this.headers,
    this.structuredHeaderValues,
    this.method,
    this.url,
    this.fields,
    this.body,
    this.text,
  });

  final String title;
  final JugaadSectionType type;
  final int? statusCode;
  final String? statusText;
  final List<MapEntry<String, String>>? headers;

  /// Header name → decoded JSON value shown in place of the raw string.
  final Map<String, Object?>? structuredHeaderValues;
  final String? method;
  final String? url;
  final List<MapEntry<String, String>>? fields;
  final JugaadBodyContent? body;
  final String? text;
}

class JugaadStructuredOutput {
  const JugaadStructuredOutput({required this.sections});

  final List<JugaadOutputSection> sections;

  Object? get jsonBodyValue {
    for (final section in sections) {
      final body = section.body;
      if (body != null && body.isJson) {
        return body.jsonValue;
      }
    }
    for (final section in sections) {
      final values = section.structuredHeaderValues;
      if (values != null && values.isNotEmpty) {
        return values.values.first;
      }
    }
    return null;
  }

  bool get hasStructuredHeaderJson => sections.any(
        (section) => section.structuredHeaderValues?.isNotEmpty ?? false,
      );
}
