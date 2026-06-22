import 'package:animal/core/network/api_exception.dart';
import 'package:animal/features/anime/data/mal_anime_api.dart';
import 'package:animal/features/anime/domain/anime.dart';
import 'package:animal/features/anime/domain/anime_detail.dart';
import 'package:animal/features/anime/domain/mal_user.dart';
import 'package:animal/features/anime/domain/season.dart';
import 'package:animal/features/anime/domain/watch_status.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// High-level repository that wraps [MalAnimeApi] with error handling.
class AnimeRepository {
  const AnimeRepository(this._api, [this._logger]);

  final MalAnimeApi _api;
  final Logger? _logger;

  /// Search anime. Returns an empty list on error.
  Future<List<Anime>> searchAnime(String query, {int limit = 20}) async {
    try {
      return await _api.searchAnime(query, limit: limit);
    } on DioException catch (e) {
      _logger?.e('searchAnime failed', error: e);
      throw _mapDioException(e);
    }
  }

  /// Get seasonal anime (used for the schedule view).
  Future<List<Anime>> getSeasonalAnime({
    required int year,
    required Season season,
    int limit = 100,
  }) async {
    try {
      return await _api.getSeasonalAnime(
        year: year,
        season: season,
        limit: limit,
      );
    } on DioException catch (e) {
      // Return empty list for 404 (season not found / too far in future)
      if (e.response?.statusCode == 404) {
        _logger?.i('Season $season $year not available yet');
        return [];
      }
      _logger?.e('getSeasonalAnime failed', error: e);
      throw _mapDioException(e);
    }
  }

  /// Get anime detail. Returns `null` if the anime doesn't exist (404).
  Future<AnimeDetail?> getAnimeDetail(int animeId) async {
    try {
      return await _api.getAnimeDetail(animeId);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _logger?.i('Anime $animeId not found on MAL');
        return null;
      }
      _logger?.e('getAnimeDetail failed', error: e);
      throw _mapDioException(e);
    }
  }

  /// Get anime ranking.
  Future<List<Anime>> getAnimeRanking({
    String rankingType = 'all',
    int limit = 20,
  }) async {
    try {
      return await _api.getAnimeRanking(
        rankingType: rankingType,
        limit: limit,
      );
    } on DioException catch (e) {
      _logger?.e('getAnimeRanking failed', error: e);
      throw _mapDioException(e);
    }
  }

  /// Get the current user's anime list filtered by [status].
  ///
  /// Use [WatchStatus.watching], [WatchStatus.planToWatch] or
  /// [WatchStatus.onHold] for the corresponding tabs.
  Future<List<Anime>> getUserAnimeList({
    WatchStatus status = WatchStatus.watching,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      return await _api.getUserAnimeList(
        status: status,
        limit: limit,
        offset: offset,
      );
    } on DioException catch (e) {
      _logger?.e('getUserAnimeList failed', error: e);
      throw _mapDioException(e);
    }
  }

  /// Remove [animeId] from the user's list.
  Future<void> deleteAnimeFromList(int animeId) async {
    try {
      await _api.deleteAnimeFromList(animeId);
    } on DioException catch (e) {
      _logger?.e('deleteAnimeFromList failed', error: e);
      throw _mapDioException(e);
    }
  }

  /// Update the user's list status for [animeId].
  Future<void> updateAnimeListStatus(
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
      await _api.updateAnimeListStatus(
        animeId,
        status: status,
        numWatchedEpisodes: numWatchedEpisodes,
        score: score,
        isRewatching: isRewatching,
        priority: priority,
        rewatchValue: rewatchValue,
        comments: comments,
      );
    } on DioException catch (e) {
      _logger?.e('updateAnimeListStatus failed', error: e);
      throw _mapDioException(e);
    }
  }

  /// Fetch the current user's MAL profile info.
  Future<MalUser> getUserInfo() async {
    try {
      return await _api.getUserInfo();
    } on DioException catch (e) {
      _logger?.e('getUserInfo failed', error: e);
      throw _mapDioException(e);
    }
  }

  ApiException _mapDioException(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        ApiException.network(message: e.message ?? 'Network error'),
      _ when e.response?.statusCode == 401 =>
        const ApiException.unauthorized(),
      _ when e.response != null =>
        ApiException.server(
          statusCode: e.response!.statusCode!,
          message: e.response?.statusMessage ?? 'Server error',
        ),
      _ => ApiException.unknown(message: e.message),
    };
  }
}
