import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_path.dart';

void main() {
  group('JsonPath', () {
    test('builds dot notation for simple keys', () {
      expect(JsonPath.childPath(r'$', 'user'), r'$.user');
      expect(
        JsonPath.childPath(r'$.user', 'profile'),
        r'$.user.profile',
      );
    });

    test('builds bracket notation for special-character keys', () {
      expect(
        JsonPath.childPath(r'$', 'weird.key'),
        r'$["weird.key"]',
      );
      expect(
        JsonPath.childPath(r'$', r'key"quote'),
        r'$["key\"quote"]',
      );
    });

    test('builds array index paths', () {
      expect(JsonPath.indexPath(r'$.users', 0), r'$.users[0]');
      expect(
        JsonPath.indexPath(r'$.users[0]', 1),
        r'$.users[0][1]',
      );
    });
  });
}
