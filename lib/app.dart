import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

class JugaadKitApp extends StatefulWidget {
  const JugaadKitApp({super.key});

  @override
  State<JugaadKitApp> createState() => _JugaadKitAppState();
}

class _JugaadKitAppState extends State<JugaadKitApp> {
  late final AppRouter _appRouter;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(onToggleTheme: _toggleTheme);
  }

  void _toggleTheme() {
    setState(() {
      final platformBrightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      final isCurrentlyDark = switch (_themeMode) {
        ThemeMode.dark => true,
        ThemeMode.light => false,
        ThemeMode.system => platformBrightness == Brightness.dark,
      };
      _themeMode = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      routerConfig: _appRouter.router,
    );
  }
}
