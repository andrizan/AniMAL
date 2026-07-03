import 'package:animal/core/network/api_exception.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/local/memory_cache.dart';
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

final _cache = MemoryCache();

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

/// High-level repository that wraps [MalApiClient] with error handling and caching.
class AnimeRepository {
  AnimeRepository(this._ref, this._api, [this._logger]);

  final Ref _ref;
  final MalApiClient _api;
  final Logger? _logger;

  static const _ttlShort = Duration(minutes: 1);
  static const _ttlUserList = Duration(minutes: 3);
  static const _ttlMedium = Duration(minutes: 10);
  static const _ttlLong = Duration(minutes: 15);

  Future<List<Anime>> searchAnime(String query, {int limit = 20}) async {
    final key = 'search_${query}_$limit';
    final cached = _cache.get<List<Anime>>(key);
    if (cached != null) return cached;

    try {
      final result = await _api.searchAnime(query, limit: limit);
      _cache.put(key, result, ttl: _ttlShort);
      return result;
    } on DioException catch (e) {
      _logger?.e('searchAnime failed', error: e);
      throw _mapDioException(e);
    }
  }

  Future<List<Anime>> getSeasonalAnime({
    required int year,
    required Season season,
    int limit = 100,
  }) async {
    final key = 'seasonal_${year}_${season.value}_$limit';
    final cached = _cache.get<List<Anime>>(key);
    if (cached != null) return cached;

    try {
      final result = await _api.getSeasonalAnime(
        year: year,
        season: season,
        limit: limit,
      );
      _cache.put(key, result, ttl: _ttlLong);
      return result;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _logger?.i('Season $season $year not available yet');
        return [];
      }
      _logger?.e('getSeasonalAnime failed', error: e);
      throw _mapDioException(e);
    }
  }

  Future<AnimeDetail?> getAnimeDetail(int animeId) async {
    final key = 'detail_$animeId';
    final cached = _cache.get<AnimeDetail>(key);
    if (cached != null) return cached;

    try {
      final result = await _api.getAnimeDetail(animeId);
      if (result != null) _cache.put(key, result, ttl: _ttlLong);
      return result;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _logger?.i('Anime $animeId not found on MAL');
        return null;
      }
      _logger?.e('getAnimeDetail failed', error: e);
      throw _mapDioException(e);
    }
  }

  Future<List<Anime>> getAnimeRanking({
    String rankingType = 'all',
    int limit = 20,
  }) async {
    final key = 'ranking_${rankingType}_$limit';
    final cached = _cache.get<List<Anime>>(key);
    if (cached != null) return cached;

    try {
      final result = await _api.getAnimeRanking(
        rankingType: rankingType,
        limit: limit,
      );
      _cache.put(key, result, ttl: _ttlMedium);
      return result;
    } on DioException catch (e) {
      _logger?.e('getAnimeRanking failed', error: e);
      throw _mapDioException(e);
    }
  }

  Future<List<Anime>> getUserAnimeList({
    WatchStatus status = WatchStatus.watching,
    int limit = 100,
    int offset = 0,
  }) async {
    final key = 'userlist_${status.value}_$limit';
    final cached = _cache.get<List<Anime>>(key);
    if (cached != null) return cached;

    try {
      final result = await _api.getUserAnimeList(
        status: status,
        limit: limit,
        offset: offset,
      );
      _cache.put(key, result, ttl: _ttlUserList);
      return result;
    } on DioException catch (e) {
      _logger?.e('getUserAnimeList failed', error: e);
      throw _mapDioException(e);
    }
  }

  Future<void> deleteAnimeFromList(int animeId) async {
    try {
      await _api.deleteAnimeFromList(animeId);
      _cache.remove('detail_$animeId');
      _invalidateUserListCache();
      _clearMyListStatusInAuxCaches(animeId);
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
      _updateUserListCache(animeId, updated);
      _cache.remove('detail_$animeId');
      _propagateMyListStatusToAuxCaches(animeId, updated);
      _bumpListVersion();
      return updated;
    } on DioException catch (e) {
      _logger?.e('updateAnimeListStatus failed', error: e);
      throw _mapDioException(e);
    }
  }

  void _bumpListVersion() {
    _ref.read(animeListVersionProvider.notifier).bump();
  }

  void _propagateMyListStatusToAuxCaches(int animeId, MyListStatus status) {
    final seasonalKeys = _cache
        .getWhere<List<Anime>>((key) => key.startsWith('seasonal_'))
        .map((e) => e.key)
        .toList();
    for (final key in seasonalKeys) {
      final list = _cache.get<List<Anime>>(key);
      if (list == null) continue;
      final idx = list.indexWhere((a) => a.id == animeId);
      if (idx == -1) continue;
      final newList = List<Anime>.from(list);
      newList[idx] = list[idx].copyWith(myListStatus: status);
      _cache.put(key, newList, ttl: _ttlLong);
    }

    final searchKeys = _cache
        .getWhere<List<Anime>>((key) => key.startsWith('search_'))
        .map((e) => e.key)
        .toList();
    for (final key in searchKeys) {
      final list = _cache.get<List<Anime>>(key);
      if (list == null) continue;
      final idx = list.indexWhere((a) => a.id == animeId);
      if (idx == -1) continue;
      final newList = List<Anime>.from(list);
      newList[idx] = list[idx].copyWith(myListStatus: status);
      _cache.put(key, newList, ttl: _ttlShort);
    }
  }

  void _clearMyListStatusInAuxCaches(int animeId) {
    for (final prefix in ['seasonal_', 'search_']) {
      final keys = _cache
          .getWhere<List<Anime>>((key) => key.startsWith(prefix))
          .map((e) => e.key)
          .toList();
      for (final key in keys) {
        final list = _cache.get<List<Anime>>(key);
        if (list == null) continue;
        final idx = list.indexWhere((a) => a.id == animeId);
        if (idx == -1) continue;
        final newList = List<Anime>.from(list);
        newList[idx] = list[idx].copyWith(myListStatus: null);
        _cache.put(key, newList, ttl: _ttlShort);
      }
    }
  }

  void _updateUserListCache(int animeId, MyListStatus updatedStatus) {
    const limit = 100;
    final newStatus = updatedStatus.status;
    final newKey = 'userlist_${newStatus.value}_$limit';
    Anime? sourceAnime;

    final oldKeys = _cache
        .getWhere<List<Anime>>((key) => key.startsWith('userlist_'))
        .map((e) => e.key)
        .toList();

    for (final key in oldKeys) {
      final list = _cache.get<List<Anime>>(key);
      if (list == null) continue;
      final idx = list.indexWhere((a) => a.id == animeId);
      if (idx == -1) continue;
      sourceAnime ??= list[idx];
      if (key == newKey) {
        final newList = List<Anime>.from(list);
        newList[idx] = list[idx].copyWith(myListStatus: updatedStatus);
        _cache.put(key, newList, ttl: _ttlUserList);
      } else {
        final newList = list.where((a) => a.id != animeId).toList();
        _cache.put(key, newList, ttl: _ttlUserList);
      }
    }

    final newList = _cache.get<List<Anime>>(newKey);
    if (newList != null &&
        !newList.any((a) => a.id == animeId) &&
        sourceAnime != null) {
      _cache.put(
        newKey,
        [...newList, sourceAnime.copyWith(myListStatus: updatedStatus)],
        ttl: _ttlUserList,
      );
    }
  }

  Future<MalUser?> getUserInfo() async {
    const key = 'userInfo';
    final cached = _cache.get<MalUser>(key);
    if (cached != null) return cached;

    try {
      final result = await _api.getUserInfo();
      if (result != null) _cache.put(key, result, ttl: _ttlMedium);
      return result;
    } on DioException catch (e) {
      _logger?.e('getUserInfo failed', error: e);
      throw _mapDioException(e);
    }
  }

  void _invalidateUserListCache() {
    _cache.removeWhere((key) => key.startsWith('userlist_'));
  }

  Future<List<Anime>> getAnimeList(List<int> malIds) async {
    final results = <Anime>[];
    for (final id in malIds) {
      try {
        final detail = await getAnimeDetail(id);
        if (detail != null) {
          results.add(
            Anime(
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
            ),
          );
        }
      } catch (_) {
        // skip individual failures
      }
    }
    return results;
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
    ref.watch(loggerProvider),
  );
});

/// FutureProvider family for anime detail by ID.
final animeDetailProvider = FutureProvider.autoDispose
    .family<AnimeDetail?, int>((ref, animeId) async {
      final repo = ref.watch(animeRepositoryProvider);
      return repo.getAnimeDetail(animeId);
    });

/// FutureProvider family for a batch of Anime by MAL IDs.
/// Uses a comma-separated string key for stable provider identity.
final animeListProvider = FutureProvider.autoDispose
    .family<List<Anime>, String>((ref, key) async {
      if (key.isEmpty) return [];
      final malIds = key.split(',').map((s) => int.parse(s)).toList();
      final repo = ref.watch(animeRepositoryProvider);
      return repo.getAnimeList(malIds);
    });
