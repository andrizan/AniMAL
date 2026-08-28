import 'package:animal/data/local/anime_cache.dart';
import 'package:animal/data/local/app_database.dart';
import 'package:animal/data/local/cache_mappers.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/data/models/mal_user.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite-backed [AnimeCache] implementation.
class SqliteAnimeCache implements AnimeCache {
  SqliteAnimeCache(this._appDb, {CacheMappers? mappers})
    : _mappers = mappers ?? const CacheMappers();

  final AppDatabase _appDb;
  final CacheMappers _mappers;

  Database get _db => _appDb.raw;

  // ---------- Key builders ----------

  static String searchKey(String query, int limit) {
    final normalized = query.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    return 'search_${normalized}_$limit';
  }

  static String seasonalKey(int year, String season, int limit) =>
      'seasonal_${year}_${season}_$limit';

  static String rankingKey(String type, int limit) => 'ranking_${type}_$limit';

  static String detailKey(int malId) => 'detail_$malId';

  static String userListKey(String status, int limit, int offset) =>
      'userlist_${status}_${limit}_$offset';

  static const _userInfoKey = 'userInfo';

  // ---------- Public read API ----------

  @override
  Future<List<Anime>?> getSearchResults(String query, int limit) async {
    return _readList(searchKey(query, limit));
  }

  @override
  Future<List<Anime>?> getSeasonalAnime(int year, String season, int limit) {
    return _readList(seasonalKey(year, season, limit));
  }

  @override
  Future<List<Anime>?> getAnimeRanking(String rankingType, int limit) {
    return _readList(rankingKey(rankingType, limit));
  }

  @override
  Future<List<Anime>?> getUserAnimeList(String status, int limit, int offset) {
    return _readList(userListKey(status, limit, offset), relation: 'userlist');
  }

  @override
  Future<DateTime?> getFetchedAt(String cacheKey) async {
    final rows = await _db.query(
      'cache_meta',
      columns: ['fetched_at'],
      where: 'cache_key = ?',
      whereArgs: [cacheKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final ms = rows.first['fetched_at']! as int;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  @override
  Future<AnimeDetail?> getAnimeDetail(int malId) async {
    final key = detailKey(malId);
    if (await getFetchedAt(key) == null) return null;
    final row = await _db.query(
      'anime',
      columns: ['*'],
      where: 'mal_id = ?',
      whereArgs: [malId],
      limit: 1,
    );
    if (row.isEmpty) return null;
    final detailRow = await _db.query(
      'anime_detail',
      where: 'mal_id = ?',
      whereArgs: [malId],
      limit: 1,
    );
    final merged = <String, Object?>{...row.first};
    if (detailRow.isNotEmpty) {
      merged.addAll(detailRow.first);
    }
    final genres = await _loadGenresFor(malId);
    return _mappers.animeDetailFromRow(merged, genres: genres);
  }

  @override
  Future<MalUser?> getUserInfo() async {
    if (await getFetchedAt(_userInfoKey) == null) return null;
    final rows = await _db.query(
      'mal_user_cache',
      where: 'cache_key = ?',
      whereArgs: [_userInfoKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _mappers.malUserFromRow(rows.first);
  }

  // ---------- Public write API ----------

  @override
  Future<void> saveSearchResults(String query, int limit, List<Anime> results) {
    return _saveList(searchKey(query, limit), results);
  }

  @override
  Future<void> saveSeasonalAnime(
    int year,
    String season,
    int limit,
    List<Anime> results,
  ) {
    return _saveList(seasonalKey(year, season, limit), results);
  }

  @override
  Future<void> saveAnimeRanking(
    String rankingType,
    int limit,
    List<Anime> results,
  ) {
    return _saveList(rankingKey(rankingType, limit), results);
  }

  @override
  Future<void> saveUserAnimeList(
    String status,
    int limit,
    int offset,
    List<Anime> results,
  ) {
    return _saveList(
      userListKey(status, limit, offset),
      results,
      relation: 'userlist',
    );
  }

  @override
  Future<void> saveAnimeDetail(AnimeDetail detail) async {
    final key = detailKey(detail.id);
    await _saveDetailInTxn(detail, key);
  }

  @override
  Future<void> saveUserInfo(MalUser user) async {
    await _db.transaction((txn) async {
      await txn.insert(
        'mal_user_cache',
        _mappers.malUserToRow(user),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _upsertCacheMeta(txn, _userInfoKey);
    });
  }

  // ---------- Public invalidation API ----------

  @override
  Future<void> invalidateAnimeDetail(int malId) async {
    await _db.delete(
      'cache_meta',
      where: 'cache_key = ?',
      whereArgs: [detailKey(malId)],
    );
  }

  @override
  Future<void> invalidateUserAnimeLists() async {
    await _db.delete(
      'cache_meta',
      where: 'cache_key LIKE ?',
      whereArgs: [
        'userlist_%',
      ],
    );
  }

  @override
  Future<void> invalidateUserAnimeList(
      String status, int limit, int offset) async {
    await _db.delete(
      'cache_meta',
      where: 'cache_key = ?',
      whereArgs: [userListKey(status, limit, offset)],
    );
  }

  @override
  Future<void> updateCachedAnimeListStatus(
    int malId,
    MyListStatus status,
  ) async {
    await _writeMyListStatus(malId, status);
  }

  @override
  Future<void> clearCachedAnimeListStatus(int malId) async {
    await _writeMyListStatus(malId, null);
  }

  // ---------- Internal helpers ----------

  Future<void> _writeMyListStatus(int malId, MyListStatus? status) async {
    await _db.transaction((txn) async {
      await txn.update(
        'anime',
        {
          'my_list_status_json': status == null
              ? null
              : _mappers.encodeMyListStatus(status),
          'my_list_status_user': status?.status.value,
        },
        where: 'mal_id = ?',
        whereArgs: [malId],
      );
    });
  }

  Future<List<Anime>?> _readList(
    String key, {
    String relation = 'search',
  }) async {
    if (await getFetchedAt(key) == null) return null;
    final itemsTable = relation == 'userlist'
        ? 'user_anime_list_item'
        : 'anime_query_item';
    final rows = await _db.rawQuery(
      '''
      SELECT a.*, $itemsTable.position AS _pos
      FROM $itemsTable
      JOIN anime a ON a.mal_id = $itemsTable.mal_id
      WHERE $itemsTable.cache_key = ?
      ORDER BY $itemsTable.position ASC
      ''',
      [key],
    );
    if (rows.isEmpty) return <Anime>[];
    final malIds = rows.map((r) => r['mal_id']! as int).toList();
    final genreMap = await _loadGenresForMany(malIds);
    return rows.map((r) {
      final id = r['mal_id']! as int;
      return _mappers.animeFromRow(
        r,
        genres: genreMap[id] ?? const <Genre>[],
      );
    }).toList();
  }

  Future<List<Genre>> _loadGenresFor(int malId) async {
    final map = await _loadGenresForMany([malId]);
    return map[malId] ?? const <Genre>[];
  }

  Future<Map<int, List<Genre>>> _loadGenresForMany(List<int> malIds) async {
    if (malIds.isEmpty) return const <int, List<Genre>>{};
    final placeholders = List.filled(malIds.length, '?').join(',');
    final rows = await _db.rawQuery(
      '''
      SELECT ag.mal_id, g.id, g.name
      FROM anime_genre ag
      JOIN genre g ON g.id = ag.genre_id
      WHERE ag.mal_id IN ($placeholders)
      ORDER BY ag.mal_id, g.id
      ''',
      malIds,
    );
    final result = <int, List<Genre>>{};
    for (final row in rows) {
      final mid = row['mal_id']! as int;
      final g = Genre(id: row['id']! as int, name: row['name']! as String);
      result.putIfAbsent(mid, () => <Genre>[]).add(g);
    }
    return result;
  }

  Future<void> _saveList(
    String key,
    List<Anime> results, {
    String relation = 'search',
  }) async {
    final itemsTable = relation == 'userlist'
        ? 'user_anime_list_item'
        : 'anime_query_item';
    await _db.transaction((txn) async {
      for (final a in results) {
        final row = _mappers.animeToRow(a);
        // INSERT OR REPLACE keeps the row single; preserves FK target.
        await txn.insert(
          'anime',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        // Refresh genre rows
        await txn.delete(
          'anime_genre',
          where: 'mal_id = ?',
          whereArgs: [a.id],
        );
        for (final g in a.genres) {
          await txn.insert(
            'genre',
            {'id': g.id, 'name': g.name},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
          await txn.insert('anime_genre', {
            'mal_id': a.id,
            'genre_id': g.id,
          });
        }
      }
      await txn.delete(
        itemsTable,
        where: 'cache_key = ?',
        whereArgs: [key],
      );
      for (var i = 0; i < results.length; i++) {
        await txn.insert(itemsTable, {
          'cache_key': key,
          'mal_id': results[i].id,
          'position': i,
        });
      }
      await _upsertCacheMeta(txn, key);
    });
  }

  Future<void> _saveDetailInTxn(AnimeDetail detail, String key) async {
    await _db.transaction((txn) async {
      // Upsert anime row first (without detail-only fields)
      final baseAnime = Anime(
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
      await txn.insert(
        'anime',
        _mappers.animeToRow(baseAnime),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      // Refresh genres
      await txn.delete(
        'anime_genre',
        where: 'mal_id = ?',
        whereArgs: [detail.id],
      );
      for (final g in detail.genres) {
        await txn.insert(
          'genre',
          {'id': g.id, 'name': g.name},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        await txn.insert('anime_genre', {
          'mal_id': detail.id,
          'genre_id': g.id,
        });
      }
      // Upsert detail row
      await txn.insert(
        'anime_detail',
        _mappers.animeDetailToExtraRow(detail),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _upsertCacheMeta(txn, key);
    });
  }

  Future<void> _upsertCacheMeta(DatabaseExecutor txn, String key) async {
    await txn.insert(
      'cache_meta',
      {
        'cache_key': key,
        'fetched_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
