import 'package:jugaadkit/features/json_jugaad/models/json_tree_node.dart';

import 'json_path.dart';

class VisibleTreeRow {
  const VisibleTreeRow({
    required this.node,
    required this.isExpanded,
    this.isCloseBracket = false,
    this.isOpenBracket = false,
  });

  final JsonTreeNode node;
  final bool isExpanded;
  final bool isCloseBracket;
  final bool isOpenBracket;
}

abstract final class JsonTreeFlatten {
  static List<VisibleTreeRow> visibleRows({
    required JsonTreeNode root,
    required Set<String> collapsedPaths,
    required Set<String> forceExpandedPaths,
  }) {
    final rows = <VisibleTreeRow>[];

    void visit(JsonTreeNode node) {
      if (node.isExpandable) {
        final expanded = _isExpanded(
          node.path,
          collapsedPaths,
          forceExpandedPaths,
        );

        // Root keeps a dedicated opening-bracket row when expanded so the
        // top-level `{` / `[` stays visually distinct, but it can still collapse.
        if (node.path == JsonPath.root && node.key == null) {
          if (expanded) {
            rows.add(
              VisibleTreeRow(
                node: node,
                isExpanded: true,
                isOpenBracket: true,
              ),
            );
            for (final child in node.children) {
              visit(child);
            }
            rows.add(
              VisibleTreeRow(
                node: node,
                isExpanded: true,
                isCloseBracket: true,
              ),
            );
          } else {
            rows.add(VisibleTreeRow(node: node, isExpanded: false));
          }
          return;
        }

        rows.add(VisibleTreeRow(node: node, isExpanded: expanded));
        if (expanded) {
          for (final child in node.children) {
            visit(child);
          }
          rows.add(
            VisibleTreeRow(
              node: node,
              isExpanded: expanded,
              isCloseBracket: true,
            ),
          );
        }
        return;
      }

      rows.add(VisibleTreeRow(node: node, isExpanded: false));
    }

    visit(root);
    return rows;
  }

  static bool _isExpanded(
    String path,
    Set<String> collapsedPaths,
    Set<String> forceExpandedPaths,
  ) {
    if (forceExpandedPaths.contains(path)) {
      return true;
    }
    return !collapsedPaths.contains(path);
  }
}
