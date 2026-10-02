import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/features/json_jugaad/engine/body_content_classifier.dart';
import 'package:jugaadkit/features/json_jugaad/engine/detected_format.dart';
import 'package:jugaadkit/features/json_jugaad/engine/jugaad_engine.dart';
import 'package:jugaadkit/features/json_jugaad/models/jugaad_structured_output.dart';

const _formContentType = 'application/x-www-form-urlencoded; charset=utf-8';

const _curl = r"""
curl --location --request POST 'https://app.example.com/move_in_move_out/m_submit_move_in_data' \
--header 'x-acclient: iosmember_6.3.9' \
--header 'content-type: application/x-www-form-urlencoded; charset=utf-8' \
--data-raw 'comm_id=eNortjK2UjIysFSyBlwwDXACNQ~~&move_in_date=&is_existing_user_request=0&relationship_type=Tenant&documents=%5B%7B%22document_type_id%22%3A%22eNortjKxUjIyN7VQsgZcMBAMAnE~%22%2C%22uploadedObjData%22%3A%7B%22details%22%3A%5B%7B%22file_name%22%3A%22requestIssueIcon.pdf%22%2C%22file_size%22%3A%227.75%22%2C%22is_image%22%3A%22false%22%7D%5D%7D%7D%5D'
""";

void main() {
  group('Form-urlencoded request bodies', () {
    test('cURL form body is shown as JSON with nested JSON values decoded', () {
      final result = JugaadEngine().processAuto(_curl);
      expect(result.detectedFormat, DetectedFormat.curl);

      final bodySection = result.structuredOutput!.sections
          .firstWhere((section) => section.type == JugaadSectionType.body);
      final body = bodySection.body!;
      expect(body.isJson, isTrue);

      final value = body.jsonValue! as Map<String, Object?>;
      expect(value['comm_id'], 'eNortjK2UjIysFSyBlwwDXACNQ~~');
      expect(value['move_in_date'], '');
      expect(value['is_existing_user_request'], '0');
      expect(value['relationship_type'], 'Tenant');

      final documents = value['documents']! as List<Object?>;
      final first = documents.first! as Map<String, Object?>;
      expect(first['document_type_id'], 'eNortjKxUjIyN7VQsgZcMBAMAnE~');
      final details = (first['uploadedObjData']! as Map)['details'] as List;
      expect((details.first as Map)['file_name'], 'requestIssueIcon.pdf');
    });

    test('cURL text output contains pretty-printed form body', () {
      final result = JugaadEngine().processAuto(_curl);
      expect(result.formattedJson, contains('"relationship_type": "Tenant"'));
      expect(result.formattedJson, contains('"document_type_id"'));
      expect(result.formattedJson, isNot(contains('%7B')));
    });

    test('repeated keys become a list', () {
      final body = BodyContentClassifier.classify(
        'tag=a&tag=b&name=x',
        contentType: _formContentType,
      );
      expect(body.jsonValue, {
        'tag': ['a', 'b'],
        'name': 'x',
      });
    });

    test('plus signs decode to spaces', () {
      final body = BodyContentClassifier.classify(
        'q=hello+world&n=1',
        contentType: _formContentType,
      );
      expect(body.jsonValue, {'q': 'hello world', 'n': '1'});
    });

    test('malformed percent encoding stays plain text', () {
      final body = BodyContentClassifier.classify(
        'a=%ZZ&b=1',
        contentType: _formContentType,
      );
      expect(body.isPlain, isTrue);
    });

    test('form-looking body without form content type stays plain text', () {
      final body = BodyContentClassifier.classify(
        'a=1&b=2',
        contentType: 'text/plain',
      );
      expect(body.isPlain, isTrue);
    });

    test('JSON body with form content type is still parsed as JSON', () {
      final body = BodyContentClassifier.classify(
        '{"a":1}',
        contentType: _formContentType,
      );
      expect(body.jsonValue, {'a': 1});
    });
  });
}
