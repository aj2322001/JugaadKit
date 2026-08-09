import 'package:jugaadkit/features/json_jugaad/models/json_tree_node.dart';

import 'json_path.dart';

abstract final class JsonTreeBuilder {
  static JsonTreeNode build(Object? value) {
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
      final children = <JsonTreeNode>[];
      for (final entry in value.entries) {
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

      return JsonTreeNode(
        key: key,
        path: path,
        type: JsonValueType.object,
        value: value,
        children: children,
        depth: depth,
      );
    }

    if (value is List) {
      final children = <JsonTreeNode>[];
      for (var index = 0; index < value.length; index++) {
        children.add(
          _buildNode(
            value: value[index],
            path: JsonPath.indexPath(path, index),
            key: index.toString(),
            depth: depth + 1,
          ),
        );
      }

      return JsonTreeNode(
        key: key,
        path: path,
        type: JsonValueType.array,
        value: value,
        children: children,
        depth: depth,
      );
    }

    return JsonTreeNode(
      key: key,
      path: path,
      type: _primitiveType(value),
      value: value,
      children: const [],
      depth: depth,
    );
  }

  static JsonValueType _primitiveType(Object? value) {
    return switch (value) {
      String() => JsonValueType.string,
      num() => JsonValueType.number,
      bool() => JsonValueType.boolean,
      _ => JsonValueType.nullValue,
    };
  }
}
