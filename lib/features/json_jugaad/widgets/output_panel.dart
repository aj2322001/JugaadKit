import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jugaadkit/core/utils/app_feedback.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_error.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_result.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_ui_state.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_search.dart';
import 'package:jugaadkit/widgets/common/action_button.dart';
import 'package:jugaadkit/widgets/common/empty_state.dart';
import 'package:jugaadkit/widgets/common/error_state.dart';

import 'json_tree_view.dart';

class OutputPanel extends StatelessWidget {
  const OutputPanel({
    super.key,
    required this.status,
    this.result,
    this.error,
  });

  final JsonJugaadStatus status;
  final JsonJugaadResult? result;
  final JsonJugaadError? error;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: switch (status) {
        JsonJugaadStatus.empty => const _OutputShell(
            child: EmptyState(
              title: 'No output yet',
              message: 'Paste JSON in the input panel to see formatted output.',
            ),
          ),
        JsonJugaadStatus.processing => const _OutputShell(
            child: Center(child: CircularProgressIndicator()),
          ),
        JsonJugaadStatus.success when result != null => _JsonOutputExplorer(
            result: result!,
          ),
        JsonJugaadStatus.error => _OutputShell(
            child: SingleChildScrollView(
              child: ErrorState(
                message: error?.message ?? 'Failed to process input.',
                detail: error?.detail ?? error?.lastAttempt,
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
  const _JsonOutputExplorer({required this.result});

  final JsonJugaadResult result;

  @override
  State<_JsonOutputExplorer> createState() => _JsonOutputExplorerState();
}

class _JsonOutputExplorerState extends State<_JsonOutputExplorer> {
  late final TextEditingController _searchController;
  String _searchQuery = '';
  int? _matchCount;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search JSON…',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            tooltip: 'Clear search',
                            onPressed: _searchController.clear,
                            icon: const Icon(Icons.clear, size: 16),
                          )
                        : null,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              if (_matchCount != null) ...[
                const SizedBox(width: 8),
                Text(
                  _matchCount == 0 ? 'No matches' : '$_matchCount matches',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _matchCount == 0
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
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
                    onSearchChanged: _onSearchChanged,
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
