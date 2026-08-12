import 'package:flutter/material.dart';

import 'app_credit.dart';
import 'app_header.dart';

class AppPageShell extends StatelessWidget {
  const AppPageShell({
    super.key,
    required this.onToggleTheme,
    required this.child,
  });

  final VoidCallback onToggleTheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeader(onToggleTheme: onToggleTheme),
          Expanded(child: child),
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Center(
              child: AppCredit(),
            ),
          ),
        ],
      ),
    );
  }
}
