import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_search.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_search_index.dart';

void main() {
  group('JsonTreeSearchIndex', () {
    late JsonTreeSearchIndex index;

    setUp(() {
      index = JsonTreeSearchIndex.fromValue({
        'communityId': 123,
        'user': {
          'name': 'Archit',
          'active': true,
          'email': null,
        },
      });
    });

    test('searchIndex matches same results as tree search', () {
      expect(
        JsonTreeSearch.searchIndex(index, 'communityid').matchCount,
        1,
      );
      expect(
        JsonTreeSearch.searchIndex(index, 'archit').matches.single.path,
        r'$.user.name',
      );
      expect(JsonTreeSearch.searchIndex(index, '123').matchCount, 1);
      expect(JsonTreeSearch.searchIndex(index, 'true').matchCount, 1);
      expect(
        JsonTreeSearch.searchIndex(index, 'null').matches.single.path,
        r'$.user.email',
      );
    });

    test('indexes nested paths without building tree nodes', () {
      expect(index.entries.map((entry) => entry.path), contains(r'$.user.name'));
    });
  });
}
