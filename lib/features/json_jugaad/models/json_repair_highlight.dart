import 'package:flutter/material.dart';

/// Pure red used for repaired JSON portions in the tree viewer.
const Color jsonRepairHighlightColor = Colors.red;

/// Hint shown in transformation status when JSON was repaired.
const jsonRepairStatusHint =
    'Errors shown in red — hover to see what was fixed.';

enum JsonRepairKind {
  unquotedKey,
  singleQuotedString,
  pythonTrue,
  pythonFalse,
  pythonNone,
  trailingComma,
  comment,
  missingClosing,
}

enum JsonRepairTarget {
  key,
  value,
  structure,
}

class JsonRepairHighlight {
  const JsonRepairHighlight({
    required this.path,
    required this.target,
    required this.kind,
    this.originalText,
    this.repairedText,
  });

  final String path;
  final JsonRepairTarget target;
  final JsonRepairKind kind;

  /// Original problematic text from the input, when known.
  final String? originalText;

  /// Repaired text that replaced or was added for this highlight.
  final String? repairedText;

  /// Short title shown on the first line of the repair tooltip.
  String get tooltipTitle => switch (kind) {
        JsonRepairKind.unquotedKey => 'Unquoted key',
        JsonRepairKind.singleQuotedString => 'Single quotes',
        JsonRepairKind.pythonTrue ||
        JsonRepairKind.pythonFalse ||
        JsonRepairKind.pythonNone =>
          'Invalid JSON value',
        JsonRepairKind.trailingComma => 'Trailing comma',
        JsonRepairKind.comment => 'JSON comment',
        JsonRepairKind.missingClosing => repairedText == ']'
            ? 'Missing closing bracket'
            : 'Missing closing brace',
      };

  /// Whether this highlight has enough metadata to show a repair tooltip.
  bool get hasTooltip {
    if (originalText != null && repairedText != null) {
      return true;
    }
    if (kind == JsonRepairKind.missingClosing && repairedText != null) {
      return true;
    }
    return tooltipDetailPlain != null;
  }

  /// Plain-text detail for repairs that are not colorized in the tooltip.
  String? get tooltipDetailPlain => switch (kind) {
        JsonRepairKind.trailingComma => 'Removed trailing comma',
        JsonRepairKind.comment => null,
        _ => null,
      };

  /// Fallback plain-text tooltip for accessibility and tests.
  String? get tooltipMessage {
    if (!hasTooltip) {
      return null;
    }
    final buffer = StringBuffer('⚠️ $tooltipTitle');
    if (originalText != null && repairedText != null) {
      buffer.write('\n$originalText → $repairedText');
    } else if (kind == JsonRepairKind.missingClosing && repairedText != null) {
      buffer.write('\nAdded: $repairedText');
    } else if (tooltipDetailPlain != null) {
      buffer.write('\n$tooltipDetailPlain');
    }
    return buffer.toString();
  }
}

class JsonRepairHighlightSet {
  const JsonRepairHighlightSet({
    required this.keyPaths,
    required this.valuePaths,
    required this.structurePaths,
    required this.keyHighlights,
    required this.valueHighlights,
    required this.structureHighlights,
  });

  factory JsonRepairHighlightSet.from(List<JsonRepairHighlight> highlights) {
    final keyPaths = <String>{};
    final valuePaths = <String>{};
    final structurePaths = <String>{};
    final keyHighlights = <String, JsonRepairHighlight>{};
    final valueHighlights = <String, JsonRepairHighlight>{};
    final structureHighlights = <String, JsonRepairHighlight>{};

    for (final highlight in highlights) {
      switch (highlight.target) {
        case JsonRepairTarget.key:
          keyPaths.add(highlight.path);
          keyHighlights[highlight.path] = highlight;
        case JsonRepairTarget.value:
          valuePaths.add(highlight.path);
          valueHighlights[highlight.path] = highlight;
        case JsonRepairTarget.structure:
          structurePaths.add(highlight.path);
          structureHighlights[highlight.path] = highlight;
      }
    }

    return JsonRepairHighlightSet(
      keyPaths: keyPaths,
      valuePaths: valuePaths,
      structurePaths: structurePaths,
      keyHighlights: keyHighlights,
      valueHighlights: valueHighlights,
      structureHighlights: structureHighlights,
    );
  }

  static const empty = JsonRepairHighlightSet(
    keyPaths: {},
    valuePaths: {},
    structurePaths: {},
    keyHighlights: {},
    valueHighlights: {},
    structureHighlights: {},
  );

  final Set<String> keyPaths;
  final Set<String> valuePaths;
  final Set<String> structurePaths;
  final Map<String, JsonRepairHighlight> keyHighlights;
  final Map<String, JsonRepairHighlight> valueHighlights;
  final Map<String, JsonRepairHighlight> structureHighlights;

  bool shouldHighlightKey(String path) => keyPaths.contains(path);

  bool shouldHighlightValue(String path) => valuePaths.contains(path);

  bool shouldHighlightStructure(String path) => structurePaths.contains(path);

  JsonRepairHighlight? highlightForKey(String path) => keyHighlights[path];

  JsonRepairHighlight? highlightForValue(String path) => valueHighlights[path];

  JsonRepairHighlight? highlightForStructure(String path) =>
      structureHighlights[path];

  /// Opening bracket on a container row when that structure was repaired.
  bool shouldHighlightOpeningBracket(String path) =>
      shouldHighlightStructure(path);

  /// Closing bracket row when that structure was repaired.
  bool shouldHighlightClosingBracket(String path) =>
      shouldHighlightStructure(path);

  bool get isEmpty =>
      keyPaths.isEmpty && valuePaths.isEmpty && structurePaths.isEmpty;
}
