import 'dart:io';

import 'package:animal/core/providers.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/data/local/app_database.dart';
import 'package:animal/data/local/sqlite_anime_cache.dart';
import 'package:animal/data/mal/mal_api_client.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/shared/providers/anilist_providers.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/fake_adapter.dart';

class _AniList extends Fake implements AniListClient {
  final refreshed = <int>[];
  Object? failure;

  @override
  Future<AniListAnimeExtra> refreshAnimeExtra(int malId) async {
    refreshed.add(malId);
    if (failure != null) throw failure!;
    return const AniListAnimeExtra();
  }
}

class _BrokenCache extends SqliteAnimeCache {
  _BrokenCache(super.db);

  int attempts = 0;

  @override
  Future<void> applyUserListMutation(
    int animeId,
    MyListStatus updated,
    int limit,
    int offset,
  ) async {
    attempts++;
    throw StateError('disk full');
  }
}

class _Repo extends Fake implements AnimeRepository {
  final details = <int>[];
  final cached = <int>[];

  @override
  Future<AnimeDetail?> getAnimeDetail(int animeId) async {
    details.add(animeId);
    return AnimeDetail(id: animeId, title: 'Anime $animeId');
  }

  @override
  Future<Anime?> getCachedAnime(int malId) async {
    cached.add(malId);
    return Anime(id: malId, title: 'Anime $malId');
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase appDb;
  late FakeAdapter adapter;
  late _AniList anilist;
  late ProviderContainer container;

  setUp(() async {
    final tmp = Directory.systemTemp.createTempSync('anime_wiring_');
    appDb = await AppDatabase.open(
      pathOverride: '${tmp.path}/test.db',
      runMigrations: false,
    );
    anilist = _AniList();
    adapter = FakeAdapter((o) {
      if (o.method == 'PUT') {
        return const FakeResponse.json({
          'status': 'watching',
          'num_episodes_watched': 3,
          'score': 8,
        });
      }
      final id = int.tryParse(o.path.split('/').last) ?? 0;
      return FakeResponse.json({'id': id, 'title': 'Anime $id'});
    });
    container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [
        appDatabaseProvider.overrideWithValue(appDb),
        dioProvider.overrideWithValue(fakeDio(adapter)),
        anilistApiProvider.overrideWithValue(anilist),
        loggerProvider.overrideWithValue(Logger(level: Level.off)),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await appDb.close();
    });
  });

  group('default wiring', () {
    test('the repository talks to MAL through the shared Dio', () async {
      final detail = await container.read(animeDetailProvider(5).future);

      expect(detail!.id, 5);
      expect(detail.title, 'Anime 5');
      expect(adapter.requests.single.path, '/anime/5');
      expect(adapter.requests.single.queryParameters['fields'], isNotNull);
    });

    test('a detail is read from SQLite the second time', () async {
      await container.read(animeDetailProvider(5).future);
      container.invalidate(animeDetailProvider(5));

      final again = await container.read(animeDetailProvider(5).future);

      expect(again!.title, 'Anime 5');
      expect(adapter.requests, hasLength(1));
    });

    test('one repository serves the whole container', () {
      expect(
        container.read(animeRepositoryProvider),
        same(container.read(animeRepositoryProvider)),
      );
      expect(container.read(malAnimeApiProvider), isA<MalApiClient>());
    });

    test('a list edit updates the open detail without refetching it', () async {
      final sub = container.listen(animeDetailProvider(5), (_, _) {});
      addTearDown(sub.close);
      await container.read(animeDetailProvider(5).future);

      await container
          .read(animeRepositoryProvider)
          .updateAnimeListStatus(5, numWatchedEpisodes: 3);
      final detail = await container.read(animeDetailProvider(5).future);

      expect(detail!.myListStatus?.numEpisodesWatched, 3);
      expect(adapter.requests.map((r) => r.method), ['GET', 'PUT']);
    });

    test('a removal updates the open detail without refetching it', () async {
      final sub = container.listen(animeDetailProvider(5), (_, _) {});
      addTearDown(sub.close);
      await container.read(animeDetailProvider(5).future);
      await container
          .read(animeRepositoryProvider)
          .updateAnimeListStatus(5, numWatchedEpisodes: 3);
      await container.read(animeDetailProvider(5).future);

      await container.read(animeRepositoryProvider).deleteAnimeFromList(5);
      final detail = await container.read(animeDetailProvider(5).future);

      expect(detail!.myListStatus, isNull);
      expect(adapter.requests.map((r) => r.method), ['GET', 'PUT', 'DELETE']);
    });

    test('a stored anime is read without a request', () async {
      await SqliteAnimeCache(appDb).saveUserAnimeList('watching', 500, 0, [
        const Anime(id: 6, title: 'Stored'),
      ]);

      final anime = await container.read(cachedAnimeProvider(6).future);

      expect(anime!.title, 'Stored');
      expect(adapter.requests, isEmpty);
    });

    test('an anime never fetched is null, still without a request', () async {
      expect(await container.read(cachedAnimeProvider(6).future), isNull);
      expect(adapter.requests, isEmpty);
    });
  });

  group('providers over a repository', () {
    late _Repo repo;

    setUp(() {
      repo = _Repo();
      container.dispose();
      container = ProviderContainer(
        retry: noProviderRetry,
        overrides: [animeRepositoryProvider.overrideWithValue(repo)],
      );
    });

    test('a detail is reloaded when the list changes', () async {
      final sub = container.listen(animeDetailProvider(7), (_, _) {});
      addTearDown(sub.close);
      await container.read(animeDetailProvider(7).future);

      container.read(animeListVersionProvider.notifier).bump();
      await container.read(animeDetailProvider(7).future);

      expect(repo.details, [7, 7]);
    });

    test('details of different anime are independent', () async {
      await container.read(animeDetailProvider(1).future);
      await container.read(animeDetailProvider(2).future);

      expect(repo.details, [1, 2]);
    });

    test('a stored anime is read through the repository', () async {
      final anime = await container.read(cachedAnimeProvider(4).future);

      expect(anime!.title, 'Anime 4');
      expect(repo.cached, [4]);
    });

    test('a stored anime is read again when the list changes', () async {
      final sub = container.listen(cachedAnimeProvider(4), (_, _) {});
      addTearDown(sub.close);
      await container.read(cachedAnimeProvider(4).future);

      container.read(animeListVersionProvider.notifier).bump();
      await container.read(cachedAnimeProvider(4).future);

      expect(repo.cached, [4, 4]);
    });
  });

  group('refreshAnimeDetail', () {
    AnimeRepository repoWith({AniListClient? anilistApi}) => AnimeRepository(
      _refOf(container),
      MalApiClient(container.read(dioProvider)),
      SqliteAnimeCache(appDb),
      Logger(level: Level.off),
      anilistApi,
    );

    test('refreshes MAL and AniList together', () async {
      final repo = repoWith(anilistApi: anilist);

      final detail = await repo.refreshAnimeDetail(9);

      expect(detail!.title, 'Anime 9');
      expect(anilist.refreshed, [9]);
      expect(await SqliteAnimeCache(appDb).getAnimeDetail(9), isNotNull);
    });

    test('an AniList failure does not fail the refresh', () async {
      anilist.failure = Exception('AniList down');
      final repo = repoWith(anilistApi: anilist);

      final detail = await repo.refreshAnimeDetail(9);

      expect(detail!.id, 9);
      expect(anilist.refreshed, [9]);
      expect(await SqliteAnimeCache(appDb).getAnimeDetail(9), isNotNull);
    });

    test('works without an AniList client', () async {
      final repo = repoWith();

      expect((await repo.refreshAnimeDetail(9))!.id, 9);
    });

    test('a MAL failure is thrown and nothing is cached', () async {
      adapter = FakeAdapter((_) => const FakeResponse.json({}, status: 500));
      container.dispose();
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(appDb),
          dioProvider.overrideWithValue(fakeDio(adapter)),
        ],
      );
      final repo = AnimeRepository(
        _refOf(container),
        MalApiClient(container.read(dioProvider)),
        SqliteAnimeCache(appDb),
        Logger(level: Level.off),
        anilist,
      );

      await expectLater(repo.refreshAnimeDetail(9), throwsA(anything));

      expect(await SqliteAnimeCache(appDb).getAnimeDetail(9), isNull);
    });
  });

  group('a list edit whose local copy cannot be updated', () {
    test('still succeeds and tells the open pages', () async {
      final broken = _BrokenCache(appDb);
      final repo = AnimeRepository(
        _refOf(container),
        MalApiClient(container.read(dioProvider)),
        broken,
        Logger(level: Level.off),
      );
      final before = container.read(animeListVersionProvider);

      final updated = await repo.updateAnimeListStatus(
        4,
        status: WatchStatus.watching,
        numWatchedEpisodes: 3,
        score: 8,
      );

      expect(broken.attempts, 1);
      expect(updated.numEpisodesWatched, 3);
      expect(updated.score, 8);
      expect(container.read(animeListVersionProvider), before + 1);
    });
  });
}

/// A [Ref] bound to [container], for building repositories by hand.
Ref _refOf(ProviderContainer container) => container.read(_refProvider);

final _refProvider = Provider<Ref>((ref) => ref);
