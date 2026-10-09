import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:animal/core/constants/mal_endpoints.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/local/anime_cache.dart';
import 'package:animal/data/local/app_database.dart';
import 'package:animal/data/local/sqlite_anime_cache.dart';
import 'package:animal/data/mal/mal_api_client.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _ListStatusAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({'status': 'completed', 'num_episodes_watched': 12}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
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
  late AnimeRepository repo;

  setUp(() async {
    final tmp = Directory.systemTemp.createTempSync('list_mutation_');
    appDb = await AppDatabase.open(
      pathOverride: '${tmp.path}/test.db',
      runMigrations: false,
    );
    cache = SqliteAnimeCache(appDb);
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = _ListStatusAdapter();
    final repoProvider = Provider<AnimeRepository>(
      (ref) => AnimeRepository(ref, MalApiClient(dio), cache),
    );
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(appDb)],
    );
    repo = container.read(repoProvider);
  });

  tearDown(() async {
    container.dispose();
    await appDb.close();
  });

  Anime makeAnime(int id) => Anime(id: id, title: 'Anime $id');

  group('AnimeRepository list mutation', () {
    test('moving to a never-fetched status does not fake its list', () async {
      await cache.saveUserAnimeList('watching', limit, 0, [
        makeAnime(1),
        makeAnime(2),
      ]);

      await repo.updateAnimeListStatus(1, status: WatchStatus.completed);

      final watching = await cache.getUserAnimeList('watching', limit, 0);
      expect(watching!.map((a) => a.id).toList(), [2]);
      expect(await cache.getUserAnimeList('completed', limit, 0), isNull);
      expect(
        await cache.getFetchedAt(
          SqliteAnimeCache.userListKey('completed', limit, 0),
        ),
        isNull,
      );
    });

    test('moving to an already cached status appends to its list', () async {
      await cache.saveUserAnimeList('watching', limit, 0, [makeAnime(1)]);
      await cache.saveUserAnimeList('completed', limit, 0, [makeAnime(2)]);

      await repo.updateAnimeListStatus(1, status: WatchStatus.completed);

      final completed = await cache.getUserAnimeList('completed', limit, 0);
      expect(completed!.map((a) => a.id).toList(), [2, 1]);
      final watching = await cache.getUserAnimeList('watching', limit, 0);
      expect(watching, isEmpty);
    });
  });
}
