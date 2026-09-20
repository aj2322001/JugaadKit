import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/features/json_jugaad/engine/detected_format.dart';
import 'package:jugaadkit/features/json_jugaad/engine/jugaad_engine.dart';
import 'package:jugaadkit/features/json_jugaad/engine/json_body_processor.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_repair_highlight.dart';
import 'package:jugaadkit/features/json_jugaad/models/transformation_step.dart';

void main() {
  const engine = JugaadEngine();
  late String payload;

  setUp(() {
    payload = File(
      'test/features/json_jugaad/engine/fixtures/escaped_json_missing_null_values.escaped.json',
    ).readAsStringSync();
  });

  group('Escaped JSON with missing null values', () {
    test('real-world escaped home API payload parses through engine', () {
      final result = engine.process(payload);
      final data = (result.parsedValue as Map)['data'] as List;

      expect(data, hasLength(4));
      expect((data[0] as Map)['type'], 'comm_icon');
      expect((data[1] as Map)['type'], 'events');
      expect((data[2] as Map)['type'], 'community_feeds');
      expect((data[3] as Map)['type'], 'actions');

      expect(
        result.steps.any(
          (step) => step.type == TransformationType.decodedEscaped,
        ),
        isTrue,
      );
      expect(result.detectedFormat, DetectedFormat.escapedJson);
      expect(
        result.repairHighlights.any(
          (highlight) => highlight.kind == JsonRepairKind.missingNullValue,
        ),
        isTrue,
      );
    });

    test('preserves HTML, URLs, and escaped newlines in nested values', () {
      final result = engine.process(payload);
      final commIcon = ((result.parsedValue as Map)['data'] as List).first
          as Map;
      final event = (((result.parsedValue as Map)['data'] as List)[1] as Map)['data']
          as Map;
      final eventList = event['event_list'] as List;
      final stepathon = eventList.first as Map;

      expect(
        (commIcon['data'] as Map)['organization'],
        contains('Embassy Federation'),
      );
      expect(
        (commIcon['data'] as Map)['organization'],
        contains('font-family: "Inter"'),
      );
      expect((commIcon['data'] as Map)['is_smart_access_user'], isNull);
      expect(stepathon['cancellation_reason'], isNull);
      expect(
        stepathon['instructions'],
        'Registrations open for Stepathon 2026.\nOn 25th Nov 2026. 6 AM onwards',
      );
      expect(
        stepathon['event_redirection_url'],
        contains('staging-events-embassy.anacity.com'),
      );
    });

    test('json body processor handles escaped payload with missing values', () {
      final processed = JsonBodyProcessor.tryProcess(
        payload,
        contentType: 'application/json',
      );

      expect(processed, isNotNull);
      expect(processed!.wasRepaired, isTrue);
      expect(
        ((processed.value as Map)['data'] as List),
        hasLength(4),
      );
    });
  });
}
