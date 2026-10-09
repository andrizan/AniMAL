import 'dart:math' show min;

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
    // Serve whatever rows we have even when `cache_meta` is gone (e.g. after
    // invalidateAnimeDetail from a list mutation): the SWR layer refreshes in
    // the background, and a failed refetch now falls back to stored data
    // instead of showing an error or an empty page.
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
    // A stub row (created by the AniList cache before the MAL detail was
    // ever fetched) carries no useful data: treat it as a cache miss.
    final isStub =
        detailRow.isEmpty && ((row.first['title'] as String?)?.isEmpty ?? true);
    if (isStub) return null;
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
      whereArgs: ['userlist_%'],
    );
  }

  @override
  Future<void> invalidateUserAnimeList(
    String status,
    int limit,
    int offset,
  ) async {
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
  Future<void> applyUserListMutation(
    int malId,
    MyListStatus status,
    int limit,
    int offset,
  ) async {
    final newKey = userListKey(status.status.value, limit, offset);
    await _db.transaction((txn) async {
      await _setMyListStatus(txn, malId, status);
      final memberships = await txn.query(
        'user_anime_list_item',
        columns: ['cache_key'],
        where: 'mal_id = ?',
        whereArgs: [malId],
      );
      final keys = {for (final r in memberships) r['cache_key']! as String};
      if (keys.isEmpty) {
        await txn.delete(
          'cache_meta',
          where: 'cache_key = ?',
          whereArgs: [newKey],
        );
        return;
      }
      await txn.delete(
        'user_anime_list_item',
        where: 'mal_id = ? AND cache_key != ?',
        whereArgs: [malId, newKey],
      );
      if (keys.contains(newKey)) return;
      final cached = await txn.query(
        'cache_meta',
        columns: ['cache_key'],
        where: 'cache_key = ?',
        whereArgs: [newKey],
      );
      if (cached.isEmpty) return;
      final next = await txn.rawQuery(
        'SELECT COALESCE(MAX(position), -1) + 1 AS next '
        'FROM user_anime_list_item WHERE cache_key = ?',
        [newKey],
      );
      await txn.insert('user_anime_list_item', {
        'cache_key': newKey,
        'mal_id': malId,
        'position': next.first['next'],
      });
    });
  }

  @override
  Future<void> clearCachedAnimeListStatus(int malId) async {
    await _writeMyListStatus(malId, null);
  }

  // ---------- Internal helpers ----------

  Future<void> _writeMyListStatus(int malId, MyListStatus? status) async {
    await _db.transaction((txn) => _setMyListStatus(txn, malId, status));
  }

  Future<void> _setMyListStatus(
    DatabaseExecutor txn,
    int malId,
    MyListStatus? status,
  ) async {
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
  }

  Future<List<Anime>?> _readList(
    String key, {
    String relation = 'search',
  }) async {
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
    if (rows.isEmpty) {
      // Keep the "cached empty result" contract only when the key was
      // actually fetched before; otherwise it is a genuine miss.
      if (await getFetchedAt(key) == null) return null;
      return <Anime>[];
    }
    final malIds = rows.map((r) => r['mal_id']! as int).toList();
    final genreMap = await _loadGenresForMany(malIds);
    return rows.map((r) {
      final id = r['mal_id']! as int;
      return _mappers.animeFromRow(r, genres: genreMap[id] ?? const <Genre>[]);
    }).toList();
  }

  Future<List<Genre>> _loadGenresFor(int malId) async {
    final map = await _loadGenresForMany([malId]);
    return map[malId] ?? const <Genre>[];
  }

  static const _maxSqlVariables = 500;

  Iterable<List<int>> _chunks(List<int> ids) sync* {
    for (var i = 0; i < ids.length; i += _maxSqlVariables) {
      yield ids.sublist(i, min(i + _maxSqlVariables, ids.length));
    }
  }

  Future<Map<int, List<Genre>>> _loadGenresForMany(List<int> malIds) async {
    final result = <int, List<Genre>>{};
    for (final chunk in _chunks(malIds)) {
      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = await _db.rawQuery('''
        SELECT ag.mal_id, g.id, g.name
        FROM anime_genre ag
        JOIN genre g ON g.id = ag.genre_id
        WHERE ag.mal_id IN ($placeholders)
        ORDER BY ag.mal_id, g.id
        ''', chunk);
      for (final row in rows) {
        final mid = row['mal_id']! as int;
        final g = Genre(id: row['id']! as int, name: row['name']! as String);
        result.putIfAbsent(mid, () => <Genre>[]).add(g);
      }
    }
    return result;
  }

  Future<Map<int, Map<String, Object?>>> _loadAnimeRows(
    DatabaseExecutor txn,
    List<int> malIds,
  ) async {
    final result = <int, Map<String, Object?>>{};
    for (final chunk in _chunks(malIds)) {
      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = await txn.rawQuery(
        'SELECT * FROM anime WHERE mal_id IN ($placeholders)',
        chunk,
      );
      for (final row in rows) {
        result[row['mal_id']! as int] = {...row};
      }
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
      final known = await _loadAnimeRows(txn, [for (final a in results) a.id]);
      final batch = txn.batch();
      for (final a in results) {
        _queueAnimeUpsert(batch, a, known[a.id]);
        _queueGenres(batch, a.id, a.genres);
      }
      batch.delete(itemsTable, where: 'cache_key = ?', whereArgs: [key]);
      for (var i = 0; i < results.length; i++) {
        batch.insert(itemsTable, {
          'cache_key': key,
          'mal_id': results[i].id,
          'position': i,
        });
      }
      batch.insert('cache_meta', {
        'cache_key': key,
        'fetched_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await batch.commit(noResult: true);
    });
  }

  void _queueAnimeUpsert(Batch batch, Anime a, Map<String, Object?>? existing) {
    final row = _mappers.animeToRow(a);
    if (existing == null) {
      batch.insert('anime', row);
      return;
    }
    final merged = <String, Object?>{...existing};
    row.forEach((k, v) {
      if (v != null) merged[k] = v;
    });
    batch.update('anime', merged, where: 'mal_id = ?', whereArgs: [a.id]);
  }

  void _queueGenres(Batch batch, int malId, List<Genre> genres) {
    if (genres.isEmpty) return;
    batch.delete('anime_genre', where: 'mal_id = ?', whereArgs: [malId]);
    for (final g in genres) {
      batch
        ..insert('genre', {
          'id': g.id,
          'name': g.name,
        }, conflictAlgorithm: ConflictAlgorithm.ignore)
        ..insert('anime_genre', {'mal_id': malId, 'genre_id': g.id});
    }
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
      await _upsertAnime(txn, baseAnime);
      await _upsertGenres(txn, detail.id, detail.genres);
      await _upsertAnimeDetail(txn, detail);
      await _upsertCacheMeta(txn, key);
    });
  }

  /// Merge-based upsert. Never deletes the existing `anime` row (REPLACE
  /// would cascade-wipe anime_query_item / user_anime_list_item entries and
  /// anime_detail for this anime). Null incoming fields keep the old value so
  /// partial responses never erase richer cached data.
  Future<void> _upsertAnime(DatabaseExecutor txn, Anime a) async {
    final row = _mappers.animeToRow(a);
    final existing = await txn.query(
      'anime',
      where: 'mal_id = ?',
      whereArgs: [a.id],
      limit: 1,
    );
    if (existing.isEmpty) {
      await txn.insert('anime', row);
      return;
    }
    final merged = <String, Object?>{...existing.first};
    row.forEach((k, v) {
      if (v != null) merged[k] = v;
    });
    await txn.update('anime', merged, where: 'mal_id = ?', whereArgs: [a.id]);
  }

  /// Merge-based upsert for `anime_detail`. Null incoming fields keep old.
  Future<void> _upsertAnimeDetail(DatabaseExecutor txn, AnimeDetail d) async {
    final row = _mappers.animeDetailToExtraRow(d);
    final existing = await txn.query(
      'anime_detail',
      where: 'mal_id = ?',
      whereArgs: [d.id],
      limit: 1,
    );
    if (existing.isEmpty) {
      await txn.insert('anime_detail', row);
      return;
    }
    final merged = <String, Object?>{...existing.first};
    row.forEach((k, v) {
      if (v != null) merged[k] = v;
    });
    await txn.update(
      'anime_detail',
      merged,
      where: 'mal_id = ?',
      whereArgs: [d.id],
    );
  }

  /// Only replaces genre links when the incoming list is non-empty, so a
  /// partial response cannot wipe previously cached genres.
  Future<void> _upsertGenres(
    DatabaseExecutor txn,
    int malId,
    List<Genre> genres,
  ) async {
    if (genres.isEmpty) return;
    await txn.delete('anime_genre', where: 'mal_id = ?', whereArgs: [malId]);
    for (final g in genres) {
      await txn.insert('genre', {
        'id': g.id,
        'name': g.name,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await txn.insert('anime_genre', {'mal_id': malId, 'genre_id': g.id});
    }
  }

  Future<void> _upsertCacheMeta(DatabaseExecutor txn, String key) async {
    await txn.insert('cache_meta', {
      'cache_key': key,
      'fetched_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
