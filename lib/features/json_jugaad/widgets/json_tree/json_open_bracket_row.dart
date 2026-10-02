import 'package:flutter/material.dart';

import 'package:jugaadkit/features/json_jugaad/models/json_repair_highlight.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_tree_node.dart';
import 'package:jugaadkit/features/json_jugaad/theme/json_syntax_colors.dart';

import 'json_repair_tooltip.dart';
import 'json_tree_controls.dart';

typedef JsonTreeHoverCallback = void Function(JsonTreeNode node);
typedef JsonTreeExpansionCallback = void Function(String path);

class JsonOpenBracketRow extends StatelessWidget {
  const JsonOpenBracketRow({
    super.key,
    required this.node,
    required this.onHover,
    required this.onToggle,
    this.repairHighlights = JsonRepairHighlightSet.empty,
  });

  final JsonTreeNode node;
  final JsonTreeHoverCallback onHover;
  final JsonTreeExpansionCallback onToggle;
  final JsonRepairHighlightSet repairHighlights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = JsonSyntaxColors.of(context);
    final highlightBracket =
        repairHighlights.shouldHighlightOpeningBracket(node.path);

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => onHover(node),
        child: JsonTreeRowShell(
          depth: node.depth,
          leading: JsonTreeExpandLeadingSlot(
            child: InkWell(
              onTap: () => onToggle(node.path),
              borderRadius: BorderRadius.circular(4),
              child: Center(
                child: JsonTreeExpandIcon(
                  isExpanded: true,
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
          trailing: const SizedBox(width: JsonTreeLayout.trailingActionsWidth),
          child: JsonRepairTooltip(
            highlight: highlightBracket
                ? repairHighlights.highlightForStructure(node.path)
                : null,
            child: Text(
              node.openingBracket,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: highlightBracket
                    ? jsonRepairHighlightColor
                    : colors.structure.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
