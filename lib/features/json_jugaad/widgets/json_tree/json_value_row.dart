import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jugaadkit/core/utils/app_feedback.dart';
import 'package:jugaadkit/features/json_jugaad/engine/timestamp_detector.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_repair_highlight.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_tree_node.dart';
import 'package:jugaadkit/features/json_jugaad/theme/json_syntax_colors.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_copy_util.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_search.dart';

import 'highlighted_text.dart';
import 'json_repair_tooltip.dart';
import 'json_tree_controls.dart';
import 'json_tree_copy_target.dart';

typedef JsonTreeHoverCallback = void Function(JsonTreeNode node);

class JsonValueRow extends StatelessWidget {
  const JsonValueRow({
    super.key,
    required this.node,
    required this.searchQuery,
    required this.searchResult,
    required this.hoveredPath,
    this.isActiveSearchMatch = false,
    required this.onHover,
    this.repairHighlights = JsonRepairHighlightSet.empty,
  });

  static const double _trailingContentGap = 12;

  final JsonTreeNode node;
  final String searchQuery;
  final JsonTreeSearchResult? searchResult;
  final ValueNotifier<String?> hoveredPath;
  final bool isActiveSearchMatch;
  final JsonTreeHoverCallback onHover;
  final JsonRepairHighlightSet repairHighlights;

  Future<void> _copyPath(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: node.path));
    if (!context.mounted) {
      return;
    }
    showCopyFeedback(context, CopyFeedbackType.path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = JsonSyntaxColors.of(context);
    final match = searchResult?.matchFor(node.path);
    final keyStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 13,
      color: repairHighlights.shouldHighlightKey(node.path)
          ? jsonRepairHighlightColor
          : colors.key,
    );
    final valueStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 13,
      color: repairHighlights.shouldHighlightValue(node.path)
          ? jsonRepairHighlightColor
          : _valueColor(colors),
    );

    return ValueListenableBuilder<String?>(
      valueListenable: hoveredPath,
      builder: (context, activePath, _) {
        final showActions = activePath == node.path;

        return RepaintBoundary(
          child: MouseRegion(
            onEnter: (_) => onHover(node),
            child: SearchMatchHighlight(
              isActive: isActiveSearchMatch,
              child: JsonTreeRowShell(
                depth: node.depth,
                leading: const JsonTreeExpandLeadingSlot(),
                trailing: JsonTreeTrailingActions(
                  visible: showActions,
                  onCopyPath: () => _copyPath(context),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (node.key != null) ...[
                      JsonRepairTooltip(
                        highlight: repairHighlights.highlightForKey(
                          node.path,
                        ),
                        child: JsonTreeCopyTarget(
                          text: node.key!,
                          copyType: CopyFeedbackType.key,
                          child: HighlightedText(
                            text: node.key!,
                            query: match?.keyMatches == true
                                ? searchQuery
                                : null,
                            highlightColor: colors.searchHighlight,
                            style: keyStyle,
                          ),
                        ),
                      ),
                      Text(
                        ': ',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: colors.structure.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          right: _trailingContentGap,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            JsonRepairTooltip(
                              highlight: repairHighlights.highlightForValue(
                                node.path,
                              ),
                              child: JsonTreeCopyTarget(
                                text: JsonCopyUtil.valueForClipboard(node),
                                copyType: CopyFeedbackType.value,
                                child: HighlightedText(
                                  text: _formattedValue(),
                                  query: match?.valueMatches == true
                                      ? searchQuery
                                      : null,
                                  highlightColor: colors.searchHighlight,
                                  style: valueStyle,
                                ),
                              ),
                            ),
                            if (_timestampHint != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'timestamp ${_timestampHint!.label}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formattedValue() {
    return switch (node.type) {
      JsonValueType.string => '"${node.displayText}"',
      JsonValueType.nullValue => 'null',
      _ => node.displayText,
    };
  }

  TimestampHint? get _timestampHint {
    if (node.type != JsonValueType.number || node.value is! num) {
      return null;
    }
    return TimestampDetector.detect(node.value as num);
  }

  Color _valueColor(JsonSyntaxColors colors) {
    return switch (node.type) {
      JsonValueType.string => colors.string,
      JsonValueType.number => colors.number,
      JsonValueType.boolean => colors.boolean,
      JsonValueType.nullValue => colors.nullValue,
      _ => colors.structure,
    };
  }
}
