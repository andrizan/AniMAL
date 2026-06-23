import 'package:animal/data/mal/mal_api_client.dart';
import 'package:animal/data/models/season.dart' show Season;
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/features/home/domain/entities/anime_entity.dart';
import 'package:animal/features/home/domain/repositories/home_repository.dart';
import 'package:dio/dio.dart';
import 'package:animal/core/logger/app_logger.dart';
import 'package:logger/logger.dart';

final class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({
    required MalApiClient malApi,
    Logger? logger,
  }) : _malApi = malApi,
       _logger = logger ?? appLogger;

  final MalApiClient _malApi;
  final Logger _logger;

  @override
  Future<List<AnimeEntity>> getSeasonalAnime({
    required int year,
    required Season season,
  }) async {
    try {
      final result = await _malApi.getSeasonalAnime(
        year: year,
        season: season,
      );
      return result.map(AnimeEntity.fromModel).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      _logger.e('getSeasonalAnime failed', error: e);
      rethrow;
    }
  }

  @override
  Future<List<AnimeEntity>> getAnimeRanking({
    String rankingType = 'all',
    int limit = 20,
  }) async {
    try {
      final result = await _malApi.getAnimeRanking(
        rankingType: rankingType,
        limit: limit,
      );
      return result.map(AnimeEntity.fromModel).toList();
    } on DioException catch (e) {
      _logger.e('getAnimeRanking failed', error: e);
      rethrow;
    }
  }

  @override
  Future<List<AnimeEntity>> getUserAnimeList({
    required String status,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final watchStatus = WatchStatus.values.firstWhere(
        (s) => s.value == status,
        orElse: () => WatchStatus.watching,
      );
      final result = await _malApi.getUserAnimeList(
        status: watchStatus,
        limit: limit,
        offset: offset,
      );
      return result.map(AnimeEntity.fromModel).toList();
    } on DioException catch (e) {
      _logger.e('getUserAnimeList failed', error: e);
      rethrow;
    }
  }

  @override
  Future<void> updateAnimeListStatus(
    int animeId, {
    String? status,
    int? numWatchedEpisodes,
    int? score,
  }) async {
    try {
      final watchStatus = status != null
          ? WatchStatus.values.firstWhere(
              (s) => s.value == status,
              orElse: () => WatchStatus.watching,
            )
          : null;
      await _malApi.updateAnimeListStatus(
        animeId,
        status: watchStatus,
        numWatchedEpisodes: numWatchedEpisodes,
        score: score,
      );
    } on DioException catch (e) {
      _logger.e('updateAnimeListStatus failed', error: e);
      rethrow;
    }
  }
}
