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
    return null;
  }
}
