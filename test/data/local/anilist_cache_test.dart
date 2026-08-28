import 'dart:io';

import 'package:animal/data/local/anilist_cache.dart';
import 'package:animal/data/local/app_database.dart';
import 'package:animal/data/models/anilist/anilist_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase appDb;
  late SqliteAniListCache cache;

  setUp(() async {
    final tmp = Directory.systemTemp.createTempSync('anilist_cache_');
    appDb = await AppDatabase.open(
      pathOverride: '${tmp.path}/test.db',
      runMigrations: false,
    );
    cache = SqliteAniListCache(appDb);
  });

  tearDown(() async {
    await appDb.close();
  });

  AniListScheduleEntry makeEntry({
    required int anilistId,
    required int malId,
    required DateTime airingAt,
    int episode = 1,
    String? title,
  }) {
    return AniListScheduleEntry(
      anilistId: anilistId,
      malId: malId,
      title: title ?? 'Title $anilistId',
      titleEnglish: 'English $anilistId',
      airingAt: airingAt,
      episode: episode,
      timeUntilAiring: airingAt.difference(DateTime.now()).inSeconds,
    );
  }

  group('AniListCache.weekly', () {
    test('save and read by week window', () async {
      final now = DateTime.now().toUtc();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final weekStart = DateTime.utc(monday.year, monday.month, monday.day);
      final weekStartSec = weekStart.millisecondsSinceEpoch ~/ 1000;

      final entry1 = makeEntry(
        anilistId: 1,
        malId: 10,
        airingAt: weekStart.add(const Duration(days: 0, hours: 10)),
      );
      final entry2 = makeEntry(
        anilistId: 2,
        malId: 20,
        airingAt: weekStart.add(const Duration(days: 3, hours: 10)),
      );

      final schedule = <String, List<AniListScheduleEntry>>{
        'monday': [entry1],
        'thursday': [entry2],
        for (final d in [
          'tuesday',
          'wednesday',
          'friday',
          'saturday',
          'sunday',
        ])
          d: <AniListScheduleEntry>[],
      };

      await cache.saveWeeklySchedule(weekStartSec, schedule);

      final out = await cache.getWeeklySchedule(weekStartSec);
      expect(out, isNotNull);
      expect(out!['monday']!.length, 1);
      expect(out['thursday']!.length, 1);
      expect(out['monday']!.first.anilistId, 1);
      expect(out['thursday']!.first.malId, 20);
    });

    test('week key changes on week boundary', () async {
      // Two different weekStart values produce different keys.
      final a = SqliteAniListCache.weeklyKey(0);
      final b = SqliteAniListCache.weeklyKey(7 * 24 * 60 * 60);
      expect(a, isNot(b));
    });
  });

  group('AniListCache.character', () {
    test('save and read preserves fields and media order', () async {
      final c = AniListCharacterDetail(
        id: 42,
        name: 'Spike',
        nativeName: 'スパイク',
        imageUrl: 'https://example.com/spike.jpg',
        description: 'A bounty hunter.',
        age: '27',
        gender: 'Male',
        mediaAppearances: [
          AniListMediaAppearance(
            anilistId: 1,
            malId: 1,
            title: 'Cowboy Bebop',
            role: 'MAIN',
          ),
          AniListMediaAppearance(
            anilistId: 2,
            malId: null,
            title: 'Cowboy Bebop: Knockin on Heavens Door',
            role: 'MAIN',
          ),
        ],
      );
      await cache.saveCharacter(c);
      final out = await cache.getCharacter(42);
      expect(out, isNotNull);
      expect(out!.name, 'Spike');
      expect(out.mediaAppearances.length, 2);
      expect(out.mediaAppearances.first.malId, 1);
      expect(out.mediaAppearances.last.malId, isNull);
    });
  });

  group('AniListCache.studio', () {
    test('save and read', () async {
      final s = AniListStudioDetail(
        id: 7,
        name: 'Sunrise',
        isAnimationStudio: true,
        siteUrl: 'https://sunrise.example',
        favourites: 1000,
        mediaWorks: [
          AniListMediaAppearance(
            anilistId: 100,
            malId: 200,
            title: 'Gundam',
          ),
        ],
      );
      await cache.saveStudio(s);
      final out = await cache.getStudio(7);
      expect(out, isNotNull);
      expect(out!.name, 'Sunrise');
      expect(out.mediaWorks.length, 1);
    });
  });

  group('AniListCache.staff', () {
    test('save and read with years/occupations JSON', () async {
      final s = AniListStaffDetail(
        id: 3,
        name: 'Hayao Miyazaki',
        yearsActive: [1971, 1978, 2001, 2013],
        occupations: ['Director', 'Screenwriter', 'Author'],
        mediaWorks: const [],
      );
      await cache.saveStaff(s);
      final out = await cache.getStaff(3);
      expect(out, isNotNull);
      expect(out!.yearsActive, [1971, 1978, 2001, 2013]);
      expect(out.occupations, ['Director', 'Screenwriter', 'Author']);
    });
  });

  group('AniListCache.animeExtra', () {
    test('save and read preserves next airing, links, studios', () async {
      // FK constraint: anilist_anime_extra.mal_id references anime.mal_id.
      await appDb.raw.insert('anime', {'mal_id': 123, 'title': 'Stub'});
      final extra = AniListAnimeExtra(
        nextAiring: AniListNextAiring(
          airingAt: DateTime.utc(2026, 9, 1, 12),
          episode: 5,
          timeUntilAiring: 1000,
        ),
        externalLinks: const [
          AniListExternalLink(id: 1, url: 'https://x.example', site: 'X'),
        ],
        studios: const [
          AniListStudio(id: 1, name: 'MAPPA', isAnimationStudio: true),
        ],
      );
      await cache.saveAnimeExtra(123, extra);
      final out = await cache.getAnimeExtra(123);
      expect(out, isNotNull);
      expect(out!.nextAiring?.episode, 5);
      expect(out.externalLinks.length, 1);
      expect(out.studios.first.name, 'MAPPA');
    });
  });
}
