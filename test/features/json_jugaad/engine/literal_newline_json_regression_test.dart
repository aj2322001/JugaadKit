import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/features/json_jugaad/engine/detected_format.dart';
import 'package:jugaadkit/features/json_jugaad/engine/jugaad_engine.dart';
import 'package:jugaadkit/features/json_jugaad/engine/jugaad_validator.dart';
import 'package:jugaadkit/features/json_jugaad/engine/json_body_processor.dart';
import 'package:jugaadkit/features/json_jugaad/engine/json_string_control_char_repair.dart';

import 'literal_newline_payload_fixture.dart';

void main() {
  const engine = JugaadEngine();

  group('JsonStringControlCharRepair', () {
    test('repairs literal newline inside a string', () {
      const input = '{"message":"hello\nworld"}';
      final repaired = JsonStringControlCharRepair.tryRepair(input);

      expect(repaired, r'{"message":"hello\nworld"}');
      expect(
        JugaadValidator.tryParseJsonRepairingLiteralControlChars(repaired!)
            ?.value,
        {
        'message': 'hello\nworld',
      },
      );
    });

    test('repairs multiple literal newlines inside one string', () {
      const input = '{"text":"line1\nline2\nline3"}';
      final repaired = JsonStringControlCharRepair.tryRepair(input);

      expect(repaired, r'{"text":"line1\nline2\nline3"}');
      expect(
        (JugaadValidator.tryParseJsonRepairingLiteralControlChars(repaired!)!
                .value as Map)['text'],
        'line1\nline2\nline3',
      );
    });

    test('repairs literal CRLF inside a string', () {
      const input = '{"text":"hello\r\nworld"}';
      final repaired = JsonStringControlCharRepair.tryRepair(input);

      expect(repaired, r'{"text":"hello\r\nworld"}');
      expect(
        (JugaadValidator.tryParseJsonRepairingLiteralControlChars(repaired!)!
                .value as Map)['text'],
        'hello\r\nworld',
      );
    });

    test('does not modify newlines outside strings', () {
      const input = '{\n  "data": [\n    {\n      "id": 1\n    }\n  ]\n}';
      final repaired = JsonStringControlCharRepair.tryRepair(input);

      expect(repaired, isNull);
      expect(
        JugaadValidator.tryParseJsonRepairingLiteralControlChars(input)!.value,
        {'data': [
        {'id': 1},
      ]},
      );
    });

    test('repairs newline after escaped quote inside string', () {
      const input = '{"html":"<div class=\\"test\\">\nHello\n</div>"}';
      final repaired = JsonStringControlCharRepair.tryRepair(input);

      expect(repaired, r'{"html":"<div class=\"test\">\nHello\n</div>"}');
      expect(
        (JugaadValidator.tryParseJsonRepairingLiteralControlChars(repaired!)!
                .value as Map)['html'],
        '<div class="test">\nHello\n</div>',
      );
    });

    test('does not treat backslash-escaped quote as string terminator', () {
      const input = r'{"value":"foo\"bar"}';
      final repaired = JsonStringControlCharRepair.tryRepair(input);

      expect(repaired, isNull);
      expect(
        (JugaadValidator.tryParseJson(input)!.value as Map)['value'],
        r'foo"bar',
      );
    });

    test('does not treat odd backslash count before quote as terminator', () {
      const trailingBackslash = r'{"value":"foo\\"}';
      final repairedTrailing = JsonStringControlCharRepair.tryRepair(
        trailingBackslash,
      );
      expect(repairedTrailing, isNull);
      expect(
        (JugaadValidator.tryParseJson(trailingBackslash)!.value as Map)['value'],
        r'foo\',
      );

      const embeddedQuote = r'{"value":"foo\\\"bar"}';
      final repairedEmbedded = JsonStringControlCharRepair.tryRepair(
        embeddedQuote,
      );
      expect(repairedEmbedded, isNull);
      expect(
        (JugaadValidator.tryParseJson(embeddedQuote)!.value as Map)['value'],
        r'foo\"bar',
      );
    });

    test('does not double-escape existing \\n escape sequences', () {
      const input = r'{"description":"Line one\nLine two"}';
      final repaired = JsonStringControlCharRepair.tryRepair(input);

      expect(repaired, isNull);
      expect(
        (JugaadValidator.tryParseJson(input)!.value as Map)['description'],
        'Line one\nLine two',
      );
    });

    test('preserves existing escaped slash sequences', () {
      const input = r'{"url":"https:\/\/example.com\/path"}';
      final repaired = JsonStringControlCharRepair.tryRepair(input);

      expect(repaired, isNull);
      expect(
        (JugaadValidator.tryParseJson(input)!.value as Map)['url'],
        r'https://example.com/path',
      );
    });

    test('repairs HTML containing escaped quotes and literal newlines', () {
      const input =
          '{"html":"<link href=\\"style.css\\" rel=\\"stylesheet\\">\n<body>"}';
      final repaired = JsonStringControlCharRepair.tryRepair(input);

      expect(repaired, isNotNull);
      expect(
        (JugaadValidator.tryParseJsonRepairingLiteralControlChars(repaired!)!
                .value as Map)['html'],
        '<link href="style.css" rel="stylesheet">\n<body>',
      );
    });

    test('preserves URL query parameters and escaped slashes', () {
      const input =
          r'{"url":"https:\/\/cdn.example.com\/api?token=abc&user_id=123"}';
      final repaired = JsonStringControlCharRepair.tryRepair(input);

      expect(repaired, isNull);
      expect(
        (JugaadValidator.tryParseJson(input)!.value as Map)['url'],
        'https://cdn.example.com/api?token=abc&user_id=123',
      );
    });
  });

  group('Literal newline JSON integration', () {
    test('normal JSON still produces exactly the same output', () {
      final normalJson = jsonEncode(literalNewlineExpectedPayload);
      final result = engine.process(normalJson);

      expect(result.parsedValue, literalNewlineExpectedPayload);
      expect(result.detectedFormat, DetectedFormat.json);
    });

    test('escaped JSON still produces exactly the same output', () {
      final normalJson = jsonEncode(literalNewlineExpectedPayload);
      final escapedJson = normalJson.replaceAll('"', r'\"');
      final normalResult = engine.process(normalJson);
      final escapedResult = engine.process(escapedJson);

      expect(escapedResult.parsedValue, normalResult.parsedValue);
    });

    test('malformed JSON with literal newline parses to expected output', () {
      final malformedJson = buildLiteralNewlineMalformedPayload();
      final result = engine.process(malformedJson);

      expect(result.parsedValue, literalNewlineExpectedPayload);
    });

    test('pretty-printed malformed JSON is not misclassified as NDJSON', () {
      final malformedJson = buildPrettyPrintedLiteralNewlineMalformedPayload();

      expect(JugaadValidator.looksLikeNdjsonAttempt(malformedJson), isFalse);
      expect(
        JugaadValidator.tryParseResolvableJsonDocument(malformedJson),
        isNotNull,
      );

      final result = engine.process(malformedJson);
      expect(result.parsedValue, literalNewlineExpectedPayload);
      expect(result.detectedFormat, DetectedFormat.json);
    });

    test('running the parser twice remains idempotent', () {
      final malformedJson = buildLiteralNewlineMalformedPayload();
      final firstPass = engine.process(malformedJson);
      final secondPass = engine.process(firstPass.formattedJson);

      expect(secondPass.parsedValue, firstPass.parsedValue);
    });

    test('JsonBodyProcessor handles literal newline payloads', () {
      final malformedJson = buildLiteralNewlineMalformedPayload();
      final processed = JsonBodyProcessor.tryProcess(malformedJson);

      expect(processed, isNotNull);
      expect(processed!.value, literalNewlineExpectedPayload);
    });
  });

  group('Literal newline community payload regression', () {
    test('parses complete payload and preserves instructions newline', () {
      final malformedJson = buildLiteralNewlineMalformedPayload();
      final result = engine.process(malformedJson);
      final root = result.parsedValue as Map;
      final data = root['data'] as List;

      final commIcon = data.firstWhere(
        (item) => (item as Map)['type'] == 'comm_icon',
      ) as Map;
      expect(commIcon['iconUrl'], contains('https://'));
      expect(commIcon['link'], contains('token=abc&user_id=123'));

      final organization = data.firstWhere(
        (item) => (item as Map)['type'] == 'organization',
      ) as Map;
      expect(organization['name'], isNotEmpty);
      expect(organization['settings'], isA<Map>());

      final events = data.firstWhere(
        (item) => (item as Map)['type'] == 'events',
      ) as Map;
      final eventList = events['event_list'] as List;
      expect(eventList, isNotEmpty);
      expect(eventList.first, isA<Map>());

      final instructions = events['instructions'] as String;
      expect(instructions, contains('Stepathon 2026.'));
      expect(instructions, contains('On 25th Nov 2026.'));
      expect(instructions, contains('\n'));
      expect(
        instructions,
        'Registrations open for Stepathon 2026.\nOn 25th Nov 2026. 6 AM onwards',
      );

      final communityFeeds = data.firstWhere(
        (item) => (item as Map)['type'] == 'community_feeds',
      ) as Map;
      expect(communityFeeds['feeds'], isA<List>());
      expect((communityFeeds['feeds'] as List).first, isA<Map>());

      final actions = data.firstWhere(
        (item) => (item as Map)['type'] == 'actions',
      ) as Map;
      expect(actions['items'], isA<List>());
      expect((actions['items'] as List).first, isA<Map>());

      expect(root['authToken'], literalNewlineJwt);
      expect(root['statusMessage'], 'Success');
    });
  });

  group('Escaped vs literal newline compatibility', () {
    test('does not repair escaped JSON documents before layer decode', () {
      const escaped = r'{\"message\":\"Line one\\nLine two\"}';

      expect(JsonStringControlCharRepair.tryRepair(escaped), isNull);
      expect(
        JugaadValidator.tryParseJsonRepairingLiteralControlChars(escaped),
        isNull,
      );
      expect(
        JugaadValidator.looksLikeDocumentLevelEscapedJson(escaped),
        isTrue,
      );
    });

    test('allows repair for normal JSON containing escaped string content', () {
      const input =
          '{"html":"<link href=\\"style.css\\" rel=\\"stylesheet\\">\n<body>"}';

      expect(JugaadValidator.looksLikeDocumentLevelEscapedJson(input), isFalse);
      expect(JsonStringControlCharRepair.tryRepair(input), isNotNull);
    });

    test('malformed JSON with literal newline parses via repair helper', () {
      const input = '{"message":"Line one\nLine two"}';

      expect(
        (JugaadValidator.tryParseJsonRepairingLiteralControlChars(input)!
                .value as Map)['message'],
        'Line one\nLine two',
      );
    });

    test('all three JSON forms produce the same final value', () {
      const normal = r'{"message":"Line one\nLine two"}';
      const escaped = r'{\"message\":\"Line one\\nLine two\"}';
      const malformed = '{"message":"Line one\nLine two"}';
      const expected = 'Line one\nLine two';

      expect(
        (engine.process(normal).parsedValue as Map)['message'],
        expected,
      );
      expect(
        (engine.process(escaped).parsedValue as Map)['message'],
        expected,
      );
      expect(
        (engine.process(malformed).parsedValue as Map)['message'],
        expected,
      );
    });
  });
}
