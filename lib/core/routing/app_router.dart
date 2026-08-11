import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/views/home_view.dart';
import 'app_routes.dart';
import 'deferred_data_jugaad_page.dart';

class AppRouter {
  AppRouter({required VoidCallback onToggleTheme})
      : _onToggleTheme = onToggleTheme;

  final VoidCallback _onToggleTheme;

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) => _noTransitionPage(
          state: state,
          child: HomeView(onToggleTheme: _onToggleTheme),
        ),
      ),
      GoRoute(
        path: AppRoutes.jsonParser,
        redirect: (context, state) => AppRoutes.dataJugaad,
      ),
      GoRoute(
        path: AppRoutes.dataJugaad,
        pageBuilder: (context, state) => _noTransitionPage(
          state: state,
          child: DeferredDataJugaadPage(onToggleTheme: _onToggleTheme),
        ),
      ),
      GoRoute(
        path: '/:path(.*)',
        redirect: (context, state) => AppRoutes.home,
      ),
    ],
  );

  static Page<void> _noTransitionPage({
    required GoRouterState state,
    required Widget child,
  }) {
    return NoTransitionPage<void>(
      key: state.pageKey,
      child: child,
    );
  }
}
