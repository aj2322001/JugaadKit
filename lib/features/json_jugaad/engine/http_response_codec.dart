import 'dart:convert';

import 'jugaad_validator.dart';

class HttpResponseData {
  const HttpResponseData({
    required this.statusCode,
    required this.statusText,
    required this.headers,
    required this.body,
  });

  final int statusCode;
  final String statusText;
  final List<MapEntry<String, String>> headers;
  final String body;
}

abstract final class HttpResponseCodec {
  static HttpResponseData? tryParse(String input) {
    if (!JugaadValidator.looksLikeHttpResponse(input)) {
      return null;
    }

    final lines = input.split(RegExp(r'\r?\n'));
    if (lines.isEmpty) {
      return null;
    }

    final statusMatch = RegExp(
      r'^HTTP/\d(?:\.\d)?\s+(\d{3})(?:\s+(.*))?$',
      caseSensitive: false,
    ).firstMatch(lines.first.trim());

    if (statusMatch == null) {
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

      final header = _parseHeaderLine(line);
      if (header == null) {
        return null;
      }
      headers.add(header);
    }

    final body = lines.sublist(index).join('\n').trimRight();
    return HttpResponseData(
      statusCode: int.parse(statusMatch.group(1)!),
      statusText: statusMatch.group(2)?.trim() ?? '',
      headers: headers,
      body: body,
    );
  }

  static String format(HttpResponseData response) {
    final statusLine = response.statusText.isEmpty
        ? '${response.statusCode}'
        : '${response.statusCode} ${response.statusText}';

    final buffer = StringBuffer()
      ..writeln('Status:')
      ..writeln(statusLine)
      ..writeln();

    if (response.headers.isNotEmpty) {
      buffer.writeln('Headers:');
      for (final header in response.headers) {
        buffer.writeln('${header.key}: ${header.value}');
      }
      buffer.writeln();
    }

    buffer.writeln('Body:');
    final trimmedBody = response.body.trim();
    if (trimmedBody.isEmpty) {
      return buffer.toString().trimRight();
    }

    final parsed = JugaadValidator.tryParseJson(trimmedBody);
    if (parsed != null) {
      buffer.writeln(
        const JsonEncoder.withIndent('  ').convert(parsed.value),
      );
    } else {
      buffer.writeln(response.body);
    }

    return buffer.toString().trimRight();
  }

  static MapEntry<String, String>? _parseHeaderLine(String line) {
    final index = line.indexOf(':');
    if (index <= 0) {
      return null;
    }

    final name = line.substring(0, index).trim();
    final value = line.substring(index + 1).trim();
    if (name.isEmpty) {
      return null;
    }

    return MapEntry(name, value);
  }
}
