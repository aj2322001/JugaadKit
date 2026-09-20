import 'package:jugaadkit/features/json_jugaad/models/json_tree_node.dart';

import 'json_path.dart';

class JsonTreeSearchIndexEntry {
  const JsonTreeSearchIndexEntry({
    required this.path,
    required this.key,
    required this.keyLower,
    required this.valueSearchable,
    required this.valueLower,
  });

  final String path;
  final String? key;
  final String? keyLower;
  final String valueSearchable;
  final String valueLower;
}

class JsonTreeSearchIndex {
  JsonTreeSearchIndex._(this.entries);

  final List<JsonTreeSearchIndexEntry> entries;

  static JsonTreeSearchIndex fromValue(Object? value) {
    final entries = <JsonTreeSearchIndexEntry>[];
    _walk(value, JsonPath.root, null, entries);
    return JsonTreeSearchIndex._(entries);
  }

  static void _walk(
    Object? value,
    String path,
    String? key,
    List<JsonTreeSearchIndexEntry> entries,
  ) {
    final valueSearchable = _searchableText(value);
    entries.add(
      JsonTreeSearchIndexEntry(
        path: path,
        key: key,
        keyLower: key?.toLowerCase(),
        valueSearchable: valueSearchable,
        valueLower: valueSearchable.toLowerCase(),
      ),
    );

    if (value is Map) {
      for (final entry in value.entries) {
        final childKey = entry.key.toString();
        _walk(
          entry.value,
          JsonPath.childPath(path, childKey),
          childKey,
          entries,
        );
      }
      return;
    }

    if (value is List) {
      for (var index = 0; index < value.length; index++) {
        _walk(
          value[index],
          JsonPath.indexPath(path, index),
          index.toString(),
          entries,
        );
      }
    }
  }

  static String _searchableText(Object? value) {
    return switch (value) {
      String() => value,
      num() => JsonTreeNode.formatNumber(value),
      bool() => value.toString(),
      null => 'null',
      Map() || List() => '',
      _ => '',
    };
  }
}
