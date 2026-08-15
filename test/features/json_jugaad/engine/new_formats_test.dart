import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/features/json_jugaad/engine/confidence.dart';
import 'package:jugaadkit/features/json_jugaad/engine/csv_codec.dart';
import 'package:jugaadkit/features/json_jugaad/engine/curl_codec.dart';
import 'package:jugaadkit/features/json_jugaad/engine/detected_format.dart';
import 'package:jugaadkit/features/json_jugaad/engine/http_headers_codec.dart';
import 'package:jugaadkit/features/json_jugaad/engine/http_response_codec.dart';
import 'package:jugaadkit/features/json_jugaad/engine/jugaad_engine.dart';
import 'package:jugaadkit/features/json_jugaad/engine/xml_codec.dart';
import 'package:jugaadkit/features/json_jugaad/engine/yaml_codec.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_error.dart';
import 'package:jugaadkit/features/json_jugaad/models/jugaad_output_type.dart';
import 'package:jugaadkit/features/json_jugaad/models/processing_mode.dart';
import 'package:jugaadkit/features/json_jugaad/services/json_jugaad_service.dart';

void main() {
  const engine = JugaadEngine();
  const service = JsonJugaadService();

  group('cURL', () {
    const input = """
curl 'https://api.example.com/users?page=1' \\
  -X POST \\
  -H 'Authorization: Bearer xxx' \\
  -H 'Content-Type: application/json' \\
  -d '{"name":"Archit","active":true}'
""";

    test('auto detects cURL', () {
      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.curl);
      expect(result.confidence, Confidence.high);
      expect(result.outputType, JugaadOutputType.text);
      expect(result.formattedJson, contains('POST https://api.example.com/users?page=1'));
      expect(result.formattedJson, contains('Authorization: Bearer xxx'));
      expect(result.formattedJson, contains('"name": "Archit"'));
    });

    test('manual cURL mode works', () {
      final result = engine.processManual(input, ProcessingMode.curl);
      expect(result.detectedFormat, DetectedFormat.curl);
      expect(result.isAutomatic, isFalse);
    });

    test('malformed cURL fails in manual mode', () {
      expect(
        () => engine.processManual('curl without url', ProcessingMode.curl),
        throwsA(isA<JsonJugaadError>()),
      );
    });

    test('codec parses GET with query parameters', () {
      final parsed = CurlCodec.tryParse("curl https://api.example.com/users?page=1");
      expect(parsed, isNotNull);
      expect(parsed!.method, 'GET');
      expect(parsed.url, 'https://api.example.com/users?page=1');
    });
  });

  group('HTTP Headers', () {
    const input = '''
Authorization: Bearer xxx
Content-Type: application/json
Accept: application/json
X-App-Version: 2.4.1
Cache-Control: no-cache
''';

    test('auto detects HTTP headers', () {
      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.httpHeaders);
      expect(result.formattedJson, contains('Authorization: Bearer xxx'));
      expect(result.formattedJson, contains('Content-Type: application/json'));
    });

    test('manual HTTP headers mode works', () {
      final result = engine.processManual(input, ProcessingMode.httpHeaders);
      expect(result.detectedFormat, DetectedFormat.httpHeaders);
    });

    test('invalid headers fail in manual mode', () {
      expect(
        () => engine.processManual('not a header block', ProcessingMode.httpHeaders),
        throwsA(isA<JsonJugaadError>()),
      );
    });

    test('codec supports repeated headers', () {
      final parsed = HttpHeadersCodec.tryParse('''
X-Trace-Id: abc
X-Trace-Id: def
''');
      expect(parsed, isNotNull);
      expect(parsed!.headers.length, 2);
    });
  });

  group('URL', () {
    const input =
        'https://api.example.com:8443/v1/users/123?include=profile&sort=name#details';

    test('auto detects standalone URL', () {
      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.url);
      expect(result.formattedJson, contains('Scheme:'));
      expect(result.formattedJson, contains('api.example.com'));
      expect(result.formattedJson, contains('8443'));
      expect(result.formattedJson, contains('include = profile'));
      expect(result.formattedJson, contains('details'));
    });

    test('manual URL mode works', () {
      final result = engine.processManual(input, ProcessingMode.url);
      expect(result.detectedFormat, DetectedFormat.url);
    });

    test('invalid URL fails in manual mode', () {
      expect(
        () => engine.processManual('not a url', ProcessingMode.url),
        throwsA(isA<JsonJugaadError>()),
      );
    });

    test('cURL is not detected as URL', () {
      final result = engine.processAuto(
        "curl 'https://api.example.com/users?page=1' -X GET",
      );
      expect(result.detectedFormat, DetectedFormat.curl);
      expect(result.detectedFormat, isNot(DetectedFormat.url));
    });

    test('auto detects URL with JWT-looking query parameter', () {
      const input =
          'https://example.com/auth?token=eyJhbGciOiJIUzI1NiJ9.test.test';

      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.url);
      expect(result.confidence, Confidence.high);
      expect(result.formattedJson, contains('token = eyJhbGciOiJIUzI1NiJ9.test.test'));
    });

    test('auto detects URL with encoded redirect query parameter', () {
      const input =
          'https://example.com/login?redirect=https%3A%2F%2Fexample.com';

      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.url);
      expect(result.confidence, Confidence.high);
      expect(result.formattedJson, contains('redirect = https://example.com'));
    });

    test('auto detects URL with multiple normal query parameters', () {
      const input = 'https://api.example.com/users?id=123&token=abc123';

      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.url);
      expect(result.confidence, Confidence.high);
      expect(result.formattedJson, contains('id = 123'));
      expect(result.formattedJson, contains('token = abc123'));
    });

    test('auto detects URL with token-like jwt query parameter name', () {
      const input =
          'https://example.com/path?jwt=eyJhbGciOiJIUzI1NiJ9.test.test';

      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.url);
      expect(result.confidence, Confidence.high);
    });

    test('standalone JWT is not detected as URL', () {
      const input =
          'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjMifQ.signature';

      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.jwt);
      expect(result.detectedFormat, isNot(DetectedFormat.url));
    });
  });

  group('CSV', () {
    const input = '''
id,name,role,active
1,Archit,Developer,true
2,Rahul,Designer,true
3,"John, Jr.",Manager,false
''';

    test('auto detects CSV', () {
      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.csv);
      expect(result.outputType, JugaadOutputType.json);
      expect(result.parsedValue, isA<List>());
      expect((result.parsedValue as List).length, 3);
    });

    test('manual CSV mode works', () {
      final result = engine.processManual(input, ProcessingMode.csv);
      expect(result.detectedFormat, DetectedFormat.csv);
      expect((result.parsedValue as List).first, isA<Map>());
    });

    test('quoted fields with commas are parsed', () {
      final parsed = CsvCodec.tryParse('name,note\nArchit,"hello, world"');
      expect(parsed, isNotNull);
      expect(parsed!.rows.first['note'], 'hello, world');
    });

    test('malformed CSV fails in manual mode', () {
      expect(
        () => engine.processManual('a,b\n1', ProcessingMode.csv),
        throwsA(isA<JsonJugaadError>()),
      );
    });
  });

  group('YAML', () {
    const input = '''
user:
  id: 123
  name: Archit
  active: true
  roles:
    - admin
    - developer
''';

    test('auto detects YAML', () {
      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.yaml);
      expect(result.outputType, JugaadOutputType.json);
      expect((result.parsedValue as Map)['user'], isA<Map>());
    });

    test('manual YAML mode works', () {
      final result = engine.processManual(input, ProcessingMode.yaml);
      expect(result.detectedFormat, DetectedFormat.yaml);
    });

    test('codec parses nested YAML', () {
      final parsed = YamlCodec.tryParse(input);
      expect(parsed, isA<Map>());
    });

    test('malformed YAML fails in manual mode', () {
      expect(
        () => engine.processManual('user:\n  - bad: [', ProcessingMode.yaml),
        throwsA(isA<JsonJugaadError>()),
      );
    });
  });

  group('XML', () {
    const input =
        '<user><id>123</id><name>Archit</name><active>true</active></user>';

    test('auto detects XML', () {
      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.xml);
      expect(result.outputType, JugaadOutputType.text);
      expect(result.formattedJson, contains('<user>'));
      expect(result.formattedJson, contains('  <id>123</id>'));
    });

    test('manual XML mode works', () {
      final result = engine.processManual(input, ProcessingMode.xml);
      expect(result.detectedFormat, DetectedFormat.xml);
    });

    test('self-closing elements are supported', () {
      final formatted = XmlCodec.tryFormat('<item id="1" />');
      expect(formatted, isNotNull);
      expect(formatted, contains('item'));
    });

    test('malformed XML fails in manual mode', () {
      expect(
        () => engine.processManual('<user><id>123', ProcessingMode.xml),
        throwsA(isA<JsonJugaadError>()),
      );
    });
  });

  group('HTTP Response', () {
    const input = '''
HTTP/1.1 401 Unauthorized
Content-Type: application/json
X-Request-ID: 8f72c91a

{"error":"token_expired","message":"Access token has expired","retry":true}
''';

    test('auto detects HTTP response', () {
      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.httpResponse);
      expect(result.formattedJson, contains('401 Unauthorized'));
      expect(result.formattedJson, contains('"error": "token_expired"'));
    });

    test('HTTP response is not detected as plain JSON', () {
      final result = engine.processAuto(input);
      expect(result.detectedFormat, isNot(DetectedFormat.json));
    });

    test('manual HTTP response mode works', () {
      final result = engine.processManual(input, ProcessingMode.httpResponse);
      expect(result.detectedFormat, DetectedFormat.httpResponse);
    });

    test('plain text body is supported', () {
      const plain = '''
HTTP/1.1 200 OK
Content-Type: text/plain

hello world
''';
      final parsed = HttpResponseCodec.tryParse(plain);
      expect(parsed, isNotNull);
      expect(HttpResponseCodec.format(parsed!), contains('hello world'));
    });

    test('malformed HTTP response fails in manual mode', () {
      expect(
        () => engine.processManual('Not an HTTP response', ProcessingMode.httpResponse),
        throwsA(isA<JsonJugaadError>()),
      );
    });
  });

  group('Auto detection priority', () {
    test('cURL beats URL', () {
      final result = service.process(
        "curl 'https://api.example.com/users?page=1' -H 'Accept: application/json'",
      );
      expect(result.detectedFormat, DetectedFormat.curl);
    });

    test('HTTP response beats JSON body', () {
      final result = service.process('''
HTTP/1.1 200 OK
Content-Type: application/json

{"ok":true}
''');
      expect(result.detectedFormat, DetectedFormat.httpResponse);
    });
  });

  group('Manual mode behavior', () {
    test('manual mode does not fall back to auto on failure', () {
      expect(
        () => service.process('not csv', mode: ProcessingMode.csv),
        throwsA(
          predicate<JsonJugaadError>(
            (error) =>
                error.processingMode == ProcessingMode.csv &&
                error.isAutomatic == false,
          ),
        ),
      );
    });

    test('switching back to auto uses original input via view model contract', () {
      const input = '''
id,name
1,Archit
''';
      final jsonAttempt = engine.processManual('{"id":1}', ProcessingMode.json);
      expect(jsonAttempt.detectedFormat, DetectedFormat.json);

      final csvAuto = engine.processAuto(input);
      expect(csvAuto.detectedFormat, DetectedFormat.csv);
    });
  });
}
