import 'package:jugaadkit/features/json_jugaad/utils/json_path.dart';

enum JsonValueType {
  object,
  array,
  string,
  number,
  boolean,
  nullValue,
}

class JsonTreeNode {
  JsonTreeNode({
    required this.path,
    required this.type,
    required this.value,
    required this.depth,
    this.key,
    List<JsonTreeNode>? children,
  }) : _children = children;

  final String? key;
  final String path;
  final JsonValueType type;
  final Object? value;
  final int depth;

  List<JsonTreeNode>? _children;

  bool get isExpandable =>
      type == JsonValueType.object || type == JsonValueType.array;

  List<JsonTreeNode> get children {
    if (!isExpandable) {
      return const [];
    }
    final built = _children;
    if (built != null) {
      return built;
    }
    final loaded = _buildChildren();
    _children = loaded;
    return loaded;
  }

  int get childCount {
    if (!isExpandable) {
      return 0;
    }
    final built = _children;
    if (built != null) {
      return built.length;
    }
    if (value is Map) {
      return (value as Map).length;
    }
    if (value is List) {
      return (value as List).length;
    }
    return 0;
  }

  static JsonTreeNode buildRoot(Object? value) {
    return _buildNode(
      value: value,
      path: JsonPath.root,
      key: null,
      depth: 0,
    );
  }

  static JsonTreeNode _buildNode({
    required Object? value,
    required String path,
    required String? key,
    required int depth,
  }) {
    if (value is Map) {
      return JsonTreeNode(
        key: key,
        path: path,
        type: JsonValueType.object,
        value: value,
        depth: depth,
      );
    }

    if (value is List) {
      return JsonTreeNode(
        key: key,
        path: path,
        type: JsonValueType.array,
        value: value,
        depth: depth,
      );
    }

    return JsonTreeNode(
      key: key,
      path: path,
      type: _primitiveType(value),
      value: value,
      depth: depth,
      children: const [],
    );
  }

  List<JsonTreeNode> _buildChildren() {
    final raw = value;
    if (raw is Map) {
      final children = <JsonTreeNode>[];
      for (final entry in raw.entries) {
        final childKey = entry.key.toString();
        children.add(
          _buildNode(
            value: entry.value,
            path: JsonPath.childPath(path, childKey),
            key: childKey,
            depth: depth + 1,
          ),
        );
      }
      return children;
    }

    if (raw is List) {
      final children = <JsonTreeNode>[];
      for (var index = 0; index < raw.length; index++) {
        children.add(
          _buildNode(
            value: raw[index],
            path: JsonPath.indexPath(path, index),
            key: index.toString(),
            depth: depth + 1,
          ),
        );
      }
      return children;
    }

    return const [];
  }

  static JsonValueType _primitiveType(Object? value) {
    return switch (value) {
      String() => JsonValueType.string,
      num() => JsonValueType.number,
      bool() => JsonValueType.boolean,
      _ => JsonValueType.nullValue,
    };
  }

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
