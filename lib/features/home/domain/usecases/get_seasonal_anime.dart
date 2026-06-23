import 'package:animal/data/models/season.dart';
import 'package:animal/features/home/domain/entities/anime_entity.dart';
import 'package:animal/features/home/domain/repositories/home_repository.dart';

final class GetSeasonalAnime {
  const GetSeasonalAnime(this._repository);

  final HomeRepository _repository;

  Future<List<AnimeEntity>> call({
    required int year,
    required Season season,
  }) {
    return _repository.getSeasonalAnime(year: year, season: season);
  }
}
