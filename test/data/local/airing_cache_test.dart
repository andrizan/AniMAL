import 'dart:convert';
import 'dart:io';

import 'package:animal/data/local/airing_cache.dart';
import 'package:animal/data/local/app_database.dart';
import 'package:animal/data/models/anilist/anilist_models.dart';
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
    required DateTime airingAt,
    int? malId,
  }) {
    return AiringEntry(
      anilistId: anilistId,
      malId: malId,
      title: 'T$anilistId',
      airingAt: airingAt,
      episode: 1,
      timeUntilAiring: airingAt.difference(DateTime.now()).inSeconds,
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
    );
    final monday2 = makeEntry(
      anilistId: 2,
      malId: 20,
      airingAt: weekStart.add(const Duration(hours: 21)),
    );
    final thursday = makeEntry(
      anilistId: 3,
      malId: 30,
      airingAt: weekStart.add(const Duration(days: 3, hours: 12)),
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

  test('save and read hundreds of entries keeps per-day order', () async {
    final now = DateTime.now().toUtc();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime.utc(monday.year, monday.month, monday.day);
    final weekStartSec = weekStart.millisecondsSinceEpoch ~/ 1000;
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final week = <String, List<AiringEntry>>{
      for (var d = 0; d < days.length; d++)
        days[d]: [
          for (var i = 0; i < 80; i++)
            makeEntry(
              anilistId: d * 1000 + i,
              airingAt: weekStart.add(Duration(days: d, minutes: i * 10)),
            ),
        ],
    };

    await cache.saveMergedWeek(weekStartSec, week);

    final out = await cache.getMergedWeek(weekStartSec);
    expect(out!.values.fold<int>(0, (s, l) => s + l.length), 560);
    expect(out['sunday']!.map((e) => e.anilistId).toList(), [
      for (var i = 0; i < 80; i++) 6000 + i,
    ]);
  });

  test('updateMyListStatus rewrites only the matching anime', () async {
    final now = DateTime.now().toUtc();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime.utc(monday.year, monday.month, monday.day);
    final weekStartSec = weekStart.millisecondsSinceEpoch ~/ 1000;
    AiringEntry entry(int anilistId, int malId) => AiringEntry(
      anilistId: anilistId,
      malId: malId,
      title: 'T$anilistId',
      airingAt: weekStart.add(Duration(hours: anilistId)),
      episode: 1,
      timeUntilAiring: 0,
      myListStatus: const MyListStatus(
        status: WatchStatus.watching,
        numEpisodesWatched: 1,
      ),
    );
    await cache.saveMergedWeek(weekStartSec, {
      'monday': [entry(1, 10), entry(2, 20)],
    });

    await cache.updateMyListStatus(
      10,
      const MyListStatus(
        status: WatchStatus.completed,
        numEpisodesWatched: 12,
        score: 9,
      ),
    );

    var week = (await cache.getMergedWeek(weekStartSec))!['monday']!;
    expect(week[0].myListStatus?.status, WatchStatus.completed);
    expect(week[0].myListStatus?.numEpisodesWatched, 12);
    expect(week[0].myListStatus?.score, 9);
    expect(week[1].myListStatus?.numEpisodesWatched, 1);

    await cache.updateMyListStatus(10, null);

    week = (await cache.getMergedWeek(weekStartSec))!['monday']!;
    expect(week[0].myListStatus, isNull);
    expect(week[1].myListStatus, isNotNull);
  });

  test(
    'syncMyListStatuses copies the stored anime statuses into the week',
    () async {
      final now = DateTime.now().toUtc();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final weekStart = DateTime.utc(monday.year, monday.month, monday.day);
      final weekStartSec = weekStart.millisecondsSinceEpoch ~/ 1000;
      AiringEntry entry(int anilistId, int? malId) => AiringEntry(
        anilistId: anilistId,
        malId: malId,
        title: 'T$anilistId',
        airingAt: weekStart.add(Duration(hours: anilistId)),
        episode: 1,
        timeUntilAiring: 0,
        myListStatus: const MyListStatus(
          status: WatchStatus.watching,
          numEpisodesWatched: 1,
        ),
      );
      await cache.saveMergedWeek(weekStartSec, {
        'monday': [entry(1, 10), entry(2, 20), entry(3, 30), entry(4, null)],
      });
      await appDb.raw.insert('anime', {
        'mal_id': 10,
        'title': 'Completed on the website',
        'my_list_status_json': jsonEncode({
          'status': 'completed',
          'num_episodes_watched': 12,
          'score': 9,
        }),
        'my_list_status_user': 'completed',
      });
      await appDb.raw.insert('anime', {
        'mal_id': 20,
        'title': 'Not in the list',
      });

      await cache.syncMyListStatuses();

      final week = (await cache.getMergedWeek(weekStartSec))!['monday']!;
      expect(week[0].myListStatus?.status, WatchStatus.completed);
      expect(week[0].myListStatus?.numEpisodesWatched, 12);
      expect(week[0].myListStatus?.score, 9);
      expect(week[1].myListStatus, isNull);
      expect(week[2].myListStatus?.numEpisodesWatched, 1);
      expect(week[3].myListStatus?.numEpisodesWatched, 1);
    },
  );

  test('updateNextAiring replaces the next episode in every entry of an '
      'anime and leaves the others alone', () async {
    final now = DateTime.now().toUtc();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime.utc(monday.year, monday.month, monday.day);
    final weekStartSec = weekStart.millisecondsSinceEpoch ~/ 1000;
    AiringEntry entry(int anilistId, int malId, int episode) => AiringEntry(
      anilistId: anilistId,
      malId: malId,
      title: 'T$anilistId',
      airingAt: weekStart.add(Duration(hours: anilistId)),
      episode: episode,
      timeUntilAiring: 0,
      status: 'RELEASING',
      nextAiringAt: weekStart.add(Duration(hours: anilistId)),
      nextEpisode: episode,
      nextTimeUntilAiring: 0,
    );
    await cache.saveMergedWeek(weekStartSec, {
      'monday': [entry(1, 10, 2), entry(2, 20, 5)],
      'tuesday': [entry(1, 10, 3)],
    });
    final next = AniListNextAiring(
      airingAt: DateTime.utc(2030, 1, 2, 3, 4),
      episode: 4,
      timeUntilAiring: 600,
    );

    await cache.updateNextAiring(10, next: next, status: 'FINISHED');

    final week = (await cache.getMergedWeek(weekStartSec))!;
    for (final e in [week['monday']![0], week['tuesday']![0]]) {
      expect(e.nextAiringAt, next.airingAt);
      expect(e.nextEpisode, 4);
      expect(e.nextTimeUntilAiring, 600);
      expect(e.status, 'FINISHED');
    }
    final other = week['monday']![1];
    expect(other.nextEpisode, 5);
    expect(other.status, 'RELEASING');
  });

  test('updateNextAiring with no next episode clears it and keeps the '
      'status when none is given', () async {
    final now = DateTime.now().toUtc();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime.utc(monday.year, monday.month, monday.day);
    final weekStartSec = weekStart.millisecondsSinceEpoch ~/ 1000;
    await cache.saveMergedWeek(weekStartSec, {
      'monday': [
        AiringEntry(
          anilistId: 1,
          malId: 10,
          title: 'T1',
          airingAt: weekStart.add(const Duration(hours: 1)),
          episode: 2,
          timeUntilAiring: 0,
          status: 'RELEASING',
          nextAiringAt: weekStart.add(const Duration(hours: 1)),
          nextEpisode: 2,
          nextTimeUntilAiring: 0,
        ),
      ],
    });

    await cache.updateNextAiring(10, next: null);

    final e = (await cache.getMergedWeek(weekStartSec))!['monday']!.single;
    expect(e.nextAiringAt, isNull);
    expect(e.nextEpisode, isNull);
    expect(e.status, 'RELEASING');
  });
}
