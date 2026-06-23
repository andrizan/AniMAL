import 'package:animal/features/home/domain/entities/anime_entity.dart';
import 'package:animal/features/home/domain/repositories/home_repository.dart';

final class GetTrendingAnime {
  const GetTrendingAnime(this._repository);

  final HomeRepository _repository;

  Future<List<AnimeEntity>> call({int limit = 20}) {
    return _repository.getAnimeRanking(rankingType: 'all', limit: limit);
  }
}
