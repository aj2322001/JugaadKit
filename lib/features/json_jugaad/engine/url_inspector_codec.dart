import 'jugaad_validator.dart';

abstract final class UrlInspectorCodec {
  static Uri? tryParseStandalone(
    String input, {
    bool conservative = false,
  }) {
    if (!JugaadValidator.looksLikeStandaloneUrl(input)) {
      return null;
    }

    if (conservative && !JugaadValidator.looksLikeInspectableUrl(input)) {
      return null;
    }

    final trimmed = input.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return null;
    }

    return uri;
  }

  static String format(Uri uri) {
    final buffer = StringBuffer()
      ..writeln('Scheme:')
      ..writeln(uri.scheme)
      ..writeln()
      ..writeln('Host:')
      ..writeln(uri.host);

    if (uri.hasPort) {
      buffer
        ..writeln()
        ..writeln('Port:')
        ..writeln(uri.port);
    }

    buffer
      ..writeln()
      ..writeln('Path:')
      ..writeln(uri.path.isEmpty ? '/' : uri.path);

    if (uri.queryParameters.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Query:');
      for (final entry in uri.queryParameters.entries) {
        buffer.writeln('${entry.key} = ${entry.value}');
      }
    }

    if (uri.fragment.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Fragment:')
        ..writeln(uri.fragment);
    }

    return buffer.toString().trimRight();
  }
}
