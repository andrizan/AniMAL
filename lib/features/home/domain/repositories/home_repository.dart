import 'package:animal/data/models/season.dart';
import 'package:animal/features/home/domain/entities/anime_entity.dart';

abstract interface class HomeRepository {
  Future<List<AnimeEntity>> getSeasonalAnime({
    required int year,
    required Season season,
  });

  Future<List<AnimeEntity>> getAnimeRanking({
    String rankingType,
    int limit,
  });

  Future<List<AnimeEntity>> getUserAnimeList({
    required String status,
    int limit,
    int offset,
  });

  Future<void> updateAnimeListStatus(
    int animeId, {
    String? status,
    int? numWatchedEpisodes,
    int? score,
  });
}
