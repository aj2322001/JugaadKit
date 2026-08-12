import 'package:flutter/material.dart';

class AppCredit extends StatelessWidget {
  const AppCredit({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IgnorePointer(
      child: Text(
        'Made by Archit Joshi',
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 12.5,
          fontFamily: 'sans-serif',
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
          letterSpacing: 0.15,
          height: 1.2,
        ),
      ),
    );
  }
}
