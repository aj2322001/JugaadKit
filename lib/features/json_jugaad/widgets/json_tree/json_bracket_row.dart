import 'package:flutter/material.dart';

import 'package:jugaadkit/features/json_jugaad/models/json_repair_highlight.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_tree_node.dart';
import 'package:jugaadkit/features/json_jugaad/theme/json_syntax_colors.dart';

import 'json_repair_tooltip.dart';
import 'json_tree_controls.dart';

typedef JsonTreeHoverCallback = void Function(JsonTreeNode node);

class JsonBracketRow extends StatelessWidget {
  const JsonBracketRow({
    super.key,
    required this.node,
    required this.onHover,
    this.repairHighlights = JsonRepairHighlightSet.empty,
  });

  final JsonTreeNode node;
  final JsonTreeHoverCallback onHover;
  final JsonRepairHighlightSet repairHighlights;

  @override
  Widget build(BuildContext context) {
    final colors = JsonSyntaxColors.of(context);
    final highlightBracket =
        repairHighlights.shouldHighlightClosingBracket(node.path);

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => onHover(node),
        child: JsonTreeRowShell(
          depth: node.depth,
          leading: const JsonTreeExpandLeadingSlot(),
          trailing: const SizedBox(width: JsonTreeLayout.trailingActionsWidth),
          child: JsonRepairTooltip(
            highlight: highlightBracket
                ? repairHighlights.highlightForStructure(node.path)
                : null,
            child: Text(
              node.closingBracket,
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
