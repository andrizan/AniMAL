import 'package:animal/core/providers.dart';
import 'package:animal/core/router/app_router.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeAuthRepository()..authenticated = true;
    container = ProviderContainer(
      overrides: [malAuthRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  GoRouter router() => container.read(routerProvider);

  GoRoute? routeOf(String location) {
    final match = router().configuration.findMatch(Uri.parse(location));
    return match.isError ? null : match.last.route as GoRoute;
  }

  Future<void> pumpRouter(WidgetTester tester) async {
    container.read(authControllerProvider);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('route table', () {
    const named = {
      '/home': 'home',
      '/airing': 'airing',
      '/calendar': 'calendar',
      '/profile': 'profile',
      '/search': 'search',
      '/anime/5': 'animeDetail',
      '/character/7': 'characterProfile',
      '/staff/8': 'staffProfile',
      '/studio/9': 'studioProfile',
      '/login': 'login',
      '/oauth/callback?code=abc&state=xyz': 'oauthCallback',
    };

    for (final entry in named.entries) {
      test('${entry.key} is the ${entry.value} route', () {
        expect(routeOf(entry.key)?.name, entry.value);
      });
    }

    test('starts on the library tab', () {
      expect(router().routeInformationProvider.value.uri.path, '/home');
    });

    test('the path constants match the table', () {
      expect(routeOf(AppRoutes.login)?.name, 'login');
      expect(routeOf(AppRoutes.search)?.name, 'search');
      expect(routeOf('/anime/1')?.path, AppRoutes.animeDetail);
      expect(routeOf('/character/1')?.path, AppRoutes.characterProfile);
      expect(routeOf('/staff/1')?.path, AppRoutes.staffProfile);
      expect(routeOf('/studio/1')?.path, AppRoutes.studioProfile);
      expect(routeOf(AppRoutes.oauthCallback)?.name, 'oauthCallback');
    });

    test('the id is a path parameter', () {
      final match = router().configuration.findMatch(Uri.parse('/studio/42'));

      expect(match.pathParameters, {'id': '42'});
    });

    test('the OAuth callback keeps its query', () {
      final match = router().configuration.findMatch(
        Uri.parse('/oauth/callback?code=abc&state=xyz'),
      );

      expect(match.uri.queryParameters, {'code': 'abc', 'state': 'xyz'});
    });

    test('an unknown location is an error', () {
      expect(routeOf('/nowhere'), isNull);
      expect(routeOf('/anime'), isNull);
      expect(routeOf('/anime/5/extra'), isNull);
    });

    test('a name builds the matching path', () {
      expect(
        router().namedLocation('animeDetail', pathParameters: {'id': '9'}),
        '/anime/9',
      );
      expect(
        router().namedLocation('studioProfile', pathParameters: {'id': '3'}),
        '/studio/3',
      );
    });
  });

  group('ids that are not numbers', () {
    const pages = {
      '/anime/abc': 'anime',
      '/character/x1': 'character',
      '/staff/-': 'staff',
      '/studio/1.5': 'studio',
    };

    for (final entry in pages.entries) {
      testWidgets('${entry.key} says the ${entry.value} ID is invalid', (
        tester,
      ) async {
        router().go(entry.key);
        await pumpRouter(tester);

        expect(find.text('Invalid ${entry.value} ID'), findsOneWidget);
        expect(find.text('Invalid ID'), findsOneWidget);
      });
    }
  });

  group('signed out', () {
    setUp(() => repo.authenticated = false);

    testWidgets('a protected page leads to the login page', (tester) async {
      router().go('/anime/5');
      await pumpRouter(tester);

      expect(
        router().routerDelegate.currentConfiguration.uri.path,
        AppRoutes.login,
      );
      expect(find.text('Invalid anime ID'), findsNothing);
    });

    testWidgets('the home tab leads to the login page', (tester) async {
      await pumpRouter(tester);

      expect(
        router().routerDelegate.currentConfiguration.uri.path,
        AppRoutes.login,
      );
    });

    testWidgets('the OAuth callback stays reachable', (tester) async {
      router().go('/oauth/callback?code=abc&state=xyz');
      container.read(authControllerProvider);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router()),
        ),
      );
      await tester.pump();

      expect(
        router().routerDelegate.currentConfiguration.uri.path,
        AppRoutes.oauthCallback,
      );
    });
  });

  group('fadePage', () {
    GoRouter fadeRouter() => GoRouter(
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) =>
              fadePage(context, state, const Scaffold(body: Text('FIRST'))),
        ),
        GoRoute(
          path: '/second',
          pageBuilder: (context, state) =>
              fadePage(context, state, const Scaffold(body: Text('SECOND'))),
        ),
      ],
    );

    Future<GoRouter> show(WidgetTester tester) async {
      final r = fadeRouter();
      addTearDown(r.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: r));
      await tester.pumpAndSettle();
      return r;
    }

    CustomTransitionPage<void> topPage(WidgetTester tester) =>
        tester.widget<Navigator>(find.byType(Navigator)).pages.last
            as CustomTransitionPage<void>;

    double secondOpacity(WidgetTester tester) => tester
        .widget<FadeTransition>(
          find
              .ancestor(
                of: find.text('SECOND'),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;

    testWidgets('is a 200 ms fade both ways', (tester) async {
      await show(tester);

      final page = topPage(tester);

      expect(page.transitionDuration, const Duration(milliseconds: 200));
      expect(page.reverseTransitionDuration, const Duration(milliseconds: 200));
    });

    testWidgets('fades the new page in over 200 ms', (tester) async {
      final r = await show(tester);

      r.go('/second');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final halfway = secondOpacity(tester);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(halfway, greaterThan(0));
      expect(halfway, lessThan(1));
      expect(find.text('SECOND'), findsOneWidget);
      expect(secondOpacity(tester), 1);
    });

    testWidgets('is instant when the device asks for reduced motion', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final r = await show(tester);

      expect(topPage(tester).transitionDuration, Duration.zero);
      expect(topPage(tester).reverseTransitionDuration, Duration.zero);

      r.go('/second');
      await tester.pump();

      expect(find.text('SECOND'), findsOneWidget);
      expect(secondOpacity(tester), 1);
    });

    testWidgets('keeps one page per location', (tester) async {
      final r = await show(tester);

      r.go('/second');
      await tester.pumpAndSettle();
      final key = topPage(tester).key;
      r.go('/');
      await tester.pumpAndSettle();
      r.go('/second');
      await tester.pumpAndSettle();

      expect(topPage(tester).key, key);
    });
  });
}
