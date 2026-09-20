const literalNewlineJwt =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
    'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkFyY2hpdCJ9.'
    'SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

const literalNewlineInstructions =
    'Registrations open for Stepathon 2026.\nOn 25th Nov 2026. 6 AM onwards';

final Map<String, Object?> literalNewlineExpectedPayload = {
  'statusMessage': 'Success',
  'authToken': literalNewlineJwt,
  'expiresIn': 3600,
  'tokenType': 'Bearer',
  'refreshToken': 'refresh-token-value',
  'refreshTokenExpiresIn': 86400,
  'data': [
    {
      'type': 'comm_icon',
      'title': 'Community',
      'iconUrl': 'https://cdn.example.com/icons/comm_icon.png',
      'link': 'https://example.com/path?token=abc&user_id=123',
      'html':
          '<html><head><link href="https://cdn.example.com/style.css" rel="stylesheet"></head><body>Welcome to <span>Embassy Federation</span></body></html>',
      'stylesheet':
          'body{margin:0;padding:0;} .hero{background:url(https://cdn.example.com/hero.png);}',
      'meta': {'value': null, 'enabled': true},
      'tags': ['alpha', 'beta'],
    },
    {
      'type': 'organization',
      'name': 'Embassy Federation',
      'settings': {
        'timezone': 'Asia/Kolkata',
        'notifications': true,
        'supportEmail': 'support@example.com',
      },
    },
    {
      'type': 'events',
      'event_list': [
        {
          'id': 'event-1',
          'title': 'Stepathon 2026',
          'startAt': '2026-11-25T06:00:00+05:30',
          'registrationUrl':
              'https://events.example.com/register?event_id=stepathon-2026&token=abc',
        },
        {
          'id': 'event-2',
          'title': 'Community Run',
          'startAt': '2026-12-01T06:00:00+05:30',
          'registrationUrl':
              'https://events.example.com/register?event_id=community-run&token=def',
        },
      ],
      'instructions': literalNewlineInstructions,
      'description': 'Line one\nLine two',
    },
    {
      'type': 'community_feeds',
      'feeds': [
        {
          'id': 'feed-1',
          'title': 'Weekly Update',
          'body':
              '<p>Check out <a href="https://example.com/news?id=42">latest news</a></p>',
          'mediaUrl': 'https://cdn.example.com/feeds/feed-1.jpg?size=large',
        },
        {
          'id': 'feed-2',
          'title': 'Event Reminder',
          'body': 'Stepathon registrations are open.',
          'mediaUrl': null,
        },
      ],
    },
    {
      'type': 'actions',
      'items': [
        {
          'id': 'action-register',
          'label': 'Register',
          'url':
              'https://actions.example.com/go?action=register&source=home&token=xyz',
        },
        {
          'id': 'action-share',
          'label': 'Share',
          'url': 'https://actions.example.com/go?action=share&source=home',
        },
      ],
    },
  ],
};

String buildLiteralNewlineMalformedPayload() {
  final validJson = _encodePayload(literalNewlineExpectedPayload);
  return _injectLiteralNewlineIntoInstructions(validJson);
}

String buildPrettyPrintedLiteralNewlineMalformedPayload() {
  final validJson = _encodePrettyPayload(literalNewlineExpectedPayload);
  return _injectLiteralNewlineIntoInstructions(validJson);
}

String _injectLiteralNewlineIntoInstructions(String validJson) {
  return validJson.replaceFirst(
    'Registrations open for Stepathon 2026.\\nOn 25th Nov 2026. 6 AM onwards',
    'Registrations open for Stepathon 2026.\nOn 25th Nov 2026. 6 AM onwards',
  );
}

String _encodePrettyPayload(Map<String, Object?> payload) {
  final buffer = StringBuffer();
  _writePrettyJsonValue(buffer, payload, 0);
  return buffer.toString();
}

void _writePrettyJsonValue(StringBuffer buffer, Object? value, int depth) {
  final indent = '  ' * depth;
  final childIndent = '  ' * (depth + 1);

  if (value == null) {
    buffer.write('null');
    return;
  }

  if (value is bool || value is num) {
    buffer.write(value);
    return;
  }

  if (value is String) {
    buffer.write(_encodeJsonString(value));
    return;
  }

  if (value is List) {
    if (value.isEmpty) {
      buffer.write('[]');
      return;
    }

    buffer.writeln('[');
    for (var index = 0; index < value.length; index++) {
      buffer.write(childIndent);
      _writePrettyJsonValue(buffer, value[index], depth + 1);
      if (index < value.length - 1) {
        buffer.write(',');
      }
      buffer.writeln();
    }
    buffer.write('$indent]');
    return;
  }

  if (value is Map) {
    if (value.isEmpty) {
      buffer.write('{}');
      return;
    }

    buffer.writeln('{');
    final entries = value.entries.toList();
    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      buffer.write(childIndent);
      buffer.write(_encodeJsonString(entry.key as String));
      buffer.write(': ');
      _writePrettyJsonValue(buffer, entry.value, depth + 1);
      if (index < entries.length - 1) {
        buffer.write(',');
      }
      buffer.writeln();
    }
    buffer.write('$indent}');
  }
}

String _encodeJsonString(String value) {
  final buffer = StringBuffer('"');
  for (final codeUnit in value.codeUnits) {
    final char = String.fromCharCode(codeUnit);
    switch (char) {
      case r'\':
        buffer.write(r'\\');
      case '"':
        buffer.write(r'\"');
      case '\n':
        buffer.write(r'\n');
      case '\r':
        buffer.write(r'\r');
      case '\t':
        buffer.write(r'\t');
      case '\b':
        buffer.write(r'\b');
      case '\f':
        buffer.write(r'\f');
      default:
        if (codeUnit < 0x20) {
          buffer.write(
            '\\u${codeUnit.toRadixString(16).padLeft(4, '0')}',
          );
        } else {
          buffer.write(char);
        }
    }
  }
  buffer.write('"');
  return buffer.toString();
}

String _encodePayload(Map<String, Object?> payload) {
  final buffer = StringBuffer();
  _writeJsonValue(buffer, payload);
  return buffer.toString();
}

void _writeJsonValue(StringBuffer buffer, Object? value) {
  if (value == null) {
    buffer.write('null');
    return;
  }

  if (value is bool) {
    buffer.write(value);
    return;
  }

  if (value is num) {
    buffer.write(value);
    return;
  }

  if (value is String) {
    buffer.write(_encodeJsonString(value));
    return;
  }

  if (value is List) {
    buffer.write('[');
    for (var index = 0; index < value.length; index++) {
      if (index > 0) {
        buffer.write(',');
      }
      _writeJsonValue(buffer, value[index]);
    }
    buffer.write(']');
    return;
  }

  if (value is Map) {
    buffer.write('{');
    var index = 0;
    for (final entry in value.entries) {
      if (index > 0) {
        buffer.write(',');
      }
      _writeJsonValue(buffer, entry.key as String);
      buffer.write(':');
      _writeJsonValue(buffer, entry.value);
      index++;
    }
    buffer.write('}');
  }
}
