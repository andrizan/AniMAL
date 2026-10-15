import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:animal/core/constants/mal_endpoints.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/data/local/anilist_cache.dart';
import 'package:animal/data/local/anime_cache.dart';
import 'package:animal/data/local/app_database.dart';
import 'package:animal/data/mal/mal_api_client.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/shared/providers/airing_entry.dart';
import 'package:animal/shared/providers/anilist_providers.dart';
import 'package:animal/shared/providers/anime_list_providers.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

ResponseBody _json(Object body) => ResponseBody.fromString(
  jsonEncode(body),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

/// MAL, where the completed list holds anime 1 and 2 and the others are
/// empty.
class _MalAdapter implements HttpClientAdapter {
  final listStatuses = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path != MalEndpoints.animeList) {
      return _json({'data': <dynamic>[]});
    }
    final status = options.queryParameters['status'] as String;
    listStatuses.add(status);
    return _json({
      'data': [
        if (status == 'completed') ...[
          {
            'node': {
              'id': 1,
              'title': 'Anime 1',
              'my_list_status': {
                'status': 'completed',
                'num_episodes_watched': 12,
                'score': 9,
              },
            },
          },
          {
            'node': {
              'id': 2,
              'title': 'Anime 2',
              'my_list_status': {
                'status': 'completed',
                'num_episodes_watched': 24,
              },
            },
          },
        ],
      ],
      'paging': <String, dynamic>{},
    });
  }

  @override
  void close({bool force = false}) {}
}

/// AniList, which only counts how often it is asked.
class _AniListAdapter implements HttpClientAdapter {
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    return _json({
      'data': {
        'Page': {
          'pageInfo': {'hasNextPage': false},
          'airingSchedules': <dynamic>[],
        },
      },
    });
  }

  @override
  void close({bool force = false}) {}
}

class _FailingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString('{}', 500);

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  const limit = ApiConstants.malUserListPageSize;

  late AppDatabase appDb;
  late AnimeCache cache;
  late ProviderContainer container;
  late Dio malDio;
  late _MalAdapter mal;
  late _AniListAdapter anilist;

  setUp(() async {
    final tmp = Directory.systemTemp.createTempSync('refresh_list_');
    appDb = await AppDatabase.open(
      pathOverride: '${tmp.path}/test.db',
      runMigrations: false,
    );
    mal = _MalAdapter();
    anilist = _AniListAdapter();

    malDio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = mal;
    final anilistClient = AniListClient(
      cache: SqliteAniListCache(appDb),
      logger: Logger(level: Level.off),
    );
    anilistClient.dio.httpClientAdapter = anilist;

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(appDb),
        animeRepositoryProvider.overrideWith(
          (ref) => AnimeRepository(
            ref,
            MalApiClient(malDio),
            ref.watch(animeCacheProvider),
          ),
        ),
        anilistApiProvider.overrideWithValue(anilistClient),
      ],
    );
    cache = container.read(animeCacheProvider);
  });

  tearDown(() async {
    container.dispose();
    await appDb.close();
  });

  int currentWeekStartSec() {
    final now = DateTime.now().toUtc();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime.utc(monday.year, monday.month, monday.day);
    return weekStart.millisecondsSinceEpoch ~/ 1000;
  }

  test('refetches the list without touching the AniList schedule', () async {
    await cache.saveUserAnimeList('completed', limit, 0, [
      const Anime(id: 1, title: 'Stale'),
    ]);

    await container.read(refreshUserAnimeListProvider)(WatchStatus.completed);

    final list = await cache.getUserAnimeList('completed', limit, 0);
    expect(list!.map((a) => a.id).toList(), [1, 2]);
    expect(mal.listStatuses, ['completed']);
    expect(anilist.requests, 0);
  });

  test('copies the statuses it brought into the stored airing week', () async {
    final weekStartSec = currentWeekStartSec();
    final weekStart = DateTime.fromMillisecondsSinceEpoch(
      weekStartSec * 1000,
      isUtc: true,
    );
    AiringEntry entry(int anilistId, int malId, MyListStatus status) =>
        AiringEntry(
          anilistId: anilistId,
          malId: malId,
          title: 'Anime $malId',
          airingAt: weekStart.add(Duration(hours: anilistId)),
          episode: 1,
          timeUntilAiring: 0,
          myListStatus: status,
        );
    const stale = MyListStatus(status: WatchStatus.watching, score: 5);
    await container.read(airingCacheProvider).saveMergedWeek(weekStartSec, {
      'monday': [entry(100, 1, stale), entry(300, 3, stale)],
    });
    final sub = container.listen(weeklyAiringProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(weeklyAiringProvider.future);

    await container.read(refreshUserAnimeListProvider)(WatchStatus.completed);

    final week = await container.read(weeklyAiringProvider.future);
    final byMalId = {for (final e in week['monday']!) e.malId: e.myListStatus};
    expect(byMalId[1]?.status, WatchStatus.completed);
    expect(byMalId[1]?.score, 9);
    expect(byMalId[3], stale);
    expect(anilist.requests, 0);
  });

  test('a failing MAL fetch keeps the stored list', () async {
    await cache.saveUserAnimeList('completed', limit, 0, [
      const Anime(id: 1, title: 'Stale'),
    ]);
    malDio.httpClientAdapter = _FailingAdapter();

    await container.read(refreshUserAnimeListProvider)(WatchStatus.completed);

    final list = await cache.getUserAnimeList('completed', limit, 0);
    expect(list!.map((a) => a.id).toList(), [1]);
  });
}
