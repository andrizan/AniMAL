import 'dart:async';

import 'package:animal/core/notification/anime_notification_service.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/models/anilist/anilist_models.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/data/models/broadcast.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/features/detail/presentation/screens/anime_detail_page.dart';
import 'package:animal/shared/providers/anilist_providers.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Repo extends Fake implements AnimeRepository {
  final updates = <Map<String, Object?>>[];
  int removals = 0;
  int refreshes = 0;
  Object? failure;
  AnimeDetail? refreshed;

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
    final error = failure;
    if (error != null) throw error;
    updates.add({'status': status, 'eps': numWatchedEpisodes, 'score': score});
    return MyListStatus(
      status: status ?? WatchStatus.watching,
      numEpisodesWatched: numWatchedEpisodes,
      score: score,
    );
  }

  @override
  Future<void> deleteAnimeFromList(int animeId) async {
    final error = failure;
    if (error != null) throw error;
    removals++;
  }

  @override
  Future<AnimeDetail?> refreshAnimeDetail(int animeId) async {
    refreshes++;
    final error = failure;
    if (error != null) throw error;
    return refreshed;
  }
}

class _Notifications extends Fake implements AnimeNotificationService {
  @override
  bool get permissionGranted => true;

  @override
  Set<int> get notificationIds => const {};
}

AnimeDetail _detail({
  MyListStatus? list,
  int? episodes = 12,
  String status = 'finished_airing',
}) => AnimeDetail(
  id: 1,
  title: 'Sousou no Frieren',
  mean: 9.314,
  rank: 1,
  numEpisodes: episodes,
  mediaType: 'tv',
  status: status,
  rating: 'pg_13',
  source: 'manga',
  synopsis: 'An elf outlives her party.',
  startDate: '2023-09-29',
  endDate: '2024-03-22',
  averageEpisodeDuration: 1560,
  startSeason: const StartSeason(year: 2023, season: 'fall'),
  broadcast: const Broadcast(dayOfWeek: 'friday', startTime: '23:00'),
  genres: const [
    Genre(id: 1, name: 'Adventure'),
    Genre(id: 2, name: 'Fantasy'),
  ],
  alternativeTitles: const AlternativeTitles(
    ja: '葬送のフリーレン',
    en: 'Frieren: Beyond Journey\'s End',
    synonyms: ['Frieren', ''],
  ),
  relatedAnime: const [
    RelatedAnime(
      node: AnimeNode(id: 2, title: 'Frieren Season 2'),
      relationTypeFormatted: 'Sequel',
    ),
  ],
  myListStatus: list,
);

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

void main() {
  late _Repo repo;

  Future<void> open(
    WidgetTester tester, {
    FutureOr<AnimeDetail?> Function()? detail,
    FutureOr<AniListAnimeExtra> Function()? extra,
  }) async {
    repo = _Repo();
    final overrides = <Override>[
      notificationServiceProvider.overrideWithValue(_Notifications()),
      animeRepositoryProvider.overrideWithValue(repo),
      animeDetailProvider(1)
          .overrideWith((ref) async => (detail ?? () => _detail())()),
      anilistAnimeExtraProvider(1).overrideWith(
        (ref) async => (extra ?? () => const AniListAnimeExtra())(),
      ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        retry: noProviderRetry,
        overrides: overrides,
        child: const MaterialApp(home: AnimeDetailPage(animeId: 1)),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('states', () {
    testWidgets('shows a spinner while loading', (tester) async {
      final gate = Completer<AnimeDetail?>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWithValue(_Notifications()),
            animeDetailProvider(1).overrideWith((ref) => gate.future),
            anilistAnimeExtraProvider(1)
                .overrideWith((ref) async => const AniListAnimeExtra()),
          ],
          child: const MaterialApp(home: AnimeDetailPage(animeId: 1)),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      gate.complete(_detail());
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('reports an unknown anime', (tester) async {
      await open(tester, detail: () => null);

      expect(find.text('Anime not found'), findsOneWidget);
    });

    testWidgets('shows the error and retries', (tester) async {
      var fail = true;
      await open(
        tester,
        detail: () {
          if (fail) throw Exception('offline');
          return _detail();
        },
      );
      expect(find.text('Failed to load anime detail'), findsOneWidget);

      fail = false;
      await tapVisible(tester, find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load anime detail'), findsNothing);
      expect(find.text('Synopsis'), findsOneWidget);
    });
  });

  group('information', () {
    testWidgets('shows the headline chips', (tester) async {
      await open(tester);

      expect(find.text('9.31'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('12 eps'), findsOneWidget);
      expect(find.text('TV'), findsOneWidget);
      expect(find.text('Finished'), findsOneWidget);
      expect(find.text('PG-13'), findsOneWidget);
    });

    testWidgets('hides the episode chip when the count is unknown', (
      tester,
    ) async {
      await open(tester, detail: () => _detail(episodes: 0));

      expect(find.textContaining('eps'), findsNothing);
    });

    testWidgets('lists alternative titles and skips empty synonyms', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('Alternative Titles'), findsOneWidget);
      expect(find.text('葬送のフリーレン'), findsOneWidget);
      expect(find.text('Japanese'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Synonym'), findsOneWidget);
    });

    testWidgets(
      'shows genres, broadcast, dates, season, duration, source, synopsis',
      (tester) async {
        await open(tester);
        await tester.dragUntilVisible(
          find.text('Synopsis'),
          find.byType(CustomScrollView),
          const Offset(0, -300),
        );

        expect(find.text('Adventure'), findsOneWidget);
        expect(find.text('Fantasy'), findsOneWidget);
        expect(find.text('Friday at 23:00 JST'), findsOneWidget);
        expect(
          find.text('Aired: Sep 29, 2023 to Mar 22, 2024'),
          findsOneWidget,
        );
        expect(find.text('Fall 2023'), findsOneWidget);
        expect(find.text('26m'), findsOneWidget);
        expect(find.text('Manga'), findsOneWidget);
        expect(find.text('An elf outlives her party.'), findsOneWidget);
      },
    );

    testWidgets('a running anime says Airing and omits the end date', (
      tester,
    ) async {
      await open(tester, detail: () => _detail().copyWith(endDate: null));

      expect(find.text('Airing: Sep 29, 2023'), findsOneWidget);
    });

    testWidgets('lists related anime', (tester) async {
      await open(tester);
      await tester.dragUntilVisible(
        find.text('Related Anime'),
        find.byType(CustomScrollView),
        const Offset(0, -300),
      );

      expect(find.text('Frieren Season 2'), findsOneWidget);
      expect(find.text('Sequel'), findsOneWidget);
    });
  });

  group('my list card', () {
    const watching = MyListStatus(
      status: WatchStatus.watching,
      numEpisodesWatched: 5,
      score: 7,
    );

    testWidgets('is absent for an anime that is not in the list', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('Change'), findsNothing);
      expect(find.text('Add to Watching'), findsOneWidget);
    });

    testWidgets('shows status, progress and score', (tester) async {
      await open(tester, detail: () => _detail(list: watching));

      expect(find.text('Watching'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
      expect(find.text('7'), findsWidgets);
      expect(find.text('Remove from List'), findsOneWidget);
    });

    testWidgets('+ and - change the watched episodes by one', (tester) async {
      await open(tester, detail: () => _detail(list: watching));

      await tapVisible(tester, find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      expect(repo.updates.last['eps'], 6);
      expect(find.text('Episodes updated to 6'), findsOneWidget);

      await tapVisible(tester, find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();
      expect(repo.updates.last['eps'], 5);
    });

    testWidgets('- is disabled at zero episodes', (tester) async {
      await open(
        tester,
        detail: () => _detail(
          list: const MyListStatus(
            status: WatchStatus.watching,
            numEpisodesWatched: 0,
          ),
        ),
      );

      final minus = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.remove_circle_outline),
      );
      expect(minus.onPressed, isNull);
    });

    testWidgets('+ is disabled once every episode is watched', (tester) async {
      await open(
        tester,
        detail: () => _detail(
          list: const MyListStatus(
            status: WatchStatus.watching,
            numEpisodesWatched: 12,
          ),
        ),
      );

      final plus = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.add_circle_outline),
      );
      expect(plus.onPressed, isNull);
    });

    testWidgets('typing an episode number submits it', (tester) async {
      await open(tester, detail: () => _detail(list: watching));

      await tester.enterText(find.byType(TextFormField), '9');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(repo.updates.last['eps'], 9);
    });

    testWidgets('changing the score saves it', (tester) async {
      await open(tester, detail: () => _detail(list: watching));

      await tapVisible(tester, find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('9').last);
      await tester.pumpAndSettle();

      expect(repo.updates.last['score'], 9);
      expect(find.text('Score set to 9'), findsOneWidget);
    });

    testWidgets('the status picker changes the status', (tester) async {
      await open(tester, detail: () => _detail(list: watching));

      await tapVisible(tester, find.text('Change'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('On Hold'));
      await tester.pumpAndSettle();

      expect(repo.updates.last['status'], WatchStatus.onHold);
      expect(find.text('Status changed to On Hold'), findsOneWidget);
    });

    testWidgets('completing sends every episode of a finished anime', (
      tester,
    ) async {
      await open(tester, detail: () => _detail(list: watching));

      await tapVisible(tester, find.text('Change'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Completed'));
      await tester.pumpAndSettle();

      expect(repo.updates.last['status'], WatchStatus.completed);
      expect(repo.updates.last['eps'], 12);
    });

    testWidgets('an airing anime cannot be marked completed', (tester) async {
      await open(
        tester,
        detail: () => _detail(list: watching, status: 'currently_airing'),
      );

      await tapVisible(tester, find.text('Change'));
      await tester.pumpAndSettle();

      expect(find.text('Only available for finished anime'), findsOneWidget);
      await tapVisible(tester, find.text('Completed'));
      await tester.pumpAndSettle();
      expect(repo.updates, isEmpty);
    });

    testWidgets('a failed save is reported', (tester) async {
      await open(tester, detail: () => _detail(list: watching));
      repo.failure = Exception('server down');

      await tapVisible(tester, find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed:'), findsOneWidget);
    });
  });

  group('add and remove', () {
    testWidgets('adds the anime to Watching', (tester) async {
      await open(tester);

      await tapVisible(tester, find.text('Add to Watching'));
      await tester.pumpAndSettle();

      expect(repo.updates.single['status'], WatchStatus.watching);
      expect(find.text('Added to Watching'), findsOneWidget);
      expect(find.text('Remove from List'), findsOneWidget);
    });

    testWidgets('removing asks for confirmation first', (tester) async {
      await open(
        tester,
        detail: () =>
            _detail(list: const MyListStatus(status: WatchStatus.watching)),
      );

      await tapVisible(tester, find.text('Remove from List'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Remove "Sousou no Frieren"'), findsOneWidget);
      await tapVisible(tester, find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repo.removals, 0);
    });

    testWidgets('confirming removes the anime', (tester) async {
      await open(
        tester,
        detail: () =>
            _detail(list: const MyListStatus(status: WatchStatus.watching)),
      );

      await tapVisible(tester, find.text('Remove from List'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Remove'));
      await tester.pumpAndSettle();

      expect(repo.removals, 1);
      expect(find.text('Removed from list'), findsOneWidget);
      expect(find.text('Add to Watching'), findsOneWidget);
    });

    testWidgets('a failed add is reported and nothing changes', (tester) async {
      await open(tester);
      repo.failure = Exception('server down');

      await tapVisible(tester, find.text('Add to Watching'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to add'), findsOneWidget);
      expect(find.text('Add to Watching'), findsOneWidget);
    });
  });

  group('AniList extras', () {
    AniListAnimeExtra people({int characters = 6, int staff = 6}) =>
        AniListAnimeExtra(
          people: AniListAnimePeople(
            characters: [
              for (var i = 1; i <= characters; i++)
                AniListCharacter(id: i, name: 'Character $i', role: 'MAIN'),
            ],
            staff: [
              for (var i = 1; i <= staff; i++)
                AniListStaff(id: i, name: 'Staff $i', role: 'Director'),
            ],
          ),
        );

    testWidgets('shows only four characters until See All is tapped', (
      tester,
    ) async {
      await open(tester, extra: people);
      await tester.dragUntilVisible(
        find.text('Characters & Voice Actors'),
        find.byType(CustomScrollView),
        const Offset(0, -300),
      );

      expect(find.text('Character 4'), findsOneWidget);
      expect(find.text('Character 5'), findsNothing);

      await tapVisible(tester, find.text('See All (6)'));
      expect(find.text('Character 6'), findsOneWidget);
      expect(find.text('Show Less'), findsOneWidget);
    });

    testWidgets('has no See All for four people or fewer', (tester) async {
      await open(tester, extra: () => people(characters: 4, staff: 2));

      expect(find.textContaining('See All'), findsNothing);
    });

    testWidgets('shows the next episode with its countdown', (tester) async {
      await open(
        tester,
        extra: () => AniListAnimeExtra(
          nextAiring: AniListNextAiring(
            airingAt: DateTime.now().add(const Duration(hours: 2)),
            episode: 7,
            timeUntilAiring: 7200,
          ),
        ),
      );

      expect(find.text('Next Episode'), findsOneWidget);
      expect(find.text('Episode 7'), findsOneWidget);
      expect(find.textContaining('2h 0m'), findsOneWidget);
    });

    testWidgets('groups external links and names them by site', (tester) async {
      await open(
        tester,
        extra: () => const AniListAnimeExtra(
          externalLinks: [
            AniListExternalLink(
              id: 1,
              url: 'https://official.test',
              site: 'Official Site',
              type: 'INFO',
            ),
            AniListExternalLink(
              id: 2,
              url: 'https://crunchyroll.test',
              site: 'Crunchyroll',
              type: 'STREAMING',
            ),
            AniListExternalLink(
              id: 3,
              url: 'https://x.test',
              site: 'Twitter',
              type: 'SOCIAL',
            ),
          ],
        ),
      );

      expect(find.text('External Links'), findsOneWidget);
      for (final site in ['Official Site', 'Crunchyroll', 'Twitter']) {
        expect(find.text(site), findsOneWidget, reason: site);
      }
    });

    testWidgets(
      'does not show an empty External Links header for unknown link types',
      (tester) async {
        await open(
          tester,
          extra: () => const AniListAnimeExtra(
            externalLinks: [
              AniListExternalLink(
                id: 1,
                url: 'https://x.test',
                site: 'Mystery',
              ),
            ],
          ),
        );

        expect(find.text('External Links'), findsNothing);
      },
    );

    testWidgets('shows the studios', (tester) async {
      await open(
        tester,
        extra: () => const AniListAnimeExtra(
          studios: [
            AniListStudio(id: 7, name: 'Madhouse', isAnimationStudio: true),
          ],
        ),
      );

      expect(find.text('Studios'), findsOneWidget);
      expect(find.text('Madhouse'), findsOneWidget);
    });

    testWidgets('a failing extra does not break the page', (tester) async {
      await open(tester, extra: () => throw Exception('anilist down'));

      expect(find.text('Sousou no Frieren'), findsWidgets);
      expect(find.text('Next Episode'), findsNothing);
    });
  });

  group('pull to refresh', () {
    testWidgets('refreshes from the network and shows the new data', (
      tester,
    ) async {
      await open(tester);
      repo.refreshed = _detail().copyWith(title: 'Renamed Title');

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();

      expect(repo.refreshes, 1);
      expect(find.text('Renamed Title'), findsWidgets);
    });

    testWidgets('a failed refresh keeps the cached page and says so', (
      tester,
    ) async {
      await open(tester);
      repo.failure = Exception('offline');

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('Refresh failed, showing cached data'), findsOneWidget);
      expect(find.text('Sousou no Frieren'), findsWidgets);
    });
  });
}
