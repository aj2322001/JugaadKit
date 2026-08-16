import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jugaadkit/core/utils/app_feedback.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_repair_highlight.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_tree_node.dart';
import 'package:jugaadkit/features/json_jugaad/theme/json_syntax_colors.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_copy_util.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_search.dart';

import 'highlighted_text.dart';
import 'json_repair_tooltip.dart';
import 'json_tree_controls.dart';
import 'json_tree_copy_target.dart';

typedef JsonTreeExpansionCallback = void Function(String path);
typedef JsonTreeHoverCallback = void Function(JsonTreeNode node);

class JsonExpandableRow extends StatelessWidget {
  const JsonExpandableRow({
    super.key,
    required this.node,
    required this.isExpanded,
    required this.searchQuery,
    required this.searchResult,
    required this.hoveredPath,
    this.isActiveSearchMatch = false,
    required this.onToggle,
    required this.onHover,
    this.repairHighlights = JsonRepairHighlightSet.empty,
  });

  final JsonTreeNode node;
  final bool isExpanded;
  final String searchQuery;
  final JsonTreeSearchResult? searchResult;
  final ValueNotifier<String?> hoveredPath;
  final bool isActiveSearchMatch;
  final JsonTreeExpansionCallback onToggle;
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
    final highlightBracket =
        repairHighlights.shouldHighlightOpeningBracket(node.path);
    final suffix = isExpanded ? ' ${node.openingBracket}' : node.countSuffix;
    final keyStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: repairHighlights.shouldHighlightKey(node.path)
          ? jsonRepairHighlightColor
          : colors.key,
    );
    final suffixStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      color: highlightBracket
          ? jsonRepairHighlightColor
          : colors.structure.withValues(alpha: 0.7),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                leading: JsonTreeExpandLeadingSlot(
                  child: InkWell(
                    onTap: () => onToggle(node.path),
                    borderRadius: BorderRadius.circular(4),
                    child: Center(
                      child: JsonTreeExpandIcon(
                        isExpanded: isExpanded,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
                trailing: JsonTreeTrailingActions(
                  visible: showActions,
                  onCopyPath: () => _copyPath(context),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (node.key != null)
                        JsonRepairTooltip(
                          highlight: repairHighlights.highlightForKey(
                            node.path,
                          ),
                          child: JsonTreeCopyTarget(
                            text: node.key!,
                            copyType: CopyFeedbackType.key,
                            child: HighlightedText(
                              text: node.headerLabel,
                              query: match?.keyMatches == true
                                  ? searchQuery
                                  : null,
                              highlightColor: colors.searchHighlight,
                              style: keyStyle,
                            ),
                          ),
                        )
                      else
                        HighlightedText(
                          text: node.headerLabel,
                          query: match?.keyMatches == true
                              ? searchQuery
                              : null,
                          highlightColor: colors.searchHighlight,
                          style: keyStyle,
                        ),
                      JsonRepairTooltip(
                        highlight: highlightBracket
                            ? repairHighlights.highlightForStructure(
                                node.path,
                              )
                            : null,
                        child: JsonTreeCopyTarget(
                          text: JsonCopyUtil.valueForClipboard(node),
                          copyType: CopyFeedbackType.value,
                          child: Text(suffix, style: suffixStyle),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
