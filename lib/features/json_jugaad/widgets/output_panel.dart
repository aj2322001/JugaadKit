import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jugaadkit/core/utils/app_feedback.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_error.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_result.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_ui_state.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_search.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_search_navigator.dart';
import 'package:jugaadkit/widgets/common/action_button.dart';
import 'package:jugaadkit/widgets/common/empty_state.dart';
import 'package:jugaadkit/widgets/common/error_state.dart';

import 'package:jugaadkit/features/json_jugaad/utils/json_tree_search_options.dart';

import 'json_tree_search_field.dart';
import 'json_tree_view.dart';
import 'output_json_search_focus.dart';
import 'output_scroll_behavior.dart';
import 'structured_output_view.dart';

class OutputPanel extends StatelessWidget {
  const OutputPanel({
    super.key,
    required this.status,
    this.result,
    this.error,
    this.searchFocusTarget,
  });

  final JsonJugaadStatus status;
  final JsonJugaadResult? result;
  final JsonJugaadError? error;
  final OutputJsonSearchFocus? searchFocusTarget;

  static Widget _withOutputScrollBehavior(Widget child) {
    return ScrollConfiguration(
      behavior: const OutputScrollBehavior(),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: switch (status) {
        JsonJugaadStatus.empty => _withOutputScrollBehavior(
            const _OutputShell(
              child: EmptyState(
                title: 'No output yet',
                message: 'Paste data in the input panel to see formatted output.',
              ),
            ),
          ),
        JsonJugaadStatus.processing => _withOutputScrollBehavior(
            const _OutputShell(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        JsonJugaadStatus.success when result != null && result!.isJsonOutput =>
          _withOutputScrollBehavior(
            _JsonOutputExplorer(
              key: ValueKey(result!.originalInput),
              result: result!,
              searchFocusTarget: searchFocusTarget,
            ),
          ),
        JsonJugaadStatus.success when result != null && result!.hasStructuredOutput =>
          _withOutputScrollBehavior(
            StructuredOutputView(
              key: ValueKey(result!.originalInput),
              result: result!,
              searchFocusTarget: searchFocusTarget,
            ),
          ),
        JsonJugaadStatus.success when result != null => _withOutputScrollBehavior(
            _TextOutputView(
              key: ValueKey(result!.originalInput),
              result: result!,
            ),
          ),
        JsonJugaadStatus.error => _withOutputScrollBehavior(
            _OutputShell(
              child: SingleChildScrollView(
                child: ErrorState(
                  message: error?.message ?? 'Failed to process input.',
                  detail: error?.detail ?? error?.lastAttempt,
                ),
              ),
            ),
          ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _OutputShell extends StatelessWidget {
  const _OutputShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
          child: Text('Output', style: theme.textTheme.titleMedium),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _JsonOutputExplorer extends StatefulWidget {
  const _JsonOutputExplorer({
    super.key,
    required this.result,
    this.searchFocusTarget,
  });

  final JsonJugaadResult result;
  final OutputJsonSearchFocus? searchFocusTarget;

  @override
  State<_JsonOutputExplorer> createState() => _JsonOutputExplorerState();
}

class _JsonOutputExplorerState extends State<_JsonOutputExplorer> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final JsonTreeSearchNavigator _searchNavigator;
  String _searchQuery = '';
  int? _matchCount;
  bool _matchCase = false;
  bool _wholeWord = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _searchNavigator = JsonTreeSearchNavigator();
    _registerSearchFocus();
  }

  @override
  void didUpdateWidget(_JsonOutputExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchFocusTarget != widget.searchFocusTarget) {
      oldWidget.searchFocusTarget?.unregister();
      _registerSearchFocus();
    }
  }

  void _registerSearchFocus() {
    widget.searchFocusTarget?.register(
      focusNode: _searchFocusNode,
      controller: _searchController,
    );
  }

  @override
  void dispose() {
    widget.searchFocusTarget?.unregister();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchNavigator.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query, JsonTreeSearchResult? result) {
    setState(() {
      _searchQuery = query;
      if (query.trim().isEmpty) {
        _matchCount = null;
      } else {
        _matchCount = result?.matchCount ?? 0;
      }
    });
  }

  Future<void> _copyAll() async {
    await Clipboard.setData(
      ClipboardData(text: widget.result.formattedJson),
    );
    if (!mounted) {
      return;
    }
    showCopyFeedback(context, CopyFeedbackType.all);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Output', style: theme.textTheme.titleMedium),
              const SizedBox(width: 16),
              Expanded(
                child: JsonTreeSearchField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  matchCase: _matchCase,
                  wholeWord: _wholeWord,
                  showClear: _searchQuery.isNotEmpty,
                  onMatchCaseChanged: (value) => setState(() => _matchCase = value),
                  onWholeWordChanged: (value) => setState(() => _wholeWord = value),
                ),
              ),
              if (_matchCount != null) ...[
                const SizedBox(width: 8),
                ListenableBuilder(
                  listenable: _searchNavigator,
                  builder: (context, _) {
                    if (_matchCount == 0) {
                      return Text(
                        'No matches',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      );
                    }

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_searchNavigator.activeMatchNumber}/${_searchNavigator.matchCount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Previous match',
                          onPressed: _searchNavigator.goToPrevious,
                          icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Next match',
                          onPressed: _searchNavigator.goToNext,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
              const SizedBox(width: 8),
              ActionButton(
                label: 'Copy all',
                icon: Icons.copy,
                onPressed: _copyAll,
                tooltip: 'Copy formatted JSON',
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: JsonTreeView(
                    rootValue: widget.result.parsedValue,
                    searchController: _searchController,
                    searchNavigator: _searchNavigator,
                    onSearchChanged: _onSearchChanged,
                    reportsSearchMatches: true,
                    repairHighlights: widget.result.repairHighlightSet,
                    searchOptions: JsonTreeSearchOptions(
                      matchCase: _matchCase,
                      wholeWord: _wholeWord,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TextOutputView extends StatelessWidget {
  const _TextOutputView({super.key, required this.result});

  final JsonJugaadResult result;

  Future<void> _copyAll(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: result.formattedJson));
    if (!context.mounted) {
      return;
    }
    showCopyFeedback(context, CopyFeedbackType.all);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            children: [
              Text('Output', style: theme.textTheme.titleMedium),
              const Spacer(),
              ActionButton(
                label: 'Copy all',
                icon: Icons.copy,
                onPressed: () => _copyAll(context),
                tooltip: 'Copy formatted output',
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    result.formattedJson,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
