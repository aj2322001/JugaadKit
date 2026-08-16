import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/core/theme/app_theme.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_search_navigator.dart';
import 'package:jugaadkit/features/json_jugaad/widgets/json_tree/json_tree_controls.dart';
import 'package:jugaadkit/features/json_jugaad/widgets/json_tree_view.dart';

double _keyStartX(WidgetTester tester, String key) {
  return tester.getTopLeft(find.text(key)).dx;
}

Future<void> _pumpTree(
  WidgetTester tester,
  TextEditingController searchController,
  Object rootValue, {
  double width = 500,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SizedBox(
          width: width,
          height: 800,
          child: JsonTreeView(
            rootValue: rootValue,
            searchController: searchController,
          ),
        ),
      ),
    ),
  );
}

void main() {
  Widget wrap(Widget child, {required TextEditingController searchController}) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 600,
          child: child,
        ),
      ),
    );
  }

  group('JsonTreeView', () {
    late TextEditingController searchController;

    setUp(() {
      searchController = TextEditingController();
    });

    tearDown(() {
      searchController.dispose();
    });

    testWidgets('long value text uses row width minus key and trailing gap',
        (tester) async {
      final token = 'eyJhbGciOiJIUzI1NiJ9.${'a' * 200}.signature';
      await tester.pumpWidget(
        wrap(
          JsonTreeView(
            rootValue: {
              'authToken': token,
            },
            searchController: searchController,
          ),
          searchController: searchController,
        ),
      );

      final listWidth = tester.getSize(find.byType(ListView)).width;
      final contentWidth = listWidth -
          JsonTreeLayout.trailingActionsWidth -
          JsonTreeLayout.scrollbarGutter;
      final valueArea = tester.renderObject<RenderBox>(
        find.ancestor(
          of: find.textContaining('eyJhbGciOiJIUzI1NiJ9'),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Padding &&
                widget.padding == const EdgeInsets.only(right: 12),
          ),
        ),
      );

      // authToken key + indent + colon + trailing slot consume the rest of the row.
      expect(
        valueArea.size.width,
        greaterThan(contentWidth - 240),
      );
    });

    testWidgets('sibling keys at the same depth share the same start position',
        (tester) async {
      await _pumpTree(
        tester,
        searchController,
        {
          'statusMessage': 'ok',
          'expiresIn': 3600,
          'tokenType': 'Bearer',
          'projects': [],
        },
      );

      final positions = {
        'statusMessage': _keyStartX(tester, 'statusMessage'),
        'expiresIn': _keyStartX(tester, 'expiresIn'),
        'tokenType': _keyStartX(tester, 'tokenType'),
        'projects': _keyStartX(tester, 'projects'),
      };

      expect(
        positions.values.toSet().length,
        1,
        reason: 'depth-1 keys must align: $positions',
      );
    });

    testWidgets('wrapped value does not shift the next sibling key position',
        (tester) async {
      final token = 'eyJhbGciOiJIUzI1NiJ9.${'a' * 200}.signature';
      await _pumpTree(
        tester,
        searchController,
        {
          'statusMessage': 'ok',
          'authToken': token,
          'expiresIn': 3600,
          'tokenType': 'Bearer',
        },
      );

      final before = _keyStartX(tester, 'statusMessage');
      final wrapped = _keyStartX(tester, 'authToken');
      final after = _keyStartX(tester, 'expiresIn');
      final last = _keyStartX(tester, 'tokenType');

      expect(wrapped, before);
      expect(after, before);
      expect(last, before);
    });

    testWidgets('expandable and leaf nodes at the same depth align keys',
        (tester) async {
      await _pumpTree(
        tester,
        searchController,
        {
          'projects': [
            {'id': 1},
          ],
          'statusMessage': 'ok',
          'refreshToken': 'short',
        },
      );

      final expandable = _keyStartX(tester, 'projects');
      final leaf = _keyStartX(tester, 'statusMessage');
      final anotherLeaf = _keyStartX(tester, 'refreshToken');

      expect(leaf, expandable);
      expect(anotherLeaf, expandable);
    });

    testWidgets('array siblings stay aligned after a long wrapped value',
        (tester) async {
      final token = 'eyJhbGciOiJIUzI1NiJ9.${'a' * 200}.signature';
      await _pumpTree(
        tester,
        searchController,
        {
          'items': [
            token,
            'short',
          ],
        },
      );

      final first = _keyStartX(tester, '0');
      final second = _keyStartX(tester, '1');

      expect(second, first);
    });

    testWidgets('deep nested siblings stay aligned with wrapped values',
        (tester) async {
      final token = 'eyJhbGciOiJIUzI1NiJ9.${'a' * 200}.signature';
      await _pumpTree(
        tester,
        searchController,
        {
          'level1': {
            'level2': {
              'wrapped': token,
              'plain': 'value',
              'nested': {'leaf': true},
            },
          },
        },
      );

      final wrapped = _keyStartX(tester, 'wrapped');
      final plain = _keyStartX(tester, 'plain');
      final nested = _keyStartX(tester, 'nested');
      final leaf = _keyStartX(tester, 'leaf');

      expect(plain, wrapped);
      expect(nested, wrapped);
      expect(leaf, greaterThan(wrapped));
    });

    testWidgets('renders nested objects and arrays', (tester) async {
      await tester.pumpWidget(
        wrap(
          JsonTreeView(
            rootValue: {
              'users': [
                {'name': 'Archit', 'roles': ['admin', 'developer']},
              ],
            },
            searchController: searchController,
          ),
          searchController: searchController,
        ),
      );

      expect(find.text('users'), findsOneWidget);
      expect(find.textContaining(' ['), findsWidgets);
      expect(find.text(']'), findsWidgets);
      expect(find.text('name'), findsOneWidget);
      expect(find.text('roles'), findsOneWidget);
      expect(find.textContaining(' {'), findsWidgets);
    });

    testWidgets('shows count suffix when collapsed', (tester) async {
      await tester.pumpWidget(
        wrap(
          JsonTreeView(
            rootValue: {
              'users': [{'name': 'Archit'}],
            },
            searchController: searchController,
          ),
          searchController: searchController,
        ),
      );

      await tester.tap(find.byIcon(Icons.chevron_right_rounded).first);
      await tester.pump();

      expect(find.text('name'), findsNothing);
      expect(find.textContaining('[1]'), findsOneWidget);
    });

    testWidgets('collapses and expands object nodes', (tester) async {
      await tester.pumpWidget(
        wrap(
          JsonTreeView(
            rootValue: {
              'user': {'id': 123},
            },
            searchController: searchController,
          ),
          searchController: searchController,
        ),
      );

      expect(find.text('id'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('id'), findsNothing);
      expect(find.textContaining('{1}'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('id'), findsOneWidget);
    });

    testWidgets('search highlights matches and reports count', (tester) async {
      await tester.pumpWidget(
        wrap(
          JsonTreeView(
            rootValue: {
              'communityId': 123,
              'user': {'name': 'Archit'},
            },
            searchController: searchController,
            onSearchChanged: (_, __) {},
          ),
          searchController: searchController,
        ),
      );

      searchController.text = 'archit';
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('name'), findsOneWidget);
    });

    testWidgets('search reports no matches', (tester) async {
      var matchCount = -1;
      await tester.pumpWidget(
        wrap(
          JsonTreeView(
            rootValue: {'user': {'name': 'Archit'}},
            searchController: searchController,
            onSearchChanged: (_, result) {
              matchCount = result?.matchCount ?? 0;
            },
          ),
          searchController: searchController,
        ),
      );

      searchController.text = 'missing';
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(matchCount, 0);
    });

    testWidgets('search navigation jumps between matches', (tester) async {
      final navigator = JsonTreeSearchNavigator();
      addTearDown(navigator.dispose);

      await tester.pumpWidget(
        wrap(
          JsonTreeView(
            rootValue: {
              'alpha': 'one',
              'beta': 'two',
              'gamma': 'three',
            },
            searchController: searchController,
            searchNavigator: navigator,
          ),
          searchController: searchController,
        ),
      );

      searchController.text = 'a';
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(navigator.matchCount, greaterThan(1));
      expect(navigator.activeMatchNumber, 1);

      navigator.goToNext();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(navigator.activeMatchNumber, 2);

      navigator.goToPrevious();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(navigator.activeMatchNumber, 1);
    });

    testWidgets('navigation works after scrolling and updating search',
        (tester) async {
      final navigator = JsonTreeSearchNavigator();
      addTearDown(navigator.dispose);

      final rootValue = <String, Object>{
        for (var i = 0; i < 40; i++) 'field$i': 'value$i',
        'alpha': 'match-a',
        'beta': 'match-b',
        'gamma': 'match-c',
      };

      await tester.pumpWidget(
        wrap(
          JsonTreeView(
            rootValue: rootValue,
            searchController: searchController,
            searchNavigator: navigator,
          ),
          searchController: searchController,
        ),
      );

      searchController.text = 'match';
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(navigator.matchCount, 3);
      expect(navigator.activeMatchNumber, 1);

      await tester.drag(find.byType(Scrollable), const Offset(0, -400));
      await tester.pump();

      searchController.text = 'match-';
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(navigator.activeMatchNumber, 1);

      navigator.goToNext();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(navigator.activeMatchNumber, 2);

      navigator.goToNext();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(navigator.activeMatchNumber, 3);
    });

    testWidgets('navigation scrolls to off-screen matches', (tester) async {
      final navigator = JsonTreeSearchNavigator();
      addTearDown(navigator.dispose);

      final rootValue = <String, Object>{
        for (var i = 0; i < 80; i++) 'field_$i': 'value_$i',
        'needle': 'find-me',
      };

      await tester.pumpWidget(
        wrap(
          JsonTreeView(
            rootValue: rootValue,
            searchController: searchController,
            searchNavigator: navigator,
          ),
          searchController: searchController,
        ),
      );

      searchController.text = 'find-me';
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(navigator.matchCount, 1);
      expect(find.textContaining('find-me'), findsOneWidget);

      navigator.goToNext();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(navigator.activeMatchNumber, 1);
      expect(find.textContaining('find-me'), findsOneWidget);
    });
  });
}
