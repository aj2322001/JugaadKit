import 'package:flutter/material.dart';

import 'package:jugaadkit/features/json_jugaad/engine/confidence.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_error.dart';
import 'package:jugaadkit/features/json_jugaad/models/processing_mode.dart';
import 'package:jugaadkit/features/json_jugaad/models/transformation_step.dart';

class TransformationStatus extends StatelessWidget {
  const TransformationStatus({
    super.key,
    required this.steps,
    this.showExplorerHint = false,
    this.detectionSummary,
    this.confidence = Confidence.none,
    this.showDetectionMeta = false,
    this.ambiguousError,
    this.onTryAs,
  });

  final List<TransformationStep> steps;
  final bool showExplorerHint;
  final String? detectionSummary;
  final Confidence confidence;
  final bool showDetectionMeta;
  final JsonJugaadError? ambiguousError;
  final ValueChanged<ProcessingMode>? onTryAs;

  static const String _explorerHint =
      'Click a key or value in the output to copy it.';

  @override
  Widget build(BuildContext context) {
    final lines = _buildLines();
    final showAmbiguous = ambiguousError?.isAmbiguousAutoFailure ?? false;

    if (lines.isEmpty &&
        !showDetectionMeta &&
        !showAmbiguous &&
        detectionSummary == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAmbiguous) ...[
            Text(
              ambiguousError!.message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            if (ambiguousError!.suggestedModes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Try as:',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final mode in ambiguousError!.suggestedModes)
                    ActionChip(
                      label: Text(mode.label),
                      onPressed: onTryAs == null ? null : () => onTryAs!(mode),
                    ),
                ],
              ),
            ],
          ] else if (showDetectionMeta && detectionSummary != null) ...[
            _MetaRow(
              label: 'Detected',
              value: detectionSummary!,
              theme: theme,
            ),
            const SizedBox(height: 4),
            _MetaRow(
              label: 'Confidence',
              value: confidence.label,
              theme: theme,
            ),
            const SizedBox(height: 12),
          ],
          if (lines.isNotEmpty) ...[
            Text(
              'Transformations',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          ...lines.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final line = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '$index.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: line.isHint
                                ? theme.colorScheme.onSurfaceVariant
                                : null,
                          ),
                        ),
                        if (line.detail != null)
                          Text(
                            line.detail!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              color: theme.colorScheme.outline,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  List<_DisplayLine> _buildLines() {
    final lines = <_DisplayLine>[];

    if (steps.isNotEmpty) {
      lines.add(_DisplayLine.fromStep(steps.first));
    }

    if (showExplorerHint) {
      lines.add(const _DisplayLine.hint(_explorerHint));
    }

    for (var index = 1; index < steps.length; index++) {
      lines.add(_DisplayLine.fromStep(steps[index]));
    }

    return lines;
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            '$label:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _DisplayLine {
  const _DisplayLine({
    required this.description,
    this.detail,
    this.isHint = false,
  });

  const _DisplayLine.hint(String description)
      : this(description: description, isHint: true);

  factory _DisplayLine.fromStep(TransformationStep step) {
    return _DisplayLine(
      description: step.description,
      detail: step.detail,
    );
  }

  final String description;
  final String? detail;
  final bool isHint;
}
