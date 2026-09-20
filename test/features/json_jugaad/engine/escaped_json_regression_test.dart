import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/features/json_jugaad/engine/detected_format.dart';
import 'package:jugaadkit/features/json_jugaad/engine/jugaad_engine.dart';
import 'package:jugaadkit/features/json_jugaad/engine/json_body_processor.dart';
import 'package:jugaadkit/features/json_jugaad/models/transformation_step.dart';

const _jwt =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
    'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkFyY2hpdCJ9.'
    'SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

final Map<String, Object?> _expectedPayload = {
  'statusMessage': 'Success',
  'authToken': _jwt,
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
          '<html><body>Welcome to <span>Embassy Federation</span></body></html>',
      'meta': {'value': null, 'enabled': true},
      'tags': ['alpha', 'beta'],
    },
    {
      'type': 'events',
      'data': [],
      'description': 'Line one\nLine two',
    },
  ],
};

String _escapeJsonDocument(String json) => json.replaceAll('"', r'\"');

void main() {
  const engine = JugaadEngine();
  final normalJson = jsonEncode(_expectedPayload);
  final escapedJson = _escapeJsonDocument(normalJson);

  group('Escaped JSON regression', () {
    test('normal JSON parses to expected payload', () {
      final result = engine.process(normalJson);

      expect(result.parsedValue, _expectedPayload);
      expect(result.detectedFormat, DetectedFormat.json);
    });

    test('escaped JSON parses to the same payload as normal JSON', () {
      final normalResult = engine.process(normalJson);
      final escapedResult = engine.process(escapedJson);

      expect(
        escapedResult.steps.any(
          (step) => step.type == TransformationType.decodedEscaped,
        ),
        isTrue,
      );
      expect(escapedResult.parsedValue, normalResult.parsedValue);
      expect(escapedResult.formattedJson, normalResult.formattedJson);
      expect(escapedResult.detectedFormat, DetectedFormat.escapedJson);
    });

    test('simple escaped data array matches normal JSON', () {
      const normal = '{"data":[{"type":"events","data":[]}]}';
      const escaped = r'{\"data\":[{\"type\":\"events\",\"data\":[]}]}';

      final normalResult = engine.process(normal);
      final escapedResult = engine.process(escaped);

      expect(escapedResult.parsedValue, normalResult.parsedValue);
    });

    test('nested escaped JSON string literal decodes in one step', () {
      const escaped = r'"{\"data\":[{\"type\":\"events\",\"data\":[]}]}"';

      final result = engine.process(escaped);

      expect((result.parsedValue as Map)['data'], [
        {'type': 'events', 'data': <dynamic>[]},
      ]);
    });

    test('preserves URLs, HTML, null, and booleans', () {
      final result = engine.process(escapedJson);
      final data = (result.parsedValue as Map)['data'] as List;
      final commIcon = data.first as Map;

      expect(
        commIcon['link'],
        'https://example.com/path?token=abc&user_id=123',
      );
      expect(
        commIcon['html'],
        '<html><body>Welcome to <span>Embassy Federation</span></body></html>',
      );
      expect((commIcon['meta'] as Map)['value'], isNull);
      expect((commIcon['meta'] as Map)['enabled'], isTrue);
    });

    test('sibling array items remain intact after long escaped values', () {
      final result = engine.process(escapedJson);
      final data = (result.parsedValue as Map)['data'] as List;

      expect(data, hasLength(2));
      expect(data[1], {
        'type': 'events',
        'data': <dynamic>[],
        'description': 'Line one\nLine two',
      });
    });

    test('deeply nested escaped object values parse correctly', () {
      final nestedNormal = jsonEncode({
        'level1': {
          'level2': {
            'wrapped': _expectedPayload['authToken'],
            'plain': 'value',
            'nested': {'leaf': true},
          },
        },
      });
      final nestedEscaped = _escapeJsonDocument(nestedNormal);

      final normalResult = engine.process(nestedNormal);
      final escapedResult = engine.process(nestedEscaped);

      expect(escapedResult.parsedValue, normalResult.parsedValue);
      final level2 = (((escapedResult.parsedValue as Map)['level1'] as Map)['level2']
          as Map)['nested'] as Map;
      expect(level2['leaf'], isTrue);
    });

    test('decode is idempotent once JSON is normalized', () {
      final firstPass = engine.process(escapedJson);
      final secondPass = engine.process(firstPass.formattedJson);

      expect(secondPass.parsedValue, firstPass.parsedValue);
      expect(
        secondPass.steps.any(
          (step) => step.type == TransformationType.decodedEscaped,
        ),
        isFalse,
      );
    });

    test('json body processor handles escaped JSON bodies', () {
      const escaped = r'{\"data\":[{\"type\":\"events\",\"data\":[]}]}';

      final processed = JsonBodyProcessor.tryProcess(
        escaped,
        contentType: 'application/json',
      );

      expect(processed, isNotNull);
      expect((processed!.value as Map)['data'], [
        {'type': 'events', 'data': <dynamic>[]},
      ]);
    });

    test('escaped JSON with \\n produces newline in final value', () {
      const escaped = r'{\"message\":\"Line one\\nLine two\"}';

      final result = engine.process(escaped);

      expect((result.parsedValue as Map)['message'], 'Line one\nLine two');
    });

    test('escaped JSON with URLs preserves query parameters', () {
      const escaped =
          r'{\"url\":\"https:\\/\\/example.com\\/path?a=1&b=2\"}';

      final result = engine.process(escaped);

      expect(
        (result.parsedValue as Map)['url'],
        'https://example.com/path?a=1&b=2',
      );
    });

    test('escaped JSON with HTML preserves escaped quotes', () {
      const escaped = r'{\"html\":\"<div class=\\\"test\\\">Hello<\\/div>\"}';

      final result = engine.process(escaped);

      expect(
        (result.parsedValue as Map)['html'],
        '<div class="test">Hello</div>',
      );
    });

    test('escaped JSON with literal newline inside string still parses', () {
      final escapedWithLiteralNewline = r'{\"message\":\"Line one'
          '\n'
          r'Line two\"}';

      final result = engine.process(escapedWithLiteralNewline);

      expect((result.parsedValue as Map)['message'], 'Line one\nLine two');
    });

    test('original attached payload still matches normal JSON output', () {
      final normalResult = engine.process(normalJson);
      final escapedResult = engine.process(escapedJson);

      expect(escapedResult.parsedValue, normalResult.parsedValue);
      expect(escapedResult.formattedJson, normalResult.formattedJson);
    });
  });
}
