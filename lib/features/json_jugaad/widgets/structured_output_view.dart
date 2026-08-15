import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jugaadkit/core/utils/app_feedback.dart';
import 'package:jugaadkit/features/json_jugaad/models/jugaad_body_content.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_repair_highlight.dart';
import 'package:jugaadkit/features/json_jugaad/models/jugaad_structured_output.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_result.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_search.dart';
import 'package:jugaadkit/features/json_jugaad/utils/json_tree_search_navigator.dart';
import 'package:jugaadkit/widgets/common/action_button.dart';

import 'json_tree/json_tree_copy_target.dart';
import 'json_tree_view.dart';

class StructuredOutputView extends StatefulWidget {
  const StructuredOutputView({super.key, required this.result});

  final JsonJugaadResult result;

  @override
  State<StructuredOutputView> createState() => _StructuredOutputViewState();
}

class _StructuredOutputViewState extends State<StructuredOutputView> {
  late final TextEditingController _searchController;
  late final JsonTreeSearchNavigator _searchNavigator;
  late final ValueNotifier<String?> _hoveredPathNotifier;
  Timer? _hoverClearTimer;
  String _searchQuery = '';
  int? _matchCount;

  static const Duration _hoverClearDelay = Duration(milliseconds: 150);

  bool get _hasJsonSearch =>
      widget.result.structuredOutput?.jsonBodyValue != null;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchNavigator = JsonTreeSearchNavigator();
    _hoveredPathNotifier = ValueNotifier<String?>(null);
  }

  @override
  void didUpdateWidget(StructuredOutputView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result.originalInput != widget.result.originalInput) {
      _searchController.clear();
      _searchQuery = '';
      _matchCount = null;
    }
  }

  @override
  void dispose() {
    _hoverClearTimer?.cancel();
    _searchController.dispose();
    _searchNavigator.dispose();
    _hoveredPathNotifier.dispose();
    super.dispose();
  }

  void _schedulePathClear() {
    _hoverClearTimer?.cancel();
    _hoverClearTimer = Timer(_hoverClearDelay, () {
      _hoveredPathNotifier.value = null;
    });
  }

  void _cancelPathClear() {
    _hoverClearTimer?.cancel();
  }

  Future<void> _copyPath(String path) async {
    await Clipboard.setData(ClipboardData(text: path));
    if (!mounted) {
      return;
    }
    showCopyFeedback(context, CopyFeedbackType.path);
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
    await Clipboard.setData(ClipboardData(text: widget.result.formattedJson));
    if (!mounted) {
      return;
    }
    showCopyFeedback(context, CopyFeedbackType.all);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final structured = widget.result.structuredOutput!;
    final hasJsonSearch = _hasJsonSearch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Output', style: theme.textTheme.titleMedium),
              if (hasJsonSearch) ...[
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
              ] else
                const Spacer(),
              if (!hasJsonSearch) const Spacer(),
              const SizedBox(width: 8),
              ActionButton(
                label: 'Copy all',
                icon: Icons.copy,
                onPressed: _copyAll,
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
                child: _buildStructuredContent(structured),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStructuredContent(JugaadStructuredOutput structured) {
    final hasJsonBody = structured.jsonBodyValue != null;

    return MouseRegion(
      onExit: (_) => _schedulePathClear(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: _StructuredSectionsList(
                  sections: structured.sections,
                  searchController: _searchController,
                  searchNavigator: _searchNavigator,
                  onSearchChanged: _onSearchChanged,
                  detachJsonPathFooter: hasJsonBody,
                  hoveredPathNotifier: _hoveredPathNotifier,
                  reportsSearchMatches: hasJsonBody,
                ),
              ),
            ),
          ),
          if (hasJsonBody)
            JsonTreePathFooter(
              hoveredPath: _hoveredPathNotifier,
              onHover: _cancelPathClear,
              onCopyPath: _copyPath,
            ),
        ],
      ),
    );
  }
}

class _StructuredSectionsList extends StatelessWidget {
  const _StructuredSectionsList({
    required this.sections,
    this.searchController,
    this.searchNavigator,
    this.onSearchChanged,
    this.detachJsonPathFooter = false,
    this.hoveredPathNotifier,
    this.reportsSearchMatches = false,
  });

  final List<JugaadOutputSection> sections;
  final TextEditingController? searchController;
  final JsonTreeSearchNavigator? searchNavigator;
  final void Function(String query, JsonTreeSearchResult? result)? onSearchChanged;
  final bool detachJsonPathFooter;
  final ValueNotifier<String?>? hoveredPathNotifier;
  final bool reportsSearchMatches;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 20),
          _StructuredSectionView(
            section: sections[i],
            searchController: searchController,
            searchNavigator: searchNavigator,
            onSearchChanged: onSearchChanged,
            detachJsonPathFooter: detachJsonPathFooter,
            hoveredPathNotifier: hoveredPathNotifier,
            reportsSearchMatches: reportsSearchMatches,
          ),
        ],
      ],
    );
  }
}

class _StructuredSectionView extends StatelessWidget {
  const _StructuredSectionView({
    required this.section,
    this.searchController,
    this.searchNavigator,
    this.onSearchChanged,
    this.detachJsonPathFooter = false,
    this.hoveredPathNotifier,
    this.reportsSearchMatches = false,
  });

  final JugaadOutputSection section;
  final TextEditingController? searchController;
  final JsonTreeSearchNavigator? searchNavigator;
  final void Function(String query, JsonTreeSearchResult? result)? onSearchChanged;
  final bool detachJsonPathFooter;
  final ValueNotifier<String?>? hoveredPathNotifier;
  final bool reportsSearchMatches;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(label: section.title),
        const SizedBox(height: 8),
        switch (section.type) {
          JugaadSectionType.httpStatus => _HttpStatusContent(
              statusCode: section.statusCode!,
              statusText: section.statusText ?? '',
            ),
          JugaadSectionType.headers => _HeaderRows(headers: section.headers!),
          JugaadSectionType.methodUrl => _MethodUrlContent(
              method: section.method!,
              url: section.url!,
            ),
          JugaadSectionType.keyValueList => _KeyValueRows(fields: section.fields!),
          JugaadSectionType.body => _BodyContentView(
              body: section.body!,
              searchController: searchController,
              searchNavigator: searchNavigator,
              onSearchChanged: onSearchChanged,
              detachPathFooter: detachJsonPathFooter,
              hoveredPathNotifier: hoveredPathNotifier,
              reportsSearchMatches: reportsSearchMatches,
            ),
          JugaadSectionType.xmlDocument => _MonospaceText(text: section.text!),
        },
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _HttpStatusContent extends StatelessWidget {
  const _HttpStatusContent({
    required this.statusCode,
    required this.statusText,
  });

  final int statusCode;
  final String statusText;

  Color _statusColor(ColorScheme scheme) {
    if (statusCode >= 200 && statusCode < 300) {
      return scheme.primary;
    }
    if (statusCode >= 300 && statusCode < 400) {
      return scheme.tertiary;
    }
    if (statusCode >= 400 && statusCode < 500) {
      return scheme.error.withValues(alpha: 0.9);
    }
    if (statusCode >= 500) {
      return scheme.error;
    }
    return scheme.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = statusText.isEmpty ? '$statusCode' : '$statusCode $statusText';

    return JsonTreeCopyTarget(
      text: line,
      copyType: CopyFeedbackType.value,
      child: Text(
        line,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
          color: _statusColor(theme.colorScheme),
        ),
      ),
    );
  }
}

class _CopyableLabeledValueRow extends StatelessWidget {
  const _CopyableLabeledValueRow({
    required this.label,
    required this.value,
    required this.labelWidth,
    this.labelMonospace = false,
  });

  final String label;
  final String value;
  final double labelWidth;
  final bool labelMonospace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: JsonTreeCopyTarget(
              text: label,
              copyType: CopyFeedbackType.key,
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                  fontFamily: labelMonospace ? 'monospace' : null,
                ),
              ),
            ),
          ),
          Expanded(
            child: JsonTreeCopyTarget(
              text: value,
              copyType: CopyFeedbackType.value,
              child: Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderRows extends StatelessWidget {
  const _HeaderRows({required this.headers});

  final List<MapEntry<String, String>> headers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final header in headers)
          _CopyableLabeledValueRow(
            label: header.key,
            value: header.value,
            labelWidth: 160,
            labelMonospace: true,
          ),
      ],
    );
  }
}

class _MethodUrlContent extends StatelessWidget {
  const _MethodUrlContent({
    required this.method,
    required this.url,
  });

  final String method;
  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      height: 1.5,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        JsonTreeCopyTarget(
          text: method,
          copyType: CopyFeedbackType.key,
          child: Text(
            method,
            style: baseStyle?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: JsonTreeCopyTarget(
            text: url,
            copyType: CopyFeedbackType.value,
            child: Text(
              url,
              style: baseStyle?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _KeyValueRows extends StatelessWidget {
  const _KeyValueRows({required this.fields});

  final List<MapEntry<String, String>> fields;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final field in fields)
          _CopyableLabeledValueRow(
            label: field.key,
            value: field.value,
            labelWidth: 88,
          ),
      ],
    );
  }
}

class _BodyContentView extends StatelessWidget {
  const _BodyContentView({
    required this.body,
    this.searchController,
    this.searchNavigator,
    this.onSearchChanged,
    this.detachPathFooter = false,
    this.hoveredPathNotifier,
    this.reportsSearchMatches = false,
  });

  final JugaadBodyContent body;
  final TextEditingController? searchController;
  final JsonTreeSearchNavigator? searchNavigator;
  final void Function(String query, JsonTreeSearchResult? result)? onSearchChanged;
  final bool detachPathFooter;
  final ValueNotifier<String?>? hoveredPathNotifier;
  final bool reportsSearchMatches;

  @override
  Widget build(BuildContext context) {
    if (body.isJson) {
      return JsonTreeView(
        rootValue: body.jsonValue,
        searchController: searchController!,
        searchNavigator: reportsSearchMatches ? searchNavigator : null,
        onSearchChanged: reportsSearchMatches ? onSearchChanged : null,
        reportsSearchMatches: reportsSearchMatches,
        repairHighlights: JsonRepairHighlightSet.from(body.repairHighlights),
        shrinkWrap: true,
        showPathFooter: !detachPathFooter,
        detachPathFooter: detachPathFooter,
        hoveredPathNotifier: hoveredPathNotifier,
      );
    }

    if (body.isXml) {
      return _MonospaceText(text: body.xmlText!);
    }

    return _MonospaceText(text: body.plainText ?? '');
  }
}

class _MonospaceText extends StatelessWidget {
  const _MonospaceText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return JsonTreeCopyTarget(
      text: text,
      copyType: CopyFeedbackType.value,
      child: SelectableText(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          height: 1.5,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
