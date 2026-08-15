import 'package:flutter/material.dart';

import 'package:jugaadkit/core/theme/feedback_colors.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_repair_highlight.dart';

/// Wraps a repaired JSON tree item with a hover tooltip sourced from repair
/// metadata. Non-repaired items pass through unchanged.
class JsonRepairTooltip extends StatelessWidget {
  const JsonRepairTooltip({
    super.key,
    required this.highlight,
    required this.child,
  });

  final JsonRepairHighlight? highlight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final highlight = this.highlight;
    if (highlight == null || !highlight.hasTooltip) {
      return child;
    }

    final feedback = AppFeedbackColors.of(context);
    return Tooltip(
      richMessage: buildRepairTooltipSpan(highlight, feedback),
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 350),
      showDuration: const Duration(seconds: 5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: feedback.warningBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: feedback.warningForeground.withValues(alpha: 0.35),
        ),
      ),
      child: child,
    );
  }
}

TextSpan buildRepairTooltipSpan(
  JsonRepairHighlight highlight,
  AppFeedbackColors feedback,
) {
  final baseStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 11,
    height: 1.4,
    color: feedback.warningForeground,
  );

  final children = <InlineSpan>[
    TextSpan(
      text: '⚠️ ${highlight.tooltipTitle}',
      style: baseStyle,
    ),
  ];

  if (highlight.originalText != null && highlight.repairedText != null) {
    children.addAll([
      TextSpan(text: '\n', style: baseStyle),
      TextSpan(
        text: highlight.originalText,
        style: baseStyle.copyWith(color: feedback.errorForeground),
      ),
      TextSpan(text: ' → ', style: baseStyle),
      TextSpan(
        text: highlight.repairedText,
        style: baseStyle.copyWith(color: feedback.successForeground),
      ),
    ]);
  } else if (highlight.kind == JsonRepairKind.missingClosing &&
      highlight.repairedText != null) {
    children.addAll([
      TextSpan(text: '\nAdded: ', style: baseStyle),
      TextSpan(
        text: highlight.repairedText,
        style: baseStyle.copyWith(color: feedback.successForeground),
      ),
    ]);
  } else if (highlight.tooltipDetailPlain != null) {
    children.add(
      TextSpan(
        text: '\n${highlight.tooltipDetailPlain}',
        style: baseStyle,
      ),
    );
  }

  return TextSpan(children: children);
}
