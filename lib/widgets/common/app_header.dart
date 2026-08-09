import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import 'app_logo.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = themeMode == ThemeMode.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxContentWidth,
          ),
          child: Row(
            children: [
              const AppLogo(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: theme.textTheme.titleLarge,
                    ),
                    Text(
                      AppConstants.tagline,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onToggleTheme,
                tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
                icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
