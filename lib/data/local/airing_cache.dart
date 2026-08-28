import 'dart:convert';

import 'package:animal/data/local/app_database.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/shared/providers/airing_entry.dart';
import 'package:sqflite/sqflite.dart';

/// Typed cache for the merged weekly airing schedule.
abstract interface class AiringCache {
  Future<DateTime?> getFetchedAt(String cacheKey);
  Future<Map<String, List<AiringEntry>>?> getMergedWeek(int weekStartEpochSec);
  Future<void> saveMergedWeek(
    int weekStartEpochSec,
    Map<String, List<AiringEntry>> week,
  );
  Future<void> invalidateMergedWeek(int weekStartEpochSec);
}

class SqliteAiringCache implements AiringCache {
  SqliteAiringCache(this._appDb);

  final AppDatabase _appDb;
  Database get _db => _appDb.raw;

  static String _mergedKey(int weekStartEpochSec) {
    final dt = DateTime.fromMillisecondsSinceEpoch(weekStartEpochSec * 1000)
        .toUtc();
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return 'weekly_schedule:$y-$m-$d';
  }

  static const _dayNames = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

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
    return DateTime.fromMillisecondsSinceEpoch(
      rows.first['fetched_at']! as int,
    );
  }

  @override
  Future<Map<String, List<AiringEntry>>?> getMergedWeek(
    int weekStartEpochSec,
  ) async {
    final key = _mergedKey(weekStartEpochSec);
    if (await getFetchedAt(key) == null) return null;
    final rows = await _db.query(
      'merged_airing_entry',
      where: 'week_key = ?',
      whereArgs: [key],
      orderBy: 'day, position ASC',
    );
    final grouped = <String, List<AiringEntry>>{
      for (final d in _dayNames) d: <AiringEntry>[],
    };
    for (final row in rows) {
      final day = row['day']! as String;
      grouped.putIfAbsent(day, () => <AiringEntry>[]).add(_entryFromRow(row));
    }
    return grouped;
  }

  @override
  Future<void> saveMergedWeek(
    int weekStartEpochSec,
    Map<String, List<AiringEntry>> week,
  ) async {
    final key = _mergedKey(weekStartEpochSec);
    await _db.transaction((txn) async {
      await txn.delete(
        'merged_airing_entry',
        where: 'week_key = ?',
        whereArgs: [key],
      );
      for (final day in week.keys) {
        final list = week[day]!;
        for (var i = 0; i < list.length; i++) {
          final e = list[i];
          await txn.insert('merged_airing_entry', {
            'week_key': key,
            'day': day,
            'anilist_id': e.anilistId,
            'position': i,
            'mal_id': e.malId,
            'title': e.title,
            'title_english': e.titleEnglish,
            'title_native': e.titleNative,
            'image_url': e.imageUrl,
            'airing_at': e.airingAt.millisecondsSinceEpoch ~/ 1000,
            'episode': e.episode,
            'time_until_airing': e.timeUntilAiring,
            'mal_score': e.malScore,
            'genres_json': e.genres.isEmpty ? null : jsonEncode(e.genres),
            'episodes': e.episodes,
            'format': e.format,
            'status': e.status,
            'my_list_status_json': e.myListStatus == null
                ? null
                : _encodeStatus(e.myListStatus!),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      await txn.insert(
        'cache_meta',
        {
          'cache_key': key,
          'fetched_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<void> invalidateMergedWeek(int weekStartEpochSec) async {
    final key = _mergedKey(weekStartEpochSec);
    await _db.transaction((txn) async {
      await txn.delete(
        'cache_meta',
        where: 'cache_key = ?',
        whereArgs: [key],
      );
      await txn.delete(
        'merged_airing_entry',
        where: 'week_key = ?',
        whereArgs: [key],
      );
    });
  }

  AiringEntry _entryFromRow(Map<String, Object?> row) {
    final genresJson = row['genres_json'] as String?;
    final statusJson = row['my_list_status_json'] as String?;
    return AiringEntry(
      anilistId: row['anilist_id']! as int,
      title: row['title']! as String,
      airingAt: DateTime.fromMillisecondsSinceEpoch(
        (row['airing_at']! as int) * 1000,
      ),
      episode: row['episode']! as int,
      timeUntilAiring: row['time_until_airing']! as int,
      malId: row['mal_id'] as int?,
      titleEnglish: row['title_english'] as String?,
      titleNative: row['title_native'] as String?,
      imageUrl: row['image_url'] as String?,
      malScore: (row['mal_score'] as num?)?.toDouble(),
      genres: genresJson == null
          ? const <String>[]
          : (jsonDecode(genresJson) as List<dynamic>).cast<String>(),
      episodes: row['episodes'] as int?,
      format: row['format'] as String?,
      status: row['status'] as String?,
      myListStatus: statusJson == null ? null : _decodeStatus(statusJson),
    );
  }

  String _encodeStatus(MyListStatus s) {
    return jsonEncode(<String, dynamic>{
      'status': s.status.value,
      'num_episodes_watched': s.numEpisodesWatched,
      'score': s.score,
      'is_rewatching': s.isRewatching,
      'updated_at': s.updatedAt,
      'num_times_rewatched': s.numTimesRewatched,
      'priority': s.priority,
      'rewatch_value': s.rewatchValue,
      'comments': s.comments,
    });
  }

  MyListStatus _decodeStatus(String raw) {
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return MyListStatus(
      status: WatchStatus.values.firstWhere(
        (w) => w.value == m['status'],
        orElse: () => WatchStatus.watching,
      ),
      numEpisodesWatched: m['num_episodes_watched'] as int?,
      score: m['score'] as int?,
      isRewatching: m['is_rewatching'] as bool?,
      updatedAt: m['updated_at'] as String?,
      numTimesRewatched: m['num_times_rewatched'] as int?,
      priority: m['priority'] as int?,
      rewatchValue: m['rewatch_value'] as int?,
      comments: m['comments'] as String?,
    );
  }
}
