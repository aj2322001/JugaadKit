import 'package:flutter/material.dart';

import 'package:jugaadkit/features/json_jugaad/models/json_tree_node.dart';
import 'package:jugaadkit/features/json_jugaad/theme/json_syntax_colors.dart';

import 'json_tree_controls.dart';

typedef JsonTreeHoverCallback = void Function(JsonTreeNode node);

class JsonBracketRow extends StatelessWidget {
  const JsonBracketRow({
    super.key,
    required this.node,
    required this.onHover,
  });

  final JsonTreeNode node;
  final JsonTreeHoverCallback onHover;

  @override
  Widget build(BuildContext context) {
    final colors = JsonSyntaxColors.of(context);
    final indent = node.depth * 16.0;

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => onHover(node),
        child: Padding(
          padding: EdgeInsets.only(left: indent),
          child: Row(
            children: [
              SizedBox(width: JsonTreeLayout.expandLeadingWidth),
              Text(
                node.closingBracket,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: colors.structure.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              const SizedBox(width: JsonTreeLayout.trailingActionsWidth),
            ],
          ),
        ),
      ),
    );
  }
}
