import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_tree_node.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_copy_util.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_builder.dart';

void main() {
  group('JsonCopyUtil', () {
    test('copies primitive values without JSON decoration', () {
      final root = JsonTreeBuilder.build({
        'name': 'Archit',
        'age': 25,
        'active': true,
        'email': null,
      });

      final name = root.children.firstWhere((node) => node.key == 'name');
      final age = root.children.firstWhere((node) => node.key == 'age');
      final active = root.children.firstWhere((node) => node.key == 'active');
      final email = root.children.firstWhere((node) => node.key == 'email');

      expect(JsonCopyUtil.valueForClipboard(name), 'Archit');
      expect(JsonCopyUtil.valueForClipboard(age), '25');
      expect(JsonCopyUtil.valueForClipboard(active), 'true');
      expect(JsonCopyUtil.valueForClipboard(email), 'null');
    });

    test('copies keys from nodes', () {
      final root = JsonTreeBuilder.build({
        'name': 'Archit',
        'tags': ['a'],
      });

      final name = root.children.firstWhere((node) => node.key == 'name');
      final firstTag = root.children
          .firstWhere((node) => node.key == 'tags')
          .children
          .first;

      expect(JsonCopyUtil.keyForClipboard(name), 'name');
      expect(JsonCopyUtil.keyForClipboard(firstTag), '0');
    });

    test('copies objects and arrays as valid JSON', () {
      final root = JsonTreeBuilder.build({
        'user': {'id': 123, 'name': 'Archit'},
        'tags': ['a', 'b'],
      });

      final user = root.children.firstWhere((node) => node.key == 'user');
      final tags = root.children.firstWhere((node) => node.key == 'tags');

      final userJson = JsonCopyUtil.valueForClipboard(user);
      final tagsJson = JsonCopyUtil.valueForClipboard(tags);

      expect(jsonDecode(userJson), {'id': 123, 'name': 'Archit'});
      expect(jsonDecode(tagsJson), ['a', 'b']);
      expect(user.type, JsonValueType.object);
      expect(tags.type, JsonValueType.array);
    });
  });
}
