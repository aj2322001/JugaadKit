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

      expect(rows, hasLength(3));
      expect(rows[0].isOpenBracket, isTrue);
      expect(rows[1].node.path, r'$.user');
      expect(rows[1].isExpanded, isFalse);
      expect(rows[2].isCloseBracket, isTrue);
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
