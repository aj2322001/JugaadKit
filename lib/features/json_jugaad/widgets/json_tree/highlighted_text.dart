import 'package:flutter/material.dart';

class HighlightedText extends StatelessWidget {
  const HighlightedText({
    super.key,
    required this.text,
    required this.style,
    this.query,
    this.highlightColor,
  });

  final String text;
  final TextStyle style;
  final String? query;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query?.trim();
    if (normalizedQuery == null || normalizedQuery.isEmpty) {
      return Text(text, style: style);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = normalizedQuery.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index < 0) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start), style: style));
        }
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + normalizedQuery.length),
          style: style.copyWith(
            backgroundColor: highlightColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      start = index + normalizedQuery.length;
    }

    return Text.rich(TextSpan(children: spans));
  }
}
