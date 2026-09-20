import 'package:flutter/material.dart';

class JsonTreeSearchField extends StatelessWidget {
  const JsonTreeSearchField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.matchCase,
    required this.wholeWord,
    required this.onMatchCaseChanged,
    required this.onWholeWordChanged,
    this.showClear = false,
    this.showOptions = true,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool matchCase;
  final bool wholeWord;
  final ValueChanged<bool> onMatchCaseChanged;
  final ValueChanged<bool> onWholeWordChanged;
  final bool showClear;
  final bool showOptions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        hintText: 'Search JSON…',
        prefixIcon: const Icon(Icons.search, size: 18),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        suffixIcon: _SearchSuffix(
          showOptions: showOptions,
          matchCase: matchCase,
          wholeWord: wholeWord,
          onMatchCaseChanged: onMatchCaseChanged,
          onWholeWordChanged: onWholeWordChanged,
          showClear: showClear,
          onClear: controller.clear,
          theme: theme,
        ),
      ),
      style: theme.textTheme.bodySmall?.copyWith(
        fontFamily: 'monospace',
      ),
    );
  }
}

class _SearchSuffix extends StatelessWidget {
  const _SearchSuffix({
    required this.showOptions,
    required this.matchCase,
    required this.wholeWord,
    required this.onMatchCaseChanged,
    required this.onWholeWordChanged,
    required this.showClear,
    required this.onClear,
    required this.theme,
  });

  final bool showOptions;
  final bool matchCase;
  final bool wholeWord;
  final ValueChanged<bool> onMatchCaseChanged;
  final ValueChanged<bool> onWholeWordChanged;
  final bool showClear;
  final VoidCallback onClear;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showOptions) ...[
          _SearchOptionToggle(
            tooltip: 'Match case',
            label: 'Aa',
            selected: matchCase,
            onPressed: () => onMatchCaseChanged(!matchCase),
            theme: theme,
          ),
          _SearchOptionToggle(
            tooltip: 'Match whole word',
            label: 'ab',
            selected: wholeWord,
            onPressed: () => onWholeWordChanged(!wholeWord),
            theme: theme,
          ),
        ],
        if (showClear)
          IconButton(
            tooltip: 'Clear search',
            onPressed: onClear,
            icon: const Icon(Icons.clear, size: 16),
          ),
      ],
    );
  }
}

class _SearchOptionToggle extends StatelessWidget {
  const _SearchOptionToggle({
    required this.tooltip,
    required this.label,
    required this.selected,
    required this.onPressed,
    required this.theme,
  });

  final String tooltip;
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(
        minWidth: 28,
        minHeight: 28,
      ),
      icon: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: color,
          fontSize: 11,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
