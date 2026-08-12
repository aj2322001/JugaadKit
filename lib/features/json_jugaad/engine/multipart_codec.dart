import 'jugaad_validator.dart';

class MultipartTextField {
  const MultipartTextField({
    required this.name,
    required this.value,
  });

  final String name;
  final String value;
}

class MultipartFileField {
  const MultipartFileField({
    required this.name,
    required this.filename,
    required this.contentType,
    required this.isBinary,
    this.textPreview,
  });

  final String name;
  final String filename;
  final String contentType;
  final bool isBinary;
  final String? textPreview;
}

class MultipartParseResult {
  const MultipartParseResult({
    required this.fields,
    required this.files,
  });

  final List<MultipartTextField> fields;
  final List<MultipartFileField> files;
}

abstract final class MultipartCodec {
  static MultipartParseResult? tryParse(String input) {
    if (!JugaadValidator.looksLikeMultipart(input)) {
      return null;
    }

    final normalized = input.replaceAll('\r\n', '\n').trim();
    final firstNewline = normalized.indexOf('\n');
    if (firstNewline < 0) {
      return null;
    }

    final boundary = normalized.substring(0, firstNewline).trim();
    if (!boundary.startsWith('--') || boundary.length < 3) {
      return null;
    }

    final content = normalized.substring(firstNewline + 1);
    final rawParts = content.split(boundary);
    final fields = <MultipartTextField>[];
    final files = <MultipartFileField>[];

    for (final rawPart in rawParts) {
      var part = rawPart.trim();
      if (part.isEmpty || part == '--') {
        continue;
      }

      if (part.startsWith('--')) {
        part = part.substring(2).trim();
        if (part.isEmpty) {
          continue;
        }
      }

      final blankLineIndex = part.indexOf('\n\n');
      if (blankLineIndex < 0) {
        return null;
      }

      final headerBlock = part.substring(0, blankLineIndex);
      var body = part.substring(blankLineIndex + 2).trimRight();
      if (body.endsWith('--')) {
        body = body.substring(0, body.length - 2).trimRight();
      }

      final disposition = RegExp(
        r'Content-Disposition:\s*form-data;\s*(.*)$',
        caseSensitive: false,
        multiLine: true,
      ).firstMatch(headerBlock);
      if (disposition == null) {
        return null;
      }

      final params = _parseDispositionParams(disposition.group(1)!);
      final name = params['name'];
      if (name == null || name.isEmpty) {
        return null;
      }

      final filename = params['filename'];
      final contentTypeMatch = RegExp(
        r'^Content-Type:\s*(.+)$',
        caseSensitive: false,
        multiLine: true,
      ).firstMatch(headerBlock);

      if (filename != null && filename.isNotEmpty) {
        final contentType = contentTypeMatch?.group(1)?.trim() ?? '';
        final isBinary = _looksBinary(body, contentType);
        files.add(
          MultipartFileField(
            name: name,
            filename: filename,
            contentType:
                contentType.isEmpty ? 'application/octet-stream' : contentType,
            isBinary: isBinary,
            textPreview: isBinary ? null : body,
          ),
        );
      } else {
        fields.add(MultipartTextField(name: name, value: body));
      }
    }

    if (fields.isEmpty && files.isEmpty) {
      return null;
    }

    return MultipartParseResult(fields: fields, files: files);
  }

  static String format(MultipartParseResult result) {
    final buffer = StringBuffer()..writeln('Multipart Request')..writeln();

    if (result.fields.isNotEmpty) {
      buffer.writeln('Fields');
      buffer.writeln();
      for (final field in result.fields) {
        buffer
          ..writeln(field.name)
          ..writeln(field.value)
          ..writeln();
      }
    }

    if (result.files.isNotEmpty) {
      buffer.writeln('Files');
      buffer.writeln();
      for (final file in result.files) {
        buffer
          ..writeln(file.name)
          ..writeln('Filename: ${file.filename}')
          ..writeln('Content-Type: ${file.contentType}');
        if (file.isBinary) {
          buffer.writeln('[Binary content]');
        } else if (file.textPreview != null && file.textPreview!.isNotEmpty) {
          buffer.writeln(file.textPreview);
        } else {
          buffer.writeln('[Binary content]');
        }
        buffer.writeln();
      }
    }

    return buffer.toString().trimRight();
  }

  static Map<String, String> _parseDispositionParams(String raw) {
    final params = <String, String>{};
    final matches = RegExp(r'([\w-]+)\s*=\s*"([^"]*)"').allMatches(raw);
    for (final match in matches) {
      params[match.group(1)!.toLowerCase()] = match.group(2)!;
    }
    return params;
  }

  static bool _looksBinary(String body, String contentType) {
    final lowered = contentType.toLowerCase().trim();
    if (lowered.startsWith('text/') ||
        lowered.contains('json') ||
        lowered.contains('xml') ||
        lowered.contains('javascript')) {
      return body.runes.any((rune) => rune < 9 || (rune > 13 && rune < 32));
    }

    if (lowered.isNotEmpty) {
      return true;
    }

    if (body == '[file content]' || body == '[binary content]') {
      return true;
    }

    return body.runes.any((rune) => rune < 9 || (rune > 13 && rune < 32));
  }
}
