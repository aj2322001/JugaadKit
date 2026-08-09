import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jugaadkit/core/utils/app_feedback.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_tree_node.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_builder.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_flatten.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_search.dart';

import 'json_tree/json_bracket_row.dart';
import 'json_tree/json_expandable_row.dart';
import 'json_tree/json_tree_controls.dart';
import 'json_tree/json_value_row.dart';

typedef JsonTreeSearchListener = void Function(
  String query,
  JsonTreeSearchResult? result,
);

class JsonTreeView extends StatefulWidget {
  const JsonTreeView({
    super.key,
    required this.rootValue,
    required this.searchController,
    this.onSearchChanged,
  });

  final Object? rootValue;
  final TextEditingController searchController;
  final JsonTreeSearchListener? onSearchChanged;

  @override
  State<JsonTreeView> createState() => _JsonTreeViewState();
}

class _JsonTreeViewState extends State<JsonTreeView> {
  static const Duration _hoverClearDelay = Duration(milliseconds: 150);
  static const Duration _searchDebounce = Duration(milliseconds: 150);

  late JsonTreeNode _rootNode;
  late List<VisibleTreeRow> _visibleRows;
  final Set<String> _collapsedPaths = {};
  Set<String>? _savedCollapsedPaths;
  final ValueNotifier<String?> _hoveredPath = ValueNotifier<String?>(null);

  String _searchQuery = '';
  JsonTreeSearchResult? _searchResult;
  Timer? _hoverClearTimer;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _rootNode = JsonTreeBuilder.build(widget.rootValue);
    widget.searchController.addListener(_onSearchTextChanged);
    _searchQuery = widget.searchController.text;
    _rebuildVisibleRows();
    _runSearch(_searchQuery);
  }

  @override
  void didUpdateWidget(JsonTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchController != widget.searchController) {
      oldWidget.searchController.removeListener(_onSearchTextChanged);
      widget.searchController.addListener(_onSearchTextChanged);
    }
    if (oldWidget.rootValue != widget.rootValue) {
      _rootNode = JsonTreeBuilder.build(widget.rootValue);
      _collapsedPaths.clear();
      _savedCollapsedPaths = null;
      _searchQuery = widget.searchController.text;
      _hoveredPath.value = null;
      _hoverClearTimer?.cancel();
      _rebuildVisibleRows();
      _runSearch(_searchQuery);
    }
  }

  @override
  void dispose() {
    _hoverClearTimer?.cancel();
    _searchDebounceTimer?.cancel();
    widget.searchController.removeListener(_onSearchTextChanged);
    _hoveredPath.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounce, () {
      if (!mounted) {
        return;
      }
      _applySearch(widget.searchController.text);
    });
  }

  void _applySearch(String query) {
    if (_searchQuery.isEmpty && query.isNotEmpty) {
      _savedCollapsedPaths = Set<String>.from(_collapsedPaths);
    }

    if (query.isEmpty && _savedCollapsedPaths != null) {
      _collapsedPaths
        ..clear()
        ..addAll(_savedCollapsedPaths!);
      _savedCollapsedPaths = null;
    }

    setState(() {
      _searchQuery = query;
      _runSearch(query);
      _rebuildVisibleRows();
    });
    widget.onSearchChanged?.call(_searchQuery, _searchResult);
  }

  void _runSearch(String query) {
    _searchResult = query.trim().isEmpty
        ? null
        : JsonTreeSearch.search(_rootNode, query);
  }

  void _rebuildVisibleRows() {
    _visibleRows = JsonTreeFlatten.visibleRows(
      root: _rootNode,
      collapsedPaths: _collapsedPaths,
      forceExpandedPaths: _searchResult?.pathsToExpand ?? const {},
    );
  }

  void _toggleExpansion(String path) {
    setState(() {
      if (_collapsedPaths.contains(path)) {
        _collapsedPaths.remove(path);
      } else {
        _collapsedPaths.add(path);
      }
      _rebuildVisibleRows();
    });
  }

  void _onNodeHover(JsonTreeNode node) {
    _hoverClearTimer?.cancel();
    if (_hoveredPath.value != node.path) {
      _hoveredPath.value = node.path;
    }
  }

  void _scheduleHoverClear() {
    _hoverClearTimer?.cancel();
    _hoverClearTimer = Timer(_hoverClearDelay, () {
      _hoveredPath.value = null;
    });
  }

  void _cancelHoverClear() {
    _hoverClearTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onExit: (_) => _scheduleHoverClear(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  right: JsonTreeLayout.trailingActionsWidth +
                      JsonTreeLayout.scrollbarGutter,
                  bottom: 8,
                ),
                itemCount: _visibleRows.length,
                itemBuilder: (context, index) {
                  final row = _visibleRows[index];
                  final node = row.node;

                  if (row.isCloseBracket) {
                    return JsonBracketRow(
                      key: ValueKey('${node.path}::close'),
                      node: node,
                      onHover: _onNodeHover,
                    );
                  }

                  if (node.isExpandable) {
                    return JsonExpandableRow(
                      key: ValueKey(node.path),
                      node: node,
                      isExpanded: row.isExpanded,
                      searchQuery: _searchQuery,
                      searchResult: _searchResult,
                      hoveredPath: _hoveredPath,
                      onToggle: _toggleExpansion,
                      onHover: _onNodeHover,
                    );
                  }

                  return JsonValueRow(
                    key: ValueKey(node.path),
                    node: node,
                    searchQuery: _searchQuery,
                    searchResult: _searchResult,
                    hoveredPath: _hoveredPath,
                    onHover: _onNodeHover,
                  );
                },
              ),
            ),
          ),
          _PathFooter(
            hoveredPath: _hoveredPath,
            onHover: _cancelHoverClear,
            onCopyPath: (path) => _copyPath(path),
          ),
        ],
      ),
    );
  }

  Future<void> _copyPath(String path) async {
    await Clipboard.setData(ClipboardData(text: path));
    if (!mounted) {
      return;
    }
    showCopyFeedback(context, CopyFeedbackType.path);
  }
}

class _PathFooter extends StatelessWidget {
  const _PathFooter({
    required this.hoveredPath,
    required this.onHover,
    required this.onCopyPath,
  });

  final ValueNotifier<String?> hoveredPath;
  final VoidCallback onHover;
  final ValueChanged<String> onCopyPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<String?>(
      valueListenable: hoveredPath,
      builder: (context, path, _) {
        return MouseRegion(
          onEnter: (_) => onHover(),
          child: Container(
            height: 32,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.35),
              border: Border(
                top: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: path == null
                ? const SizedBox.shrink()
                : Row(
                    children: [
                      Text(
                        'Path',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          path,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 9,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      JsonTreeIconButton(
                        tooltip: 'Copy path',
                        icon: Icons.copy,
                        onPressed: () => onCopyPath(path),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
