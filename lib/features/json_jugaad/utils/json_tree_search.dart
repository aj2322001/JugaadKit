import 'package:jugaadkit/features/json_jugaad/models/json_tree_node.dart';

import 'json_path.dart';

class JsonTreeSearchMatch {
  const JsonTreeSearchMatch({
    required this.path,
    required this.keyMatches,
    required this.valueMatches,
  });

  final String path;
  final bool keyMatches;
  final bool valueMatches;
}

class JsonTreeSearchResult {
  const JsonTreeSearchResult({
    required this.matches,
    required this.pathsToExpand,
    required this.matchByPath,
  });

  final List<JsonTreeSearchMatch> matches;
  final Set<String> pathsToExpand;
  final Map<String, JsonTreeSearchMatch> matchByPath;

  static const empty = JsonTreeSearchResult(
    matches: [],
    pathsToExpand: {},
    matchByPath: {},
  );

  int get matchCount => matches.length;

  JsonTreeSearchMatch? matchFor(String path) => matchByPath[path];
}

abstract final class JsonTreeSearch {
  static JsonTreeSearchResult search(JsonTreeNode root, String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return JsonTreeSearchResult.empty;
    }

    final normalized = trimmed.toLowerCase();
    final matches = <JsonTreeSearchMatch>[];
    final pathsToExpand = <String>{};

    void walk(JsonTreeNode node) {
      final keyMatches = node.key != null &&
          node.key!.toLowerCase().contains(normalized);
      final valueMatches =
          node.searchableText.toLowerCase().contains(normalized);

      if (keyMatches || valueMatches) {
        matches.add(
          JsonTreeSearchMatch(
            path: node.path,
            keyMatches: keyMatches,
            valueMatches: valueMatches,
          ),
        );
        _addAncestors(node.path, pathsToExpand);
      }

      for (final child in node.children) {
        walk(child);
      }
    }

    walk(root);

    final matchByPath = {
      for (final match in matches) match.path: match,
    };

    return JsonTreeSearchResult(
      matches: matches,
      pathsToExpand: pathsToExpand,
      matchByPath: matchByPath,
    );
  }

  static void _addAncestors(String path, Set<String> pathsToExpand) {
    var current = path;
    while (true) {
      pathsToExpand.add(current);
      if (current == JsonPath.root || current.length <= 1) {
        break;
      }

      if (current.endsWith(']')) {
        final openBracket = current.lastIndexOf('[');
        if (openBracket <= 0) {
          break;
        }
        current = current.substring(0, openBracket);
        continue;
      }

      final dotIndex = current.lastIndexOf('.');
      if (dotIndex <= 0) {
        current = JsonPath.root;
        continue;
      }
      current = current.substring(0, dotIndex);
    }
  }
}
