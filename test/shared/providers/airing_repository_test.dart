import 'dart:io';

import 'package:animal/core/providers.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/data/local/airing_cache.dart';
import 'package:animal/data/local/anilist_cache.dart';
import 'package:animal/data/local/app_database.dart';
import 'package:animal/data/local/sqlite_anime_cache.dart';
import 'package:animal/data/mal/mal_api_client.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/shared/providers/airing_entry.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/fake_adapter.dart';

int _weekStartSec() {
  final now = DateTime.now().toUtc();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  return DateTime.utc(
        monday.year,
        monday.month,
        monday.day,
      ).millisecondsSinceEpoch ~/
      1000;
}

Map<String, dynamic> _schedule({
  required int id,
  required int hoursFromWeekStart,
  int episode = 1,
  int? idMal,
  String romaji = 'Romaji',
  String? english,
  double? meanScore,
  int? episodes,
}) => {
  'id': id * 100 + episode,
  'airingAt': _weekStartSec() + hoursFromWeekStart * 3600,
  'episode': episode,
  'timeUntilAiring': 0,
  'media': {
    'id': id,
    'idMal': idMal,
    'title': {'romaji': romaji, 'english': english, 'native': null},
    'coverImage': {'medium': 'm$id.jpg', 'large': 'l$id.jpg'},
    'status': 'RELEASING',
    'episodes': episodes,
    'meanScore': meanScore,
    'genres': ['Action'],
    'format': 'TV',
  },
};

Map<String, dynamic> _malNode(
  int id,
  String title, {
  double? mean,
  int? eps,
  String? en,
  Map<String, dynamic>? list,
}) => {
  'node': {
    'id': id,
    'title': title,
    'mean': mean,
    'num_episodes': eps,
    'alternative_titles': {'en': en},
    'my_list_status': list,
  },
};

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase appDb;
  late SqliteAiringCache cache;
  late AniListClient anilist;
  late AiringRepository repo;
  late FakeAdapter anilistAdapter;
  late FakeAdapter malAdapter;
  late ProviderContainer container;
  var anilistPages = <Map<String, dynamic>>[];
  var anilistFails = false;
  var seasonal = <Map<String, dynamic>>[];
  var watching = <Map<String, dynamic>>[];
  var malFails = false;

  setUp(() async {
    final tmp = Directory.systemTemp.createTempSync('airing_repo_');
    appDb = await AppDatabase.open(
      pathOverride: '${tmp.path}/test.db',
      runMigrations: false,
    );
    cache = SqliteAiringCache(appDb);
    anilistPages = [];
    anilistFails = false;
    seasonal = [];
    watching = [];
    malFails = false;

    anilist = AniListClient(
      cache: SqliteAniListCache(appDb),
      logger: Logger(level: Level.off),
    );
    anilistAdapter = FakeAdapter((o) async {
      if (anilistFails) return const FakeResponse.json({}, status: 500);
      return FakeResponse.json({
        'data': {
          'Page': {
            'pageInfo': {'hasNextPage': false},
            'airingSchedules': anilistPages,
          },
        },
      });
    });
    anilist.dio.httpClientAdapter = anilistAdapter;

    malAdapter = FakeAdapter((o) async {
      if (malFails) return const FakeResponse.json({}, status: 500);
      if (o.path.contains('/anime/season/'))
        return FakeResponse.json({'data': seasonal});
      if (o.path.contains('/animelist'))
        return FakeResponse.json({'data': watching});
      return const FakeResponse.json({}, status: 404);
    });
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(appDb),
        animeRepositoryProvider.overrideWith(
          (ref) => AnimeRepository(
            ref,
            MalApiClient(fakeDio(malAdapter)),
            SqliteAnimeCache(appDb),
          ),
        ),
      ],
    );
    repo = AiringRepository(
      animeRepo: container.read(animeRepositoryProvider),
      anilistApi: anilist,
      cache: cache,
      logger: Logger(level: Level.off),
    );
  });

  tearDown(() async {
    container.dispose();
    await appDb.close();
  });

  Future<List<AiringEntry>> allEntries() async =>
      (await repo.refreshWeeklySchedule()).values.expand((l) => l).toList();

  group('merging AniList with MAL', () {
    test(
      'takes score, episode count and list status from MAL when ids match',
      () async {
        anilistPages = [
          _schedule(
            id: 1,
            hoursFromWeekStart: 10,
            idMal: 100,
            romaji: 'Sousou no Frieren',
            english: 'Frieren',
            meanScore: 90,
            episodes: 28,
          ),
        ];
        seasonal = [
          _malNode(
            100,
            'Sousou no Frieren',
            mean: 9.31,
            eps: 28,
            list: {'status': 'watching', 'num_episodes_watched': 3},
          ),
        ];

        final e = (await allEntries()).single;

        expect(e.malId, 100);
        expect(e.title, 'Frieren');
        expect(e.malScore, 9.31);
        expect(e.episodes, 28);
        expect(e.myListStatus?.status, WatchStatus.watching);
        expect(e.myListStatus?.numEpisodesWatched, 3);
      },
    );

    test('falls back to AniList numbers when MAL has no match', () async {
      anilistPages = [
        _schedule(
          id: 2,
          hoursFromWeekStart: 10,
          idMal: 999,
          meanScore: 80,
          episodes: 12,
        ),
      ];

      final e = (await allEntries()).single;

      expect(e.malScore, 80);
      expect(e.episodes, 12);
      expect(e.myListStatus, isNull);
    });

    test('finds the MAL entry by title when AniList has no MAL id', () async {
      anilistPages = [
        _schedule(
          id: 3,
          hoursFromWeekStart: 10,
          romaji: 'Dandadan',
          english: null,
        ),
      ];
      seasonal = [_malNode(500, 'dandadan', mean: 8.5, eps: 12)];

      final e = (await allEntries()).single;

      expect(e.malId, 500);
      expect(e.malScore, 8.5);
    });

    test('also matches the English title', () async {
      anilistPages = [
        _schedule(
          id: 4,
          hoursFromWeekStart: 10,
          romaji: 'Some Romaji',
          english: 'Solo Leveling',
        ),
      ];
      seasonal = [
        _malNode(
          501,
          'Ore dake Level Up na Ken',
          mean: 8.2,
          en: 'Solo Leveling',
        ),
      ];

      final e = (await allEntries()).single;

      expect(e.malId, 501);
    });

    test(
      'uses the user watching list when the seasonal list lacks the anime',
      () async {
        anilistPages = [_schedule(id: 5, hoursFromWeekStart: 10, idMal: 77)];
        watching = [
          _malNode(
            77,
            'Old Show',
            mean: 7.7,
            eps: 24,
            list: {'status': 'watching', 'num_episodes_watched': 10},
          ),
        ];

        final e = (await allEntries()).single;

        expect(e.malScore, 7.7);
        expect(e.myListStatus?.numEpisodesWatched, 10);
      },
    );

    test('still builds the week when MAL is unreachable', () async {
      malFails = true;
      anilistPages = [
        _schedule(id: 6, hoursFromWeekStart: 10, idMal: 1, meanScore: 70),
      ];

      final e = (await allEntries()).single;

      expect(e.malScore, 70);
    });
  });

  group('shaping the week', () {
    test('groups by weekday and sorts each day by air time', () async {
      anilistPages = [
        _schedule(id: 1, hoursFromWeekStart: 30, episode: 2),
        _schedule(id: 2, hoursFromWeekStart: 26),
        _schedule(id: 3, hoursFromWeekStart: 5),
      ];

      final week = await repo.refreshWeeklySchedule();

      expect(week['monday']!.map((e) => e.anilistId), [3]);
      expect(week['tuesday']!.map((e) => e.anilistId), [2, 1]);
    });

    test('keeps an anime that airs twice in the week as two entries', () async {
      anilistPages = [
        _schedule(id: 1, hoursFromWeekStart: 10, episode: 5),
        _schedule(id: 1, hoursFromWeekStart: 100, episode: 6),
      ];

      expect(await allEntries(), hasLength(2));
    });

    test('drops duplicate rows for the same episode', () async {
      anilistPages = [
        _schedule(id: 1, hoursFromWeekStart: 10, episode: 5),
        _schedule(id: 1, hoursFromWeekStart: 10, episode: 5),
      ];

      expect(await allEntries(), hasLength(1));
    });

    test('prefers the English title, then the romaji one', () async {
      anilistPages = [
        _schedule(
          id: 1,
          hoursFromWeekStart: 10,
          romaji: 'Romaji A',
          english: 'English A',
        ),
        _schedule(id: 2, hoursFromWeekStart: 11, romaji: 'Romaji B'),
      ];

      final titles = (await allEntries()).map((e) => e.title).toList();

      expect(titles, ['English A', 'Romaji B']);
    });
  });

  group('when AniList has nothing', () {
    test('keeps the previously cached week', () async {
      anilistPages = [_schedule(id: 1, hoursFromWeekStart: 10)];
      await repo.refreshWeeklySchedule();
      anilistPages = [];

      final week = await repo.refreshWeeklySchedule();

      expect(week.values.expand((l) => l), hasLength(1));
    });

    test('fails clearly when there is no cache either', () async {
      anilistPages = [];

      await expectLater(
        repo.refreshWeeklySchedule(),
        throwsA(isA<Exception>()),
      );
    });

    test('a failing AniList request keeps the cached week', () async {
      anilistPages = [_schedule(id: 1, hoursFromWeekStart: 10)];
      await repo.refreshWeeklySchedule();
      anilistFails = true;

      final week = await repo.refreshWeeklySchedule();

      expect(week.values.expand((l) => l), hasLength(1));
    });
  });

  group('reading the week', () {
    test('serves the cached week without touching the network', () async {
      anilistPages = [_schedule(id: 1, hoursFromWeekStart: 10)];
      await repo.refreshWeeklySchedule();
      final anilistCalls = anilistAdapter.requests.length;
      final malCalls = malAdapter.requests.length;

      final week = await repo.getWeeklySchedule();

      expect(week.values.expand((l) => l), hasLength(1));
      expect(anilistAdapter.requests.length, anilistCalls);
      expect(malAdapter.requests.length, malCalls);
    });

    test('builds the week on the first read and then reuses it', () async {
      anilistPages = [_schedule(id: 1, hoursFromWeekStart: 10)];

      await repo.getWeeklySchedule();
      final after = anilistAdapter.requests.length;
      await repo.getWeeklySchedule();

      expect(after, 1);
      expect(anilistAdapter.requests.length, 1);
    });

    test('merges concurrent first reads into one build', () async {
      anilistPages = [_schedule(id: 1, hoursFromWeekStart: 10)];

      await Future.wait([
        repo.getWeeklySchedule(),
        repo.getWeeklySchedule(),
        repo.getWeeklySchedule(),
      ]);

      expect(anilistAdapter.requests, hasLength(1));
    });

    test('recomputes the countdown from the stored air time', () async {
      anilistPages = [_schedule(id: 1, hoursFromWeekStart: 10)];
      await repo.refreshWeeklySchedule();

      final e = (await repo.getWeeklySchedule()).values.expand((l) => l).single;

      final expected = e.airingAt.difference(DateTime.now().toUtc()).inSeconds;
      expect((e.timeUntilAiring - expected).abs(), lessThan(5));
    });
  });

  group('AiringEntry', () {
    AiringEntry entry(int seconds) => AiringEntry(
      anilistId: 1,
      title: 't',
      airingAt: DateTime(2030),
      episode: 1,
      timeUntilAiring: seconds,
    );

    test('countdown formats days, hours and minutes', () {
      expect(entry(2 * 86400 + 5 * 3600).countdown, '2d 5h');
      expect(entry(3 * 3600 + 20 * 60).countdown, '3h 20m');
      expect(entry(45 * 60).countdown, '45m');
    });

    test('countdown is null once aired', () {
      expect(entry(0).countdown, isNull);
      expect(entry(-5).countdown, isNull);
    });

    test('isUrgent only inside the last six hours', () {
      expect(entry(0).isUrgent, isFalse);
      expect(entry(21599).isUrgent, isTrue);
      expect(entry(21600).isUrgent, isFalse);
    });
  });
}
