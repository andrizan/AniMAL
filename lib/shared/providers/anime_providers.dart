import 'package:animal/core/providers.dart';
import 'package:animal/data/mal/mal_api_client.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/data/models/mal_user.dart';
import 'package:animal/data/models/season.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/core/network/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// Provider for [MalApiClient].
final malAnimeApiProvider = Provider<MalApiClient>((ref) {
  return MalApiClient(ref.watch(dioProvider));
});

/// High-level repository that wraps [MalApiClient] with error handling.
class AnimeRepository {
  const AnimeRepository(this._api, [this._logger]);

  final MalApiClient _api;
  final Logger? _logger;

  Future<List<Anime>> searchAnime(String query, {int limit = 20}) async {
    try {
      return await _api.searchAnime(query, limit: limit);
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
    try {
      return await _api.getSeasonalAnime(year: year, season: season, limit: limit);
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

  Future<List<Anime>> getAnimeRanking({
    String rankingType = 'all',
    int limit = 20,
  }) async {
    try {
      return await _api.getAnimeRanking(rankingType: rankingType, limit: limit);
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
    try {
      return await _api.getUserAnimeList(status: status, limit: limit, offset: offset);
    } on DioException catch (e) {
      _logger?.e('getUserAnimeList failed', error: e);
      throw _mapDioException(e);
    }
  }

  Future<void> deleteAnimeFromList(int animeId) async {
    try {
      await _api.deleteAnimeFromList(animeId);
    } on DioException catch (e) {
      _logger?.e('deleteAnimeFromList failed', error: e);
      throw _mapDioException(e);
    }
  }

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

  Future<MalUser?> getUserInfo() async {
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

/// Provider for [AnimeRepository].
final animeRepositoryProvider = Provider<AnimeRepository>((ref) {
  return AnimeRepository(
    ref.watch(malAnimeApiProvider),
    ref.watch(loggerProvider),
  );
});
