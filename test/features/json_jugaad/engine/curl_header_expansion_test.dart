import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/features/json_jugaad/engine/header_value_expander.dart';
import 'package:jugaadkit/features/json_jugaad/engine/jugaad_engine.dart';
import 'package:jugaadkit/features/json_jugaad/models/jugaad_structured_output.dart';

const _cookieCurl = r"""
curl --location --request POST 'https://app.example.com/submit' \
--header 'x-acclient: iosmember_6.3.9' \
--header 'cookie: sess_map=qcdtueecqvfw; acsession=09236a33fc2c4c1f1bacae3b46bd15d7; 01-Oct-2026 11:42:12 GMT; PHPSESSID=gqs01uqs68fno9pjrjgqiefl37' \
--header 'authorization: Basic cWF1c3I6cm9vdA==' \
--header 'content-type: application/x-www-form-urlencoded; charset=utf-8' \
--data-raw 'comm_id=abc~~&relationship_type=Tenant'
""";

const _jsonHeaderCurl = r"""
curl --location --request POST 'https://example.com/api/fetchVisitorPasses' \
--header 'x-acclient: member_5141' \
--header 'user-data: {"community_id":"21","email":"someone@example.com"}' \
--header 'authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2dlcmF3b3JsZG5ldy5henVyZXdlYnNpdGVzLm5ldCIsImlhdCI6MTc3NzI4NjE3OCwiZXhwIjoxODA4ODIyMTc4LCJhdWQiOiJ3d3cuZXhhbXBsZS5jb20iLCJzdWIiOiJ0aGV2aXNoYWwuc2FwQGdtYWlsLmNvbSIsImVtYWlsIjoidGhldmlzaGFsLnNhcEBnbWFpbC5jb20ifQ.Lm23kdLdkf5pEttXUJNO0OxLrZw0jAuvqIf_T-ABjlk' \
--header 'content-type: application/json; charset=utf-8' \
--data-raw '{"pass_type":"past","upcoming_pass_offset":"0","past_pass_offset":"0"}'
""";

JugaadStructuredOutput _structured(String curl) =>
    const JugaadEngine().processAuto(curl).structuredOutput!;

JugaadOutputSection _headers(JugaadStructuredOutput output) =>
    output.sections.firstWhere((section) => section.type == JugaadSectionType.headers);

void main() {
  group('cURL header expansion in place', () {
    test('cookie expands under Headers, not a separate section', () {
      final output = _structured(_cookieCurl);
      expect(
        output.sections.where((s) => s.title.startsWith('Header ·')),
        isEmpty,
      );

      final values = _headers(output).structuredHeaderValues!;
      expect(values['cookie'], {
        'sess_map': 'qcdtueecqvfw',
        'acsession': '09236a33fc2c4c1f1bacae3b46bd15d7',
        'PHPSESSID': 'gqs01uqs68fno9pjrjgqiefl37',
      });
    });

    test('Basic authorization expands in place', () {
      final values = _headers(_structured(_cookieCurl)).structuredHeaderValues!;
      expect(values['authorization'], {
        'scheme': 'Basic',
        'username': 'qausr',
        'password': 'root',
      });
    });

    test('JSON header expands in place', () {
      final values = _headers(_structured(_jsonHeaderCurl)).structuredHeaderValues!;
      expect(values['user-data'], {
        'community_id': '21',
        'email': 'someone@example.com',
      });
    });

    test('Bearer JWT expands in place', () {
      final auth = _headers(_structured(_jsonHeaderCurl))
          .structuredHeaderValues!['authorization']! as Map;
      expect(auth['scheme'], 'Bearer');
      expect((auth['header'] as Map)['alg'], 'HS256');
      expect((auth['payload'] as Map)['email'], 'thevishal.sap@gmail.com');
    });

    test('plain headers stay raw strings', () {
      final headers = _headers(_structured(_jsonHeaderCurl));
      expect(
        headers.headers!.firstWhere((h) => h.key == 'x-acclient').value,
        'member_5141',
      );
      expect(headers.structuredHeaderValues!.containsKey('x-acclient'), isFalse);
    });

    test('body remains primary searchable JSON', () {
      final output = _structured(_jsonHeaderCurl);
      expect(output.jsonBodyValue, {
        'pass_type': 'past',
        'upcoming_pass_offset': '0',
        'past_pass_offset': '0',
      });
    });

    test('copied text shows expanded values under the header name', () {
      final text =
          const JugaadEngine().processAuto(_jsonHeaderCurl).formattedJson;
      expect(text, contains('user-data:'));
      expect(text, contains('"community_id": "21"'));
      expect(text, isNot(contains('Header user-data:')));
      expect(text, isNot(contains('Header ·')));
    });

    test('copied authorization keeps the raw Bearer string then JSON', () {
      final text =
          const JugaadEngine().processAuto(_jsonHeaderCurl).formattedJson;
      expect(
        text,
        contains(
          'authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9',
        ),
      );
      expect(text, contains('"scheme": "Bearer"'));
      expect(text, contains('"email": "thevishal.sap@gmail.com"'));
    });

    test('copied cookie still replaces the raw string with JSON only', () {
      final text = const JugaadEngine().processAuto(_cookieCurl).formattedJson;
      expect(text, contains('cookie:'));
      expect(text, contains('"PHPSESSID": "gqs01uqs68fno9pjrjgqiefl37"'));
      expect(text, isNot(contains('cookie: sess_map=')));
    });

    test('plain header values are not expanded', () {
      expect(HeaderValueExpander.tryExpand('x-acclient', 'member_5141'), isNull);
      expect(HeaderValueExpander.tryExpand('authorization', 'Bearer xxx'), isNull);
      expect(HeaderValueExpander.tryExpand('cookie', 'single=1'), isNull);
      expect(HeaderValueExpander.tryExpand('x-count', '42'), isNull);
      expect(HeaderValueExpander.tryExpand('x-broken', '{not json'), isNull);
    });
  });
}
