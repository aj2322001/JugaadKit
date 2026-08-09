import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/views/home_view.dart';
import '../../features/json_jugaad/view_models/json_jugaad_view_model.dart';
import '../../features/json_jugaad/views/json_jugaad_view.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter({
    required JsonJugaadViewModel jsonJugaadViewModel,
    required VoidCallback onToggleTheme,
  })  : _jsonJugaadViewModel = jsonJugaadViewModel,
        _onToggleTheme = onToggleTheme;

  final JsonJugaadViewModel _jsonJugaadViewModel;
  final VoidCallback _onToggleTheme;

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => HomeView(onToggleTheme: _onToggleTheme),
      ),
      GoRoute(
        path: AppRoutes.jsonParser,
        builder: (context, state) => JsonJugaadView(
          viewModel: _jsonJugaadViewModel,
          onToggleTheme: _onToggleTheme,
        ),
      ),
    ],
  );
}
