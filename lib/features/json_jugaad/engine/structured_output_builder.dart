import '../models/jugaad_body_content.dart';
import '../models/jugaad_structured_output.dart';
import 'authorization_codec.dart';
import 'body_content_classifier.dart';
import 'cookie_codec.dart';
import 'curl_codec.dart';
import 'http_error_codec.dart';
import 'http_headers_codec.dart';
import 'http_response_codec.dart';
import 'multipart_codec.dart';

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

  static JugaadStructuredOutput fromCookie(CookieParseResult result) {
    final sections = <JugaadOutputSection>[];

    for (var i = 0; i < result.cookies.length; i++) {
      final cookie = result.cookies[i];
      sections.add(
        JugaadOutputSection(
          title: result.cookies.length > 1 ? 'Cookie ${i + 1}' : 'Cookie',
          type: JugaadSectionType.keyValueList,
          fields: [
            MapEntry('Name', cookie.name),
            MapEntry('Value', cookie.value),
          ],
        ),
      );

      if (cookie.attributes.isNotEmpty) {
        sections.add(
          JugaadOutputSection(
            title: 'Attributes',
            type: JugaadSectionType.keyValueList,
            fields: cookie.attributes,
          ),
        );
      }
    }

    return JugaadStructuredOutput(sections: sections);
  }

  static JugaadStructuredOutput fromAuthorization(AuthorizationData data) {
    final sections = <JugaadOutputSection>[
      JugaadOutputSection(
        title: 'Authorization',
        type: JugaadSectionType.keyValueList,
        fields: [
          MapEntry('Scheme', data.scheme),
          if (data.scheme.toLowerCase() == 'basic') ...[
            MapEntry('Encoded credentials', data.credential),
            if (data.decodedUsername != null)
              MapEntry('Username', data.decodedUsername!),
            if (data.decodedPassword != null)
              MapEntry('Password', data.decodedPassword!),
          ] else
            MapEntry('Token', data.credential),
        ],
      ),
    ];

    final jwt = data.jwt;
    if (jwt != null) {
      sections.add(
        JugaadOutputSection(
          title: 'JWT Header',
          type: JugaadSectionType.body,
          body: JugaadBodyContent.json(jwt.header),
        ),
      );
      sections.add(
        JugaadOutputSection(
          title: 'JWT Payload',
          type: JugaadSectionType.body,
          body: JugaadBodyContent.json(jwt.payload),
        ),
      );
    }

    return JugaadStructuredOutput(sections: sections);
  }

  static JugaadStructuredOutput fromMultipart(MultipartParseResult result) {
    final sections = <JugaadOutputSection>[];

    if (result.fields.isNotEmpty) {
      sections.add(
        JugaadOutputSection(
          title: 'Fields',
          type: JugaadSectionType.keyValueList,
          fields: [
            for (final field in result.fields) ...[
              MapEntry(field.name, field.value),
            ],
          ],
        ),
      );
    }

    if (result.files.isNotEmpty) {
      final fileFields = <MapEntry<String, String>>[];
      for (final file in result.files) {
        fileFields.add(MapEntry(file.name, ''));
        fileFields.add(MapEntry('Filename', file.filename));
        fileFields.add(MapEntry('Content-Type', file.contentType));
        fileFields.add(
          MapEntry(
            'Content',
            file.isBinary ? '[Binary content]' : (file.textPreview ?? ''),
          ),
        );
      }

      sections.add(
        JugaadOutputSection(
          title: 'Files',
          type: JugaadSectionType.keyValueList,
          fields: fileFields,
        ),
      );
    }

    return JugaadStructuredOutput(sections: sections);
  }

  static JugaadStructuredOutput fromHttpError(HttpErrorData data) {
    final sections = <JugaadOutputSection>[
      JugaadOutputSection(
        title: 'Status',
        type: JugaadSectionType.httpStatus,
        statusCode: data.statusCode,
        statusText: data.statusText,
      ),
    ];

    final details = <MapEntry<String, String>>[];
    if (data.message.isNotEmpty) {
      details.add(MapEntry('Message', data.message));
    }
    if (data.error != null && data.error!.isNotEmpty) {
      details.add(MapEntry('Error', data.error!));
    }

    if (details.isNotEmpty) {
      sections.add(
        JugaadOutputSection(
          title: 'Details',
          type: JugaadSectionType.keyValueList,
          fields: details,
        ),
      );
    }

    if (data.headers.isNotEmpty) {
      sections.add(
        JugaadOutputSection(
          title: 'Headers',
          type: JugaadSectionType.headers,
          headers: data.headers,
        ),
      );
    }

    sections.add(
      JugaadOutputSection(
        title: 'Response',
        type: JugaadSectionType.body,
        body: data.body,
      ),
    );

    return JugaadStructuredOutput(sections: sections);
  }
}
