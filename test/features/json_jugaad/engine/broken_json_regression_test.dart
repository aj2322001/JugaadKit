import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/features/json_jugaad/engine/confidence.dart';
import 'package:jugaadkit/features/json_jugaad/engine/detected_format.dart';
import 'package:jugaadkit/features/json_jugaad/engine/jugaad_engine.dart';
import 'package:jugaadkit/features/json_jugaad/models/jugaad_output_type.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_repair_highlight.dart';
import 'package:jugaadkit/features/json_jugaad/models/transformation_step.dart';

void main() {
  const engine = JugaadEngine();

  group('Broken JSON regression fixes', () {
    test('preserves root object when inner array is valid but document is truncated', () {
      const input = '{"user":{"name":"Archit","roles":["admin","developer"]';
      final result = engine.process(input);

      expect(result.detectedFormat, isNot(DetectedFormat.jsonInText));
      expect(result.parsedValue, isA<Map>());
      final map = result.parsedValue as Map;
      expect(map['user'], isA<Map>());
      final user = map['user'] as Map;
      expect(user['name'], 'Archit');
      expect(user['roles'], ['admin', 'developer']);
      expect(
        result.steps.any((s) => s.type == TransformationType.jsonExtracted),
        isFalse,
      );
    });

    test('repairs nested missing closing braces without extracting inner JSON', () {
      final shallow = engine.process('{"user":{"name":"Archit"}');
      expect((shallow.parsedValue as Map)['user'], isA<Map>());

      final nestedArray = engine.process('{"users":[{"id":1},{"id":2}');
      expect((nestedArray.parsedValue as Map)['users'], hasLength(2));
    });

    test('HTTP response keeps format and repairs broken JSON body', () {
      const input = '''HTTP/1.1 400 Bad Request
Content-Type: application/json

{error:'invalid_request',message:'Name is required',retry:False}''';

      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.httpResponse);
      expect(result.outputType, JugaadOutputType.text);
      expect(result.confidence, Confidence.high);
      expect(
        result.steps.any((s) => s.type == TransformationType.parsedHttpResponse),
        isTrue,
      );
      expect(result.hasRepairHighlights, isTrue);
      expect(
        result.steps.any((s) => s.type == TransformationType.brokenJsonRepaired),
        isFalse,
      );

      final body = result.structuredOutput!.jsonBodyValue as Map;
      expect(body['error'], 'invalid_request');
      expect(body['message'], 'Name is required');
      expect(body['retry'], isFalse);
    });

    test('cURL keeps format and repairs broken JSON body', () {
      const input = '''curl -X POST https://api.example.com \\
-d '{name:"Archit",active:True}' ''';

      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.curl);
      expect(result.outputType, JugaadOutputType.text);
      expect(result.confidence, Confidence.high);
      expect(
        result.steps.any((s) => s.type == TransformationType.parsedCurl),
        isTrue,
      );
      expect(result.hasRepairHighlights, isTrue);
      expect(
        result.steps.any((s) => s.type == TransformationType.brokenJsonRepaired),
        isFalse,
      );

      final body = result.structuredOutput!.jsonBodyValue as Map;
      expect(body['name'], 'Archit');
      expect(body['active'], isTrue);
    });

    test('valid HTTP response with JSON body stays unchanged', () {
      const input = '''HTTP/1.1 200 OK
Content-Type: application/json

{"name":"Archit","active":true}''';

      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.httpResponse);
      expect(result.hasRepairHighlights, isFalse);
      expect(
        result.steps.any((s) => s.type == TransformationType.brokenJsonRepaired),
        isFalse,
      );
      final body = result.structuredOutput!.jsonBodyValue as Map;
      expect(body['name'], 'Archit');
      expect(body['active'], isTrue);
    });

    test('valid cURL with JSON body stays unchanged', () {
      const input = '''curl -X POST https://api.example.com \\
-H "Content-Type: application/json" \\
-d '{"name":"Archit","active":true}' ''';

      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.curl);
      expect(
        result.steps.any((s) => s.type == TransformationType.brokenJsonRepaired),
        isFalse,
      );
      final body = result.structuredOutput!.jsonBodyValue as Map;
      expect(body['name'], 'Archit');
      expect(body['active'], isTrue);
    });

    test('JSON extraction from surrounding text still works', () {
      const input = 'Response:\n{name: "Archit"}\nStatus: 200';
      final result = engine.process(input);
      expect((result.parsedValue as Map)['name'], 'Archit');
      expect(
        result.steps.any((s) => s.type == TransformationType.jsonExtracted),
        isTrue,
      );
    });

    test('HTTP response body repair highlights repaired fields only', () {
      const input = '''HTTP/1.1 400 Bad Request
Content-Type: application/json

{error:'invalid_request',message:'ok'}''';

      final result = engine.processAuto(input);
      final bodySection = result.structuredOutput!.sections
          .firstWhere((section) => section.title == 'Body');
      final highlights = bodySection.body!.repairHighlights;
      expect(highlights, isNotEmpty);
      expect(
        highlights.any((h) => h.kind == JsonRepairKind.singleQuotedString),
        isTrue,
      );
    });
  });
}
