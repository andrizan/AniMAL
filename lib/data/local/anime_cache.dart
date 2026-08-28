import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/data/models/mal_user.dart';
import 'package:animal/data/models/my_list_status.dart';

/// Typed cache for MAL endpoints (search, seasonal, detail, ranking, user
/// list, user info).
abstract interface class AnimeCache {
  // Read
  Future<List<Anime>?> getSearchResults(String query, int limit);
  Future<List<Anime>?> getSeasonalAnime(int year, String season, int limit);
  Future<AnimeDetail?> getAnimeDetail(int malId);
  Future<List<Anime>?> getAnimeRanking(String rankingType, int limit);
  Future<List<Anime>?> getUserAnimeList(String status, int limit, int offset);
  Future<MalUser?> getUserInfo();
  Future<DateTime?> getFetchedAt(String cacheKey);

  // Write
  Future<void> saveSearchResults(String query, int limit, List<Anime> results);
  Future<void> saveSeasonalAnime(
    int year,
    String season,
    int limit,
    List<Anime> results,
  );
  Future<void> saveAnimeDetail(AnimeDetail detail);
  Future<void> saveAnimeRanking(
    String rankingType,
    int limit,
    List<Anime> results,
  );
  Future<void> saveUserAnimeList(
    String status,
    int limit,
    int offset,
    List<Anime> results,
  );
  Future<void> saveUserInfo(MalUser user);

  // Invalidation
  Future<void> invalidateAnimeDetail(int malId);
  Future<void> invalidateUserAnimeLists();
  Future<void> invalidateUserAnimeList(String status, int limit, int offset);
  Future<void> updateCachedAnimeListStatus(int malId, MyListStatus status);
  Future<void> clearCachedAnimeListStatus(int malId);
}
