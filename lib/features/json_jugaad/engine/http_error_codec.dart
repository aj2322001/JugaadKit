import 'dart:convert';

import 'body_content_classifier.dart';
import 'http_response_codec.dart';
import 'jugaad_validator.dart';
import '../models/jugaad_body_content.dart';

class HttpErrorData {
  const HttpErrorData({
    required this.statusCode,
    required this.statusText,
    required this.message,
    this.error,
    this.headers = const [],
    this.body = const JugaadBodyContent.plain(''),
  });

  final int statusCode;
  final String statusText;
  final String message;
  final String? error;
  final List<MapEntry<String, String>> headers;
  final JugaadBodyContent body;
}

abstract final class HttpErrorCodec {
  static HttpErrorData? tryParse(String input) {
    if (!JugaadValidator.looksLikeHttpError(input)) {
      return null;
    }

    if (HttpResponseCodec.tryParse(input) != null) {
      return null;
    }

    final trimmed = input.trim();
    final dio = _tryParseDioException(trimmed);
    if (dio != null) {
      return dio;
    }

    final shorthand = _tryParseShorthandStatus(trimmed);
    if (shorthand != null) {
      return shorthand;
    }

    return null;
  }

  static String format(HttpErrorData data) {
    final statusLine = data.statusText.isEmpty
        ? '${data.statusCode}'
        : '${data.statusCode} ${data.statusText}';

    final buffer = StringBuffer()
      ..writeln('HTTP Error')
      ..writeln()
      ..writeln('Status:')
      ..writeln(statusLine)
      ..writeln();

    if (data.message.isNotEmpty) {
      buffer
        ..writeln('Message:')
        ..writeln(data.message)
        ..writeln();
    }

    if (data.error != null && data.error!.isNotEmpty) {
      buffer
        ..writeln('Error:')
        ..writeln(data.error)
        ..writeln();
    }

    if (data.headers.isNotEmpty) {
      buffer.writeln('Headers:');
      for (final header in data.headers) {
        buffer.writeln('${header.key}: ${header.value}');
      }
      buffer.writeln();
    }

    buffer.writeln('Response:');
    final body = data.body;
    if (body.isJson) {
      buffer.writeln(
        const JsonEncoder.withIndent('  ').convert(body.jsonValue),
      );
    } else if (body.isXml) {
      buffer.writeln(body.xmlText);
    } else {
      buffer.writeln(body.plainText ?? '');
    }

    return buffer.toString().trimRight();
  }

  static HttpErrorData? _tryParseDioException(String input) {
    final statusMatch = RegExp(
      r'status code\s+(\d{3})',
      caseSensitive: false,
    ).firstMatch(input);
    if (statusMatch == null) {
      return null;
    }

    final statusCode = int.parse(statusMatch.group(1)!);
    if (statusCode < 400) {
      return null;
    }

    final responseMatch = RegExp(
      r'Response Text:\s*(.+)$',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(input);

    final bodyText = responseMatch?.group(1)?.trim() ?? '';
    final extracted = _extractErrorFields(bodyText);

    return HttpErrorData(
      statusCode: statusCode,
      statusText: _defaultStatusText(statusCode),
      message: extracted.message,
      error: extracted.error,
      body: BodyContentClassifier.classify(bodyText),
    );
  }

  static HttpErrorData? _tryParseShorthandStatus(String input) {
    final lines = input.split(RegExp(r'\r?\n'));
    if (lines.isEmpty) {
      return null;
    }

    final statusMatch = RegExp(
      r'^HTTP\s+(\d{3})(?:\s+(.*))?$',
      caseSensitive: false,
    ).firstMatch(lines.first.trim());

    if (statusMatch == null) {
      return null;
    }

    final statusCode = int.parse(statusMatch.group(1)!);
    if (statusCode < 400) {
      return null;
    }

    final headers = <MapEntry<String, String>>[];
    var index = 1;
    for (; index < lines.length; index++) {
      final line = lines[index];
      if (line.trim().isEmpty) {
        index++;
        break;
      }

      final headerIndex = line.indexOf(':');
      if (headerIndex <= 0) {
        break;
      }

      headers.add(
        MapEntry(
          line.substring(0, headerIndex).trim(),
          line.substring(headerIndex + 1).trim(),
        ),
      );
    }

    final bodyText = lines.sublist(index).join('\n').trim();
    final extracted = _extractErrorFields(bodyText);

    return HttpErrorData(
      statusCode: statusCode,
      statusText: statusMatch.group(2)?.trim() ?? _defaultStatusText(statusCode),
      message: extracted.message,
      error: extracted.error,
      headers: headers,
      body: BodyContentClassifier.classify(bodyText),
    );
  }

  static ({String message, String? error}) _extractErrorFields(String bodyText) {
    final parsed = JugaadValidator.tryParseJson(bodyText.trim());
    if (parsed?.value is Map) {
      final map = Map<String, dynamic>.from(parsed!.value as Map);
      final message = _readField(map, const ['message', 'error_message', 'detail', 'description']);
      final error = _readField(map, const ['error', 'code', 'type']);
      return (
        message: message ?? '',
        error: error,
      );
    }

    return (message: bodyText.trim(), error: null);
  }

  static String? _readField(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) {
        continue;
      }
      return value.toString();
    }
    return null;
  }

  static String _defaultStatusText(int statusCode) {
    return switch (statusCode) {
      400 => 'Bad Request',
      401 => 'Unauthorized',
      403 => 'Forbidden',
      404 => 'Not Found',
      405 => 'Method Not Allowed',
      409 => 'Conflict',
      422 => 'Unprocessable Entity',
      429 => 'Too Many Requests',
      500 => 'Internal Server Error',
      502 => 'Bad Gateway',
      503 => 'Service Unavailable',
      504 => 'Gateway Timeout',
      _ => '',
    };
  }
}
