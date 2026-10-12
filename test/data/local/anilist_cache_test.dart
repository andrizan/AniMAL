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
        airingAt: weekStart.add(const Duration(hours: 10)),
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

    test(
      'saves hundreds of entries and replaces rescheduled duplicates',
      () async {
        final now = DateTime.now().toUtc();
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final weekStart = DateTime.utc(monday.year, monday.month, monday.day);
        final weekStartSec = weekStart.millisecondsSinceEpoch ~/ 1000;

        final schedule = <String, List<AniListScheduleEntry>>{
          'monday': [
            for (var i = 1; i <= 400; i++)
              makeEntry(
                anilistId: i,
                malId: i,
                airingAt: weekStart.add(Duration(minutes: i)),
              ),
          ],
          'tuesday': [
            makeEntry(
              anilistId: 1,
              malId: 1,
              airingAt: weekStart.add(const Duration(days: 1, hours: 1)),
            ),
          ],
        };

        await cache.saveWeeklySchedule(weekStartSec, schedule);

        final out = await cache.getWeeklySchedule(weekStartSec);
        expect(out!['monday']!, hasLength(399));
        expect(out['tuesday']!.map((e) => e.anilistId), [1]);
        expect(
          await cache.getFetchedAt(SqliteAniListCache.weeklyKey(weekStartSec)),
          isNotNull,
        );
      },
    );

    test('week key changes on week boundary', () async {
      // Two different weekStart values produce different keys.
      final a = SqliteAniListCache.weeklyKey(0);
      final b = SqliteAniListCache.weeklyKey(7 * 24 * 60 * 60);
      expect(a, isNot(b));
    });
  });

  group('AniListCache.character', () {
    test('save and read preserves fields and media order', () async {
      const c = AniListCharacterDetail(
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
      const s = AniListStudioDetail(
        id: 7,
        name: 'Sunrise',
        isAnimationStudio: true,
        siteUrl: 'https://sunrise.example',
        favourites: 1000,
        mediaWorks: [
          AniListMediaAppearance(anilistId: 100, malId: 200, title: 'Gundam'),
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
      const s = AniListStaffDetail(
        id: 3,
        name: 'Hayao Miyazaki',
        yearsActive: [1971, 1978, 2001, 2013],
        occupations: ['Director', 'Screenwriter', 'Author'],
      );
      await cache.saveStaff(s);
      final out = await cache.getStaff(3);
      expect(out, isNotNull);
      expect(out!.yearsActive, [1971, 1978, 2001, 2013]);
      expect(out.occupations, ['Director', 'Screenwriter', 'Author']);
    });
  });

  group('AniListCache.works lists', () {
    AniListMediaAppearance work(int n, {String? role}) =>
        AniListMediaAppearance(
          anilistId: n,
          malId: n + 1000,
          title: 'Work $n',
          titleEnglish: 'English $n',
          imageUrl: 'w$n.jpg',
          type: 'ANIME',
          role: role,
        );

    List<AniListMediaAppearance> works(int from, int count) => [
      for (var i = from; i < from + count; i++) work(i),
    ];

    AniListWorksPage page(int from, int count, {bool next = true}) =>
        AniListWorksPage(items: works(from, count), hasNextPage: next);

    Future<void> save(
      AniListWorksSource source,
      int id,
      List<AniListMediaAppearance> items, {
      AniListWorksCursor cursor = const AniListWorksCursor(hasMore: true),
    }) => switch (source) {
      AniListWorksSource.character => cache.saveCharacter(
        AniListCharacterDetail(
          id: id,
          name: 'C',
          mediaAppearances: items,
          worksCursor: cursor,
        ),
      ),
      AniListWorksSource.staff => cache.saveStaff(
        AniListStaffDetail(
          id: id,
          name: 'S',
          mediaWorks: items,
          worksCursor: cursor,
        ),
      ),
      AniListWorksSource.studio => cache.saveStudio(
        AniListStudioDetail(
          id: id,
          name: 'Z',
          mediaWorks: items,
          worksCursor: cursor,
        ),
      ),
    };

    Future<(List<AniListMediaAppearance>, AniListWorksCursor)?> read(
      AniListWorksSource source,
      int id,
    ) async => switch (source) {
      AniListWorksSource.character => switch (await cache.getCharacter(id)) {
        final d? => (d.mediaAppearances, d.worksCursor),
        null => null,
      },
      AniListWorksSource.staff => switch (await cache.getStaff(id)) {
        final d? => (d.mediaWorks, d.worksCursor),
        null => null,
      },
      AniListWorksSource.studio => switch (await cache.getStudio(id)) {
        final d? => (d.mediaWorks, d.worksCursor),
        null => null,
      },
    };

    List<int> ids(List<AniListMediaAppearance> items) => [
      for (final m in items) m.anilistId,
    ];

    for (final source in AniListWorksSource.values) {
      group(source.name, () {
        test('the cursor saved with a detail comes back with it', () async {
          await save(
            source,
            5,
            works(1, 3),
            cursor: const AniListWorksCursor(nextPage: 4, hasMore: true),
          );

          final (items, cursor) = (await read(source, 5))!;

          expect(items, hasLength(3));
          expect(cursor.nextPage, 4);
          expect(cursor.hasMore, isTrue);
        });

        test('a detail saved without a cursor has no more pages', () async {
          await save(
            source,
            5,
            works(1, 3),
            cursor: const AniListWorksCursor(),
          );

          final (_, cursor) = (await read(source, 5))!;

          expect(cursor.hasMore, isFalse);
          expect(cursor.nextPage, 2);
        });

        test(
          'appends the next page after the stored works, in order',
          () async {
            await save(source, 5, works(1, 3));

            await cache.appendWorks(source, 5, 2, page(4, 3));

            final (items, cursor) = (await read(source, 5))!;
            expect(ids(items), [1, 2, 3, 4, 5, 6]);
            expect(cursor.nextPage, 3);
            expect(cursor.hasMore, isTrue);
          },
        );

        test('keeps appending page after page', () async {
          await save(source, 5, works(1, 2));

          await cache.appendWorks(source, 5, 2, page(3, 2));
          await cache.appendWorks(source, 5, 3, page(5, 2));
          await cache.appendWorks(source, 5, 4, page(7, 1, next: false));

          final (items, cursor) = (await read(source, 5))!;
          expect(ids(items), [1, 2, 3, 4, 5, 6, 7]);
          expect(cursor.nextPage, 5);
          expect(cursor.hasMore, isFalse);
        });

        test('the last page closes the list', () async {
          await save(source, 5, works(1, 2));

          await cache.appendWorks(source, 5, 2, page(3, 1, next: false));

          final (_, cursor) = (await read(source, 5))!;
          expect(cursor.hasMore, isFalse);
        });

        test('an empty page closes the list whatever AniList says', () async {
          await save(source, 5, works(1, 2));

          await cache.appendWorks(source, 5, 2, page(3, 0));

          final (items, cursor) = (await read(source, 5))!;
          expect(items, hasLength(2));
          expect(cursor.hasMore, isFalse);
        });

        test('works already stored are not stored twice', () async {
          await save(source, 5, works(1, 3));

          await cache.appendWorks(source, 5, 2, page(2, 4));

          final (items, cursor) = (await read(source, 5))!;
          expect(ids(items), [1, 2, 3, 4, 5]);
          expect(cursor.nextPage, 3);
        });

        test('only the page right after the stored ones is accepted', () async {
          await save(source, 5, works(1, 2));

          await cache.appendWorks(source, 5, 3, page(3, 2));
          await cache.appendWorks(source, 5, 1, page(3, 2));
          await cache.appendWorks(source, 5, 2, page(3, 2));
          await cache.appendWorks(source, 5, 2, page(5, 2));

          final (items, cursor) = (await read(source, 5))!;
          expect(ids(items), [1, 2, 3, 4]);
          expect(cursor.nextPage, 3);
        });

        test('nothing is stored for a detail that is not cached', () async {
          await cache.appendWorks(source, 99, 2, page(1, 3));

          expect(await read(source, 99), isNull);
          expect(await appDb.raw.query('anilist_works_progress'), isEmpty);
        });

        test('saving the detail again starts the list over', () async {
          await save(source, 5, works(1, 3));
          await cache.appendWorks(source, 5, 2, page(4, 3));

          await save(source, 5, works(1, 3));

          final (items, cursor) = (await read(source, 5))!;
          expect(items, hasLength(3));
          expect(cursor.nextPage, 2);
          expect(cursor.hasMore, isTrue);
        });

        test('keeps roles, titles and images of appended works', () async {
          await save(source, 5, works(1, 1));

          await cache.appendWorks(
            source,
            5,
            2,
            AniListWorksPage(
              items: [work(2, role: 'Music')],
              hasNextPage: false,
            ),
          );

          final (items, _) = (await read(source, 5))!;
          expect(items.last.role, 'Music');
          expect(items.last.title, 'Work 2');
          expect(items.last.titleEnglish, 'English 2');
          expect(items.last.imageUrl, 'w2.jpg');
          expect(items.last.malId, 1002);
          expect(items.last.type, 'ANIME');
        });

        test('another entity of the same kind is left alone', () async {
          await save(source, 5, works(1, 2));
          await save(source, 6, works(1, 2));

          await cache.appendWorks(source, 5, 2, page(3, 2));

          final (other, cursor) = (await read(source, 6))!;
          expect(other, hasLength(2));
          expect(cursor.nextPage, 2);
        });
      });
    }

    test('lists of different kinds with the same id stay apart', () async {
      await save(AniListWorksSource.staff, 5, works(1, 2));
      await save(AniListWorksSource.studio, 5, works(1, 2));

      await cache.appendWorks(AniListWorksSource.staff, 5, 2, page(3, 2));

      final (studio, cursor) = (await read(AniListWorksSource.studio, 5))!;
      expect(studio, hasLength(2));
      expect(cursor.nextPage, 2);
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

    test('save and read preserves characters and staff via JSON', () async {
      await appDb.raw.insert('anime', {'mal_id': 124, 'title': 'Stub2'});
      const extra = AniListAnimeExtra(
        people: AniListAnimePeople(
          characters: [
            AniListCharacter(
              id: 101,
              name: 'Test Char',
              nativeName: 'テスト',
              imageUrl: 'https://example.com/char.jpg',
              role: 'MAIN',
              voiceActors: [
                AniListVoiceActor(
                  id: 201,
                  name: 'VA Name',
                  nativeName: 'VA Native',
                  imageUrl: 'https://example.com/va.jpg',
                  language: 'JAPANESE',
                ),
              ],
            ),
          ],
          staff: [
            AniListStaff(
              id: 301,
              name: 'Staff Name',
              nativeName: 'スタッフ',
              imageUrl: 'https://example.com/staff.jpg',
              role: 'Director',
            ),
          ],
        ),
      );
      await cache.saveAnimeExtra(124, extra);
      final out = await cache.getAnimeExtra(124);
      expect(out, isNotNull);
      expect(out!.people.characters.length, 1);
      expect(out.people.characters.first.name, 'Test Char');
      expect(out.people.characters.first.nativeName, 'テスト');
      expect(out.people.characters.first.role, 'MAIN');
      expect(out.people.characters.first.voiceActors.first.name, 'VA Name');
      expect(out.people.staff.length, 1);
      expect(out.people.staff.first.name, 'Staff Name');
      expect(out.people.staff.first.role, 'Director');
    });

    test(
      'saveAnimeExtra works without a MAL anime row (stub created)',
      () async {
        const extra = AniListAnimeExtra(
          people: AniListAnimePeople(
            characters: [AniListCharacter(id: 1, name: 'C')],
          ),
        );
        // No anime row exists for 999 — the FK used to fail the transaction.
        await cache.saveAnimeExtra(999, extra);
        final out = await cache.getAnimeExtra(999);
        expect(out!.people.characters.length, 1);
      },
    );

    test('partial extra refresh preserves cached characters/staff', () async {
      const full = AniListAnimeExtra(
        people: AniListAnimePeople(
          characters: [AniListCharacter(id: 1, name: 'Char A')],
          staff: [AniListStaff(id: 2, name: 'Staff B')],
        ),
        externalLinks: [
          AniListExternalLink(id: 3, url: 'https://x.com', site: 'X'),
        ],
      );
      await cache.saveAnimeExtra(55, full);

      // Refresh returns only links (characters/staff missing).
      await cache.saveAnimeExtra(
        55,
        const AniListAnimeExtra(
          externalLinks: [
            AniListExternalLink(id: 4, url: 'https://y.com', site: 'Y'),
          ],
        ),
      );

      final out = await cache.getAnimeExtra(55);
      expect(out!.people.characters.first.name, 'Char A');
      expect(out.people.staff.first.name, 'Staff B');
      expect(out.externalLinks.map((l) => l.site), ['Y']);
    });
  });
}
