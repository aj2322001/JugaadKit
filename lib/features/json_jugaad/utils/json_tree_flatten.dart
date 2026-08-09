import 'package:jugaadkit/features/json_jugaad/models/json_tree_node.dart';

import 'json_path.dart';

class VisibleTreeRow {
  const VisibleTreeRow({
    required this.node,
    required this.isExpanded,
    this.isCloseBracket = false,
  });

  final JsonTreeNode node;
  final bool isExpanded;
  final bool isCloseBracket;
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
        if (node.path == JsonPath.root && node.key == null) {
          for (final child in node.children) {
            visit(child);
          }
          return;
        }

        final expanded = _isExpanded(
          node.path,
          collapsedPaths,
          forceExpandedPaths,
        );
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
