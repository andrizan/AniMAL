import 'package:animal/core/providers.dart';
import 'package:animal/core/router/app_router.dart';
import 'package:animal/features/airing/presentation/screens/anime_airing_page.dart';
import 'package:animal/features/auth/presentation/login_page.dart';
import 'package:animal/features/auth/presentation/oauth_callback_page.dart';
import 'package:animal/features/detail/presentation/screens/anime_detail_page.dart';
import 'package:animal/features/detail/presentation/screens/character_staff_page.dart';
import 'package:animal/features/detail/presentation/screens/studio_page.dart';
import 'package:animal/features/home/presentation/widgets/anime_home_tab.dart';
import 'package:animal/features/profile/presentation/screens/anime_profile_page.dart';
import 'package:animal/features/search/presentation/screens/anime_search_page.dart';
import 'package:animal/features/seasonal/presentation/screens/anime_schedule_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GoRouter router;
  late BuildContext context;

  setUp(() {
    final container = ProviderContainer(
      overrides: [
        malAuthRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      ],
    );
    addTearDown(container.dispose);
    router = container.read(routerProvider);
  });

  Future<void> mountContext(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
  }

  /// What the route at [location] builds, without building it.
  Object pageAt(String location) {
    final match = router.configuration.findMatch(Uri.parse(location));
    final route = match.last.route as GoRoute;
    final state = GoRouterState(
      router.configuration,
      uri: match.uri,
      matchedLocation: match.uri.path,
      name: route.name,
      path: route.path,
      fullPath: match.fullPath,
      pathParameters: match.pathParameters,
      pageKey: ValueKey(location),
    );
    final pageBuilder = route.pageBuilder;
    if (pageBuilder != null) {
      return (pageBuilder(context, state) as CustomTransitionPage<void>).child;
    }
    return route.builder!(context, state);
  }

  group('tabs', () {
    final tabs = <String, Type>{
      '/home': AnimeHomeTab,
      '/airing': AnimeAiringPage,
      '/calendar': AnimeSchedulePage,
      '/profile': AnimeProfilePage,
    };

    for (final entry in tabs.entries) {
      testWidgets('${entry.key} is the ${entry.value} page', (tester) async {
        await mountContext(tester);

        expect(pageAt(entry.key).runtimeType, entry.value);
      });
    }
  });

  group('full screen pages', () {
    testWidgets('search and login have no parameters', (tester) async {
      await mountContext(tester);

      expect(pageAt('/search'), isA<AnimeSearchPage>());
      expect(pageAt('/login'), isA<LoginPage>());
    });

    testWidgets('the anime id reaches the detail page', (tester) async {
      await mountContext(tester);

      expect((pageAt('/anime/5') as AnimeDetailPage).animeId, 5);
      expect((pageAt('/anime/12345') as AnimeDetailPage).animeId, 12345);
    });

    testWidgets('each profile page gets its own id', (tester) async {
      await mountContext(tester);

      expect((pageAt('/character/7') as CharacterProfilePage).characterId, 7);
      expect((pageAt('/staff/8') as StaffProfilePage).staffId, 8);
      expect((pageAt('/studio/9') as StudioProfilePage).studioId, 9);
    });

    testWidgets('an id that is not a number builds the invalid page', (
      tester,
    ) async {
      await mountContext(tester);

      for (final location in [
        '/anime/x',
        '/character/x',
        '/staff/x',
        '/studio/x',
      ]) {
        expect(pageAt(location), isA<Scaffold>(), reason: location);
      }
    });

    testWidgets('the OAuth callback receives the code and state', (
      tester,
    ) async {
      await mountContext(tester);

      final page =
          pageAt('/oauth/callback?code=abc&state=xyz') as OAuthCallbackPage;

      expect(page.code, 'abc');
      expect(page.state, 'xyz');
    });

    testWidgets('an OAuth callback without a query has neither', (
      tester,
    ) async {
      await mountContext(tester);

      final page = pageAt('/oauth/callback') as OAuthCallbackPage;

      expect(page.code, isNull);
      expect(page.state, isNull);
    });
  });
}
