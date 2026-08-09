import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jugaadkit/core/utils/app_feedback.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_tree_node.dart';
import 'package:jugaadkit/features/json_jugaad/theme/json_syntax_colors.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_copy_util.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_search.dart';

import 'highlighted_text.dart';
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
    required this.onHover,
  });

  final JsonTreeNode node;
  final String searchQuery;
  final JsonTreeSearchResult? searchResult;
  final ValueNotifier<String?> hoveredPath;
  final JsonTreeHoverCallback onHover;

  Future<void> _copyPath(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: node.path));
    if (!context.mounted) {
      return;
    }
    showCopyFeedback(context, CopyFeedbackType.path);
  }

  @override
  Widget build(BuildContext context) {
    final colors = JsonSyntaxColors.of(context);
    final match = searchResult?.matchFor(node.path);
    final keyStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 13,
      color: colors.key,
    );
    final valueStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 13,
      color: _valueColor(colors),
    );

    return ValueListenableBuilder<String?>(
      valueListenable: hoveredPath,
      builder: (context, activePath, _) {
        final showActions = activePath == node.path;

        return RepaintBoundary(
          child: MouseRegion(
            onEnter: (_) => onHover(node),
            child: Padding(
              padding: EdgeInsets.only(left: 16.0 + (node.depth * 16)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (node.key != null) ...[
                          Flexible(
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
                      ],
                    ),
                  ),
                  JsonTreeTrailingActions(
                    visible: showActions,
                    onCopyPath: () => _copyPath(context),
                  ),
                ],
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
