import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/json_jugaad/view_models/json_jugaad_view_model.dart';
import 'features/json_jugaad/views/json_jugaad_view.dart';

class JugaadKitApp extends StatefulWidget {
  const JugaadKitApp({super.key});

  @override
  State<JugaadKitApp> createState() => _JugaadKitAppState();
}

class _JugaadKitAppState extends State<JugaadKitApp> {
  late final JsonJugaadViewModel _jsonJugaadViewModel;
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _jsonJugaadViewModel = JsonJugaadViewModel();
  }

  @override
  void dispose() {
    _jsonJugaadViewModel.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: JsonJugaadView(
        viewModel: _jsonJugaadViewModel,
        themeMode: _themeMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}
