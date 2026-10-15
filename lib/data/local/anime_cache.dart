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

  /// The stored row of an anime, with no network: null when the anime was
  /// never fetched or is only a stub made for its AniList extra.
  Future<Anime?> getCachedAnime(int malId);
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
  Future<void> invalidateUserAnimeList(String status, int limit, int offset);
  Future<void> updateCachedAnimeListStatus(int malId, MyListStatus status);
  Future<void> applyUserListMutation(
    int malId,
    MyListStatus status,
    int limit,
    int offset,
  );

  /// Forgets the personal status of [malId] and drops it from every cached
  /// user list. The lists stay valid, so nothing is refetched.
  Future<void> applyUserListRemoval(int malId);
}
