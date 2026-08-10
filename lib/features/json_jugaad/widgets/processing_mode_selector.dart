import 'package:flutter/material.dart';

import 'package:jugaadkit/features/json_jugaad/models/processing_mode.dart';

class ProcessingModeSelector extends StatelessWidget {
  const ProcessingModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  final ProcessingMode selectedMode;
  final ValueChanged<ProcessingMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MenuAnchor(
      menuChildren: [
        for (final mode in ProcessingModeLabel.selectableModes)
          MenuItemButton(
            onPressed: () => onModeChanged(mode),
            child: Text(mode.menuLabel),
          ),
      ],
      builder: (context, controller, child) {
        return Tooltip(
          message: 'Processing mode',
          child: OutlinedButton.icon(
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            icon: const Icon(Icons.expand_more, size: 18),
            label: Text(selectedMode.menuLabel),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
              side: BorderSide(color: theme.colorScheme.outline),
            ),
          ),
        );
      },
    );
  }
}
