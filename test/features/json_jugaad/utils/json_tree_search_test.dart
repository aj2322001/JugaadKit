import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_tree_node.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_builder.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_search.dart';

void main() {
  group('JsonTreeSearch', () {
    late JsonTreeNode root;

    setUp(() {
      root = JsonTreeBuilder.build({
        'communityId': 123,
        'user': {
          'name': 'Archit',
          'active': true,
          'email': null,
        },
      });
    });

    test('matches property names case-insensitively', () {
      final result = JsonTreeSearch.search(root, 'communityid');
      expect(result.matchCount, 1);
      expect(result.matches.single.path, r'$.communityId');
    });

    test('matches string values case-insensitively', () {
      final result = JsonTreeSearch.search(root, 'archit');
      expect(result.matchCount, 1);
      expect(result.matches.single.path, r'$.user.name');
    });

    test('matches numbers and booleans', () {
      expect(JsonTreeSearch.search(root, '123').matchCount, 1);
      expect(JsonTreeSearch.search(root, 'true').matchCount, 1);
    });

    test('matches null values', () {
      final result = JsonTreeSearch.search(root, 'null');
      expect(result.matchCount, 1);
      expect(result.matches.single.path, r'$.user.email');
    });

    test('returns no matches for unknown query', () {
      final result = JsonTreeSearch.search(root, 'missing-value');
      expect(result.matchCount, 0);
      expect(result.pathsToExpand, isEmpty);
    });

    test('collects ancestor paths to expand', () {
      final result = JsonTreeSearch.search(root, 'archit');
      expect(result.pathsToExpand, containsAll([r'$', r'$.user', r'$.user.name']));
    });
  });
}
