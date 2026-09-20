import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_search.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_search_index.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_search_options.dart';

void main() {
  group('JsonTreeSearchOptions', () {
    late JsonTreeSearchIndex index;

    setUp(() {
      index = JsonTreeSearchIndex.fromValue({
        'communityId': 123,
        'events': 'community events',
        'user': {
          'name': 'Archit',
          'active': true,
        },
      });
    });

    test('match case distinguishes Archit from archit', () {
      expect(
        JsonTreeSearch.searchIndex(
          index,
          'archit',
          options: const JsonTreeSearchOptions(matchCase: true),
        ).matchCount,
        0,
      );
      expect(
        JsonTreeSearch.searchIndex(
          index,
          'Archit',
          options: const JsonTreeSearchOptions(matchCase: true),
        ).matchCount,
        1,
      );
    });

    test('whole word avoids partial key matches', () {
      expect(
        JsonTreeSearch.searchIndex(
          index,
          'event',
          options: const JsonTreeSearchOptions(wholeWord: true),
        ).matchCount,
        0,
      );
      expect(
        JsonTreeSearch.searchIndex(
          index,
          'events',
          options: const JsonTreeSearchOptions(wholeWord: true),
        ).matchCount,
        1,
      );
    });

    test('whole word matches standalone values', () {
      expect(
        JsonTreeSearch.searchIndex(
          index,
          'true',
          options: const JsonTreeSearchOptions(wholeWord: true),
        ).matches.single.path,
        r'$.user.active',
      );
    });
  });
}
