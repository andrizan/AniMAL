import 'dart:io';

import 'package:animal/data/local/anime_cache.dart';
import 'package:animal/data/local/app_database.dart';
import 'package:animal/data/local/sqlite_anime_cache.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase appDb;
  late AnimeCache cache;

  setUp(() async {
    final tmp = Directory.systemTemp.createTempSync('anime_cache_');
    appDb = await AppDatabase.open(
      pathOverride: '${tmp.path}/test.db',
      runMigrations: false,
    );
    cache = SqliteAnimeCache(appDb);
  });

  tearDown(() async {
    await appDb.close();
  });

  Anime makeAnime(
    int id, {
    String title = 'Test',
    List<Genre> genres = const [],
    MyListStatus? myListStatus,
  }) {
    return Anime(
      id: id,
      title: title,
      mainPicture: const MainPicture(medium: 'm.jpg', large: 'l.jpg'),
      mean: 7.5,
      rank: id,
      popularity: id * 10,
      numEpisodes: 12,
      status: 'finished_airing',
      rating: 'pg13',
      mediaType: 'tv',
      genres: genres,
      myListStatus: myListStatus,
    );
  }

  group('AnimeCache', () {
    test('search: save then read returns same list in order', () async {
      final list = [
        makeAnime(1, title: 'A'),
        makeAnime(2, title: 'B'),
        makeAnime(3, title: 'C'),
      ];
      await cache.saveSearchResults('Naruto', 20, list);
      final out = await cache.getSearchResults('Naruto', 20);
      expect(out, isNotNull);
      expect(out!.map((a) => a.id).toList(), [1, 2, 3]);
      expect(out[0].title, 'A');
    });

    test('freshness: getFetchedAt returns null for missing key', () async {
      expect(await cache.getFetchedAt('search_xyz_20'), isNull);
    });

    test('freshness: getFetchedAt returns DateTime after save', () async {
      await cache.saveSearchResults('foo', 10, [makeAnime(1)]);
      final ts = await cache.getFetchedAt('search_foo_10');
      expect(ts, isNotNull);
      expect(
        DateTime.now().difference(ts!).inSeconds.abs(),
        lessThan(5),
      );
    });

    test('seasonal: round-trip', () async {
      final list = [makeAnime(10), makeAnime(11)];
      await cache.saveSeasonalAnime(2026, 'winter', 50, list);
      final out = await cache.getSeasonalAnime(2026, 'winter', 50);
      expect(out!.map((a) => a.id).toList(), [10, 11]);
    });

    test('ranking: round-trip', () async {
      final list = [makeAnime(99)];
      await cache.saveAnimeRanking('all', 20, list);
      expect(
        (await cache.getAnimeRanking('all', 20))!.map((a) => a.id).toList(),
        [99],
      );
    });

    test('userlist: round-trip with offset', () async {
      final list = [makeAnime(7)];
      await cache.saveUserAnimeList('watching', 100, 0, list);
      expect(
        (await cache.getUserAnimeList('watching', 100, 0))!.map((a) => a.id),
        [7],
      );
    });

    test('anime shared by search and seasonal is a single row', () async {
      final list1 = [makeAnime(1, title: 'X')];
      final list2 = [makeAnime(1, title: 'X')];
      await cache.saveSearchResults('q1', 10, list1);
      await cache.saveSeasonalAnime(2025, 'spring', 10, list2);

      final count = Sqflite.firstIntValue(
        await appDb.raw.rawQuery('SELECT COUNT(*) FROM anime WHERE mal_id = 1'),
      );
      expect(count, 1);
    });

    test('detail: save then read preserves detail-only fields', () async {
      final detail = AnimeDetail(
        id: 42,
        title: 'Detail',
        mainPicture: const MainPicture(medium: 'm', large: 'l'),
        mean: 8.0,
        source: 'manga',
        synopsis: 'A test synopsis.',
        startDate: '2020-01-01',
        endDate: '2020-06-30',
        mediaType: 'tv',
        numScoringUsers: 100,
        genres: const [],
        startSeason: const StartSeason(year: 2020, season: 'winter'),
        averageEpisodeDuration: 1440,
      );
      await cache.saveAnimeDetail(detail);
      final out = await cache.getAnimeDetail(42);
      expect(out, isNotNull);
      expect(out!.synopsis, 'A test synopsis.');
      expect(out.source, 'manga');
      expect(out.startSeason?.year, 2020);
      expect(out.averageEpisodeDuration, 1440);
    });

    test('updateCachedAnimeListStatus updates embedded status without dropping cache', () async {
      final list = [makeAnime(1)];
      await cache.saveSearchResults('q', 10, list);

      // Manually craft a status
      final newStatus = MyListStatus(status: WatchStatus.completed, score: 9);
      await cache.updateCachedAnimeListStatus(1, newStatus);

      // Cache is still present
      final out = await cache.getSearchResults('q', 10);
      expect(out, isNotNull);
      expect(out!.first.myListStatus?.status, WatchStatus.completed);
      expect(out.first.myListStatus?.score, 9);
    });

    test('invalidateAnimeDetail removes only that detail key', () async {
      final d = AnimeDetail(
        id: 1,
        title: 'T',
        mainPicture: const MainPicture(),
      );
      await cache.saveAnimeDetail(d);
      expect(await cache.getFetchedAt('detail_1'), isNotNull);
      await cache.invalidateAnimeDetail(1);
      expect(await cache.getFetchedAt('detail_1'), isNull);
    });

    test('invalidateUserAnimeLists removes all userlist_* keys', () async {
      await cache.saveUserAnimeList('watching', 100, 0, [makeAnime(1)]);
      await cache.saveUserAnimeList('completed', 100, 0, [makeAnime(2)]);
      await cache.invalidateUserAnimeLists();
      expect(await cache.getFetchedAt('userlist_watching_100_0'), isNull);
      expect(await cache.getFetchedAt('userlist_completed_100_0'), isNull);
    });

    test('clearCachedAnimeListStatus sets columns to NULL', () async {
      final list = [
        makeAnime(
          1,
          myListStatus: MyListStatus(status: WatchStatus.watching),
        ),
      ];
      await cache.saveSearchResults('q', 10, list);
      await cache.clearCachedAnimeListStatus(1);
      final out = await cache.getSearchResults('q', 10);
      expect(out!.first.myListStatus, isNull);
    });

    test('search key normalization is stable', () async {
      final list = [makeAnime(1)];
      await cache.saveSearchResults('  NARUTO  ONE  ', 20, list);
      // 'naruto one' (trimmed/lowercased/collapsed)
      final out = await cache.getSearchResults('naruto one', 20);
      expect(out, isNotNull);
      expect(out!.length, 1);
    });

    test(
      'saving detail does not remove anime from other cached lists',
      () async {
        await cache.saveSearchResults('q', 20, [makeAnime(1), makeAnime(2)]);
        await cache.saveUserAnimeList('watching', 100, 0, [makeAnime(1)]);

        await cache.saveAnimeDetail(
          AnimeDetail(id: 1, title: 'Updated', synopsis: 'New synopsis'),
        );

        // REPLACE on the anime row used to cascade-delete the list memberships.
        final search = await cache.getSearchResults('q', 20);
        expect(search!.map((a) => a.id).toList(), [1, 2]);
        final userlist = await cache.getUserAnimeList('watching', 100, 0);
        expect(userlist!.map((a) => a.id).toList(), [1]);
      },
    );

    test('partial detail save preserves existing detail fields', () async {
      await cache.saveAnimeDetail(
        AnimeDetail(
          id: 5,
          title: 'Full',
          synopsis: 'Long synopsis',
          startDate: '2020-01-01',
          mean: 8.2,
          genres: const [Genre(id: 1, name: 'Action')],
        ),
      );

      await cache.saveAnimeDetail(AnimeDetail(id: 5, title: 'Full'));

      final out = await cache.getAnimeDetail(5);
      expect(out, isNotNull);
      expect(out!.synopsis, 'Long synopsis');
      expect(out.startDate, '2020-01-01');
      expect(out.mean, 8.2);
      expect(out.genres.map((g) => g.name), ['Action']);
    });

    test('empty genres in new data do not wipe cached genres', () async {
      await cache.saveSearchResults('q', 20, [
        makeAnime(1, genres: const [Genre(id: 2, name: 'Comedy')]),
      ]);
      await cache.saveSearchResults('q2', 20, [makeAnime(1)]);

      final out = await cache.getSearchResults('q', 20);
      expect(out![0].genres.map((g) => g.name), ['Comedy']);
    });

    test('null myListStatus in new data keeps cached status', () async {
      await cache.saveSearchResults('q', 20, [
        makeAnime(
          1,
          myListStatus: MyListStatus(status: WatchStatus.watching, score: 7),
        ),
      ]);
      await cache.saveSearchResults('q2', 20, [makeAnime(1)]);

      final out = await cache.getSearchResults('q', 20);
      expect(out![0].myListStatus?.status, WatchStatus.watching);
      expect(out[0].myListStatus?.score, 7);
    });
  });
}
