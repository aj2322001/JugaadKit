import 'package:jugaadkit/features/json_jugaad/models/json_tree_node.dart';

abstract final class JsonTreeBuilder {
  static JsonTreeNode build(Object? value) => JsonTreeNode.buildRoot(value);
}
