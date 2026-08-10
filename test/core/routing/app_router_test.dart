import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jugaadkit/core/routing/app_router.dart';
import 'package:jugaadkit/core/routing/app_routes.dart';
import 'package:jugaadkit/core/theme/app_theme.dart';
import 'package:jugaadkit/features/json_jugaad/view_models/json_jugaad_view_model.dart';

void main() {
  group('AppRoutes', () {
    test('routes are application-relative', () {
      for (final route in AppRoutes.knownRoutes) {
        expect(route.startsWith('/'), isTrue);
        expect(route.contains('github'), isFalse);
        expect(route.contains('http'), isFalse);
        expect(route.contains('aj2322001'), isFalse);
      }
    });
  });

  group('AppRouter', () {
    late JsonJugaadViewModel viewModel;
    late AppRouter appRouter;

    setUp(() {
      viewModel = JsonJugaadViewModel();
      appRouter = AppRouter(
        jsonJugaadViewModel: viewModel,
        onToggleTheme: () {},
      );
    });

    tearDown(() {
      viewModel.dispose();
    });

    Future<void> pumpRouter(
      WidgetTester tester, {
      String initialLocation = AppRoutes.home,
    }) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      appRouter.router.go(initialLocation);
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: appRouter.router,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('home route works', (tester) async {
      await pumpRouter(tester);

      expect(appRouter.router.state.uri.path, AppRoutes.home);
      expect(find.text('Tools'), findsOneWidget);
    });

    testWidgets('/data_jugaad works', (tester) async {
      await pumpRouter(tester, initialLocation: AppRoutes.dataJugaad);

      expect(appRouter.router.state.uri.path, AppRoutes.dataJugaad);
      expect(find.text('Input'), findsOneWidget);
      expect(find.text('Output'), findsOneWidget);
    });

    testWidgets('/jsonParser redirects to /data_jugaad', (tester) async {
      await pumpRouter(tester, initialLocation: AppRoutes.jsonParser);

      expect(appRouter.router.state.uri.path, AppRoutes.dataJugaad);
      expect(find.text('Input'), findsOneWidget);
    });

    testWidgets('unknown routes redirect to home', (tester) async {
      await pumpRouter(tester, initialLocation: '/unknown-route');

      expect(appRouter.router.state.uri.path, AppRoutes.home);
      expect(find.text('Tools'), findsOneWidget);
    });

    testWidgets('nested unknown routes redirect to home', (tester) async {
      await pumpRouter(tester, initialLocation: '/foo/bar');

      expect(appRouter.router.state.uri.path, AppRoutes.home);
      expect(find.text('Tools'), findsOneWidget);
    });

    testWidgets('internal navigation uses application routes', (tester) async {
      await pumpRouter(tester);

      await tester.tap(find.text('Data Jugaad'));
      await tester.pumpAndSettle();

      final location = appRouter.router.state.uri.toString();
      expect(location, AppRoutes.dataJugaad);
      expect(location.contains('github'), isFalse);
      expect(location.contains('http'), isFalse);
    });
  });
}
