import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_tree_node.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_builder.dart';

void main() {
  group('JsonTreeBuilder', () {
    test('builds nested object nodes', () {
      final root = JsonTreeBuilder.build({
        'user': {
          'id': 123,
          'profile': {'name': 'Archit'},
        },
      });

      expect(root.type, JsonValueType.object);
      expect(root.children, hasLength(1));

      final user = root.children.first;
      expect(user.key, 'user');
      expect(user.path, r'$.user');
      expect(user.type, JsonValueType.object);
      expect(user.children, hasLength(2));

      final profile = user.children.last;
      expect(profile.path, r'$.user.profile');
      expect(profile.children.single.path, r'$.user.profile.name');
    });

    test('builds nested array nodes', () {
      final root = JsonTreeBuilder.build({
        'users': [
          {'name': 'Archit'},
          {'name': 'Rahul'},
        ],
      });

      final users = root.children.single;
      expect(users.path, r'$.users');
      expect(users.type, JsonValueType.array);
      expect(users.children, hasLength(2));
      expect(users.children.first.path, r'$.users[0]');
      expect(users.children.first.children.single.path, r'$.users[0].name');
    });
  });
}
