import 'dart:async';

import 'package:animal/core/providers.dart';
import 'package:animal/data/models/mal_user.dart';
import 'package:animal/features/profile/domain/entities/profile_insights.dart';
import 'package:animal/features/profile/presentation/screens/anime_profile_page.dart';
import 'package:animal/features/profile/presentation/widgets/profile_header.dart';
import 'package:animal/features/profile/presentation/widgets/profile_sections.dart';
import 'package:animal/features/profile/providers/profile_providers.dart';
import 'package:flutter/services.dart';
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
  numDaysWatching: 2,
  numDaysCompleted: 27.5,
  numDaysDropped: 1.26,
  meanScore: 7.9,
  numItems: 166,
  numEpisodes: 2500,
  numItemsWatching: 3,
  numItemsCompleted: 120,
  numItemsOnHold: 1,
  numItemsDropped: 2,
  numItemsPlanToWatch: 40,
);

const _noInsights = ProfileInsights(
  totalCount: 0,
  scoreCounts: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  genres: [],
  formats: [],
  activity: [],
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
    ProfileInsights insights = _noInsights,
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
      profileInsightsProvider.overrideWith((ref) async => insights),
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
            profileInsightsProvider.overrideWith((ref) async => _noInsights),
          ],
          child: const MaterialApp(home: Scaffold(body: AnimeProfilePage())),
        ),
      );
      await tester.pump();

      expect(find.byType(ProfileHeaderPlaceholder), findsOneWidget);
      gate.complete(const MalUser(id: 1, name: 'late'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileHeaderPlaceholder), findsNothing);
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

  group('header details', () {
    testWidgets('shows when the user joined and the three headline numbers', (
      tester,
    ) async {
      await open(
        tester,
        user: () => const MalUser(
          id: 1,
          name: 'andrizan',
          joinedAt: '2019-03-12T09:41:05+00:00',
          animeStatistics: _stats,
        ),
      );

      expect(find.textContaining('Since '), findsOneWidget);
      expect(find.textContaining('2019'), findsOneWidget);
      expect(find.text('30.8'), findsOneWidget);
      expect(find.text('Days watched'), findsOneWidget);
      expect(find.text('2,500'), findsOneWidget);
      expect(find.text('Episodes'), findsOneWidget);
      expect(find.text('7.90'), findsOneWidget);
      expect(find.text('Mean score'), findsOneWidget);
    });

    testWidgets('a user without a join date or location omits those pills', (
      tester,
    ) async {
      await open(tester, user: () => const MalUser(id: 1, name: 'andrizan'));

      expect(find.textContaining('Since '), findsNothing);
      expect(find.byIcon(Icons.location_on_outlined), findsNothing);
      expect(find.text('Connected to MyAnimeList'), findsOneWidget);
    });

    testWidgets('missing headline numbers fall back to zero or a dash', (
      tester,
    ) async {
      await open(
        tester,
        user: () =>
            const MalUser(id: 1, name: 'u', animeStatistics: AnimeStatistics()),
      );

      expect(find.text('-'), findsOneWidget);
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('a user without statistics has no headline numbers', (
      tester,
    ) async {
      await open(tester, user: () => const MalUser(id: 1, name: 'u'));

      expect(find.text('Days watched'), findsNothing);
      expect(find.byType(LibrarySection), findsNothing);
      expect(find.byType(TimeInvestedSection), findsNothing);
    });
  });

  group('statistics and charts', () {
    testWidgets('are shown for a signed in user', (tester) async {
      await open(tester);

      expect(find.byType(LibrarySection), findsOneWidget);
      expect(find.byType(TimeInvestedSection), findsOneWidget);
      expect(find.byType(InsightsSection), findsOneWidget);
      expect(find.text('166 anime'), findsOneWidget);
      expect(find.text('738 hours'), findsOneWidget);
    });

    testWidgets('the insight charts appear once the lists are analysed', (
      tester,
    ) async {
      await open(
        tester,
        insights: ProfileInsights(
          totalCount: 4,
          scoreCounts: const [0, 0, 0, 0, 0, 0, 1, 2, 0, 0],
          genres: const [CountEntry('Action', 3)],
          formats: const [CountEntry('TV', 4)],
          activity: [
            MonthActivity(month: DateTime(2026, 9), count: 2),
            MonthActivity(month: DateTime(2026, 10), count: 1),
          ],
        ),
      );

      expect(find.text('Score distribution'), findsOneWidget);
      expect(find.text('Top genres'), findsOneWidget);
      expect(find.text('Formats'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
    });

    testWidgets('are replaced by a login prompt when signed out', (
      tester,
    ) async {
      await open(tester, signedIn: false);

      expect(find.byType(LibrarySection), findsNothing);
      expect(find.byType(InsightsSection), findsNothing);
      expect(find.byType(ProfileHeader), findsNothing);
      expect(find.text('Connect MyAnimeList'), findsOneWidget);
    });

    testWidgets('the login prompt opens the login page', (tester) async {
      await open(tester, signedIn: false);

      await tapVisible(tester, find.text('Log in'));

      expect(openedRoute, '/login');
    });

    testWidgets('a user MAL returned nothing for shows no charts', (
      tester,
    ) async {
      await open(tester, user: () => null);

      expect(find.byType(LibrarySection), findsNothing);
      expect(find.byType(InsightsSection), findsNothing);
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
    const launcher = MethodChannel('plugins.flutter.io/url_launcher');
    late List<MethodCall> launched;

    setUp(() {
      launched = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(launcher, (call) async {
            launched.add(call);
            return true;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(launcher, null);
    });

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
      expect(launched, isEmpty);
    });

    testWidgets('Download opens the release page in the browser', (
      tester,
    ) async {
      await open(tester, release: () async => release('v2.10.0'));
      await tapVisible(tester, find.text('Check for Update'));

      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();

      expect(find.text('Update Available'), findsNothing);
      final call = launched.single;
      expect(call.method, 'launch');
      final args = call.arguments as Map;
      expect(
        args['url'],
        'https://github.com/andrizan/AniMAL/releases/tag/v2.10.0',
      );
      expect(args['useWebView'], isFalse);
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
