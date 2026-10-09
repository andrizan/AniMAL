import 'dart:async';

import 'package:animal/core/notification/anime_notification_service.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/broadcast.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/season.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/features/airing/presentation/screens/anime_airing_page.dart';
import 'package:animal/features/home/presentation/widgets/anime_list_tab.dart';
import 'package:animal/features/search/presentation/screens/anime_search_page.dart';
import 'package:animal/features/seasonal/presentation/screens/anime_schedule_page.dart';
import 'package:animal/shared/providers/airing_entry.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:animal/shared/widgets/anime_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _FakeRepo extends Fake implements AnimeRepository {
  _FakeRepo(this.ref, this.anime);

  final Ref ref;
  final List<Anime> anime;
  int listLoads = 0;
  int seasonalLoads = 0;

  Future<List<Anime>> _load() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return List.of(anime);
  }

  @override
  Future<List<Anime>> getUserAnimeList({
    WatchStatus status = WatchStatus.watching,
  }) {
    listLoads++;
    return _load();
  }

  @override
  Future<List<Anime>> getSeasonalAnime({
    required int year,
    required Season season,
    int limit = 100,
  }) {
    seasonalLoads++;
    return _load();
  }

  @override
  Future<List<Anime>> searchAnime(String query, {int limit = 20}) => _load();

  @override
  Future<List<Anime>> getAnimeRanking({
    String rankingType = 'all',
    int limit = 20,
  }) async => const <Anime>[];

  @override
  Future<MyListStatus> updateAnimeListStatus(
    int animeId, {
    WatchStatus? status,
    int? numWatchedEpisodes,
    int? score,
    bool? isRewatching,
    int? priority,
    int? rewatchValue,
    String? comments,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final i = anime.indexWhere((a) => a.id == animeId);
    final old = anime[i].myListStatus!;
    final updated = old.copyWith(
      numEpisodesWatched: numWatchedEpisodes ?? old.numEpisodesWatched,
    );
    anime[i] = anime[i].copyWith(myListStatus: updated);
    ref.read(animeListVersionProvider.notifier).bump();
    return updated;
  }
}

List<Anime> _library() => [
  for (var i = 1; i <= 60; i++)
    Anime(
      id: i,
      title: 'Anime $i',
      numEpisodes: 12,
      broadcast: const Broadcast(dayOfWeek: 'monday', startTime: '10:00'),
      myListStatus: const MyListStatus(
        status: WatchStatus.watching,
        numEpisodesWatched: 0,
        score: 0,
      ),
    ),
];

void main() {
  late _FakeRepo repo;

  Future<void> pumpApp(
    WidgetTester tester,
    Widget body, {
    List<Override> overrides = const [],
  }) async {
    final library = _library();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationServiceProvider.overrideWithValue(
            AnimeNotificationService(),
          ),
          airingByMalIdProvider.overrideWith((ref) async => {}),
          animeRepositoryProvider.overrideWith((ref) {
            return repo = _FakeRepo(ref, library);
          }),
          ...overrides,
        ],
        child: MaterialApp(home: Scaffold(body: body)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder verticalScrollable() => find
      .byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      )
      .first;

  double scrollOffset(WidgetTester tester) =>
      tester.state<ScrollableState>(verticalScrollable()).position.pixels;

  Future<void> scrollDown(WidgetTester tester) async {
    await tester.drag(verticalScrollable(), const Offset(0, -1400));
    await tester.pumpAndSettle();
  }

  Finder firstVisibleCard(WidgetTester tester) {
    final height =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    for (final e in find.byType(AnimeCard).evaluate()) {
      final box = e.renderObject! as RenderBox;
      final centerY = box.localToGlobal(box.size.center(Offset.zero)).dy;
      if (centerY > 200 && centerY < height - 100) {
        return find.byWidget(e.widget);
      }
    }
    throw StateError('no fully visible AnimeCard');
  }

  bool listSpinnerVisible() => find
      .byType(CircularProgressIndicator)
      .evaluate()
      .any(
        (e) => find
            .ancestor(
              of: find.byWidget(e.widget),
              matching: find.byType(FilledButton),
            )
            .evaluate()
            .isEmpty,
      );

  /// Edits the first visible card through the real edit modal (+3 episodes,
  /// Save). Returns the edited anime id and whether a list-level loading
  /// spinner showed up while the save propagated.
  Future<({int id, bool sawSpinner})> saveViaModal(WidgetTester tester) async {
    final card = firstVisibleCard(tester);
    final id = tester.widget<AnimeCard>(card).anime.id;
    await tester.longPress(card);
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();
    }
    await tester.tap(find.text('Save'));
    var sawSpinner = false;
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 15));
      if (listSpinnerVisible()) sawSpinner = true;
    }
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    return (id: id, sawSpinner: sawSpinner);
  }

  testWidgets('home list: a save updates the card, keeps the scroll, '
      'and reloads the list once', (tester) async {
    await pumpApp(tester, const AnimeListTab(status: WatchStatus.watching));
    await scrollDown(tester);
    final before = scrollOffset(tester);

    final result = await saveViaModal(tester);

    expect(result.sawSpinner, isFalse);
    expect(scrollOffset(tester), before);
    expect(find.text('3/12 ep'), findsOneWidget);
    expect(repo.listLoads, 2);
  });

  testWidgets('calendar: a save keeps the list in place without a spinner', (
    tester,
  ) async {
    await pumpApp(tester, const AnimeSchedulePage());
    await scrollDown(tester);
    final before = scrollOffset(tester);

    final result = await saveViaModal(tester);

    expect(result.sawSpinner, isFalse);
    expect(scrollOffset(tester), before);
    expect(find.text('3/12 ep'), findsOneWidget);
  });

  testWidgets('search: a save keeps the results in place without a spinner', (
    tester,
  ) async {
    await pumpApp(tester, const AnimeSearchPage());
    await tester.enterText(find.byType(TextField), 'anime');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await scrollDown(tester);
    final before = scrollOffset(tester);

    final result = await saveViaModal(tester);

    expect(result.sawSpinner, isFalse);
    expect(scrollOffset(tester), before);
    expect(find.text('3/12 ep'), findsOneWidget);
  });

  testWidgets('airing: a save keeps the list in place without a spinner', (
    tester,
  ) async {
    final today = const [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ][DateTime.now().toUtc().weekday - 1];

    await pumpApp(
      tester,
      const AnimeAiringPage(),
      overrides: [
        weeklyAiringProvider.overrideWith((ref) async {
          ref.watch(animeListVersionProvider);
          final library = await ref
              .watch(animeRepositoryProvider)
              .getUserAnimeList();
          final airing = DateTime.now().toUtc().add(const Duration(hours: 3));
          return {
            today: [
              for (final a in library)
                AiringEntry(
                  anilistId: a.id,
                  malId: a.id,
                  title: a.title,
                  airingAt: airing,
                  episode: 3,
                  timeUntilAiring: 10800,
                  episodes: a.numEpisodes,
                  myListStatus: a.myListStatus,
                ),
            ],
          };
        }),
      ],
    );
    await scrollDown(tester);
    final before = scrollOffset(tester);

    final result = await saveViaModal(tester);

    expect(result.sawSpinner, isFalse);
    expect(scrollOffset(tester), before);
    expect(find.text('3/12 ep'), findsOneWidget);
  });
}
