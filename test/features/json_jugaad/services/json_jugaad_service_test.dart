import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_error.dart';
import 'package:jugaadkit/features/json_jugaad/models/transformation_step.dart';
import 'package:jugaadkit/features/json_jugaad/services/json_jugaad_service.dart';

void main() {
  const service = JsonJugaadService();

  group('JsonJugaadService', () {
    test('parses normal JSON', () {
      const input = '{"user":{"id":123,"name":"Ada"}}';
      final result = service.process(input);

      expect(result.parsedValue, isA<Map>());
      expect((result.parsedValue as Map)['user'], isA<Map>());
      expect(result.steps.any((s) => s.type == TransformationType.parsedJson),
          isTrue);
    });

    test('handles Swift Optional wrapper with escaped JSON', () {
      const input = r'Optional("{\"user\":{\"id\":123}}")';
      final result = service.process(input);

      expect(result.parsedValue, isA<Map>());
      final user = (result.parsedValue as Map)['user'] as Map;
      expect(user['id'], 123);
      expect(
        result.steps.any((s) => s.type == TransformationType.removedWrapper),
        isTrue,
      );
      expect(
        result.steps.any((s) => s.type == TransformationType.decodedEscaped),
        isTrue,
      );
    });

    test('decodes double-escaped JSON', () {
      const input = r'{\"user\":{\"id\":123}}';
      final result = service.process(input);

      expect(result.parsedValue, isA<Map>());
      expect(
        (result.parsedValue as Map)['user'],
        isA<Map>(),
      );
    });

    test('extracts JSON nested inside a JSON string value', () {
      const input = r'{"payload":"{\"active\":true}"}';
      final result = service.process(input);

      final payload = (result.parsedValue as Map)['payload'];
      expect(payload, isA<Map>());
      expect((payload as Map)['active'], isTrue);
      expect(
        result.steps.any((s) => s.type == TransformationType.extractedNestedJson),
        isTrue,
      );
    });

    test('decodes URL-encoded JSON', () {
      const input = '%7B%22id%22%3A42%7D';
      final result = service.process(input);

      expect(result.parsedValue, isA<Map>());
      expect((result.parsedValue as Map)['id'], 42);
      expect(
        result.steps.any((s) => s.type == TransformationType.urlDecoded),
        isTrue,
      );
    });

    test('handles unicode escapes', () {
      const input = r'{"greeting":"\u0048\u0069"}';
      final result = service.process(input);

      expect((result.parsedValue as Map)['greeting'], 'Hi');
    });

    test('throws on malformed input', () {
      expect(
        () => service.process('not json at all'),
        throwsA(isA<JsonJugaadError>()),
      );
    });

    test('throws on empty input', () {
      expect(
        () => service.process('   '),
        throwsA(isA<JsonJugaadError>()),
      );
    });
  });
}
