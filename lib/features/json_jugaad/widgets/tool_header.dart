import 'package:flutter/material.dart';

import 'package:jugaadkit/features/json_jugaad/constants/json_jugaad_constants.dart';

class ToolHeader extends StatelessWidget {
  const ToolHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 2,
        children: [
          Text(
            JsonJugaadConstants.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              height: 1.15,
              color: theme.colorScheme.secondary,
            ),
          ),
          Text(
            JsonJugaadConstants.descriptor,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.15,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
