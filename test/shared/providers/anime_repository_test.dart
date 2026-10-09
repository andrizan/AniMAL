import 'dart:io';
import 'dart:typed_data';

import 'package:animal/core/network/api_exception.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/local/anime_cache.dart';
import 'package:animal/data/local/app_database.dart';
import 'package:animal/data/local/sqlite_anime_cache.dart';
import 'package:animal/data/mal/mal_api_client.dart';
import 'package:animal/data/models/season.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/fake_adapter.dart';

Map<String, dynamic> _list(List<int> ids) => {
  'data': [
    for (final id in ids)
      {
        'node': {'id': id, 'title': 'Anime $id'},
      },
  ],
};

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase appDb;
  late AnimeCache cache;
  late ProviderContainer container;
  late FakeAdapter adapter;
  late AnimeRepository repo;
  FakeResponse Function(RequestOptions o) respond = (_) =>
      const FakeResponse.json({});

  int calls(String pathPart) =>
      adapter.requests.where((o) => o.path.contains(pathPart)).length;

  setUp(() async {
    final tmp = Directory.systemTemp.createTempSync('anime_repo_');
    appDb = await AppDatabase.open(
      pathOverride: '${tmp.path}/test.db',
      runMigrations: false,
    );
    cache = SqliteAnimeCache(appDb);
    respond = (_) => FakeResponse.json(_list([1, 2]));
    adapter = FakeAdapter((o) async {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      return respond(o);
    });
    final dio = fakeDio(adapter);
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(appDb),
        animeRepositoryProvider.overrideWith(
          (ref) => AnimeRepository(ref, MalApiClient(dio), cache),
        ),
      ],
    );
    repo = container.read(animeRepositoryProvider);
  });

  tearDown(() async {
    container.dispose();
    await appDb.close();
  });

  group('search', () {
    test('sends the query and caches the result per query', () async {
      final first = await repo.searchAnime('naruto');
      final again = await repo.searchAnime('naruto');

      expect(first.map((a) => a.id), [1, 2]);
      expect(again.map((a) => a.id), [1, 2]);
      expect(calls('/anime'), 1);
      expect(adapter.requests.single.queryParameters['q'], 'naruto');
      expect(adapter.requests.single.queryParameters['limit'], 20);
    });

    test('treats different queries as different cache entries', () async {
      await repo.searchAnime('naruto');
      await repo.searchAnime('bleach');

      expect(calls('/anime'), 2);
    });

    test('merges concurrent identical searches into one request', () async {
      await Future.wait([
        repo.searchAnime('x'),
        repo.searchAnime('x'),
        repo.searchAnime('x'),
      ]);

      expect(calls('/anime'), 1);
    });
  });

  group('seasonal', () {
    test('requests the season endpoint and caches the list', () async {
      await repo.getSeasonalAnime(year: 2026, season: Season.fall);
      await repo.getSeasonalAnime(year: 2026, season: Season.fall);

      expect(calls('/anime/season/2026/fall'), 1);
    });

    test(
      'a season that is not published yet is an empty cached list',
      () async {
        respond = (_) => const FakeResponse.json({}, status: 404);

        final first = await repo.getSeasonalAnime(
          year: 2030,
          season: Season.winter,
        );
        final second = await repo.getSeasonalAnime(
          year: 2030,
          season: Season.winter,
        );

        expect(first, isEmpty);
        expect(second, isEmpty);
        expect(calls('/season/'), 1);
      },
    );

    test('other failures are not swallowed', () async {
      respond = (_) => const FakeResponse.json({}, status: 500);

      await expectLater(
        repo.getSeasonalAnime(year: 2026, season: Season.fall),
        throwsA(
          isA<ServerException>().having((e) => e.statusCode, 'status', 500),
        ),
      );
    });
  });

  test('ranking sends its type and caches per type', () async {
    await repo.getAnimeRanking(rankingType: 'airing');
    await repo.getAnimeRanking(rankingType: 'airing');
    await repo.getAnimeRanking();

    expect(calls('/ranking'), 2);
    expect(adapter.requests.first.queryParameters['ranking_type'], 'airing');
  });

  group('detail', () {
    setUp(() {
      respond = (_) => const FakeResponse.json({
        'id': 5,
        'title': 'Detail',
        'synopsis': 'Long text',
        'genres': [
          {'id': 1, 'name': 'Action'},
        ],
      });
    });

    test('fetches once and then serves from the cache', () async {
      final first = await repo.getAnimeDetail(5);
      final second = await repo.getAnimeDetail(5);

      expect(first!.title, 'Detail');
      expect(second!.synopsis, 'Long text');
      expect(second.genres.single.name, 'Action');
      expect(calls('/anime/5'), 1);
    });

    test('an unknown anime is null and is asked about again later', () async {
      respond = (_) => const FakeResponse.json({}, status: 404);

      expect(await repo.getAnimeDetail(5), isNull);
      expect(await repo.getAnimeDetail(5), isNull);
      expect(calls('/anime/5'), 2);
    });

    test(
      'refreshAnimeDetail ignores the cache and stores the new data',
      () async {
        await repo.getAnimeDetail(5);
        respond = (_) => const FakeResponse.json({'id': 5, 'title': 'Renamed'});

        final refreshed = await repo.refreshAnimeDetail(5);

        expect(refreshed!.title, 'Renamed');
        expect(calls('/anime/5'), 2);
        expect((await repo.getAnimeDetail(5))!.title, 'Renamed');
      },
    );

    test(
      'refreshAnimeDetail fails when MAL fails, keeping the cache',
      () async {
        await repo.getAnimeDetail(5);
        respond = (_) => const FakeResponse.json({}, status: 500);

        await expectLater(
          repo.refreshAnimeDetail(5),
          throwsA(isA<DioException>()),
        );

        expect((await repo.getAnimeDetail(5))!.title, 'Detail');
      },
    );
  });

  group('user info', () {
    test('is cached after the first load', () async {
      respond = (_) => const FakeResponse.json({
        'id': 1,
        'name': 'andrizan',
        'anime_statistics': {'num_items_completed': 120, 'mean_score': 7.9},
      });

      final first = await repo.getUserInfo();
      final second = await repo.getUserInfo();

      expect(first!.name, 'andrizan');
      expect(second!.animeStatistics!.numItemsCompleted, 120);
      expect(second.animeStatistics!.meanScore, 7.9);
      expect(calls('/users/@me'), 1);
    });
  });

  group('batch getAnimeList', () {
    test('is empty for no ids and makes no request', () async {
      expect(await repo.getAnimeList(const []), isEmpty);
      expect(adapter.requests, isEmpty);
    });

    test('maps details to cards and silently skips failures', () async {
      respond = (o) => o.path.endsWith('/2')
          ? const FakeResponse.json({}, status: 500)
          : FakeResponse.json({
              'id': int.parse(o.path.split('/').last),
              'title': 'T',
            });

      final result = await repo.getAnimeList([1, 2, 3]);

      expect(result.map((a) => a.id), [1, 3]);
    });
  });

  group('error mapping', () {
    Future<Object?> failWith(FakeResponse Function(RequestOptions o) r) async {
      respond = r;
      try {
        await repo.searchAnime('boom');
      } on Object catch (e) {
        return e;
      }
      return null;
    }

    test('401 becomes unauthorized', () async {
      expect(
        await failWith((_) => const FakeResponse.json({}, status: 401)),
        isA<UnauthorizedException>(),
      );
    });

    test('other HTTP statuses carry their code', () async {
      final e = await failWith((_) => const FakeResponse.json({}, status: 503));

      expect(
        e,
        isA<ServerException>().having((x) => x.statusCode, 'code', 503),
      );
    });

    test('connection problems become a network error', () async {
      final dio = Dio(
        BaseOptions(baseUrl: 'https://api.test/v2'),
      )..httpClientAdapter = _ThrowingAdapter(DioExceptionType.connectionError);
      final broken = AnimeRepository(_ref(container), MalApiClient(dio), cache);

      await expectLater(
        broken.searchAnime('x'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('timeouts become a network error', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test/v2'))
        ..httpClientAdapter = _ThrowingAdapter(DioExceptionType.receiveTimeout);
      final broken = AnimeRepository(_ref(container), MalApiClient(dio), cache);

      await expectLater(
        broken.searchAnime('x'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('stale fallback', () {
    test(
      'an invalidated user list is served from disk when the network fails',
      () async {
        respond = (_) => FakeResponse.json(_list([1, 2, 3]));
        await repo.getUserAnimeList(status: WatchStatus.completed);
        await cache.invalidateUserAnimeList('completed', 500, 0);
        respond = (_) => const FakeResponse.json({}, status: 500);

        final list = await repo.getUserAnimeList(status: WatchStatus.completed);

        expect(list.map((a) => a.id), [1, 2, 3]);
      },
    );

    test('with nothing cached the failure is reported', () async {
      respond = (_) => const FakeResponse.json({}, status: 500);

      await expectLater(
        repo.getUserAnimeList(status: WatchStatus.completed),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('mutations', () {
    test(
      'a failed update is mapped and does not bump the list version',
      () async {
        respond = (_) => const FakeResponse.json({}, status: 500);
        final before = container.read(animeListVersionProvider);

        await expectLater(
          repo.updateAnimeListStatus(1, numWatchedEpisodes: 3),
          throwsA(isA<ServerException>()),
        );

        expect(container.read(animeListVersionProvider), before);
      },
    );

    test(
      'a failed removal is mapped and does not bump the list version',
      () async {
        respond = (_) => const FakeResponse.json({}, status: 500);
        final before = container.read(animeListVersionProvider);

        await expectLater(
          repo.deleteAnimeFromList(1),
          throwsA(isA<ServerException>()),
        );

        expect(container.read(animeListVersionProvider), before);
      },
    );

    test('a successful update bumps the version once', () async {
      respond = (_) => const FakeResponse.json({
        'status': 'watching',
        'num_episodes_watched': 4,
      });
      final before = container.read(animeListVersionProvider);

      final updated = await repo.updateAnimeListStatus(
        1,
        numWatchedEpisodes: 4,
      );

      expect(updated.numEpisodesWatched, 4);
      expect(container.read(animeListVersionProvider), before + 1);
    });
  });
}

Ref _ref(ProviderContainer c) => c.read(_refProvider);

final _refProvider = Provider<Ref>((ref) => ref);

class _ThrowingAdapter implements HttpClientAdapter {
  _ThrowingAdapter(this.type);

  final DioExceptionType type;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(requestOptions: options, type: type);
  }

  @override
  void close({bool force = false}) {}
}
