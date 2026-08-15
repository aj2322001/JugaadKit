import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/core/theme/feedback_colors.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_repair_highlight.dart';
import 'package:jugaadkit/features/json_jugaad/widgets/json_tree/json_repair_tooltip.dart';

void main() {
  group('JsonRepairHighlight tooltip messages', () {
    test('unquoted key', () {
      const highlight = JsonRepairHighlight(
        path: r'$.name',
        target: JsonRepairTarget.key,
        kind: JsonRepairKind.unquotedKey,
        originalText: 'name',
        repairedText: '"name"',
      );

      expect(
        highlight.tooltipMessage,
        '⚠️ Unquoted key\nname → "name"',
      );
    });

    test('single-quoted string', () {
      const highlight = JsonRepairHighlight(
        path: r'$.name',
        target: JsonRepairTarget.value,
        kind: JsonRepairKind.singleQuotedString,
        originalText: "'Archit'",
        repairedText: '"Archit"',
      );

      expect(
        highlight.tooltipMessage,
        "⚠️ Single quotes\n'Archit' → \"Archit\"",
      );
    });

    test('python primitive', () {
      const highlight = JsonRepairHighlight(
        path: r'$.active',
        target: JsonRepairTarget.value,
        kind: JsonRepairKind.pythonTrue,
        originalText: 'True',
        repairedText: 'true',
      );

      expect(
        highlight.tooltipMessage,
        '⚠️ Invalid JSON value\nTrue → true',
      );
    });

    test('missing closing brace', () {
      const highlight = JsonRepairHighlight(
        path: r'$',
        target: JsonRepairTarget.structure,
        kind: JsonRepairKind.missingClosing,
        repairedText: '}',
      );

      expect(
        highlight.tooltipMessage,
        '⚠️ Missing closing brace\nAdded: }',
      );
    });

    test('missing closing bracket', () {
      const highlight = JsonRepairHighlight(
        path: r'$.roles',
        target: JsonRepairTarget.structure,
        kind: JsonRepairKind.missingClosing,
        repairedText: ']',
      );

      expect(
        highlight.tooltipMessage,
        '⚠️ Missing closing bracket\nAdded: ]',
      );
    });

    test('returns null when detail cannot be mapped', () {
      const highlight = JsonRepairHighlight(
        path: r'$.name',
        target: JsonRepairTarget.key,
        kind: JsonRepairKind.unquotedKey,
      );

      expect(highlight.tooltipMessage, isNull);
    });
  });

  group('JsonRepairHighlightSet lookup', () {
    test('returns highlight for key path', () {
      const highlight = JsonRepairHighlight(
        path: r'$.name',
        target: JsonRepairTarget.key,
        kind: JsonRepairKind.unquotedKey,
        originalText: 'name',
        repairedText: '"name"',
      );
      final set = JsonRepairHighlightSet.from([highlight]);

      expect(set.highlightForKey(r'$.name'), highlight);
      expect(set.highlightForValue(r'$.name'), isNull);
    });
  });

  group('buildRepairTooltipSpan', () {
    test('uses warning, error, and success theme colors', () {
      const highlight = JsonRepairHighlight(
        path: r'$.name',
        target: JsonRepairTarget.key,
        kind: JsonRepairKind.unquotedKey,
        originalText: 'name',
        repairedText: '"name"',
      );
      final span = buildRepairTooltipSpan(highlight, AppFeedbackColors.dark);
      final children = (span.children ?? const <InlineSpan>[]);

      expect((children[0] as TextSpan).style?.color,
          AppFeedbackColors.dark.warningForeground);
      expect((children[2] as TextSpan).text, 'name');
      expect((children[2] as TextSpan).style?.color,
          AppFeedbackColors.dark.errorForeground);
      expect((children[4] as TextSpan).text, '"name"');
      expect((children[4] as TextSpan).style?.color,
          AppFeedbackColors.dark.successForeground);
    });
  });
}
