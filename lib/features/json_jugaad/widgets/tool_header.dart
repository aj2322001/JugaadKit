import 'package:flutter/material.dart';

import 'package:jugaadkit/features/json_jugaad/constants/json_jugaad_constants.dart';

class ToolHeader extends StatelessWidget {
  const ToolHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          JsonJugaadConstants.title,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Paste messy, escaped, or wrapped JSON — we\'ll clean it up.',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
