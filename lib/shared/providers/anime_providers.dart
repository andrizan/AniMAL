import 'dart:async';

import 'package:animal/core/network/api_exception.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/local/anime_cache.dart';
import 'package:animal/data/local/app_database.dart';
import 'package:animal/data/local/sqlite_anime_cache.dart';
import 'package:animal/data/mal/mal_api_client.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/data/models/mal_user.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/season.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// Bumped whenever the user mutates their anime list. Providers that show
/// `myListStatus` (user list, calendar, airing, search) watch this so the
/// updated value propagates everywhere without manually invalidating each
/// provider at every call site.
class AnimeListVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() {
    state = state + 1;
  }
}

final animeListVersionProvider =
    NotifierProvider<AnimeListVersionNotifier, int>(
      AnimeListVersionNotifier.new,
    );

/// Provider for [MalApiClient].
final malAnimeApiProvider = Provider<MalApiClient>((ref) {
  return MalApiClient(ref.watch(dioProvider));
});

/// High-level repository that wraps [MalApiClient] with error handling,
/// persistent caching, stale-while-revalidate, and in-flight deduplication.
class AnimeRepository {
  AnimeRepository(this._ref, this._api, this._cache, [this._logger]);

  final Ref _ref;
  final MalApiClient _api;
  final AnimeCache _cache;
  final Logger? _logger;

  static const _ttlShort = Duration(minutes: 1);
  static const _ttlUserList = Duration(minutes: 3);
  static const _ttlMedium = Duration(minutes: 10);
  static const _ttlLong = Duration(minutes: 15);

  final Map<String, Future<dynamic>> _inFlight = <String, Future<dynamic>>{};

  // ---------- Search / Seasonal / Ranking (SWR over List<Anime>) ----------

  Future<List<Anime>> searchAnime(String query, {int limit = 20}) {
    final key = SqliteAnimeCache.searchKey(query, limit);
    return _swrList<Anime>(
      key: key,
      ttl: _ttlShort,
      readFresh: () => _cache.getSearchResults(query, limit),
      networkFetch: () => _api.searchAnime(query, limit: limit),
      writeCache: (list) => _cache.saveSearchResults(query, limit, list),
    );
  }

  Future<List<Anime>> getSeasonalAnime({
    required int year,
    required Season season,
    int limit = 100,
  }) {
    final key = SqliteAnimeCache.seasonalKey(year, season.value, limit);
    return _swrList<Anime>(
      key: key,
      ttl: _ttlLong,
      readFresh: () => _cache.getSeasonalAnime(year, season.value, limit),
      networkFetch: () async {
        try {
          return await _api.getSeasonalAnime(
            year: year,
            season: season,
            limit: limit,
          );
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) {
            _logger?.i('Season $season $year not available yet');
            return <Anime>[];
          }
          rethrow;
        }
      },
      writeCache: (list) =>
          _cache.saveSeasonalAnime(year, season.value, limit, list),
    );
  }

  Future<List<Anime>> getAnimeRanking({
    String rankingType = 'all',
    int limit = 20,
  }) {
    final key = SqliteAnimeCache.rankingKey(rankingType, limit);
    return _swrList<Anime>(
      key: key,
      ttl: _ttlMedium,
      readFresh: () => _cache.getAnimeRanking(rankingType, limit),
      networkFetch: () =>
          _api.getAnimeRanking(rankingType: rankingType, limit: limit),
      writeCache: (list) => _cache.saveAnimeRanking(rankingType, limit, list),
    );
  }

  // ---------- Detail (SWR over T?) ----------

  Future<AnimeDetail?> getAnimeDetail(int animeId) {
    final key = SqliteAnimeCache.detailKey(animeId);
    return _swrNullable<AnimeDetail>(
      key: key,
      ttl: _ttlLong,
      readFresh: () => _cache.getAnimeDetail(animeId),
      networkFetch: () async {
        try {
          return await _api.getAnimeDetail(animeId);
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) {
            _logger?.i('Anime $animeId not found on MAL');
            return null;
          }
          rethrow;
        }
      },
      writeCache: (d) async {
        if (d != null) await _cache.saveAnimeDetail(d);
      },
      isMissingNetworkValue: (v) => v == null,
    );
  }

  // ---------- User list / User info (SWR with stale fallback) ----------

  Future<List<Anime>> getUserAnimeList({
    WatchStatus status = WatchStatus.watching,
    int limit = 100,
    int offset = 0,
  }) {
    final key = SqliteAnimeCache.userListKey(status.value, limit, offset);
    return _swrList<Anime>(
      key: key,
      ttl: _ttlUserList,
      readFresh: () => _cache.getUserAnimeList(status.value, limit, offset),
      networkFetch: () => _api.getUserAnimeList(
        status: status,
        limit: limit,
        offset: offset,
      ),
      writeCache: (list) =>
          _cache.saveUserAnimeList(status.value, limit, offset, list),
    );
  }

  Future<MalUser?> getUserInfo() {
    const key = 'userInfo';
    return _swrNullable<MalUser>(
      key: key,
      ttl: _ttlMedium,
      readFresh: () => _cache.getUserInfo(),
      networkFetch: () => _api.getUserInfo(),
      writeCache: (u) async {
        if (u != null) await _cache.saveUserInfo(u);
      },
    );
  }

  // ---------- Mutations ----------

  Future<void> deleteAnimeFromList(int animeId) async {
    try {
      await _api.deleteAnimeFromList(animeId);
      await _cache.invalidateAnimeDetail(animeId);
      await _cache.invalidateUserAnimeLists();
      await _cache.clearCachedAnimeListStatus(animeId);
      _bumpListVersion();
    } on DioException catch (e) {
      _logger?.e('deleteAnimeFromList failed', error: e);
      throw _mapDioException(e);
    }
  }

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
    try {
      final updated = await _api.updateAnimeListStatus(
        animeId,
        status: status,
        numWatchedEpisodes: numWatchedEpisodes,
        score: score,
        isRewatching: isRewatching,
        priority: priority,
        rewatchValue: rewatchValue,
        comments: comments,
      );
      await _applyListMutation(animeId, updated);
      _bumpListVersion();
      return updated;
    } on DioException catch (e) {
      _logger?.e('updateAnimeListStatus failed', error: e);
      throw _mapDioException(e);
    }
  }

  /// Apply a list mutation to SQLite caches.
  Future<void> _applyListMutation(int animeId, MyListStatus updated) async {
    try {
      final newStatus = updated.status;
      const newLimit = 100;
      const newOffset = 0;
      final newKey = SqliteAnimeCache.userListKey(
        newStatus.value,
        newLimit,
        newOffset,
      );

      final metaRows = await _appDb.raw.query(
        'cache_meta',
        columns: ['cache_key'],
        where: 'cache_key LIKE ?',
        whereArgs: ['userlist_%'],
      );

      Anime? sourceAnime;
      bool foundInNewKey = false;
      final keys = metaRows.map((r) => r['cache_key']! as String).toList();

      for (final key in keys) {
        try {
          final status = _statusFromKey(key);
          final limit = _limitFromKey(key);
          final offset = _offsetFromKey(key);
          final list = await _cache.getUserAnimeList(status, limit, offset);
          if (list == null) continue;
          final idx = list.indexWhere((a) => a.id == animeId);
          if (idx != -1) {
            sourceAnime ??= list[idx];
            if (key == newKey) {
              foundInNewKey = true;
              final newList = List<Anime>.from(list);
              newList[idx] = list[idx].copyWith(myListStatus: updated);
              await _cache.saveUserAnimeList(status, limit, offset, newList);
            } else {
              final newList = list.where((a) => a.id != animeId).toList();
              await _cache.saveUserAnimeList(status, limit, offset, newList);
            }
          }
        } catch (e) {
          _logger?.w('Skipping malformed userlist cache key: $e');
        }
      }

      if (!foundInNewKey && sourceAnime != null) {
        final existingNewList = await _cache.getUserAnimeList(
          newStatus.value,
          newLimit,
          newOffset,
        );
        if (existingNewList != null) {
          if (!existingNewList.any((a) => a.id == animeId)) {
            await _cache.saveUserAnimeList(
              newStatus.value,
              newLimit,
              newOffset,
              [...existingNewList, sourceAnime.copyWith(myListStatus: updated)],
            );
          }
        } else {
          await _cache.saveUserAnimeList(newStatus.value, newLimit, newOffset, [
            sourceAnime.copyWith(myListStatus: updated),
          ]);
        }
      } else if (!foundInNewKey && sourceAnime == null) {
        await _cache.invalidateUserAnimeList(
          newStatus.value,
          newLimit,
          newOffset,
        );
      }

      await _cache.updateCachedAnimeListStatus(animeId, updated);
      await _cache.invalidateAnimeDetail(animeId);
    } catch (e, st) {
      _logger?.e(
        'Failed to apply list mutation to cache',
        error: e,
        stackTrace: st,
      );
    }
  }

  // The repository's cache wraps the AppDatabase; expose a tiny accessor for
  // cleanup queries that need to look at `cache_meta` directly. Today the
  // cache is interface-only, so we use the AppDatabase via a separate path:
  // we use `cache_meta` lookups by delegating to AnimeCache.getFetchedAt.
  // However `_applyListMutation` needs to enumerate userlist keys. We add
  // a dedicated helper for that via the AppDatabase provider.
  AppDatabase get _appDb => _ref.read(appDatabaseProvider);

  String _statusFromKey(String key) {
    final parts = key.split('_');
    return parts.sublist(1, parts.length - 2).join('_');
  }

  int _limitFromKey(String key) {
    final parts = key.split('_');
    return int.parse(parts[parts.length - 2]);
  }

  int _offsetFromKey(String key) {
    final parts = key.split('_');
    return int.parse(parts.last);
  }

  void _bumpListVersion() {
    _ref.read(animeListVersionProvider.notifier).bump();
  }

  // ---------- Batch helper ----------

  Future<List<Anime>> getAnimeList(List<int> malIds) async {
    if (malIds.isEmpty) return <Anime>[];
    final futures = malIds.map((id) async {
      try {
        final detail = await getAnimeDetail(id);
        if (detail == null) return null;
        return Anime(
          id: detail.id,
          title: detail.title,
          mainPicture: detail.mainPicture,
          mean: detail.mean,
          rank: detail.rank,
          popularity: detail.popularity,
          numEpisodes: detail.numEpisodes,
          status: detail.status,
          rating: detail.rating,
          mediaType: detail.mediaType,
          broadcast: detail.broadcast,
          alternativeTitles: detail.alternativeTitles,
          genres: detail.genres,
          myListStatus: detail.myListStatus,
        );
      } on Object catch (_) {
        return null;
      }
    }).toList();
    final settled = await Future.wait(futures);
    return settled.whereType<Anime>().toList();
  }

  // ---------- Generic helpers ----------

  /// SWR for list-of-T reads. On missing, blocking network. On stale,
  /// returns stale and kicks off a background refresh.
  Future<List<T>> _swrList<T>({
    required String key,
    required Duration ttl,
    required Future<List<T>?> Function() readFresh,
    required Future<List<T>> Function() networkFetch,
    required Future<void> Function(List<T>) writeCache,
  }) {
    return _deduped<List<T>>(key, () async {
      final cached = await readFresh();
      final fetchedAt = await _cache.getFetchedAt(key);
      if (cached != null && fetchedAt != null) {
        final age = DateTime.now().difference(fetchedAt);
        if (age < ttl) return cached;
        unawaited(_refreshList(key, networkFetch, writeCache));
        return cached;
      }
      try {
        final fresh = await networkFetch();
        await writeCache(fresh);
        return fresh;
      } on Object catch (e) {
        if (cached != null) return cached;
        if (e is DioException) throw _mapDioException(e);
        rethrow;
      }
    });
  }

  /// SWR for T? reads. [isMissingNetworkValue] decides if a network `null`
  /// (e.g., 404) is treated as a valid value to cache, or as a real failure.
  Future<T?> _swrNullable<T>({
    required String key,
    required Duration ttl,
    required Future<T?> Function() readFresh,
    required Future<T?> Function() networkFetch,
    required Future<void> Function(T?) writeCache,
    bool Function(T?)? isMissingNetworkValue,
  }) {
    return _deduped<T?>(key, () async {
      final cached = await readFresh();
      final fetchedAt = await _cache.getFetchedAt(key);
      if (cached != null && fetchedAt != null) {
        final age = DateTime.now().difference(fetchedAt);
        if (age < ttl) return cached;
        unawaited(_refreshNullable(key, networkFetch, writeCache));
        return cached;
      }
      try {
        final fresh = await networkFetch();
        final isMissing = isMissingNetworkValue?.call(fresh) ?? false;
        if (!isMissing) {
          await writeCache(fresh);
        }
        return fresh;
      } on Object catch (e) {
        if (cached != null) return cached;
        if (e is DioException) throw _mapDioException(e);
        rethrow;
      }
    });
  }

  Future<void> _refreshList<T>(
    String key,
    Future<List<T>> Function() networkFetch,
    Future<void> Function(List<T>) writeCache,
  ) async {
    try {
      final fresh = await networkFetch();
      await writeCache(fresh);
    } on Object catch (_) {
      // best-effort
    }
  }

  Future<void> _refreshNullable<T>(
    String key,
    Future<T?> Function() networkFetch,
    Future<void> Function(T?) writeCache,
  ) async {
    try {
      final fresh = await networkFetch();
      await writeCache(fresh);
    } on Object catch (_) {
      // best-effort
    }
  }

  Future<T> _deduped<T>(String key, Future<T> Function() run) {
    final existing = _inFlight[key];
    if (existing != null) {
      return existing as Future<T>;
    }
    final fut = run();
    // whenComplete fires the callback whether `fut` succeeds or rejects,
    // which is what we want for cleanup. The resulting future propagates
    // any rejection from `fut`; we suppress it here since the original
    // caller already sees it through `fut`.
    unawaited(
      fut.whenComplete(() {
        _inFlight.remove(key);
      }),
    );
    _inFlight[key] = fut;
    return fut;
  }

  ApiException _mapDioException(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => ApiException.network(
        message: e.message ?? 'Network error',
      ),
      _ when e.response?.statusCode == 401 => const ApiException.unauthorized(),
      _ when e.response != null => ApiException.server(
        statusCode: e.response!.statusCode!,
        message: e.response?.statusMessage ?? 'Server error',
      ),
      _ => ApiException.unknown(message: e.message),
    };
  }
}

/// Provider for [AnimeRepository].
final animeRepositoryProvider = Provider<AnimeRepository>((ref) {
  return AnimeRepository(
    ref,
    ref.watch(malAnimeApiProvider),
    ref.watch(animeCacheProvider),
    ref.watch(loggerProvider),
  );
});

/// FutureProvider family for anime detail by ID.
// ignore: specify_nonobvious_property_types
final animeDetailProvider = FutureProvider.autoDispose
    .family<AnimeDetail?, int>((ref, animeId) async {
      final repo = ref.watch(animeRepositoryProvider);
      return repo.getAnimeDetail(animeId);
    });

/// FutureProvider family for a batch of Anime by MAL IDs.
/// Uses a comma-separated string key for stable provider identity.
// ignore: specify_nonobvious_property_types
final animeListProvider = FutureProvider.autoDispose
    .family<List<Anime>, String>((ref, key) async {
      if (key.isEmpty) return <Anime>[];
      final malIds = key.split(',').map(int.parse).toList();
      final repo = ref.watch(animeRepositoryProvider);
      return repo.getAnimeList(malIds);
    });
