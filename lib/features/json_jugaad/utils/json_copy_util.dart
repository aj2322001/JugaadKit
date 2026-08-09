import 'dart:convert';

import 'package:jugaadkit/features/json_jugaad/models/json_tree_node.dart';

abstract final class JsonCopyUtil {
  static String? keyForClipboard(JsonTreeNode node) => node.key;

  static String valueForClipboard(JsonTreeNode node) {
    return switch (node.type) {
      JsonValueType.string => node.value as String,
      JsonValueType.number => JsonTreeNode.formatNumber(node.value),
      JsonValueType.boolean => node.value.toString(),
      JsonValueType.nullValue => 'null',
      JsonValueType.object || JsonValueType.array =>
        const JsonEncoder.withIndent('  ').convert(node.value),
    };
  }
}
