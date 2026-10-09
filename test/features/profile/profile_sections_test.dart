import 'dart:async';

import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/data/models/mal_user.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/features/profile/presentation/widgets/profile_sections.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:animal/shared/widgets/section_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _stats = AnimeStatistics(
  numDaysWatched: 30.76,
  numDaysWatching: 2,
  numDaysCompleted: 27.5,
  numDaysOnHold: 0,
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

Future<void> _show(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _Repo extends Fake implements AnimeRepository {
  final lists = <WatchStatus, List<Anime>>{};
  Completer<void>? gate;
  var failing = false;
  var calls = 0;

  @override
  Future<List<Anime>> getUserAnimeList({
    WatchStatus status = WatchStatus.watching,
  }) async {
    calls++;
    await gate?.future;
    if (failing) throw Exception('offline');
    return lists[status] ?? const <Anime>[];
  }
}

Anime _anime(
  int id, {
  int score = 0,
  List<String> genres = const [],
  String? type,
  DateTime? updated,
}) => Anime(
  id: id,
  title: 'Anime $id',
  mediaType: type,
  genres: [
    for (var i = 0; i < genres.length; i++) Genre(id: i, name: genres[i]),
  ],
  myListStatus: MyListStatus(
    status: WatchStatus.completed,
    score: score,
    updatedAt: updated?.toIso8601String(),
  ),
);

void main() {
  group('LibrarySection', () {
    testWidgets('shows the total, each status with its share and the rates', (
      tester,
    ) async {
      await _show(tester, const LibrarySection(stats: _stats));

      expect(find.text('Library'), findsOneWidget);
      expect(find.text('166 anime'), findsOneWidget);
      expect(find.text('166'), findsOneWidget);
      for (final label in [
        'Watching',
        'Completed',
        'On Hold',
        'Dropped',
        'Plan to Watch',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('120'), findsOneWidget);
      expect(find.text('72%'), findsOneWidget);
      expect(find.text('24%'), findsOneWidget);
      expect(find.text('95%'), findsOneWidget);
      expect(find.text('19.8'), findsOneWidget);
      expect(find.text('Completion rate'), findsOneWidget);
      expect(find.text('Episodes per anime'), findsOneWidget);
    });

    testWidgets('only plan-to-watch titles means no rates to show', (
      tester,
    ) async {
      await _show(
        tester,
        const LibrarySection(
          stats: AnimeStatistics(numItems: 5, numItemsPlanToWatch: 5),
        ),
      );

      expect(find.text('5 anime'), findsOneWidget);
      expect(find.text('Completion rate'), findsNothing);
    });

    testWidgets('missing numbers count as zero and the total falls back', (
      tester,
    ) async {
      await _show(
        tester,
        const LibrarySection(
          stats: AnimeStatistics(numItemsCompleted: 4, numItemsDropped: 1),
        ),
      );

      expect(find.text('5 anime'), findsOneWidget);
      expect(find.text('80%'), findsNWidgets(2));
    });

    testWidgets('an empty library does not divide by zero', (tester) async {
      await _show(tester, const LibrarySection(stats: AnimeStatistics()));

      expect(find.text('0 anime'), findsOneWidget);
      expect(find.text('0%'), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('large totals are grouped', (tester) async {
      await _show(
        tester,
        const LibrarySection(
          stats: AnimeStatistics(numItems: 1234, numItemsCompleted: 1234),
        ),
      );

      expect(find.text('1,234 anime'), findsOneWidget);
    });
  });

  group('TimeInvestedSection', () {
    testWidgets('shows hours and the days of each status that has any', (
      tester,
    ) async {
      await _show(tester, const TimeInvestedSection(stats: _stats));

      expect(find.text('Time invested'), findsOneWidget);
      expect(find.text('738 hours'), findsOneWidget);
      expect(find.text('27.5d'), findsOneWidget);
      expect(find.text('2.0d'), findsOneWidget);
      expect(find.text('1.3d'), findsOneWidget);
      expect(find.text('On Hold'), findsNothing);
    });

    testWidgets('falls back to the sum of days when the total is missing', (
      tester,
    ) async {
      await _show(
        tester,
        const TimeInvestedSection(
          stats: AnimeStatistics(numDaysCompleted: 1, numDaysWatching: 1),
        ),
      );

      expect(find.text('48 hours'), findsOneWidget);
    });

    testWidgets('is hidden without any watch time', (tester) async {
      await _show(tester, const TimeInvestedSection(stats: AnimeStatistics()));

      expect(find.text('Time invested'), findsNothing);
    });
  });

  group('InsightsSection', () {
    late _Repo repo;

    setUp(() => repo = _Repo());

    Future<void> open(WidgetTester tester, {bool settle = true}) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [animeRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: InsightsSection()),
            ),
          ),
        ),
      );
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump();
      }
    }

    testWidgets('shows a progress card while the lists load', (tester) async {
      repo.gate = Completer<void>();

      await open(tester, settle: false);

      expect(find.text('Analyzing your list...'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      repo.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Analyzing your list...'), findsNothing);
    });

    testWidgets('reads every status list', (tester) async {
      await open(tester);

      expect(repo.calls, WatchStatus.values.length);
    });

    testWidgets('an empty library invites adding anime', (tester) async {
      await open(tester);

      expect(find.textContaining('Add anime to your lists'), findsOneWidget);
      expect(find.text('Score distribution'), findsNothing);
    });

    testWidgets('charts the whole library across every list', (tester) async {
      final recent = DateTime.now().subtract(const Duration(days: 1));
      repo.lists[WatchStatus.completed] = [
        _anime(
          1,
          score: 8,
          genres: ['Action', 'Drama'],
          type: 'tv',
          updated: recent,
        ),
        _anime(2, score: 8, genres: ['Action'], type: 'tv', updated: recent),
        _anime(3, score: 9, genres: ['Comedy'], type: 'movie'),
      ];
      repo.lists[WatchStatus.watching] = [
        _anime(4, genres: ['Action'], type: 'ona', updated: recent),
      ];

      await open(tester);

      expect(find.text('Score distribution'), findsOneWidget);
      expect(find.text('3 rated'), findsOneWidget);
      expect(find.text('Most given score: 8 (2 titles)'), findsOneWidget);
      expect(find.text('Top genres'), findsOneWidget);
      expect(find.text('3 genres'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Formats'), findsOneWidget);
      expect(find.text('3 types'), findsOneWidget);
      expect(find.text('Movie'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.textContaining('Titles by last update'), findsOneWidget);
    });

    testWidgets('without any score it says how to get a distribution', (
      tester,
    ) async {
      repo.lists[WatchStatus.planToWatch] = [_anime(1), _anime(2)];

      await open(tester);

      expect(find.text('0 rated'), findsOneWidget);
      expect(
        find.text('Rate anime to see how you score them.'),
        findsOneWidget,
      );
      expect(find.textContaining('Most given score'), findsNothing);
    });

    testWidgets('cards without data are left out', (tester) async {
      repo.lists[WatchStatus.completed] = [_anime(1, score: 7)];

      await open(tester);

      expect(find.text('Score distribution'), findsOneWidget);
      expect(find.text('Top genres'), findsNothing);
      expect(find.text('Formats'), findsNothing);
      expect(find.text('Activity'), findsNothing);
    });

    testWidgets('only the six most common genres are charted', (tester) async {
      repo.lists[WatchStatus.completed] = [
        for (var i = 0; i < 8; i++) _anime(i, genres: ['Genre $i'], score: 5),
        _anime(100, genres: ['Genre 0', 'Genre 1']),
      ];

      await open(tester);

      expect(find.text('8 genres'), findsOneWidget);
      expect(find.textContaining('Genre '), findsNWidgets(6));
      expect(find.text('Genre 0'), findsOneWidget);
      expect(find.text('Genre 7'), findsNothing);
    });

    testWidgets('a failure offers Retry which reloads every list', (
      tester,
    ) async {
      repo.failing = true;
      await open(tester);
      expect(find.text("Couldn't load your list insights"), findsOneWidget);
      final before = repo.calls;

      repo
        ..failing = false
        ..lists[WatchStatus.completed] = [_anime(1, score: 6)];
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't load your list insights"), findsNothing);
      expect(find.text('1 rated'), findsOneWidget);
      expect(repo.calls, greaterThan(before));
    });

    testWidgets('an edit refreshes the charts without a loading flash', (
      tester,
    ) async {
      repo.lists[WatchStatus.completed] = [_anime(1, score: 6)];
      await open(tester);
      expect(find.text('1 rated'), findsOneWidget);

      repo.lists[WatchStatus.completed] = [
        _anime(1, score: 6),
        _anime(2, score: 9),
      ];
      repo.gate = Completer<void>();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(InsightsSection)),
      );
      container.read(animeListVersionProvider.notifier).bump();
      await tester.pump();

      expect(find.text('Analyzing your list...'), findsNothing);
      expect(find.text('1 rated'), findsOneWidget);

      repo.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('2 rated'), findsOneWidget);
    });
  });

  group('SectionCard', () {
    testWidgets('shows its title and trailing caption', (tester) async {
      await _show(
        tester,
        const SectionCard(
          title: 'Title',
          trailing: 'caption',
          child: Text('body'),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('caption'), findsOneWidget);
      expect(find.text('body'), findsOneWidget);
    });

    testWidgets('works without a title', (tester) async {
      await _show(tester, const SectionCard(child: Text('body')));

      expect(find.text('body'), findsOneWidget);
    });
  });
}
