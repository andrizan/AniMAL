import 'dart:io';

import 'package:animal/data/local/airing_cache.dart';
import 'package:animal/data/local/app_database.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/shared/providers/airing_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase appDb;
  late AiringCache cache;

  setUp(() async {
    final tmp = Directory.systemTemp.createTempSync('airing_cache_');
    appDb = await AppDatabase.open(
      pathOverride: '${tmp.path}/test.db',
      runMigrations: false,
    );
    cache = SqliteAiringCache(appDb);
  });

  tearDown(() async {
    await appDb.close();
  });

  AiringEntry makeEntry({
    required int anilistId,
    int? malId,
    required DateTime airingAt,
    String day = 'monday',
  }) {
    return AiringEntry(
      anilistId: anilistId,
      malId: malId,
      title: 'T$anilistId',
      airingAt: airingAt,
      episode: 1,
      timeUntilAiring: airingAt.difference(DateTime.now()).inSeconds,
      myListStatus: WatchStatus.watching == WatchStatus.watching
          ? null
          : MyListStatus(status: WatchStatus.watching),
    );
  }

  test('save and read merged week preserves day grouping and order', () async {
    final now = DateTime.now().toUtc();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime.utc(monday.year, monday.month, monday.day);
    final weekStartSec = weekStart.millisecondsSinceEpoch ~/ 1000;

    final monday1 = makeEntry(
      anilistId: 1,
      malId: 10,
      airingAt: weekStart.add(const Duration(hours: 9)),
      day: 'monday',
    );
    final monday2 = makeEntry(
      anilistId: 2,
      malId: 20,
      airingAt: weekStart.add(const Duration(hours: 21)),
      day: 'monday',
    );
    final thursday = makeEntry(
      anilistId: 3,
      malId: 30,
      airingAt: weekStart.add(const Duration(days: 3, hours: 12)),
      day: 'thursday',
    );

    final week = <String, List<AiringEntry>>{
      'monday': [monday1, monday2],
      'thursday': [thursday],
    };

    await cache.saveMergedWeek(weekStartSec, week);
    final out = await cache.getMergedWeek(weekStartSec);
    expect(out, isNotNull);
    expect(out!['monday']!.length, 2);
    expect(out['thursday']!.length, 1);
    expect(out['monday']!.first.anilistId, 1);
    expect(out['monday']!.last.anilistId, 2);
  });

  test('invalidateMergedWeek clears cache', () async {
    final now = DateTime.now().toUtc();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime.utc(monday.year, monday.month, monday.day);
    final weekStartSec = weekStart.millisecondsSinceEpoch ~/ 1000;

    await cache.saveMergedWeek(weekStartSec, {
      'monday': [makeEntry(anilistId: 1, airingAt: weekStart)],
    });
    expect(await cache.getMergedWeek(weekStartSec), isNotNull);
    await cache.invalidateMergedWeek(weekStartSec);
    expect(await cache.getMergedWeek(weekStartSec), isNull);
  });
}
