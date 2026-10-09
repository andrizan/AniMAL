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
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/shared/providers/anilist_providers.dart';
import 'package:animal/shared/providers/anime_list_providers.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Tracker {
  final intervals = <String, (DateTime, DateTime)>{};

  Future<ResponseBody> track(
    String label,
    ResponseBody Function() respond,
  ) async {
    final start = DateTime.now();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    intervals[label] = (start, DateTime.now());
    return respond();
  }

  bool overlap(String a, String b) {
    final x = intervals[a]!;
    final y = intervals[b]!;
    return x.$1.isBefore(y.$2) && y.$1.isBefore(x.$2);
  }
}

ResponseBody _json(Object body) => ResponseBody.fromString(
  jsonEncode(body),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

class _MalAdapter implements HttpClientAdapter {
  _MalAdapter(this.tracker);

  final _Tracker tracker;
  final listStatuses = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    final isList = options.path == MalEndpoints.animeList;
    final status = options.queryParameters['status'] as String?;
    return tracker.track(isList ? 'mal:$status' : 'mal:other', () {
      if (isList) {
        listStatuses.add(status!);
        return _json({
          'data': [
            if (status == 'completed')
              for (final id in [1, 2])
                {
                  'node': {'id': id, 'title': 'Anime $id'},
                },
          ],
          'paging': <String, dynamic>{},
        });
      }
      return _json({'data': <dynamic>[]});
    });
  }

  @override
  void close({bool force = false}) {}
}

class _AniListAdapter implements HttpClientAdapter {
  _AniListAdapter(this.tracker);

  final _Tracker tracker;
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests++;
    return tracker.track(
      'anilist',
      () => _json({
        'data': {
          'Page': {
            'pageInfo': {'hasNextPage': false},
            'airingSchedules': [
              {
                'id': 1,
                'airingAt':
                    DateTime.now()
                        .toUtc()
                        .add(const Duration(hours: 5))
                        .millisecondsSinceEpoch ~/
                    1000,
                'episode': 3,
                'timeUntilAiring': 18000,
                'media': {
                  'id': 100,
                  'idMal': 1,
                  'title': {'romaji': 'Anime 1'},
                },
              },
            ],
          },
        },
      }),
    );
  }

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
  late _Tracker tracker;
  late _MalAdapter mal;
  late _AniListAdapter anilist;

  setUp(() async {
    final tmp = Directory.systemTemp.createTempSync('refresh_list_');
    appDb = await AppDatabase.open(
      pathOverride: '${tmp.path}/test.db',
      runMigrations: false,
    );
    tracker = _Tracker();
    mal = _MalAdapter(tracker);
    anilist = _AniListAdapter(tracker);

    final malDio = Dio(BaseOptions(baseUrl: 'https://example.test'))
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

  test('refetches the list and the schedule in parallel', () async {
    await cache.saveUserAnimeList('completed', limit, 0, [
      const Anime(id: 1, title: 'Stale'),
    ]);

    await container.read(refreshUserAnimeListProvider)(WatchStatus.completed);

    final list = await cache.getUserAnimeList('completed', limit, 0);
    expect(list!.map((a) => a.id).toList(), [1, 2]);
    expect(mal.listStatuses.where((s) => s == 'completed'), hasLength(1));
    expect(anilist.requests, greaterThanOrEqualTo(1));
    expect(tracker.overlap('anilist', 'mal:completed'), isTrue);
  });

  test('a failing AniList schedule still refreshes the list', () async {
    container.read(anilistApiProvider).dio.httpClientAdapter =
        _FailingAdapter();

    await container.read(refreshUserAnimeListProvider)(WatchStatus.completed);

    final list = await cache.getUserAnimeList('completed', limit, 0);
    expect(list!.map((a) => a.id).toList(), [1, 2]);
  });
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
