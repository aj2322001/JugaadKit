import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/features/json_jugaad/engine/confidence.dart';
import 'package:jugaadkit/features/json_jugaad/engine/detected_format.dart';
import 'package:jugaadkit/features/json_jugaad/engine/jugaad_engine.dart';
import 'package:jugaadkit/features/json_jugaad/models/jugaad_output_type.dart';
import 'package:jugaadkit/features/json_jugaad/models/jugaad_structured_output.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_error.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_result.dart';
import 'package:jugaadkit/features/json_jugaad/models/transformation_step.dart';

const _jwt =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
    'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkFyY2hpdCJ9.'
    'SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

typedef CorpusVerifier = void Function(JsonJugaadResult result);

class AutoCorpusCase {
  AutoCorpusCase({
    required this.name,
    required this.input,
    required this.expectedFormat,
    this.expectedConfidence,
    this.expectedSteps = const [],
    this.verify,
  });

  final String name;
  final String input;
  final DetectedFormat expectedFormat;
  final Confidence? expectedConfidence;
  final List<TransformationType> expectedSteps;
  final CorpusVerifier? verify;
}

class AmbiguousCorpusCase {
  const AmbiguousCorpusCase({
    required this.name,
    required this.input,
    this.expectAmbiguous = true,
  });

  final String name;
  final String input;
  final bool expectAmbiguous;
}

JugaadOutputSection _section(JsonJugaadResult result, String title) {
  return result.structuredOutput!.sections.firstWhere(
    (section) => section.title == title,
  );
}

void _runAutoCase(JugaadEngine engine, AutoCorpusCase testCase) {
  final result = engine.processAuto(testCase.input);

  expect(
    result.detectedFormat,
    testCase.expectedFormat,
    reason: '${testCase.name}: detected format',
  );

  if (testCase.expectedConfidence != null) {
    expect(
      result.confidence,
      testCase.expectedConfidence,
      reason: '${testCase.name}: confidence',
    );
  }

  for (final stepType in testCase.expectedSteps) {
    expect(
      result.steps.any((step) => step.type == stepType),
      isTrue,
      reason: '${testCase.name}: missing step $stepType',
    );
  }

  testCase.verify?.call(result);
}

void _runAmbiguousCase(JugaadEngine engine, AmbiguousCorpusCase testCase) {
  expect(
    () => engine.processAuto(testCase.input),
    throwsA(
      predicate<JsonJugaadError>(
        (error) => error.isAmbiguousAutoFailure == testCase.expectAmbiguous,
        'expected ambiguous=${testCase.expectAmbiguous} for ${testCase.name}',
      ),
    ),
    reason: testCase.name,
  );
}

void main() {
  const engine = JugaadEngine();

  group('Data Jugaad regression corpus — format representatives', () {
    final cases = <AutoCorpusCase>[
      AutoCorpusCase(
        name: 'valid JSON object',
        input: '{"user":{"name":"Archit","roles":["admin","developer"]}}',
        expectedFormat: DetectedFormat.json,
        expectedConfidence: Confidence.high,
        verify: (result) {
          final user = (result.parsedValue as Map)['user'] as Map;
          expect(user['name'], 'Archit');
          expect(user['roles'], ['admin', 'developer']);
          expect(result.repairHighlights, isEmpty);
        },
      ),
      AutoCorpusCase(
        name: 'broken JSON — unquoted keys',
        input: '{name: "Archit", active: true}',
        expectedFormat: DetectedFormat.looseJson,
        expectedConfidence: Confidence.medium,
        verify: (result) {
          expect((result.parsedValue as Map)['name'], 'Archit');
          expect(result.hasRepairHighlights, isTrue);
        },
      ),
      AutoCorpusCase(
        name: 'broken JSON — single-quoted strings',
        input: "{'name': 'Archit'}",
        expectedFormat: DetectedFormat.looseJson,
        expectedConfidence: Confidence.medium,
        verify: (result) {
          expect((result.parsedValue as Map)['name'], 'Archit');
          expect(result.hasRepairHighlights, isTrue);
        },
      ),
      AutoCorpusCase(
        name: 'broken JSON — Python True/False/None',
        input: '{active: True, deleted: False, value: None}',
        expectedFormat: DetectedFormat.looseJson,
        expectedConfidence: Confidence.medium,
        verify: (result) {
          final map = result.parsedValue as Map;
          expect(map['active'], isTrue);
          expect(map['deleted'], isFalse);
          expect(map['value'], isNull);
        },
      ),
      AutoCorpusCase(
        name: 'broken JSON — trailing comma',
        input: '{"name": "Archit", "age": 25,}',
        expectedFormat: DetectedFormat.looseJson,
        expectedSteps: [TransformationType.trailingCommaRemoved],
        verify: (result) {
          expect((result.parsedValue as Map)['name'], 'Archit');
        },
      ),
      AutoCorpusCase(
        name: 'broken JSON — comments',
        input: '''
{
  // user profile
  "name": "Archit" /* primary */
}''',
        expectedFormat: DetectedFormat.looseJson,
        expectedSteps: [TransformationType.commentRemoved],
        verify: (result) {
          expect((result.parsedValue as Map)['name'], 'Archit');
        },
      ),
      AutoCorpusCase(
        name: 'broken JSON — missing closing braces',
        input: '{"user":{"name":"Archit"}',
        expectedFormat: DetectedFormat.looseJson,
        expectedConfidence: Confidence.medium,
        verify: (result) {
          expect(((result.parsedValue as Map)['user'] as Map)['name'], 'Archit');
        },
      ),
      AutoCorpusCase(
        name: 'broken JSON — missing closing brackets',
        input: '{"roles":["admin","developer"]',
        expectedFormat: DetectedFormat.looseJson,
        verify: (result) {
          expect((result.parsedValue as Map)['roles'], ['admin', 'developer']);
        },
      ),
      AutoCorpusCase(
        name: 'broken JSON — nested missing closers',
        input: '{"user":{"name":"Archit","roles":["admin","developer"]',
        expectedFormat: DetectedFormat.looseJson,
        verify: (result) {
          final user = (result.parsedValue as Map)['user'] as Map;
          expect(user['name'], 'Archit');
          expect(user['roles'], ['admin', 'developer']);
        },
      ),
      AutoCorpusCase(
        name: 'JWT token',
        input: _jwt,
        expectedFormat: DetectedFormat.jwt,
        verify: (result) {
          final payload = (result.parsedValue as Map)['payload'] as Map;
          expect(payload['name'], 'Archit');
        },
      ),
      AutoCorpusCase(
        name: 'Base64-encoded JSON',
        input: 'eyJ1c2VyIjp7ImlkIjoxMjN9fQ==',
        expectedFormat: DetectedFormat.base64,
        expectedSteps: [TransformationType.base64Decoded],
        verify: (result) {
          expect(((result.parsedValue as Map)['user'] as Map)['id'], 123);
        },
      ),
      AutoCorpusCase(
        name: 'hex-encoded JSON',
        input: '7b226964223a3132337d',
        expectedFormat: DetectedFormat.hex,
        expectedSteps: [TransformationType.hexDecoded],
        verify: (result) {
          expect((result.parsedValue as Map)['id'], 123);
        },
      ),
      AutoCorpusCase(
        name: 'URL-encoded JSON',
        input: '%7B%22name%22%3A%22Archit%22%7D',
        expectedFormat: DetectedFormat.urlEncoded,
        expectedSteps: [TransformationType.urlDecoded],
        verify: (result) {
          expect((result.parsedValue as Map)['name'], 'Archit');
        },
      ),
      AutoCorpusCase(
        name: 'escaped JSON string',
        input: r'{\"user\":{\"id\":123}}',
        expectedFormat: DetectedFormat.escapedJson,
        expectedSteps: [TransformationType.decodedEscaped],
        verify: (result) {
          expect(((result.parsedValue as Map)['user'] as Map)['id'], 123);
        },
      ),
      AutoCorpusCase(
        name: 'HTML-entity encoded JSON',
        input: '{&quot;name&quot;:&quot;Archit&quot;}',
        expectedFormat: DetectedFormat.htmlEntities,
        expectedSteps: [TransformationType.htmlEntitiesDecoded],
        verify: (result) {
          expect((result.parsedValue as Map)['name'], 'Archit');
        },
      ),
      AutoCorpusCase(
        name: 'NDJSON / JSON Lines',
        input: '{"id":1}\n{"id":2}\n{"id":3}\n',
        expectedFormat: DetectedFormat.ndjson,
        expectedSteps: [TransformationType.parsedNdjson],
        verify: (result) {
          expect((result.parsedValue as List), hasLength(3));
        },
      ),
      AutoCorpusCase(
        name: 'query string / form data',
        input: 'name=Archit&age=25&active=true',
        expectedFormat: DetectedFormat.queryString,
        expectedSteps: [TransformationType.parsedQueryString],
        verify: (result) {
          final map = result.parsedValue as Map;
          expect(map['name'], 'Archit');
          expect(map['age'], 25);
          expect(map['active'], isTrue);
        },
      ),
      AutoCorpusCase(
        name: 'cURL command with JSON body',
        input: '''
curl -X POST https://api.example.com/users \\
  -H "Content-Type: application/json" \\
  -d '{"name":"Archit","active":true}'
''',
        expectedFormat: DetectedFormat.curl,
        expectedConfidence: Confidence.high,
        expectedSteps: [TransformationType.parsedCurl],
        verify: (result) {
          expect(result.outputType, JugaadOutputType.text);
          final request = _section(result, 'Request');
          expect(request.method, 'POST');
          expect(request.url, 'https://api.example.com/users');
          final body = _section(result, 'Body').body!.jsonValue as Map;
          expect(body['name'], 'Archit');
        },
      ),
      AutoCorpusCase(
        name: 'HTTP headers block',
        input: '''
Authorization: Bearer token-123
Content-Type: application/json
Accept: application/json
''',
        expectedFormat: DetectedFormat.httpHeaders,
        expectedSteps: [TransformationType.parsedHttpHeaders],
        verify: (result) {
          final headers = _section(result, 'Headers').headers!;
          expect(headers.any((h) => h.key == 'Authorization'), isTrue);
          expect(headers.any((h) => h.key == 'Content-Type'), isTrue);
        },
      ),
      AutoCorpusCase(
        name: 'HTTP response with JSON body',
        input: '''
HTTP/1.1 200 OK
Content-Type: application/json

{"name":"Archit","active":true}
''',
        expectedFormat: DetectedFormat.httpResponse,
        expectedConfidence: Confidence.high,
        expectedSteps: [TransformationType.parsedHttpResponse],
        verify: (result) {
          final status = _section(result, 'Status');
          expect(status.statusCode, 200);
          final body = result.structuredOutput!.jsonBodyValue as Map;
          expect(body['name'], 'Archit');
        },
      ),
      AutoCorpusCase(
        name: 'HTTP error (Dio-style)',
        input: '''
DioException [bad response]: status code 422
Response Text: {"success":false,"message":"Unit not found"}
''',
        expectedFormat: DetectedFormat.httpError,
        expectedSteps: [TransformationType.parsedHttpError],
        verify: (result) {
          final status = _section(result, 'Status');
          expect(status.statusCode, 422);
          expect(result.formattedJson, contains('Unit not found'));
        },
      ),
      AutoCorpusCase(
        name: 'Authorization Bearer header',
        input: 'Authorization: Bearer $_jwt',
        expectedFormat: DetectedFormat.authorization,
        expectedSteps: [TransformationType.parsedAuthorization],
        verify: (result) {
          expect(result.formattedJson, contains('Bearer'));
          expect(result.formattedJson, contains('Archit'));
        },
      ),
      AutoCorpusCase(
        name: 'Set-Cookie value',
        input:
            'session=abc123; Path=/; Domain=example.com; Secure; HttpOnly; SameSite=Lax',
        expectedFormat: DetectedFormat.cookie,
        expectedSteps: [TransformationType.parsedCookie],
        verify: (result) {
          expect(result.formattedJson, contains('session'));
          expect(result.formattedJson, contains('abc123'));
          expect(result.formattedJson, contains('Secure'));
        },
      ),
      AutoCorpusCase(
        name: 'multipart form request',
        input: '''
------WebKitFormBoundaryabc123
Content-Disposition: form-data; name="name"

Archit
------WebKitFormBoundaryabc123
Content-Disposition: form-data; name="email"

archit@example.com
------WebKitFormBoundaryabc123--
''',
        expectedFormat: DetectedFormat.multipart,
        expectedSteps: [TransformationType.parsedMultipart],
        verify: (result) {
          expect(result.formattedJson, contains('Archit'));
          expect(result.formattedJson, contains('archit@example.com'));
        },
      ),
      AutoCorpusCase(
        name: 'CSV table',
        input: '''
id,name,active
1,Archit,true
2,Alex,false
''',
        expectedFormat: DetectedFormat.csv,
        expectedSteps: [TransformationType.parsedCsv],
        verify: (result) {
          final rows = result.parsedValue as List;
          expect(rows, hasLength(2));
          expect((rows.first as Map)['name'], 'Archit');
        },
      ),
      AutoCorpusCase(
        name: 'YAML document with JSON-like string value',
        input: '''
user:
  name: Archit
  meta: "{not: json}"
  active: true
''',
        expectedFormat: DetectedFormat.yaml,
        expectedSteps: [TransformationType.parsedYaml],
        verify: (result) {
          final user = (result.parsedValue as Map)['user'] as Map;
          expect(user['name'], 'Archit');
          expect(user['meta'], '{not: json}');
        },
      ),
      AutoCorpusCase(
        name: 'XML document',
        input: '<user><name>Archit</name><active>true</active></user>',
        expectedFormat: DetectedFormat.xml,
        expectedSteps: [TransformationType.formattedXml],
        verify: (result) {
          expect(result.formattedJson, contains('<name>Archit</name>'));
        },
      ),
      AutoCorpusCase(
        name: 'URL inspector',
        input: 'https://api.example.com/users?page=1&active=true#profile',
        expectedFormat: DetectedFormat.url,
        expectedSteps: [TransformationType.parsedUrl],
        verify: (result) {
          expect(result.formattedJson, contains('api.example.com'));
          expect(result.formattedJson, contains('page'));
        },
      ),
      AutoCorpusCase(
        name: 'nested JSON string extraction',
        input: r'{"data":"{\"id\":123,\"name\":\"Archit\"}"}',
        expectedFormat: DetectedFormat.nestedJson,
        expectedSteps: [TransformationType.extractedNestedJson],
        verify: (result) {
          final data = (result.parsedValue as Map)['data'] as Map;
          expect(data['id'], 123);
        },
      ),
      AutoCorpusCase(
        name: 'JSON extracted from surrounding log text',
        input: 'DEBUG: API RESPONSE -> {"user":{"id":123,"name":"Archit"}}',
        expectedFormat: DetectedFormat.jsonInText,
        expectedSteps: [TransformationType.jsonExtracted],
        verify: (result) {
          final user = (result.parsedValue as Map)['user'] as Map;
          expect(user['name'], 'Archit');
        },
      ),
      AutoCorpusCase(
        name: 'JSONP callback wrapper',
        input: 'callback({"id":123,"name":"Archit"})',
        expectedFormat: DetectedFormat.jsonp,
        verify: (result) {
          expect((result.parsedValue as Map)['name'], 'Archit');
          expect(
            result.steps.any(
              (step) =>
                  step.type == TransformationType.jsonpExtracted ||
                  step.type == TransformationType.jsonExtracted,
            ),
            isTrue,
          );
        },
      ),
      AutoCorpusCase(
        name: 'Swift Optional wrapper',
        input: r'Optional("{\"id\":123,\"name\":\"Archit\"}")',
        expectedFormat: DetectedFormat.wrapper,
        verify: (result) {
          expect((result.parsedValue as Map)['name'], 'Archit');
        },
      ),
      AutoCorpusCase(
        name: 'broken JSON extracted from surrounding text',
        input: 'Response:\n{name: "Archit"}\nStatus: 200',
        expectedFormat: DetectedFormat.jsonInText,
        expectedSteps: [TransformationType.jsonExtracted],
        verify: (result) {
          expect((result.parsedValue as Map)['name'], 'Archit');
        },
      ),
    ];

    for (final testCase in cases) {
      test(testCase.name, () => _runAutoCase(engine, testCase));
    }
  });

  group('Data Jugaad regression corpus — collision / priority', () {
    final cases = <AutoCorpusCase>[
      AutoCorpusCase(
        name: 'cURL containing valid JSON stays cURL',
        input: "curl https://api.example.com -d '{\"id\":1}'",
        expectedFormat: DetectedFormat.curl,
        verify: (result) {
          expect(result.structuredOutput!.jsonBodyValue, isA<Map>());
        },
      ),
      AutoCorpusCase(
        name: 'cURL containing broken JSON stays cURL',
        input: "curl -X POST https://api.example.com -d '{name:\"Archit\",active:True}'",
        expectedFormat: DetectedFormat.curl,
        verify: (result) {
          expect(result.hasRepairHighlights, isTrue);
          final body = result.structuredOutput!.jsonBodyValue as Map;
          expect(body['name'], 'Archit');
        },
      ),
      AutoCorpusCase(
        name: 'HTTP response containing valid JSON stays HTTP response',
        input: '''
HTTP/1.1 200 OK
Content-Type: application/json

{"ok":true}
''',
        expectedFormat: DetectedFormat.httpResponse,
      ),
      AutoCorpusCase(
        name: 'HTTP response containing broken JSON stays HTTP response',
        input: '''
HTTP/1.1 400 Bad Request
Content-Type: application/json

{error:'invalid_request',message:'Name is required',retry:False}
''',
        expectedFormat: DetectedFormat.httpResponse,
        verify: (result) {
          expect(result.hasRepairHighlights, isTrue);
          final body = result.structuredOutput!.jsonBodyValue as Map;
          expect(body['error'], 'invalid_request');
          expect(body['retry'], isFalse);
        },
      ),
      AutoCorpusCase(
        name: 'Authorization containing JWT stays Authorization',
        input: 'Authorization: Bearer $_jwt',
        expectedFormat: DetectedFormat.authorization,
      ),
      AutoCorpusCase(
        name: 'multipart containing JSON-looking field stays multipart',
        input: '''
------boundary
Content-Disposition: form-data; name="payload"

{"id":1}
------boundary--
''',
        expectedFormat: DetectedFormat.multipart,
      ),
      AutoCorpusCase(
        name: 'multipart containing broken JSON field stays multipart',
        input: '''
------boundary
Content-Disposition: form-data; name="payload"

{name: "Archit"}
------boundary--
''',
        expectedFormat: DetectedFormat.multipart,
        verify: (result) {
          expect(result.formattedJson, contains('name'));
        },
      ),
      AutoCorpusCase(
        name: 'pretty-printed JSON is JSON not NDJSON',
        input: '''
{
  "hosting": {
    "public": "build/web"
  }
}
''',
        expectedFormat: DetectedFormat.json,
        verify: (result) {
          expect((result.parsedValue as Map)['hosting'], isA<Map>());
        },
      ),
      AutoCorpusCase(
        name: 'query string is not URL inspector',
        input: 'a=1&b=2&name=Archit',
        expectedFormat: DetectedFormat.queryString,
      ),
      AutoCorpusCase(
        name: 'JWT is not Base64',
        input: _jwt,
        expectedFormat: DetectedFormat.jwt,
        verify: (result) {
          expect(
            result.steps.any((s) => s.type == TransformationType.base64Decoded),
            isFalse,
          );
        },
      ),
      AutoCorpusCase(
        name: 'Base64 JSON decodes then parses JSON',
        input: 'eyJuYW1lIjoiQXJjaGl0In0=',
        expectedFormat: DetectedFormat.base64,
        expectedSteps: [TransformationType.base64Decoded],
        verify: (result) {
          expect((result.parsedValue as Map)['name'], 'Archit');
        },
      ),
      AutoCorpusCase(
        name: 'URL-encoded JSON decodes then parses JSON',
        input: '%7B%22active%22%3Atrue%7D',
        expectedFormat: DetectedFormat.urlEncoded,
        expectedSteps: [TransformationType.urlDecoded],
        verify: (result) {
          expect((result.parsedValue as Map)['active'], isTrue);
        },
      ),
      AutoCorpusCase(
        name: 'YAML with JSON-like values stays YAML',
        input: '''
settings:
  config: "{key: value}"
  enabled: true
''',
        expectedFormat: DetectedFormat.yaml,
        verify: (result) {
          final settings = (result.parsedValue as Map)['settings'] as Map;
          expect(settings['config'], '{key: value}');
          expect(settings['enabled'], isTrue);
        },
      ),
    ];

    for (final testCase in cases) {
      test(testCase.name, () => _runAutoCase(engine, testCase));
    }
  });

  group('Data Jugaad regression corpus — recently fixed regressions', () {
    test('truncated document preserves root object instead of inner array', () {
      const input = '{"user":{"name":"Archit","roles":["admin","developer"]';
      final result = engine.processAuto(input);

      expect(result.detectedFormat, DetectedFormat.looseJson);
      expect(
        result.steps.any((s) => s.type == TransformationType.jsonExtracted),
        isFalse,
      );
      final user = (result.parsedValue as Map)['user'] as Map;
      expect(user['roles'], ['admin', 'developer']);
    });

    test('HTTP response repairs broken JSON body without losing format', () {
      const input = '''
HTTP/1.1 400 Bad Request
Content-Type: application/json

{error:'invalid_request',message:'Name is required',retry:False}''';

      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.httpResponse);
      expect(result.hasRepairHighlights, isTrue);
      final body = result.structuredOutput!.jsonBodyValue as Map;
      expect(body['message'], 'Name is required');
    });

    test('cURL repairs broken JSON body without losing format', () {
      const input = '''
curl -X POST https://api.example.com \\
-d '{name:"Archit",active:True}' ''';

      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.curl);
      expect(result.hasRepairHighlights, isTrue);
      final body = result.structuredOutput!.jsonBodyValue as Map;
      expect(body['active'], isTrue);
    });
  });

  group('Data Jugaad regression corpus — string safety', () {
    test('valid JSON with broken-looking string literals stays untouched', () {
      const input = '''
{
  "message": "True False None",
  "example": "{name: value}",
  "text": "Archit's account"
}''';

      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.json);
      expect(result.confidence, Confidence.high);
      expect(result.hasRepairHighlights, isFalse);
      final map = result.parsedValue as Map;
      expect(map['message'], 'True False None');
      expect(map['example'], '{name: value}');
    });
  });

  group('Data Jugaad regression corpus — negative / ambiguous inputs', () {
    const cases = <AmbiguousCorpusCase>[
      AmbiguousCorpusCase(name: 'plain key-value line', input: 'name: Archit'),
      AmbiguousCorpusCase(name: 'colon-separated words', input: 'hello: world'),
      AmbiguousCorpusCase(name: 'equals assignment', input: 'foo = bar'),
      AmbiguousCorpusCase(
        name: 'random developer sentence',
        input: 'random developer text without structure',
      ),
      AmbiguousCorpusCase(
        name: 'plain log line without JSON',
        input: '2026-03-15 INFO worker started successfully',
      ),
      AmbiguousCorpusCase(
        name: 'not json at all',
        input: 'not json at all',
      ),
    ];

    for (final testCase in cases) {
      test(testCase.name, () => _runAmbiguousCase(engine, testCase));
    }
  });
}

// Corpus inventory (auto-maintained):
// - Format representatives: 34
// - Collision / priority: 13
// - Regression fixes: 3
// - String safety: 1
// - Negative / ambiguous: 6
// Total corpus cases: 57
