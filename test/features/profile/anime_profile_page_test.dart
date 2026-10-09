import 'dart:async';

import 'package:animal/core/providers.dart';
import 'package:animal/data/models/mal_user.dart';
import 'package:animal/features/profile/presentation/screens/anime_profile_page.dart';
import 'package:animal/features/profile/providers/profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_auth_repository.dart';

const _stats = AnimeStatistics(
  numDaysWatched: 30.76,
  meanScore: 7.9,
  numItems: 166,
  numEpisodes: 2500,
  numItemsWatching: 3,
  numItemsCompleted: 120,
  numItemsOnHold: 1,
  numItemsDropped: 2,
  numItemsPlanToWatch: 40,
);

void main() {
  late FakeAuthRepository auth;
  String? openedRoute;

  Future<void> open(
    WidgetTester tester, {
    bool signedIn = true,
    FutureOr<MalUser?> Function()? user,
    Future<Map<String, dynamic>?> Function()? release,
    String version = '2.9.0',
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    PackageInfo.setMockInitialValues(
      appName: 'AniMAL',
      packageName: 'com.andrizan.animal',
      version: version,
      buildNumber: '1',
      buildSignature: '',
    );
    auth = FakeAuthRepository()..authenticated = signedIn;
    openedRoute = null;
    final overrides = <Override>[
      malAuthRepositoryProvider.overrideWithValue(auth),
      userInfoProvider.overrideWith(
        (ref) async =>
            (user ??
            () => const MalUser(
              id: 1,
              name: 'andrizan',
              animeStatistics: _stats,
            ))(),
      ),
      if (release != null) latestReleaseProvider.overrideWithValue(release),
    ];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => const Scaffold(body: AnimeProfilePage()),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, _) {
            openedRoute = '/login';
            return const Scaffold(body: Text('LOGIN PAGE'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        retry: noProviderRetry,
        overrides: overrides,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f.first);
    await tester.pumpAndSettle();
    await tester.tap(f.first);
    await tester.pumpAndSettle();
  }

  group('profile header', () {
    testWidgets('shows the user and their location', (tester) async {
      await open(
        tester,
        user: () =>
            const MalUser(id: 1, name: 'andrizan', location: 'Indonesia'),
      );

      expect(find.text('andrizan'), findsOneWidget);
      expect(find.text('Connected to MyAnimeList'), findsOneWidget);
      expect(find.text('Indonesia'), findsOneWidget);
    });

    testWidgets('shows a placeholder while loading', (tester) async {
      final gate = Completer<MalUser?>();
      SharedPreferences.setMockInitialValues({});
      auth = FakeAuthRepository()..authenticated = true;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            malAuthRepositoryProvider.overrideWithValue(auth),
            userInfoProvider.overrideWith((ref) => gate.future),
          ],
          child: const MaterialApp(home: Scaffold(body: AnimeProfilePage())),
        ),
      );
      await tester.pump();

      expect(find.text('Loading...'), findsOneWidget);
      gate.complete(const MalUser(id: 1, name: 'late'));
      await tester.pumpAndSettle();
      expect(find.text('late'), findsOneWidget);
    });

    testWidgets('shows the error and reloads on refresh', (tester) async {
      var fail = true;
      await open(
        tester,
        user: () {
          if (fail) throw Exception('offline');
          return const MalUser(id: 1, name: 'andrizan');
        },
      );
      expect(find.text('Failed to load profile'), findsOneWidget);

      fail = false;
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(find.text('andrizan'), findsOneWidget);
    });

    testWidgets('an anonymous profile (null user) shows no header', (
      tester,
    ) async {
      await open(tester, user: () => null);

      expect(find.text('Connected to MyAnimeList'), findsNothing);
      expect(find.text('Failed to load profile'), findsNothing);
    });
  });

  group('statistics', () {
    testWidgets('are shown with sensible precision when signed in', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('Statistics'), findsOneWidget);
      expect(find.text('30.8'), findsOneWidget);
      expect(find.text('7.90'), findsOneWidget);
      expect(find.text('166'), findsOneWidget);
      expect(find.text('2500'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
    });

    testWidgets('missing numbers fall back to zero or a dash', (tester) async {
      await open(
        tester,
        user: () =>
            const MalUser(id: 1, name: 'u', animeStatistics: AnimeStatistics()),
      );

      expect(find.text('-'), findsOneWidget);
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('are hidden when signed out', (tester) async {
      await open(tester, signedIn: false);

      expect(find.text('Statistics'), findsNothing);
    });

    testWidgets('are hidden when MAL returned none', (tester) async {
      await open(tester, user: () => const MalUser(id: 1, name: 'u'));

      expect(find.text('Days Watched'), findsNothing);
    });
  });

  group('settings', () {
    testWidgets('the account tile reflects the session', (tester) async {
      await open(tester);

      expect(find.text('Connected'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('signed out, the account tile opens login', (tester) async {
      await open(tester, signedIn: false);

      expect(find.text('Tap to login'), findsOneWidget);
      await tapVisible(tester, find.text('MyAnimeList Account'));

      expect(openedRoute, '/login');
    });

    testWidgets('signed in, the account tile does nothing', (tester) async {
      await open(tester);

      await tapVisible(tester, find.text('MyAnimeList Account'));

      expect(openedRoute, isNull);
    });

    testWidgets('the theme switch flips the theme and remembers it', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('Dark'), findsOneWidget);

      await tapVisible(tester, find.byType(Switch));

      expect(find.text('Light'), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getString('theme_mode'),
        'light',
      );
    });

    testWidgets('a saved light theme is shown', (tester) async {
      await open(tester, prefs: {'theme_mode': 'light'});

      expect(find.text('Light'), findsOneWidget);
    });

    testWidgets('About shows the installed version', (tester) async {
      await open(tester, version: '2.9.0');

      await tapVisible(tester, find.text('About'));

      expect(find.text('v2.9.0'), findsOneWidget);
      expect(find.text('Unofficial MyAnimeList client'), findsOneWidget);
    });
  });

  group('logout', () {
    testWidgets('signs out and confirms', (tester) async {
      await open(tester);

      await tapVisible(tester, find.text('Logout'));

      expect(auth.logouts, 1);
      expect(find.text('Logged out'), findsOneWidget);
      expect(find.text('Logout'), findsNothing);
    });

    testWidgets('is not offered when signed out', (tester) async {
      await open(tester, signedIn: false);

      expect(find.text('Logout'), findsNothing);
    });
  });

  group('check for update', () {
    Map<String, dynamic> release(String tag) => {
      'tag_name': tag,
      'html_url': 'https://github.com/andrizan/AniMAL/releases/tag/$tag',
      'body': 'What changed',
    };

    testWidgets('offers the new version with its notes', (tester) async {
      await open(tester, release: () async => release('v2.10.0'));

      await tapVisible(tester, find.text('Check for Update'));

      expect(find.text('Update Available'), findsOneWidget);
      expect(find.text('v2.9.0 → v2.10.0'), findsOneWidget);
      expect(find.text('What changed'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
    });

    testWidgets('Later dismisses the offer', (tester) async {
      await open(tester, release: () async => release('v2.10.0'));
      await tapVisible(tester, find.text('Check for Update'));

      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();

      expect(find.text('Update Available'), findsNothing);
    });

    testWidgets('says up to date on the latest version', (tester) async {
      await open(tester, release: () async => release('v2.9.0'));

      await tapVisible(tester, find.text('Check for Update'));

      expect(find.text('Up to Date'), findsOneWidget);
      expect(
        find.text('You are running the latest version (v2.9.0).'),
        findsOneWidget,
      );
    });

    testWidgets('never offers a downgrade to an older release', (tester) async {
      await open(
        tester,
        version: '2.10.0',
        release: () async => release('v2.9.0'),
      );

      await tapVisible(tester, find.text('Check for Update'));

      expect(find.text('Up to Date'), findsOneWidget);
      expect(find.text('Update Available'), findsNothing);
    });

    testWidgets('tells the user when the check could not be made', (
      tester,
    ) async {
      await open(tester, release: () async => null);

      await tapVisible(tester, find.text('Check for Update'));

      expect(find.text('Could not check for updates'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('reports an unexpected failure', (tester) async {
      await open(tester, release: () async => throw Exception('boom'));

      await tapVisible(tester, find.text('Check for Update'));

      expect(find.textContaining('Failed to check update'), findsOneWidget);
    });
  });
}
