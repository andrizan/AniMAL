import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/shared/providers/airing_entry.dart';
import 'package:animal/shared/providers/anime_list_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Anime _anime(
  int id,
  String title, {
  double? mean,
  int? episodes,
  String? status,
}) => Anime(
  id: id,
  title: title,
  mean: mean,
  numEpisodes: episodes,
  status: status,
);

AiringEntry _airing(int malId, Duration fromNow) => AiringEntry(
  anilistId: malId,
  malId: malId,
  title: 'T$malId',
  airingAt: DateTime.now().toUtc().add(fromNow),
  episode: 1,
  timeUntilAiring: fromNow.inSeconds,
);

void main() {
  final library = [
    _anime(1, 'bleach', mean: 8.1, episodes: 366, status: 'finished_airing'),
    _anime(
      2,
      'Attack on Titan',
      mean: 9,
      episodes: 87,
      status: 'finished_airing',
    ),
    _anime(
      3,
      'Chainsaw Man',
      mean: 8.6,
      episodes: 12,
      status: 'currently_airing',
    ),
    _anime(4, 'Dandadan', episodes: 24, status: 'currently_airing'),
    _anime(5, 'Eden', status: 'not_yet_aired'),
  ];

  Future<SortedUserAnimeList> run({
    ListSort sortBy = ListSort.name,
    bool ascending = true,
    AiringFilter filter = AiringFilter.all,
    Map<int, AiringEntry> airing = const {},
    List<Anime>? items,
  }) async {
    final container = ProviderContainer(
      overrides: [
        userAnimeListProvider(WatchStatus.watching)
            .overrideWith((ref) async => items ?? library),
        airingByMalIdProvider.overrideWith((ref) async => airing),
      ],
    );
    addTearDown(container.dispose);
    return container.read(
      sortedUserAnimeListProvider((
        status: WatchStatus.watching,
        sortBy: sortBy,
        ascending: ascending,
        airingFilter: filter,
      )).future,
    );
  }

  List<int> ids(SortedUserAnimeList r) => r.anime.map((a) => a.id).toList();

  group('sort by name', () {
    test('is case-insensitive and ascending by default', () async {
      expect(ids(await run()), [2, 1, 3, 4, 5]);
    });

    test('can be reversed', () async {
      expect(ids(await run(ascending: false)), [5, 4, 3, 1, 2]);
    });
  });

  group('sort by score', () {
    test('ranks higher scores last when ascending, unrated as zero', () async {
      expect(ids(await run(sortBy: ListSort.score)).take(2), [4, 5]);
      expect(ids(await run(sortBy: ListSort.score)).last, 2);
    });

    test('puts the best scores first when descending', () async {
      expect(ids(await run(sortBy: ListSort.score, ascending: false)).take(3), [
        2,
        3,
        1,
      ]);
    });
  });

  group('sort by episodes', () {
    test('orders by episode count with unknown counts as zero', () async {
      expect(ids(await run(sortBy: ListSort.episodes)), [5, 3, 4, 2, 1]);
    });

    test('can be reversed', () async {
      expect(ids(await run(sortBy: ListSort.episodes, ascending: false)), [
        1,
        2,
        4,
        3,
        5,
      ]);
    });
  });

  group('sort by airing', () {
    final airing = {
      3: _airing(3, const Duration(hours: 30)),
      4: _airing(4, const Duration(hours: 2)),
    };

    test(
      'shows the soonest episode first and unscheduled anime last',
      () async {
        final result = await run(sortBy: ListSort.airing, airing: airing);

        expect(ids(result).take(2), [4, 3]);
        expect(ids(result).skip(2).toSet(), {1, 2, 5});
      },
    );

    test('keeps unscheduled anime last even when descending', () async {
      final result = await run(
        sortBy: ListSort.airing,
        ascending: false,
        airing: airing,
      );

      expect(ids(result).take(2), [3, 4]);
      expect(ids(result).skip(2).toSet(), {1, 2, 5});
    });

    test('hands the airing map back for the cards', () async {
      final result = await run(sortBy: ListSort.airing, airing: airing);

      expect(result.airingMap.keys.toSet(), {3, 4});
    });
  });

  group('airing filter', () {
    test('all keeps everything', () async {
      expect((await run()).anime, hasLength(5));
    });

    test('airing keeps only currently airing shows', () async {
      expect(ids(await run(filter: AiringFilter.airing)).toSet(), {3, 4});
    });

    test('finished keeps only finished shows', () async {
      expect(ids(await run(filter: AiringFilter.finished)).toSet(), {1, 2});
    });

    test('upcoming keeps only unreleased shows', () async {
      expect(ids(await run(filter: AiringFilter.upcoming)), [5]);
    });

    test('filters first, then sorts the remainder', () async {
      final result = await run(
        filter: AiringFilter.finished,
        sortBy: ListSort.score,
        ascending: false,
      );

      expect(ids(result), [2, 1]);
    });
  });

  test('sorting never reorders the source list', () async {
    final source = List<Anime>.of(library);

    await run(sortBy: ListSort.score, items: source);

    expect(source.map((a) => a.id), library.map((a) => a.id));
  });

  test('an empty list stays empty', () async {
    expect((await run(items: const [])).anime, isEmpty);
  });

  test('enum labels are shown to the user', () {
    expect(ListSort.values.map((s) => s.label), [
      'Name',
      'Score',
      'Episodes',
      'Airing',
    ]);
    expect(AiringFilter.values.map((f) => f.label), [
      'All',
      'Airing',
      'Finished',
      'Upcoming',
    ]);
  });
}
