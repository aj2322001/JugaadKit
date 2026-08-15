import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/core/theme/app_theme.dart';
import 'package:jugaadkit/core/theme/feedback_colors.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_repair_highlight.dart';
import 'package:jugaadkit/features/json_jugaad/widgets/json_tree/json_repair_tooltip.dart';
import 'package:jugaadkit/features/json_jugaad/widgets/json_tree_view.dart';

void main() {
  Widget wrap(Widget child) {
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

  group('JSON repair highlighting', () {
    late TextEditingController searchController;

    setUp(() {
      searchController = TextEditingController();
    });

    tearDown(() {
      searchController.dispose();
    });

    testWidgets('valid JSON shows top brackets without repair color',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          JsonTreeView(
            rootValue: const {'name': 'Archit'},
            searchController: searchController,
            repairHighlights: JsonRepairHighlightSet.empty,
          ),
        ),
      );

      final nameText = tester.widget<Text>(find.text('name'));
      expect(nameText.style?.color, isNot(jsonRepairHighlightColor));

      final openingBracket = tester.widget<Text>(find.text('{'));
      final closingBracket = tester.widget<Text>(find.text('}'));
      expect(openingBracket.style?.color, isNot(jsonRepairHighlightColor));
      expect(closingBracket.style?.color, isNot(jsonRepairHighlightColor));
    });

    testWidgets('repaired key is shown in error color', (tester) async {
      await tester.pumpWidget(
        wrap(
          JsonTreeView(
            rootValue: const {'name': 'Archit'},
            searchController: searchController,
            repairHighlights: JsonRepairHighlightSet.from([
              const JsonRepairHighlight(
                path: r'$.name',
                target: JsonRepairTarget.key,
                kind: JsonRepairKind.unquotedKey,
                originalText: 'name',
                repairedText: '"name"',
              ),
            ]),
          ),
        ),
      );

      final keyText = tester.widget<Text>(find.text('name'));
      expect(keyText.style?.color, jsonRepairHighlightColor);
    });

    testWidgets('repaired key has tooltip wired from repair metadata',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          JsonTreeView(
            rootValue: const {'name': 'Archit'},
            searchController: searchController,
            repairHighlights: JsonRepairHighlightSet.from([
              const JsonRepairHighlight(
                path: r'$.name',
                target: JsonRepairTarget.key,
                kind: JsonRepairKind.unquotedKey,
                originalText: 'name',
                repairedText: '"name"',
              ),
            ]),
          ),
        ),
      );

      final tooltipFinder = find.ancestor(
        of: find.text('name'),
        matching: find.byType(Tooltip),
      );
      expect(tooltipFinder, findsOneWidget);

      final tooltip = tester.widget<Tooltip>(tooltipFinder);
      final feedback = AppFeedbackColors.light;
      expect(
        tooltip.richMessage,
        buildRepairTooltipSpan(
          const JsonRepairHighlight(
            path: r'$.name',
            target: JsonRepairTarget.key,
            kind: JsonRepairKind.unquotedKey,
            originalText: 'name',
            repairedText: '"name"',
          ),
          feedback,
        ),
      );
    });

    testWidgets('valid JSON key does not show repair tooltip', (tester) async {
      await tester.pumpWidget(
        wrap(
          JsonTreeView(
            rootValue: const {'name': 'Archit'},
            searchController: searchController,
            repairHighlights: JsonRepairHighlightSet.empty,
          ),
        ),
      );

      final tooltipFinder = find.ancestor(
        of: find.text('name'),
        matching: find.byType(Tooltip),
      );
      expect(tooltipFinder, findsNothing);
    });

    testWidgets('repaired value is shown in error color', (tester) async {
      await tester.pumpWidget(
        wrap(
          JsonTreeView(
            rootValue: const {'active': true},
            searchController: searchController,
            repairHighlights: JsonRepairHighlightSet.from([
              const JsonRepairHighlight(
                path: r'$.active',
                target: JsonRepairTarget.value,
                kind: JsonRepairKind.pythonTrue,
              ),
            ]),
          ),
        ),
      );

      final valueText = tester.widget<Text>(find.text('true'));
      expect(valueText.style?.color, jsonRepairHighlightColor);
    });

    testWidgets('unrelated values are not highlighted', (tester) async {
      await tester.pumpWidget(
        wrap(
          JsonTreeView(
            rootValue: const {
              'active': true,
              'name': 'Archit',
            },
            searchController: searchController,
            repairHighlights: JsonRepairHighlightSet.from([
              const JsonRepairHighlight(
                path: r'$.active',
                target: JsonRepairTarget.value,
                kind: JsonRepairKind.pythonTrue,
              ),
            ]),
          ),
        ),
      );

      final nameValue = tester.widget<Text>(find.text('"Archit"'));
      expect(nameValue.style?.color, isNot(jsonRepairHighlightColor));
    });

    testWidgets('root brackets are not highlighted for key-only repairs',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          JsonTreeView(
            rootValue: const {'name': 'Archit'},
            searchController: searchController,
            repairHighlights: JsonRepairHighlightSet.from([
              const JsonRepairHighlight(
                path: r'$.name',
                target: JsonRepairTarget.key,
                kind: JsonRepairKind.unquotedKey,
              ),
            ]),
          ),
        ),
      );

      final openingBracket = tester.widget<Text>(find.text('{'));
      final closingBracket = tester.widget<Text>(find.text('}'));
      expect(openingBracket.style?.color, isNot(jsonRepairHighlightColor));
      expect(closingBracket.style?.color, isNot(jsonRepairHighlightColor));
    });

    testWidgets('root brackets are highlighted for structure repairs',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          JsonTreeView(
            rootValue: const {'name': 'Archit'},
            searchController: searchController,
            repairHighlights: JsonRepairHighlightSet.from([
              const JsonRepairHighlight(
                path: r'$',
                target: JsonRepairTarget.structure,
                kind: JsonRepairKind.missingClosing,
              ),
            ]),
          ),
        ),
      );

      final openingBracket = tester.widget<Text>(find.text('{'));
      final closingBracket = tester.widget<Text>(find.text('}'));
      expect(openingBracket.style?.color, jsonRepairHighlightColor);
      expect(closingBracket.style?.color, jsonRepairHighlightColor);
    });
  });
}
