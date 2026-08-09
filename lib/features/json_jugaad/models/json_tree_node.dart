enum JsonValueType {
  object,
  array,
  string,
  number,
  boolean,
  nullValue,
}

class JsonTreeNode {
  const JsonTreeNode({
    required this.path,
    required this.type,
    required this.value,
    required this.children,
    required this.depth,
    this.key,
  });

  final String? key;
  final String path;
  final JsonValueType type;
  final Object? value;
  final List<JsonTreeNode> children;
  final int depth;

  bool get isExpandable =>
      type == JsonValueType.object || type == JsonValueType.array;

  int get childCount => children.length;

  String get headerLabel {
    if (key != null) {
      return key!;
    }
    return 'root';
  }

  String get countSuffix {
    return switch (type) {
      JsonValueType.object => ' {$childCount}',
      JsonValueType.array => ' [$childCount]',
      _ => '',
    };
  }

  String get openingBracket {
    return switch (type) {
      JsonValueType.object => '{',
      JsonValueType.array => '[',
      _ => '',
    };
  }

  String get closingBracket {
    return switch (type) {
      JsonValueType.object => '}',
      JsonValueType.array => ']',
      _ => '',
    };
  }

  String get searchableText => displayText;

  String get displayText {
    return switch (type) {
      JsonValueType.string => value as String,
      JsonValueType.number => formatNumber(value),
      JsonValueType.boolean => value.toString(),
      JsonValueType.nullValue => 'null',
      JsonValueType.object || JsonValueType.array => '',
    };
  }

  static String formatNumber(Object? value) {
    if (value is int) {
      return value.toString();
    }
    if (value is double) {
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }
      return value.toString();
    }
    return value.toString();
  }
}
