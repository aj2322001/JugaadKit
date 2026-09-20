import 'package:flutter/material.dart';

import 'package:jugaadkit/features/json_jugaad/utils/json_tree_search_options.dart';

class HighlightedText extends StatelessWidget {
  const HighlightedText({
    super.key,
    required this.text,
    required this.style,
    this.query,
    this.highlightColor,
    this.searchOptions = const JsonTreeSearchOptions(),
  });

  final String text;
  final TextStyle style;
  final String? query;
  final Color? highlightColor;
  final JsonTreeSearchOptions searchOptions;

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query?.trim();
    if (normalizedQuery == null || normalizedQuery.isEmpty) {
      return Text(text, style: style, softWrap: true);
    }

    final ranges = searchOptions.matchRanges(text, normalizedQuery);
    if (ranges.isEmpty) {
      return Text(text, style: style, softWrap: true);
    }

    final spans = <TextSpan>[];
    var cursor = 0;

    for (final range in ranges) {
      if (range.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, range.start), style: style));
      }

      spans.add(
        TextSpan(
          text: text.substring(range.start, range.end),
          style: style.copyWith(
            backgroundColor: highlightColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      cursor = range.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: style));
    }

    return Text.rich(
      TextSpan(children: spans),
      softWrap: true,
    );
  }
}
