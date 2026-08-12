import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/features/json_jugaad/engine/confidence.dart';
import 'package:jugaadkit/features/json_jugaad/engine/detected_format.dart';
import 'package:jugaadkit/features/json_jugaad/engine/jugaad_engine.dart';
import 'package:jugaadkit/features/json_jugaad/engine/jugaad_validator.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_error.dart';
import 'package:jugaadkit/features/json_jugaad/models/transformation_step.dart';
import 'package:jugaadkit/features/json_jugaad/services/json_jugaad_service.dart';

void main() {
  const engine = JugaadEngine();
  const service = JsonJugaadService();

  group('JSON', () {
    test('parses plain JSON', () {
      final result = engine.process('{"user":{"id":123}}');
      expect(result.detectedFormat, DetectedFormat.json);
      expect(result.confidence, Confidence.high);
      expect(result.originalInput, '{"user":{"id":123}}');
      expect(result.parsedValue, isA<Map>());
    });

    test('handles escaped JSON', () {
      final result = engine.process(r'{\"user\":{\"id\":123}}');
      expect(
        result.steps.any((s) => s.type == TransformationType.decodedEscaped),
        isTrue,
      );
    });

    test('handles deeply escaped JSON', () {
      final result = engine.process(r'{\"user\":{\"id\":123}}');
      expect(result.parsedValue, isA<Map>());
    });

    test('extracts nested JSON strings', () {
      final result = engine.process(r'{"data":"{\"id\":123}"}');
      expect((result.parsedValue as Map)['data'], isA<Map>());
      expect(
        result.steps.any((s) => s.type == TransformationType.extractedNestedJson),
        isTrue,
      );
    });
  });

  group('URL encoding', () {
    test('decodes URL-encoded JSON', () {
      final result = engine.process('%7B%22id%22%3A42%7D');
      expect((result.parsedValue as Map)['id'], 42);
      expect(result.detectedFormat, DetectedFormat.urlEncoded);
    });

    test('does not decode normal URLs without JSON markers', () {
      expect(
        () => engine.process('https://example.com/path?name=Archit'),
        throwsA(isA<JsonJugaadError>()),
      );
    });
  });

  group('Base64', () {
    test('decodes Base64 JSON', () {
      final result = engine.process('eyJ1c2VyIjp7ImlkIjoxMjN9fQ==');
      expect((result.parsedValue as Map)['user'], isA<Map>());
      expect(
        result.steps.any((s) => s.type == TransformationType.base64Decoded),
        isTrue,
      );
    });

    test('rejects invalid Base64', () {
      expect(
        () => engine.process('not!!!base64'),
        throwsA(isA<JsonJugaadError>()),
      );
    });

    test('does not treat short alphanumeric text as Base64', () {
      expect(
        () => engine.process('HelloWorld'),
        throwsA(isA<JsonJugaadError>()),
      );
    });
  });

  group('Unicode', () {
    test('parses unicode escapes in JSON', () {
      final result = engine.process(r'{"message":"\u0048\u0069"}');
      expect((result.parsedValue as Map)['message'], 'Hi');
    });
  });

  group('HTML entities', () {
    test('decodes HTML-entity encoded JSON', () {
      final result = engine.process('{&quot;name&quot;:&quot;Archit&quot;}');
      expect((result.parsedValue as Map)['name'], 'Archit');
      expect(
        result.steps.any((s) => s.type == TransformationType.htmlEntitiesDecoded),
        isTrue,
      );
    });
  });

  group('Wrappers', () {
    test('removes Optional wrapper', () {
      final result = engine.process(r'Optional("{\"id\":123}")');
      expect((result.parsedValue as Map)['id'], 123);
    });

    test('extracts JSON from JSONP callback', () {
      final result = engine.process('callback({"id":123})');
      expect((result.parsedValue as Map)['id'], 123);
      expect(
        result.steps.any(
          (s) =>
              s.type == TransformationType.jsonpExtracted ||
              s.type == TransformationType.jsonExtracted,
        ),
        isTrue,
      );
    });

    test('extracts JSON from surrounding log text', () {
      final result =
          engine.process('DEBUG: API RESPONSE -> {"user":{"id":123}}');
      expect((result.parsedValue as Map)['user'], isA<Map>());
      expect(
        result.steps.any((s) => s.type == TransformationType.jsonExtracted),
        isTrue,
      );
    });
  });

  group('Query string', () {
    test('parses query-string data', () {
      final result = engine.process('name=Archit&age=25&active=true');
      final map = result.parsedValue as Map;
      expect(map['name'], 'Archit');
      expect(map['age'], 25);
      expect(map['active'], true);
      expect(result.detectedFormat, DetectedFormat.queryString);
    });

    test('parses encoded JSON inside query parameter', () {
      final result = engine.process('data=%7B%22id%22%3A123%7D&ok=1');
      final data = (result.parsedValue as Map)['data'];
      expect(data, isA<Map>());
      expect((data as Map)['id'], 123);
    });
  });

  group('NDJSON', () {
    test('parses JSON lines', () {
      final result = engine.process('{"id":1}\n{"id":2}\n{"id":3}\n');
      expect(result.parsedValue, isA<List>());
      expect((result.parsedValue as List).length, 3);
      expect(result.detectedFormat, DetectedFormat.ndjson);
    });

    test('rejects invalid NDJSON line', () {
      expect(
        () => engine.process('{"id":1}\n{"id":2\n'),
        throwsA(isA<JsonJugaadError>()),
      );
    });

    test('does not treat pretty-printed JSON as NDJSON', () {
      const input = '''
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}''';

      final result = engine.process(input);
      expect(result.detectedFormat, DetectedFormat.json);
      expect((result.parsedValue as Map)['hosting'], isA<Map>());
    });
  });

  group('Loose JSON', () {
    test('repairs trailing comma', () {
      final result = engine.process('{\n  "name": "Archit",\n  "age": 25,\n}');
      expect((result.parsedValue as Map)['name'], 'Archit');
      expect(
        result.steps.any((s) => s.type == TransformationType.trailingCommaRemoved),
        isTrue,
      );
    });

    test('removes comments', () {
      final result = engine.process(
        '{\n  // user information\n  "name": "Archit"\n}',
      );
      expect((result.parsedValue as Map)['name'], 'Archit');
      expect(
        result.steps.any((s) => s.type == TransformationType.commentRemoved),
        isTrue,
      );
    });

    test('does not repair arbitrary malformed JSON', () {
      expect(
        () => engine.process('{name: Archit}'),
        throwsA(isA<JsonJugaadError>()),
      );
    });
  });

  group('Hex', () {
    test('decodes hex JSON', () {
      final result = engine.process('7b226964223a3132337d');
      expect((result.parsedValue as Map)['id'], 123);
      expect(
        result.steps.any((s) => s.type == TransformationType.hexDecoded),
        isTrue,
      );
    });

    test('does not decode short numeric strings as hex', () {
      expect(
        () => engine.process('abcdef1234567890'),
        throwsA(isA<JsonJugaadError>()),
      );
    });
  });

  group('JWT', () {
    const jwt =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
        'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkFyY2hpdCJ9.'
        'SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

    test('detects and decodes JWT without verification', () {
      final result = engine.process(jwt);
      expect(result.detectedFormat, DetectedFormat.jwt);
      expect(result.confidence, Confidence.high);
      final map = result.parsedValue as Map;
      expect(map['jugaadDetected'], 'JWT');
      expect(map['header'], isA<Map>());
      expect(map['payload'], isA<Map>());
    });

    test('rejects malformed JWT', () {
      expect(
        () => engine.process('part1.part2'),
        throwsA(isA<JsonJugaadError>()),
      );
    });
  });

  group('Engine behavior', () {
    test('preserves original input', () {
      const input = r'Optional("{\"id\":123}")';
      final result = service.process(input);
      expect(result.originalInput, input);
    });

    test('records transformation history', () {
      final result = engine.process('%7B%22id%22%3A1%7D');
      expect(result.steps, isNotEmpty);
      expect(result.steps.last.type, TransformationType.parsedJson);
    });

    test('rejects failed transformation and keeps partial history', () {
      try {
        engine.process('%%%');
      } on JsonJugaadError catch (error) {
        expect(error.originalInput, '%%%');
        expect(error.partialSteps, isA<List<TransformationStep>>());
        return;
      }
      fail('Expected JsonJugaadError');
    });

    test('ambiguous Base64-like input remains unchanged on failure', () {
      const input = 'ABCDABCDABCDABCD';
      try {
        engine.process(input);
        fail('Expected failure');
      } on JsonJugaadError catch (error) {
        expect(error.confidence, Confidence.low);
        expect(error.detectedFormat, DetectedFormat.base64);
      }
    });
  });

  group('Validators', () {
    test('timestamp range helpers stay conservative', () {
      expect(JugaadValidator.looksLikeJwt('a.b'), isFalse);
      expect(JugaadValidator.looksLikeQueryString('a=1'), isFalse);
    });
  });
}
