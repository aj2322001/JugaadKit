import 'dart:convert';

import 'jwt_codec.dart';
import 'jugaad_validator.dart';

class AuthorizationData {
  const AuthorizationData({
    required this.scheme,
    required this.credential,
    this.decodedUsername,
    this.decodedPassword,
    this.jwt,
  });

  final String scheme;
  final String credential;
  final String? decodedUsername;
  final String? decodedPassword;
  final JwtDecodeResult? jwt;
}

abstract final class AuthorizationCodec {
  static AuthorizationData? tryParse(String input) {
    if (!JugaadValidator.looksLikeAuthorization(input)) {
      return null;
    }

    final trimmed = input.trim();
    final headerMatch = RegExp(
      r'^Authorization\s*:\s*(\S+)\s+(.*)$',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(trimmed);

    late final String scheme;
    late final String credential;

    if (headerMatch != null) {
      scheme = _titleCase(headerMatch.group(1)!);
      credential = headerMatch.group(2)!.trim();
    } else {
      final bareMatch = RegExp(
        r'^(Bearer|Basic|Digest)\s+(\S+)\s*$',
        caseSensitive: false,
      ).firstMatch(trimmed);
      if (bareMatch == null) {
        return null;
      }
      scheme = _titleCase(bareMatch.group(1)!);
      credential = bareMatch.group(2)!.trim();
    }

    if (credential.isEmpty) {
      return null;
    }

    switch (scheme.toLowerCase()) {
      case 'bearer':
        final jwt = JwtCodec.tryDecode(credential);
        return AuthorizationData(
          scheme: scheme,
          credential: credential,
          jwt: jwt,
        );
      case 'basic':
        final decoded = _tryDecodeBasic(credential);
        return AuthorizationData(
          scheme: scheme,
          credential: credential,
          decodedUsername: decoded?.$1,
          decodedPassword: decoded?.$2,
        );
      default:
        return AuthorizationData(scheme: scheme, credential: credential);
    }
  }

  static String format(AuthorizationData data) {
    final buffer = StringBuffer()
      ..writeln('Authorization')
      ..writeln()
      ..writeln('Scheme:')
      ..writeln(data.scheme)
      ..writeln();

    if (data.scheme.toLowerCase() == 'basic') {
      buffer
        ..writeln('Encoded credentials:')
        ..writeln(data.credential);
      if (data.decodedUsername != null) {
        buffer
          ..writeln()
          ..writeln('Username:')
          ..writeln(data.decodedUsername)
          ..writeln()
          ..writeln('Password:')
          ..writeln(data.decodedPassword ?? '');
      }
      return buffer.toString().trimRight();
    }

    buffer
      ..writeln('Token:')
      ..writeln(data.credential);

    final jwt = data.jwt;
    if (jwt != null) {
      buffer
        ..writeln()
        ..writeln('JWT Header:')
        ..writeln(const JsonEncoder.withIndent('  ').convert(jwt.header))
        ..writeln()
        ..writeln('JWT Payload:')
        ..writeln(const JsonEncoder.withIndent('  ').convert(jwt.payload));
    }

    return buffer.toString().trimRight();
  }

  static (String, String)? _tryDecodeBasic(String credential) {
    try {
      final normalized = base64.normalize(credential);
      final decoded = utf8.decode(base64.decode(normalized));
      final separator = decoded.indexOf(':');
      if (separator < 0) {
        return null;
      }
      return (
        decoded.substring(0, separator),
        decoded.substring(separator + 1),
      );
    } on FormatException {
      return null;
    }
  }

  static String _titleCase(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }
}
