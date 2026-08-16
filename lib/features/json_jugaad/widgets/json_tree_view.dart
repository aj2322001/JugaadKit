import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jugaadkit/core/utils/app_feedback.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_repair_highlight.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_tree_node.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_builder.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_flatten.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_search.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_search_navigator.dart';

import 'json_tree/json_bracket_row.dart';
import 'json_tree/json_expandable_row.dart';
import 'json_tree/json_open_bracket_row.dart';
import 'json_tree/json_tree_controls.dart';
import 'json_tree/json_value_row.dart';

Widget _fullWidthTreeRow(Widget child) {
  return LayoutBuilder(
    builder: (context, constraints) {
      return SizedBox(
        width: constraints.maxWidth,
        child: child,
      );
    },
  );
}

typedef JsonTreeSearchListener = void Function(
  String query,
  JsonTreeSearchResult? result,
);

class JsonTreeView extends StatefulWidget {
  const JsonTreeView({
    super.key,
    required this.rootValue,
    required this.searchController,
    this.searchSession,
    this.searchNavigator,
    this.onSearchChanged,
    this.shrinkWrap = false,
    this.showPathFooter = true,
    this.hoveredPathNotifier,
    this.detachPathFooter = false,
    this.reportsSearchMatches = true,
    this.repairHighlights = JsonRepairHighlightSet.empty,
  });

  final Object? rootValue;
  final TextEditingController searchController;
  final JsonTreeSearchSession? searchSession;
  final JsonTreeSearchSession? searchNavigator;
  final JsonTreeSearchListener? onSearchChanged;
  final bool shrinkWrap;
  final bool showPathFooter;
  final ValueNotifier<String?>? hoveredPathNotifier;
  final bool detachPathFooter;
  final bool reportsSearchMatches;
  final JsonRepairHighlightSet repairHighlights;

  JsonTreeSearchSession? get _session => searchSession ?? searchNavigator;

  @override
  State<JsonTreeView> createState() => _JsonTreeViewState();
}

class _JsonTreeViewState extends State<JsonTreeView> {
  static const Duration _hoverClearDelay = Duration(milliseconds: 150);
  static const Duration _searchDebounce = Duration(milliseconds: 150);
  static const double _estimatedRowHeight = 28;
  static const int _maxScrollAttempts = 64;

  late JsonTreeNode _rootNode;
  late List<VisibleTreeRow> _visibleRows;
  final ScrollController _scrollController = ScrollController();
  final Set<String> _collapsedPaths = {};
  Set<String>? _savedCollapsedPaths;
  final ValueNotifier<String?> _internalHoveredPath = ValueNotifier<String?>(null);

  ValueNotifier<String?> get _hoveredPath =>
      widget.hoveredPathNotifier ?? _internalHoveredPath;

  String _searchQuery = '';
  JsonTreeSearchResult? _searchResult;
  int? _activeMatchIndex;
  GlobalKey? _scrollTargetKey;
  Timer? _hoverClearTimer;
  Timer? _searchDebounceTimer;
  JsonTreeSearchSession? _boundSession;
  int _scrollToActiveMatchToken = 0;

  @override
  void initState() {
    super.initState();
    _rootNode = JsonTreeBuilder.build(widget.rootValue);
    widget.searchController.addListener(_onSearchTextChanged);
    _searchQuery = widget.searchController.text;
    _rebuildVisibleRows();
    _runSearch(_searchQuery);
    if (widget.reportsSearchMatches) {
      _bindSearchSession(widget._session);
      _syncActiveIndexFromSession();
    }
  }

  @override
  void didUpdateWidget(JsonTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchController != widget.searchController) {
      oldWidget.searchController.removeListener(_onSearchTextChanged);
      widget.searchController.addListener(_onSearchTextChanged);
    }
    if (oldWidget._session != widget._session) {
      _unbindSearchSession();
      _bindSearchSession(widget._session);
    }
    if (oldWidget.rootValue != widget.rootValue) {
      _rootNode = JsonTreeBuilder.build(widget.rootValue);
      _collapsedPaths.clear();
      _savedCollapsedPaths = null;
      _searchQuery = widget.searchController.text;
      _activeMatchIndex = null;
      _scrollTargetKey = null;
      _hoveredPath.value = null;
      _hoverClearTimer?.cancel();
      _rebuildVisibleRows();
      _runSearch(_searchQuery);
      _publishSearchState(resetActiveIndex: true);
    } else if (oldWidget.reportsSearchMatches != widget.reportsSearchMatches) {
      _publishSearchState(resetActiveIndex: false);
    } else {
      _syncActiveIndexFromSession();
    }
  }

  @override
  void dispose() {
    _hoverClearTimer?.cancel();
    _searchDebounceTimer?.cancel();
    widget.searchController.removeListener(_onSearchTextChanged);
    _unbindSearchSession();
    _scrollController.dispose();
    if (widget.hoveredPathNotifier == null) {
      _internalHoveredPath.dispose();
    }
    super.dispose();
  }

  void _bindSearchSession(JsonTreeSearchSession? session) {
    _boundSession = session;
    if (widget.reportsSearchMatches) {
      session?.addListener(_onSearchSessionChanged);
    }
  }

  void _unbindSearchSession() {
    if (widget.reportsSearchMatches) {
      _boundSession?.removeListener(_onSearchSessionChanged);
    }
    _boundSession = null;
  }

  void _onSearchSessionChanged() {
    if (!widget.reportsSearchMatches) {
      return;
    }
    _syncActiveIndexFromSession();
  }

  void _syncActiveIndexFromSession() {
    if (!widget.reportsSearchMatches) {
      return;
    }

    final session = widget._session;
    if (session == null) {
      return;
    }

    final matchCount = _searchResult?.matchCount ?? 0;
    if (matchCount == 0) {
      if (_activeMatchIndex != null) {
        setState(() {
          _activeMatchIndex = null;
          _scrollTargetKey = null;
        });
      }
      return;
    }

    final targetIndex = session.activeIndex.clamp(0, matchCount - 1);
    if (_activeMatchIndex != targetIndex) {
      setState(() {
        _activeMatchIndex = targetIndex;
        _scrollTargetKey = GlobalKey();
        _rebuildVisibleRows();
      });
    } else {
      _scrollTargetKey ??= GlobalKey();
    }
    _scheduleScrollToActiveMatch();
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
      final matchCount = _searchResult?.matchCount ?? 0;
      if (matchCount == 0) {
        _activeMatchIndex = null;
        _scrollTargetKey = null;
      } else {
        _activeMatchIndex = widget._session?.activeIndex ?? 0;
        if (_activeMatchIndex! >= matchCount) {
          _activeMatchIndex = 0;
        }
        _scrollTargetKey = GlobalKey();
      }
      _rebuildVisibleRows();
    });
    _publishSearchState(resetActiveIndex: true);
    if (_activeMatchIndex != null) {
      _scheduleScrollToActiveMatch();
    }
  }

  void _publishSearchState({required bool resetActiveIndex}) {
    widget.onSearchChanged?.call(_searchQuery, _searchResult);

    if (!widget.reportsSearchMatches) {
      return;
    }

    final session = widget._session;
    if (session == null) {
      return;
    }

    final matchCount = _searchResult?.matchCount ?? 0;
    if (matchCount == 0 || _searchQuery.trim().isEmpty) {
      session.clear();
      return;
    }

    session.setMatches(matchCount, resetIndex: resetActiveIndex);
  }

  String? get _activeMatchPath {
    final index = _activeMatchIndex;
    final matches = _searchResult?.matches;
    if (index == null || matches == null || matches.isEmpty) {
      return null;
    }
    return matches[index].path;
  }

  int? _rowIndexForActiveMatch() {
    final path = _activeMatchPath;
    if (path == null) {
      return null;
    }

    for (var i = 0; i < _visibleRows.length; i++) {
      final row = _visibleRows[i];
      if (!row.isCloseBracket && row.node.path == path) {
        return i;
      }
    }
    return null;
  }

  ScrollPosition? _ownedScrollPosition() {
    if (!widget.shrinkWrap && _scrollController.hasClients) {
      return _scrollController.position;
    }
    return null;
  }

  ScrollPosition? _scrollPositionForActiveMatch() {
    final owned = _ownedScrollPosition();
    if (owned != null) {
      return owned;
    }

    final scrollable = Scrollable.maybeOf(context);
    if (scrollable != null && scrollable.position.hasContentDimensions) {
      return scrollable.position;
    }

    return null;
  }

  void _scheduleScrollToActiveMatch() {
    final token = ++_scrollToActiveMatchToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || token != _scrollToActiveMatchToken) {
        return;
      }
      unawaited(_scrollToActiveMatch(token));
    });
  }

  int _approxRowAtOffset(double pixels) {
    return (pixels / _estimatedRowHeight).floor();
  }

  void _jumpScrollPosition(ScrollPosition position, int rowIndex, int attempt) {
    final maxExtent = position.maxScrollExtent;
    final viewport = position.viewportDimension;
    final approxRow = _approxRowAtOffset(position.pixels);
    final estimatedOffset =
        (rowIndex * _estimatedRowHeight).clamp(0.0, maxExtent);
    final rowDelta = rowIndex - approxRow;

    if (attempt == 0) {
      if (_visibleRows.length > 1) {
        final progress = rowIndex / (_visibleRows.length - 1);
        final proportional = (progress * maxExtent).clamp(0.0, maxExtent);
        position.jumpTo(
          estimatedOffset > proportional ? estimatedOffset : proportional,
        );
      } else {
        position.jumpTo(estimatedOffset);
      }
      return;
    }

    if (rowDelta.abs() >= 4) {
      final delta = rowDelta * _estimatedRowHeight;
      position.jumpTo((position.pixels + delta).clamp(0.0, maxExtent));
      return;
    }

    if (approxRow < rowIndex) {
      final viewportJump =
          (position.pixels + viewport * 0.85).clamp(0.0, maxExtent);
      position.jumpTo(
        estimatedOffset > position.pixels + 1 ? estimatedOffset : viewportJump,
      );
      return;
    }

    if (approxRow > rowIndex) {
      final viewportJump =
          (position.pixels - viewport * 0.85).clamp(0.0, maxExtent);
      position.jumpTo(
        estimatedOffset < position.pixels - 1 ? estimatedOffset : viewportJump,
      );
      return;
    }

    final delta = rowIndex >= approxRow
        ? _estimatedRowHeight * 3
        : -_estimatedRowHeight * 3;
    position.jumpTo((position.pixels + delta).clamp(0.0, maxExtent));
  }

  Future<void> _scrollToActiveMatch(int token) async {
    final rowIndex = _rowIndexForActiveMatch();
    if (rowIndex == null) {
      return;
    }

    ScrollPosition? position = _scrollPositionForActiveMatch();

    for (var attempt = 0; attempt < _maxScrollAttempts; attempt++) {
      if (!mounted || token != _scrollToActiveMatchToken) {
        return;
      }

      final targetContext = _scrollTargetKey?.currentContext;
      if (targetContext != null && targetContext.mounted) {
        await Scrollable.ensureVisible(
          targetContext,
          alignment: 0.2,
          duration: Duration(milliseconds: attempt == 0 ? 200 : 120),
          curve: Curves.easeInOut,
        );
        return;
      }

      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || token != _scrollToActiveMatchToken) {
        return;
      }

      position = _ownedScrollPosition() ?? position;
      if (position == null) {
        continue;
      }
      _jumpScrollPosition(position, rowIndex, attempt);
    }
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
    final treeList = ListView.builder(
      controller: widget.shrinkWrap ? null : _scrollController,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : null,
      cacheExtent: _activeMatchPath != null ? 2400 : 480,
      padding: const EdgeInsets.only(
        right: JsonTreeLayout.trailingActionsWidth +
            JsonTreeLayout.scrollbarGutter,
        bottom: 8,
      ),
      itemCount: _visibleRows.length,
      itemBuilder: (context, index) {
        final row = _visibleRows[index];
        final node = row.node;
        final activeMatchPath = _activeMatchPath;
        final isActiveSearchMatch =
            !row.isCloseBracket && node.path == activeMatchPath;
        final rowKey = isActiveSearchMatch
            ? (_scrollTargetKey ?? ValueKey(node.path))
            : ValueKey(
                row.isOpenBracket
                    ? '${node.path}::open'
                    : row.isCloseBracket
                        ? '${node.path}::close'
                        : node.path,
              );

        if (row.isOpenBracket) {
          return _fullWidthTreeRow(
            JsonOpenBracketRow(
              key: rowKey,
              node: node,
              onHover: _onNodeHover,
              repairHighlights: widget.repairHighlights,
            ),
          );
        }

        if (row.isCloseBracket) {
          return _fullWidthTreeRow(
            JsonBracketRow(
              key: rowKey,
              node: node,
              onHover: _onNodeHover,
              repairHighlights: widget.repairHighlights,
            ),
          );
        }

        if (node.isExpandable) {
          return _fullWidthTreeRow(
            JsonExpandableRow(
              key: rowKey,
              node: node,
              isExpanded: row.isExpanded,
              searchQuery: _searchQuery,
              searchResult: _searchResult,
              hoveredPath: _hoveredPath,
              isActiveSearchMatch: isActiveSearchMatch,
              onToggle: _toggleExpansion,
              onHover: _onNodeHover,
              repairHighlights: widget.repairHighlights,
            ),
          );
        }

        return _fullWidthTreeRow(
          JsonValueRow(
            key: rowKey,
            node: node,
            searchQuery: _searchQuery,
            searchResult: _searchResult,
            hoveredPath: _hoveredPath,
            isActiveSearchMatch: isActiveSearchMatch,
            onHover: _onNodeHover,
            repairHighlights: widget.repairHighlights,
          ),
        );
      },
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.shrinkWrap)
          treeList
        else
          Expanded(
            child: treeList,
          ),
        if (widget.showPathFooter && !widget.detachPathFooter)
          JsonTreePathFooter(
            hoveredPath: _hoveredPath,
            onHover: _cancelHoverClear,
            onCopyPath: (path) => _copyPath(path),
          ),
      ],
    );

    if (widget.detachPathFooter) {
      return content;
    }

    return MouseRegion(
      onExit: (_) => _scheduleHoverClear(),
      child: content,
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

class JsonTreePathFooter extends StatelessWidget {
  const JsonTreePathFooter({
    super.key,
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
