import 'dart:async';

import 'package:animal/core/notification/anime_notification_service.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/local/anime_cache.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/features/home/presentation/widgets/anime_home_tab.dart';
import 'package:animal/shared/providers/airing_entry.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:animal/shared/widgets/anime_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo extends Fake implements AnimeRepository {
  final loads = <WatchStatus>[];
  Completer<void>? gate;

  @override
  Future<List<Anime>> getUserAnimeList({
    WatchStatus status = WatchStatus.watching,
  }) async {
    loads.add(status);
    await gate?.future;
    return [
      for (final (i, name) in ['Charlie', 'alpha', 'Bravo'].indexed)
        Anime(
          id: status.index * 10 + i,
          title: '$name ${status.label}',
          mean: 7.0 + i,
          numEpisodes: 30 - i,
          myListStatus: MyListStatus(status: status),
        ),
    ];
  }
}

class _Cache extends Fake implements AnimeCache {
  final invalidated = <(String, int, int)>[];

  @override
  Future<void> invalidateUserAnimeList(
    String status,
    int limit,
    int offset,
  ) async {
    invalidated.add((status, limit, offset));
  }
}

class _Airing extends Fake implements AiringRepository {
  int refreshes = 0;

  @override
  Future<Map<String, List<AiringEntry>>> refreshWeeklySchedule() async {
    refreshes++;
    return {};
  }
}

class _Notifications extends Fake implements AnimeNotificationService {
  @override
  bool get permissionGranted => true;

  @override
  Set<int> get notificationIds => const {};
}

void main() {
  late _Repo repo;
  late _Cache cache;
  late _Airing airing;

  Future<void> open(
    WidgetTester tester, [
    Map<String, Object> prefs = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(prefs);
    repo = _Repo();
    cache = _Cache();
    airing = _Airing();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationServiceProvider.overrideWithValue(_Notifications()),
          airingByMalIdProvider.overrideWith((ref) async => {}),
          animeRepositoryProvider.overrideWithValue(repo),
          animeCacheProvider.overrideWithValue(cache),
          airingRepositoryProvider.overrideWithValue(airing),
        ],
        child: const MaterialApp(home: Scaffold(body: AnimeHomeTab())),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<String> titles(WidgetTester tester) => tester
      .widgetList<AnimeCard>(find.byType(AnimeCard))
      .map((c) => c.anime.title.split(' ').first)
      .toList();

  Future<String?> pref(String key) async =>
      (await SharedPreferences.getInstance()).get(key)?.toString();

  testWidgets('shows the five status tabs', (tester) async {
    await open(tester);

    for (final label in [
      'Watching',
      'Plan to Watch',
      'On Hold',
      'Completed',
      'Dropped',
    ]) {
      expect(find.widgetWithText(Tab, label), findsOneWidget, reason: label);
    }
  });

  testWidgets('starts on Watching sorted by name, ascending', (tester) async {
    await open(tester);

    expect(repo.loads, [WatchStatus.watching]);
    expect(titles(tester), ['alpha', 'Bravo', 'Charlie']);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
  });

  group('saved preferences', () {
    testWidgets('restore the sort field and direction', (tester) async {
      await open(tester, {'list_sort': 1, 'list_ascending': false});

      expect(find.text('Score'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      expect(titles(tester), ['Bravo', 'alpha', 'Charlie']);
    });

    testWidgets('restore the airing filter', (tester) async {
      await open(tester, {'airing_filter': 1});

      expect(find.text('Airing'), findsOneWidget);
      expect(find.text('No anime here yet'), findsOneWidget);
    });

    testWidgets('out-of-range values are clamped instead of crashing', (
      tester,
    ) async {
      await open(tester, {'list_sort': 99, 'airing_filter': 99});

      expect(tester.takeException(), isNull);
      expect(find.text('Airing'), findsWidgets);
      expect(find.text('Upcoming'), findsOneWidget);
    });
  });

  group('sorting controls', () {
    testWidgets('the arrow flips the order and is remembered', (tester) async {
      await open(tester);

      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      expect(titles(tester), ['Charlie', 'Bravo', 'alpha']);
      expect(await pref('list_ascending'), 'false');
    });

    testWidgets('the sort dropdown reorders the list and is remembered', (
      tester,
    ) async {
      await open(tester);

      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Episodes').last);
      await tester.pumpAndSettle();

      expect(titles(tester).first, 'Bravo');
      expect(await pref('list_sort'), '2');
    });

    testWidgets('the filter dropdown is remembered', (tester) async {
      await open(tester);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finished').last);
      await tester.pumpAndSettle();

      expect(await pref('airing_filter'), '2');
    });
  });

  testWidgets('opening another tab loads that status', (tester) async {
    await open(tester);

    await tester.tap(find.widgetWithText(Tab, 'Completed'));
    await tester.pumpAndSettle();

    expect(repo.loads, contains(WatchStatus.completed));
    expect(
      tester.widgetList<AnimeCard>(find.byType(AnimeCard)).first.anime.title,
      endsWith('Completed'),
    );
  });

  group('refresh', () {
    testWidgets('reloads the active list and the airing schedule', (
      tester,
    ) async {
      await open(tester);
      final before = repo.loads.length;

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();

      expect(repo.loads.length, greaterThan(before));
      expect(repo.loads.last, WatchStatus.watching);
      expect(airing.refreshes, 1);
      expect(cache.invalidated.single.$1, 'watching');
    });

    testWidgets('shows a spinner and ignores taps while refreshing', (
      tester,
    ) async {
      await open(tester);
      repo.gate = Completer<void>();

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byIcon(Icons.refresh), findsNothing);
      final button = find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Refresh',
      );
      expect(tester.widget<IconButton>(button).onPressed, isNull);

      repo.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(airing.refreshes, 1);
    });

    testWidgets('refreshes the tab that is open, not always Watching', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.widgetWithText(Tab, 'Dropped'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();

      expect(cache.invalidated.single.$1, 'dropped');
    });
  });
}
