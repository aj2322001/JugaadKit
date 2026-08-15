import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/features/json_jugaad/engine/confidence.dart';
import 'package:jugaadkit/features/json_jugaad/engine/detected_format.dart';
import 'package:jugaadkit/features/json_jugaad/engine/jugaad_engine.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_error.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_repair_highlight.dart';
import 'package:jugaadkit/features/json_jugaad/models/transformation_step.dart';

void main() {
  const engine = JugaadEngine();

  group('Broken JSON repair', () {
    test('repairs unquoted keys', () {
      final result = engine.process('{name: "Archit"}');
      expect((result.parsedValue as Map)['name'], 'Archit');
      expect(result.confidence, Confidence.medium);
      final highlight = result.repairHighlights.firstWhere(
        (h) =>
            h.kind == JsonRepairKind.unquotedKey &&
            h.path == r'$.name',
      );
      expect(highlight.originalText, 'name');
      expect(highlight.repairedText, '"name"');
      expect(
        highlight.tooltipMessage,
        '⚠️ Unquoted key\nname → "name"',
      );
    });

    test('repairs nested unquoted keys', () {
      final result = engine.process('{user: {name: "Archit", age: 25}}');
      final user = (result.parsedValue as Map)['user'] as Map;
      expect(user['name'], 'Archit');
      expect(user['age'], 25);
      expect(
        result.repairHighlights.any((h) => h.path == r'$.user'),
        isTrue,
      );
      expect(
        result.repairHighlights.any((h) => h.path == r'$.user.name'),
        isTrue,
      );
    });

    test('repairs single-quoted strings', () {
      final result = engine.process("{'name': 'Archit'}");
      expect((result.parsedValue as Map)['name'], 'Archit');
      expect(
        result.repairHighlights.any(
          (h) => h.kind == JsonRepairKind.singleQuotedString,
        ),
        isTrue,
      );
    });

    test('repairs combined single quotes and primitives', () {
      final result = engine.process("{'user': {'name': 'Archit', 'active': True}}");
      final user = (result.parsedValue as Map)['user'] as Map;
      expect(user['name'], 'Archit');
      expect(user['active'], isTrue);
    });

    test('repairs Python-style primitives', () {
      final result = engine.process('{"active": True, "deleted": False, "value": None}');
      final map = result.parsedValue as Map;
      expect(map['active'], isTrue);
      expect(map['deleted'], isFalse);
      expect(map['value'], isNull);
      expect(
        result.repairHighlights.where((h) => h.target == JsonRepairTarget.value),
        hasLength(3),
      );
    });

    test('repairs missing closing braces and brackets', () {
      final nested = engine.process(
        '{"user":{"name":"Archit","roles":["admin","developer"]',
      );
      final user = (nested.parsedValue as Map)['user'] as Map;
      expect(user['name'], 'Archit');
      expect(user['roles'], ['admin', 'developer']);
      expect(
        nested.steps.any((s) => s.type == TransformationType.jsonExtracted),
        isFalse,
      );

      final objectResult = engine.process('{"user":{"name":"Archit"}');
      expect(
        ((objectResult.parsedValue as Map)['user'] as Map)['name'],
        'Archit',
      );
      expect(
        objectResult.repairHighlights.any(
          (h) =>
              h.kind == JsonRepairKind.missingClosing &&
              h.repairedText == '}',
        ),
        isTrue,
      );

      final arrayResult = engine.process('{"users":[{"id":1},{"id":2}');
      final users = (arrayResult.parsedValue as Map)['users'] as List;
      expect(users, hasLength(2));
    });

    test('preserves trailing comma and comment repairs', () {
      final trailing = engine.process('{\n  "name": "Archit",\n}');
      expect((trailing.parsedValue as Map)['name'], 'Archit');
      expect(
        trailing.steps.any((s) => s.type == TransformationType.trailingCommaRemoved),
        isTrue,
      );

      final comments = engine.process('{\n  // comment\n  "name": "Archit"\n}');
      expect((comments.parsedValue as Map)['name'], 'Archit');
      expect(
        comments.steps.any((s) => s.type == TransformationType.commentRemoved),
        isTrue,
      );
    });

    test('does not corrupt string literals with True False None', () {
      final result = engine.process(
        r'{"message": "True False None"}',
      );
      expect((result.parsedValue as Map)['message'], 'True False None');
      expect(result.repairHighlights, isEmpty);
    });

    test('does not corrupt brace-like content inside strings', () {
      final result = engine.process(
        r'{"message": "Use {name: value}"}',
      );
      expect((result.parsedValue as Map)['message'], 'Use {name: value}');
      expect(result.repairHighlights, isEmpty);
    });

    test('does not corrupt apostrophes inside strings', () {
      final result = engine.process('{"message": "Archit\'s account"}');
      expect((result.parsedValue as Map)['message'], "Archit's account");
      expect(result.repairHighlights, isEmpty);
    });

    test('does not repair ambiguous non-json text', () {
      for (final input in ['name: Archit', 'hello: world', 'foo = bar']) {
        expect(
          () => engine.process(input),
          throwsA(isA<JsonJugaadError>()),
          reason: input,
        );
      }
    });

    test('does not repair unquoted values', () {
      expect(
        () => engine.process('{name: Archit}'),
        throwsA(isA<JsonJugaadError>()),
      );
    });

    test('valid JSON has no repair highlights', () {
      final result = engine.process('{"name":"Archit","age":25}');
      expect(result.repairHighlights, isEmpty);
      expect(result.confidence, Confidence.high);
    });

    test('does not add per-fix repair transformation steps', () {
      final result = engine.process('{name: "Archit"}');
      expect(
        result.steps.any((s) => s.type == TransformationType.brokenJsonRepaired),
        isFalse,
      );
      expect(result.repairHighlights, isNotEmpty);
      expect(result.hasRepairHighlights, isTrue);
      expect(result.detectedFormat, DetectedFormat.looseJson);
    });

    test('collapses multi-pass repair into highlights without extra steps', () {
      final result = engine.process(
        "{'user': {'name': 'Archit', 'active': True}}",
      );

      expect(
        result.steps.where((s) => s.type == TransformationType.brokenJsonRepaired),
        isEmpty,
      );
      expect(result.hasRepairHighlights, isTrue);
    });
  });

  group('Broken JSON repair detector priority', () {
    test('cURL with broken JSON body stays cURL', () {
      const input = '''curl -X POST https://api.example.com \\
  -H "Content-Type: application/json" \\
  -d '{name: "Archit"}' ''';
      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.curl);
    });

    test('HTTP response with broken JSON body stays HTTP response', () {
      const input = '''HTTP/1.1 400 Bad Request
Content-Type: application/json

{name: "Archit"}''';
      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.httpResponse);
    });

    test('multipart with broken JSON part stays multipart', () {
      const input = '''------boundary
Content-Disposition: form-data; name="payload"

{name: "Archit"}
------boundary--''';
      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.multipart);
    });

    test('authorization header stays authorization', () {
      const jwt =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkFyY2hpdCJ9.'
          'SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
      final result = engine.processAuto('Authorization: Bearer $jwt');
      expect(result.detectedFormat, DetectedFormat.authorization);
    });

    test('JWT stays JWT', () {
      const jwt =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkFyY2hpdCJ9.'
          'SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
      final result = engine.processAuto(jwt);
      expect(result.detectedFormat, DetectedFormat.jwt);
    });

    test('query string stays query string', () {
      final result = engine.processAuto('a=1&b=2');
      expect(result.detectedFormat, DetectedFormat.queryString);
    });
  });

  group('Broken JSON repair transformation chains', () {
    test('URL-encoded broken JSON repairs after decode', () {
      final encoded = Uri.encodeComponent('{name: "Archit"}');
      final result = engine.process(encoded);
      expect((result.parsedValue as Map)['name'], 'Archit');
      expect(
        result.steps.any((s) => s.type == TransformationType.urlDecoded),
        isTrue,
      );
    });

    test('extracted broken JSON from surrounding text repairs', () {
      const input = 'Response:\n{name: "Archit"}\nStatus: 200';
      final result = engine.process(input);
      expect((result.parsedValue as Map)['name'], 'Archit');
      expect(
        result.steps.any((s) => s.type == TransformationType.jsonExtracted),
        isTrue,
      );
    });
  });
}
