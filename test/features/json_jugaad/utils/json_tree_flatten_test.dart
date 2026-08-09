import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_builder.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_flatten.dart';

void main() {
  group('JsonTreeFlatten', () {
    test('flattens only expanded nodes', () {
      final root = JsonTreeBuilder.build({
        'user': {
          'id': 123,
          'profile': {'name': 'Archit'},
        },
      });

      final rows = JsonTreeFlatten.visibleRows(
        root: root,
        collapsedPaths: {r'$.user'},
        forceExpandedPaths: const {},
      );

      expect(rows, hasLength(1));
      expect(rows.single.node.path, r'$.user');
      expect(rows.single.isExpanded, isFalse);
    });

    test('includes nested children when expanded', () {
      final root = JsonTreeBuilder.build({
        'user': {
          'id': 123,
          'profile': {'name': 'Archit'},
        },
      });

      final rows = JsonTreeFlatten.visibleRows(
        root: root,
        collapsedPaths: const {},
        forceExpandedPaths: const {},
      );

      expect(rows.any((row) => row.node.path == r'$.user.profile.name'), isTrue);
    });

    test('forces expansion for search paths', () {
      final root = JsonTreeBuilder.build({
        'user': {
          'profile': {'name': 'Archit'},
        },
      });

      final rows = JsonTreeFlatten.visibleRows(
        root: root,
        collapsedPaths: {r'$.user', r'$.user.profile'},
        forceExpandedPaths: {r'$.user', r'$.user.profile'},
      );

      expect(rows.any((row) => row.node.path == r'$.user.profile.name'), isTrue);
    });
  });
}
