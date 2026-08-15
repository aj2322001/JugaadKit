import 'json_body_processor.dart';
import 'jugaad_validator.dart';

class CurlRequest {
  const CurlRequest({
    required this.method,
    required this.url,
    required this.headers,
    this.body,
  });

  final String method;
  final String url;
  final List<MapEntry<String, String>> headers;
  final String? body;
}

abstract final class CurlCodec {
  static CurlRequest? tryParse(String input) {
    if (!JugaadValidator.looksLikeCurl(input)) {
      return null;
    }

    final normalized = _normalize(input);
    final tokens = _tokenize(normalized);
    if (tokens.isEmpty || tokens.first.toLowerCase() != 'curl') {
      return null;
    }

    var method = 'GET';
    String? url;
    final headers = <MapEntry<String, String>>[];
    String? body;

    for (var i = 1; i < tokens.length; i++) {
      final token = tokens[i];
      final lower = token.toLowerCase();

      if (lower == '-x' || lower == '--request') {
        if (i + 1 >= tokens.length) {
          return null;
        }
        method = tokens[++i].toUpperCase();
        continue;
      }

      if (lower == '-h' || lower == '--header') {
        if (i + 1 >= tokens.length) {
          return null;
        }
        final header = _parseHeader(tokens[++i]);
        if (header == null) {
          return null;
        }
        headers.add(header);
        continue;
      }

      if (lower == '-d' ||
          lower == '--data' ||
          lower == '--data-raw' ||
          lower == '--data-binary') {
        if (i + 1 >= tokens.length) {
          return null;
        }
        body = tokens[++i];
        if (method == 'GET') {
          method = 'POST';
        }
        continue;
      }

      if (lower == '--url') {
        if (i + 1 >= tokens.length) {
          return null;
        }
        url = tokens[++i];
        continue;
      }

      if (_looksLikeUrl(token)) {
        url ??= token;
        continue;
      }
    }

    if (url == null) {
      return null;
    }

    return CurlRequest(
      method: method,
      url: url,
      headers: headers,
      body: body,
    );
  }

  static String format(CurlRequest request) {
    final buffer = StringBuffer()
      ..writeln('${request.method} ${request.url}')
      ..writeln();

    if (request.headers.isNotEmpty) {
      buffer.writeln('Headers:');
      for (final header in request.headers) {
        buffer.writeln('${header.key}: ${header.value}');
      }
      buffer.writeln();
    }

    final body = request.body;
    if (body != null && body.trim().isNotEmpty) {
      buffer.writeln('Body:');
      final formatted = JsonBodyProcessor.formatPrettyJson(
        body,
        contentType: JsonBodyProcessor.contentTypeFromHeaders(request.headers),
      );
      if (formatted != null) {
        buffer.writeln(formatted);
      } else {
        buffer.writeln(body);
      }
    }

    return buffer.toString().trimRight();
  }

  static String _normalize(String input) {
    return input
        .replaceAll(RegExp(r'\\\s*\r?\n'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<String> _tokenize(String input) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    String? quote;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];

      if (quote != null) {
        if (char == quote && (i == 0 || input[i - 1] != r'\')) {
          quote = null;
          tokens.add(buffer.toString());
          buffer.clear();
        } else {
          buffer.write(char);
        }
        continue;
      }

      if (char == '"' || char == "'") {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        quote = char;
        continue;
      }

      if (char == ' ' || char == '\t') {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        continue;
      }

      buffer.write(char);
    }

    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString());
    }

    return tokens;
  }

  static MapEntry<String, String>? _parseHeader(String value) {
    final index = value.indexOf(':');
    if (index <= 0) {
      return null;
    }
    final name = value.substring(0, index).trim();
    final headerValue = value.substring(index + 1).trim();
    if (name.isEmpty) {
      return null;
    }
    return MapEntry(name, headerValue);
  }

  static bool _looksLikeUrl(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }
}
