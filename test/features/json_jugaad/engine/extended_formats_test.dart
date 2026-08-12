import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/features/json_jugaad/engine/authorization_codec.dart';
import 'package:jugaadkit/features/json_jugaad/engine/confidence.dart';
import 'package:jugaadkit/features/json_jugaad/engine/cookie_codec.dart';
import 'package:jugaadkit/features/json_jugaad/engine/detected_format.dart';
import 'package:jugaadkit/features/json_jugaad/engine/http_error_codec.dart';
import 'package:jugaadkit/features/json_jugaad/engine/jugaad_engine.dart';
import 'package:jugaadkit/features/json_jugaad/engine/multipart_codec.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_error.dart';
import 'package:jugaadkit/features/json_jugaad/models/jugaad_output_type.dart';
import 'package:jugaadkit/features/json_jugaad/models/processing_mode.dart';
import 'package:jugaadkit/features/json_jugaad/services/json_jugaad_service.dart';

void main() {
  const engine = JugaadEngine();
  const service = JsonJugaadService();

  const jwt =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkFyY2hpdCJ9.'
      'SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

  group('Cookie', () {
    const setCookie =
        'session=abc123; Path=/; Domain=example.com; Secure; HttpOnly; SameSite=Lax';

    test('auto detects Set-Cookie with attributes', () {
      final result = engine.processAuto(setCookie);
      expect(result.detectedFormat, DetectedFormat.cookie);
      expect(result.confidence, Confidence.high);
      expect(result.outputType, JugaadOutputType.text);
      expect(result.formattedJson, contains('session'));
      expect(result.formattedJson, contains('abc123'));
      expect(result.formattedJson, contains('Secure'));
      expect(result.formattedJson, contains('HttpOnly'));
      expect(result.formattedJson, contains('SameSite'));
    });

    test('auto detects Cookie header with multiple cookies', () {
      const input = 'Cookie: session=abc123; theme=dark';
      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.cookie);
      expect(result.formattedJson, contains('session'));
      expect(result.formattedJson, contains('theme'));
    });

    test('auto detects Set-Cookie header prefix', () {
      const input = 'Set-Cookie: session=abc123; Path=/; Secure; HttpOnly';
      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.cookie);
      expect(result.formattedJson, contains('Path'));
      expect(result.formattedJson, contains('Secure'));
    });

    test('codec parses Expires and Max-Age', () {
      const input =
          'token=xyz; Expires=Wed, 21 Oct 2025 07:28:00 GMT; Max-Age=3600';
      final parsed = CookieCodec.tryParse(input);
      expect(parsed, isNotNull);
      final attrs = parsed!.cookies.single.attributes;
      expect(attrs.any((a) => a.key == 'Expires'), isTrue);
      expect(attrs.any((a) => a.key == 'Max-Age'), isTrue);
    });

    test('manual cookie mode works', () {
      final result = engine.processManual(setCookie, ProcessingMode.cookie);
      expect(result.detectedFormat, DetectedFormat.cookie);
      expect(result.isAutomatic, isFalse);
    });

    test('invalid cookie fails in manual mode', () {
      expect(
        () => engine.processManual('not a cookie', ProcessingMode.cookie),
        throwsA(isA<JsonJugaadError>()),
      );
    });
  });

  group('Authorization Header', () {
    test('auto detects Bearer token', () {
      const input = 'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjMifQ.xxx';
      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.authorization);
      expect(result.formattedJson, contains('Bearer'));
      expect(result.formattedJson, contains('Token:'));
    });

    test('Bearer JWT is authorization not plain JWT', () {
      final input = 'Authorization: Bearer $jwt';
      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.authorization);
      expect(result.detectedFormat, isNot(DetectedFormat.jwt));
      expect(result.formattedJson, contains('JWT Header'));
      expect(result.formattedJson, contains('Archit'));
    });

    test('auto detects Basic auth and decodes credentials', () {
      const input = 'Authorization: Basic dXNlcjpwYXNzd29yZA==';
      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.authorization);
      expect(result.formattedJson, contains('Basic'));
      expect(result.formattedJson, contains('user'));
      expect(result.formattedJson, contains('password'));
    });

    test('codec handles unknown scheme', () {
      const input = 'Authorization: ApiKey secret-key-123';
      final parsed = AuthorizationCodec.tryParse(input);
      expect(parsed, isNotNull);
      expect(parsed!.scheme, 'Apikey');
      expect(parsed.credential, 'secret-key-123');
    });

    test('manual authorization mode works', () {
      const input = 'Authorization: Bearer token123';
      final result = engine.processManual(input, ProcessingMode.authorization);
      expect(result.detectedFormat, DetectedFormat.authorization);
    });

    test('malformed authorization fails in manual mode', () {
      expect(
        () => engine.processManual('Authorization:', ProcessingMode.authorization),
        throwsA(isA<JsonJugaadError>()),
      );
    });
  });

  group('Multipart Request', () {
    const input = '''
------WebKitFormBoundaryabc123
Content-Disposition: form-data; name="name"

Archit
------WebKitFormBoundaryabc123
Content-Disposition: form-data; name="email"

archit@example.com
------WebKitFormBoundaryabc123
Content-Disposition: form-data; name="file"; filename="test.pdf"
Content-Type: application/pdf

%PDF-1.4 binary
------WebKitFormBoundaryabc123--
''';

    test('auto detects multipart form data', () {
      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.multipart);
      expect(result.confidence, Confidence.high);
      expect(result.formattedJson, contains('Archit'));
      expect(result.formattedJson, contains('archit@example.com'));
      expect(result.formattedJson, contains('test.pdf'));
      expect(result.formattedJson, contains('[Binary content]'));
    });

    test('codec parses repeated field names', () {
      const repeated = '''
------boundary
Content-Disposition: form-data; name="tag"

a
------boundary
Content-Disposition: form-data; name="tag"

b
------boundary--
''';
      final parsed = MultipartCodec.tryParse(repeated);
      expect(parsed, isNotNull);
      expect(parsed!.fields.where((f) => f.name == 'tag').length, 2);
    });

    test('multipart is not detected as JSON', () {
      const jsonPart = '''
------boundary
Content-Disposition: form-data; name="payload"

{"id":1}
------boundary--
''';
      final result = engine.processAuto(jsonPart);
      expect(result.detectedFormat, DetectedFormat.multipart);
      expect(result.detectedFormat, isNot(DetectedFormat.json));
    });

    test('manual multipart mode works', () {
      final result = engine.processManual(input, ProcessingMode.multipart);
      expect(result.detectedFormat, DetectedFormat.multipart);
    });

    test('malformed multipart fails in manual mode', () {
      expect(
        () => engine.processManual('------bad\nno disposition', ProcessingMode.multipart),
        throwsA(isA<JsonJugaadError>()),
      );
    });
  });

  group('HTTP Error', () {
    test('auto detects Dio-style error', () {
      const input = '''
DioException [bad response]: status code 422
Response Text: {"success":false,"message":"Unit not found"}
''';
      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.httpError);
      expect(result.formattedJson, contains('422'));
      expect(result.formattedJson, contains('Unit not found'));
    });

    test('auto detects HTTP shorthand error with JSON body', () {
      const input = '''
HTTP 500 Internal Server Error
{"error":"database_error","message":"Something went wrong"}
''';
      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.httpError);
      expect(result.formattedJson, contains('500'));
      expect(result.formattedJson, contains('Something went wrong'));
      expect(result.formattedJson, contains('database_error'));
    });

    test('supports common status codes', () {
      for (final code in [400, 401, 403, 404, 422, 429, 503]) {
        final parsed = HttpErrorCodec.tryParse('HTTP $code Error\nplain text');
        expect(parsed, isNotNull, reason: 'status $code');
        expect(parsed!.statusCode, code);
      }
    });

    test('plain text error body is supported', () {
      const input = 'HTTP 404 Not Found\nUser does not exist';
      final parsed = HttpErrorCodec.tryParse(input);
      expect(parsed, isNotNull);
      expect(parsed!.message, 'User does not exist');
    });

    test('complete HTTP response is not HTTP error', () {
      const input = '''
HTTP/1.1 404 Not Found
Content-Type: application/json

{"error":"not_found","message":"User does not exist"}
''';
      final result = engine.processAuto(input);
      expect(result.detectedFormat, DetectedFormat.httpResponse);
      expect(result.detectedFormat, isNot(DetectedFormat.httpError));
    });

    test('manual HTTP error mode works', () {
      const input = '''
DioException [bad response]: status code 401
Response Text: {"message":"Access token has expired"}
''';
      final result = engine.processManual(input, ProcessingMode.httpError);
      expect(result.detectedFormat, DetectedFormat.httpError);
    });

    test('malformed HTTP error fails in manual mode', () {
      expect(
        () => engine.processManual('not an error', ProcessingMode.httpError),
        throwsA(isA<JsonJugaadError>()),
      );
    });
  });

  group('Auto detection priority (extended)', () {
    test('authorization beats JWT', () {
      final result = service.process('Authorization: Bearer $jwt');
      expect(result.detectedFormat, DetectedFormat.authorization);
    });

    test('HTTP response beats HTTP error', () {
      final result = service.process('''
HTTP/1.1 404 Not Found
Content-Type: application/json

{"error":"not_found"}
''');
      expect(result.detectedFormat, DetectedFormat.httpResponse);
    });

    test('cookie is not detected as HTTP headers', () {
      const input = 'Cookie: session=abc123; Path=/';
      final result = service.process(input);
      expect(result.detectedFormat, DetectedFormat.cookie);
      expect(result.detectedFormat, isNot(DetectedFormat.httpHeaders));
    });
  });

  group('Manual mode behavior (extended)', () {
    test('manual mode does not fall back to auto on failure', () {
      expect(
        () => service.process('not cookie', mode: ProcessingMode.cookie),
        throwsA(
          predicate<JsonJugaadError>(
            (error) =>
                error.processingMode == ProcessingMode.cookie &&
                error.isAutomatic == false,
          ),
        ),
      );
    });
  });
}
