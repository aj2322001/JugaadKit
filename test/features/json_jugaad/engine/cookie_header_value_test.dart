import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/features/json_jugaad/engine/cookie_codec.dart';
import 'package:jugaadkit/features/json_jugaad/engine/detected_format.dart';
import 'package:jugaadkit/features/json_jugaad/engine/jugaad_engine.dart';
import 'package:jugaadkit/features/json_jugaad/engine/jugaad_validator.dart';
import 'package:jugaadkit/features/json_jugaad/models/jugaad_structured_output.dart';
import 'package:jugaadkit/features/json_jugaad/models/processing_mode.dart';

const _cookieValue =
    'sess_map=qcdtueecqvfwzfuvssuzatzwqqdacduucfybaztuefsbydtqtwvuyyudyrewcaby; '
    'acsession=09236a33fc2c4c1f1bacae3b46bd15d7; 01-Oct-2026 11:42:12 GMT; '
    'PHPSESSID=gqs01uqs68fno9pjrjgqiefl37';

void main() {
  const engine = JugaadEngine();

  group('Bare Cookie header value', () {
    Map<String, Object?> cookieJson(ProcessingMode? mode) {
      final result = mode == null
          ? engine.processAuto(_cookieValue)
          : engine.processManual(_cookieValue, mode);
      expect(result.detectedFormat, DetectedFormat.cookie);
      final section = result.structuredOutput!.sections.single;
      expect(section.type, JugaadSectionType.body);
      return section.body!.jsonValue! as Map<String, Object?>;
    }

    test('manual Cookie mode shows cookies as JSON', () {
      expect(cookieJson(ProcessingMode.cookie), {
        'sess_map':
            'qcdtueecqvfwzfuvssuzatzwqqdacduucfybaztuefsbydtqtwvuyyudyrewcaby',
        'acsession': '09236a33fc2c4c1f1bacae3b46bd15d7',
        'PHPSESSID': 'gqs01uqs68fno9pjrjgqiefl37',
      });
    });

    test('auto mode detects it as a cookie', () {
      expect(cookieJson(null).keys, ['sess_map', 'acsession', 'PHPSESSID']);
    });

    test('copied text is pretty-printed JSON', () {
      final result = engine.processManual(_cookieValue, ProcessingMode.cookie);
      expect(result.formattedJson, contains('"acsession": "09236a33fc2c4c1f1bacae3b46bd15d7"'));
    });

    test('repeated cookie names become a list', () {
      final parsed = CookieCodec.tryParse('a=1; a=2; b=3')!;
      expect(CookieCodec.toJsonMap(parsed), {
        'a': ['1', '2'],
        'b': '3',
      });
    });

    test('Set-Cookie with attributes keeps the existing layout', () {
      final result = engine.processAuto('session=abc123; Path=/; Secure; HttpOnly');
      final sections = result.structuredOutput!.sections;
      expect(sections.map((s) => s.title), ['Cookie', 'Attributes']);
      expect(sections.first.type, JugaadSectionType.keyValueList);
    });

    test('mostly malformed segments are not treated as a cookie', () {
      expect(JugaadValidator.looksLikeCookieHeaderValue('a=1; hello; world; foo'), isFalse);
      expect(JugaadValidator.looksLikeCookieHeaderValue('a=1'), isFalse);
      expect(JugaadValidator.looksLikeCookieHeaderValue('a=1&b=2'), isFalse);
      expect(JugaadValidator.looksLikeCookieHeaderValue('{"a":"x=1; y=2"}'), isFalse);
    });

    test('query strings are still detected as query strings', () {
      final result = engine.processAuto('a=1&b=2&c=3');
      expect(result.detectedFormat, DetectedFormat.queryString);
    });
  });
}
