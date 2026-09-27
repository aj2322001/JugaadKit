import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:jugaadkit/features/json_jugaad/engine/confidence.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_error.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_repair_highlight.dart';
import 'package:jugaadkit/features/json_jugaad/models/processing_mode.dart';
import 'package:jugaadkit/features/json_jugaad/models/transformation_step.dart';

class TransformationStatus extends StatelessWidget {
  const TransformationStatus({
    super.key,
    required this.steps,
    this.showExplorerHint = false,
    this.showRepairHint = false,
    this.detectionSummary,
    this.confidence = Confidence.none,
    this.showDetectionMeta = false,
    this.ambiguousError,
    this.onTryAs,
  });

  final List<TransformationStep> steps;
  final bool showExplorerHint;
  final bool showRepairHint;
  final String? detectionSummary;
  final Confidence confidence;
  final bool showDetectionMeta;
  final JsonJugaadError? ambiguousError;
  final ValueChanged<ProcessingMode>? onTryAs;

  static const String _explorerHint =
      'Click a key or value in the output to copy it.';

  static const String _repairHint = jsonRepairStatusHint;

  @override
  Widget build(BuildContext context) {
    final lines = _buildLines();
    final showAmbiguous = ambiguousError?.isAmbiguousAutoFailure ?? false;

    if (lines.isEmpty &&
        !showDetectionMeta &&
        !showAmbiguous &&
        !showRepairHint &&
        detectionSummary == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final showTransformationDetails = lines.isNotEmpty;
    final attachDetailsToMeta = showDetectionMeta &&
        detectionSummary != null &&
        !showAmbiguous;

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
          ],
          if (attachDetailsToMeta) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                    ],
                  ),
                ),
                if (showTransformationDetails)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: _TransformationDetailsToggle(
                      lines: lines,
                      theme: theme,
                    ),
                  ),
              ],
            ),
          ],
          if (showTransformationDetails && !attachDetailsToMeta) ...[
            if (showAmbiguous) const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _TransformationDetailsToggle(
                lines: lines,
                theme: theme,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<_DisplayLine> _buildLines() {
    final lines = <_DisplayLine>[];

    if (steps.isNotEmpty) {
      lines.add(_DisplayLine.fromStep(steps.first));
    }

    if (showRepairHint) {
      lines.add(const _DisplayLine.hint(_repairHint));
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

class _TransformationDetailsToggle extends StatefulWidget {
  const _TransformationDetailsToggle({
    required this.lines,
    required this.theme,
  });

  final List<_DisplayLine> lines;
  final ThemeData theme;

  @override
  State<_TransformationDetailsToggle> createState() =>
      _TransformationDetailsToggleState();
}

class _TransformationDetailsToggleState
    extends State<_TransformationDetailsToggle> {
  final GlobalKey _anchorKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _close() {
    if (_overlayEntry == null) {
      return;
    }
    _removeOverlay();
    if (mounted) {
      setState(() {});
    }
  }

  void _toggle() {
    if (_overlayEntry != null) {
      _close();
      return;
    }
    _openOverlay();
  }

  void _openOverlay() {
    final overlay = Overlay.of(context, rootOverlay: true);
    final renderBox =
        _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return;
    }

    final anchorOffset = renderBox.localToGlobal(Offset.zero);
    final anchorSize = renderBox.size;
    final screenSize = MediaQuery.sizeOf(context);
    const spacing = 6.0;
    const cardMaxHeight = 280.0;
    final cardWidth = math.min(320.0, screenSize.width - 16);

    var left = anchorOffset.dx + anchorSize.width - cardWidth;
    if (left < 8) {
      left = 8;
    }
    if (left + cardWidth > screenSize.width - 8) {
      left = screenSize.width - cardWidth - 8;
    }

    final spaceBelow = screenSize.height -
        (anchorOffset.dy + anchorSize.height + spacing);
    final spaceAbove = anchorOffset.dy - spacing;
    final openAbove = spaceBelow < 96 && spaceAbove > spaceBelow;
    final maxHeight = math.min(
      cardMaxHeight,
      (openAbove ? spaceAbove : spaceBelow).clamp(96.0, cardMaxHeight),
    );
    final cardBottom = screenSize.height - anchorOffset.dy + spacing;
    final cardTop = anchorOffset.dy + anchorSize.height + spacing;

    final theme = widget.theme;
    final lines = widget.lines;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        final card = Material(
          elevation: 8,
          shadowColor: theme.shadowColor.withValues(alpha: 0.25),
          color: theme.colorScheme.surfaceContainerHigh,
          surfaceTintColor: theme.colorScheme.surfaceTint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: theme.dividerColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Transformations',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _TransformationStepsList(
                    lines: lines,
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),
        );

        return Theme(
          data: theme,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _close,
                ),
              ),
              if (openAbove)
                Positioned(
                  left: left,
                  bottom: cardBottom,
                  width: cardWidth,
                  child: card,
                )
              else
                Positioned(
                  left: left,
                  top: cardTop,
                  width: cardWidth,
                  child: card,
                ),
            ],
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return _InfoIconButton(
      key: _anchorKey,
      theme: widget.theme,
      isActive: _overlayEntry != null,
      onPressed: _toggle,
    );
  }
}

class _InfoIconButton extends StatelessWidget {
  const _InfoIconButton({
    super.key,
    required this.theme,
    required this.isActive,
    required this.onPressed,
  });

  final ThemeData theme;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final baseColor = theme.colorScheme.onSurfaceVariant;
    final activeColor = theme.colorScheme.primary;

    return IconButton(
      onPressed: onPressed,
      tooltip: 'Transformation details',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      style: IconButton.styleFrom(
        foregroundColor: isActive ? activeColor : baseColor,
        backgroundColor: isActive
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : null,
        hoverColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        focusColor: theme.colorScheme.primary.withValues(alpha: 0.12),
      ),
      icon: const Icon(Icons.info_outline, size: 16),
    );
  }
}

class _TransformationStepsList extends StatelessWidget {
  const _TransformationStepsList({
    required this.lines,
    required this.theme,
  });

  final List<_DisplayLine> lines;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.asMap().entries.map((entry) {
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
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (line.detail != null)
                      Text(
                        line.detail!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
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
