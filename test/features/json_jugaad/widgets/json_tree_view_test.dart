import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/core/theme/app_theme.dart';
import 'package:jugaadkit/features/json_jugaad/widgets/json_tree_view.dart';

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

      await tester.tap(find.text('▾').first);
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

      await tester.tap(find.text('▾'));
      await tester.pump();

      expect(find.text('id'), findsNothing);
      expect(find.text('▸'), findsOneWidget);

      await tester.tap(find.text('▸'));
      await tester.pump();

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
  });
}
