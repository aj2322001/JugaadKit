import '../models/jugaad_structured_output.dart';
import 'body_content_classifier.dart';
import 'curl_codec.dart';
import 'http_headers_codec.dart';
import 'http_response_codec.dart';

abstract final class StructuredOutputBuilder {
  static JugaadStructuredOutput fromHttpResponse(HttpResponseData response) {
    final sections = <JugaadOutputSection>[
      JugaadOutputSection(
        title: 'Status',
        type: JugaadSectionType.httpStatus,
        statusCode: response.statusCode,
        statusText: response.statusText,
      ),
    ];

    if (response.headers.isNotEmpty) {
      sections.add(
        JugaadOutputSection(
          title: 'Headers',
          type: JugaadSectionType.headers,
          headers: response.headers,
        ),
      );
    }

    sections.add(
      JugaadOutputSection(
        title: 'Body',
        type: JugaadSectionType.body,
        body: BodyContentClassifier.classify(response.body),
      ),
    );

    return JugaadStructuredOutput(sections: sections);
  }

  static JugaadStructuredOutput fromCurl(CurlRequest request) {
    final sections = <JugaadOutputSection>[
      JugaadOutputSection(
        title: 'Request',
        type: JugaadSectionType.methodUrl,
        method: request.method,
        url: request.url,
      ),
    ];

    if (request.headers.isNotEmpty) {
      sections.add(
        JugaadOutputSection(
          title: 'Headers',
          type: JugaadSectionType.headers,
          headers: request.headers,
        ),
      );
    }

    final body = request.body;
    if (body != null && body.trim().isNotEmpty) {
      sections.add(
        JugaadOutputSection(
          title: 'Body',
          type: JugaadSectionType.body,
          body: BodyContentClassifier.classify(body),
        ),
      );
    }

    return JugaadStructuredOutput(sections: sections);
  }

  static JugaadStructuredOutput fromHttpHeaders(HttpHeaderBlock block) {
    return JugaadStructuredOutput(
      sections: [
        JugaadOutputSection(
          title: 'Headers',
          type: JugaadSectionType.headers,
          headers: block.headers,
        ),
      ],
    );
  }

  static JugaadStructuredOutput fromUrl(Uri uri) {
    final fields = <MapEntry<String, String>>[
      MapEntry('Scheme', uri.scheme),
      MapEntry('Host', uri.host),
    ];

    if (uri.hasPort) {
      fields.add(MapEntry('Port', uri.port.toString()));
    }

    fields.add(MapEntry('Path', uri.path.isEmpty ? '/' : uri.path));

    for (final entry in uri.queryParameters.entries) {
      fields.add(MapEntry('Query', '${entry.key} = ${entry.value}'));
    }

    if (uri.fragment.isNotEmpty) {
      fields.add(MapEntry('Fragment', uri.fragment));
    }

    return JugaadStructuredOutput(
      sections: [
        JugaadOutputSection(
          title: 'URL Breakdown',
          type: JugaadSectionType.keyValueList,
          fields: fields,
        ),
      ],
    );
  }

  static JugaadStructuredOutput fromXml(String formattedXml) {
    return JugaadStructuredOutput(
      sections: [
        JugaadOutputSection(
          title: 'XML',
          type: JugaadSectionType.xmlDocument,
          text: formattedXml,
        ),
      ],
    );
  }
}
