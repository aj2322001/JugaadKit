import 'package:flutter/material.dart';

import 'package:jugaadkit/features/json_jugaad/models/transformation_step.dart';
import 'package:jugaadkit/widgets/common/action_button.dart';

import 'transformation_status.dart';

class InputPanel extends StatelessWidget {
  const InputPanel({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.isProcessing = false,
    this.transformationSteps = const [],
    this.showExplorerHint = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isProcessing;
  final List<TransformationStep> transformationSteps;
  final bool showExplorerHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  hintText: 'Paste JSON here…',
                  alignLabelWithHint: true,
                ),
                keyboardType: TextInputType.multiline,
              ),
            ),
          ),
          if (transformationSteps.isNotEmpty || showExplorerHint)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: SingleChildScrollView(
                child: TransformationStatus(
                  steps: transformationSteps,
                  showExplorerHint: showExplorerHint,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
