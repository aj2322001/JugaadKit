import 'package:flutter/material.dart';

import 'package:jugaadkit/features/json_jugaad/engine/confidence.dart';
import 'package:jugaadkit/features/json_jugaad/models/json_jugaad_error.dart';
import 'package:jugaadkit/features/json_jugaad/models/processing_mode.dart';
import 'package:jugaadkit/features/json_jugaad/models/transformation_step.dart';
import 'package:jugaadkit/widgets/common/action_button.dart';

import 'processing_mode_selector.dart';
import 'transformation_status.dart';

class InputPanel extends StatelessWidget {
  const InputPanel({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.processingMode,
    required this.onProcessingModeChanged,
    this.onTryAs,
    this.isProcessing = false,
    this.transformationSteps = const [],
    this.showExplorerHint = false,
    this.detectionSummary,
    this.confidence = Confidence.none,
    this.showDetectionMeta = false,
    this.ambiguousError,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ProcessingMode processingMode;
  final ValueChanged<ProcessingMode> onProcessingModeChanged;
  final ValueChanged<ProcessingMode>? onTryAs;
  final bool isProcessing;
  final List<TransformationStep> transformationSteps;
  final bool showExplorerHint;
  final String? detectionSummary;
  final Confidence confidence;
  final bool showDetectionMeta;
  final JsonJugaadError? ambiguousError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showStatus = transformationSteps.isNotEmpty ||
        showExplorerHint ||
        showDetectionMeta ||
        (ambiguousError?.isAmbiguousAutoFailure ?? false);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                Text('Input', style: theme.textTheme.titleMedium),
                const Spacer(),
                if (isProcessing)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ProcessingModeSelector(
                  selectedMode: processingMode,
                  onModeChanged: onProcessingModeChanged,
                ),
                ActionButton(
                  label: 'Clear',
                  icon: Icons.clear,
                  onPressed: controller.text.isEmpty ? null : onClear,
                  tooltip: 'Clear input',
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
                decoration: const InputDecoration(
                  hintText: 'Paste your data here...',
                  alignLabelWithHint: true,
                ),
                keyboardType: TextInputType.multiline,
              ),
            ),
          ),
          if (showStatus)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: SingleChildScrollView(
                child: TransformationStatus(
                  steps: transformationSteps,
                  showExplorerHint: showExplorerHint,
                  detectionSummary: detectionSummary,
                  confidence: confidence,
                  showDetectionMeta: showDetectionMeta,
                  ambiguousError: ambiguousError,
                  onTryAs: onTryAs,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
