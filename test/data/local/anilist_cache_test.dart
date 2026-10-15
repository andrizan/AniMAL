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

    test('a work listed twice is kept once, the first one', () async {
      const s = AniListStudioDetail(
        id: 7,
        name: 'Sunrise',
        isAnimationStudio: true,
        mediaWorks: [
          AniListMediaAppearance(anilistId: 100, title: 'Gundam'),
          AniListMediaAppearance(anilistId: 101, title: 'Bebop'),
          AniListMediaAppearance(anilistId: 100, title: 'Gundam again'),
        ],
      );
      await cache.saveStudio(s);
      final out = await cache.getStudio(7);
      expect(out!.mediaWorks.map((m) => m.title), ['Gundam', 'Bebop']);
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

  group('AniListCache.weekly edge cases', () {
    test(
      'a week that was fetched but had no airings reads as empty days',
      () async {
        const weekStartSec = 1790000000;
        await cache.saveWeeklySchedule(weekStartSec, {});

        final out = await cache.getWeeklySchedule(weekStartSec);

        expect(out, isNotNull);
        expect(out!.keys, [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday',
        ]);
        expect(out.values.every((day) => day.isEmpty), isTrue);
      },
    );

    test('a week that was never fetched is unknown', () async {
      expect(await cache.getWeeklySchedule(1790000000), isNull);
    });

    test('the next airing of an entry survives a round trip', () async {
      final weekStart = DateTime.utc(2026, 10, 12);
      final weekStartSec = weekStart.millisecondsSinceEpoch ~/ 1000;
      final next = DateTime.utc(2026, 10, 19, 14, 30);
      await cache.saveWeeklySchedule(weekStartSec, {
        'monday': [
          AniListScheduleEntry(
            anilistId: 1,
            malId: 10,
            title: 'Frieren',
            airingAt: weekStart.add(const Duration(hours: 10)),
            episode: 4,
            timeUntilAiring: 3600,
            nextAiringAt: next,
            nextEpisode: 5,
            nextTimeUntilAiring: 700000,
          ),
          AniListScheduleEntry(
            anilistId: 2,
            malId: 20,
            title: 'No next',
            airingAt: weekStart.add(const Duration(hours: 11)),
            episode: 1,
            timeUntilAiring: 7200,
          ),
        ],
      });

      final out = (await cache.getWeeklySchedule(weekStartSec))!['monday']!;

      expect(out.first.nextAiringAt, next);
      expect(out.first.nextEpisode, 5);
      expect(out.first.nextTimeUntilAiring, 700000);
      expect(out.last.nextAiringAt, isNull);
      expect(out.last.nextEpisode, isNull);
    });
  });

  group('AniListCache.animeExtra stored by older versions', () {
    Future<void> markFetched(int malId) => appDb.raw.insert('cache_meta', {
      'cache_key': 'animeExtra_$malId',
      'fetched_at': DateTime.now().millisecondsSinceEpoch,
    });

    Future<void> insertExtra(
      int malId, {
      String? charactersJson,
      String? staffJson,
      int? nextAt,
    }) async {
      await appDb.raw.insert('anime', {'mal_id': malId, 'title': 'Legacy'});
      await markFetched(malId);
      await appDb.raw.insert('anilist_anime_extra', {
        'mal_id': malId,
        'characters_json': charactersJson,
        'staff_json': staffJson,
        'next_airing_at': nextAt,
        'next_airing_episode': nextAt == null ? null : 8,
        'next_airing_time_until': nextAt == null ? null : 4000,
      });
    }

    Future<void> insertVoiceActor(
      int malId,
      int characterId,
      int vaId,
      String name,
    ) => appDb.raw.insert('anilist_anime_extra_voice_actor', {
      'anime_mal_id': malId,
      'character_id': characterId,
      'va_id': vaId,
      'name': name,
      'native_name': '$name-jp',
      'image_url': 'va$vaId.jpg',
      'language': 'JAPANESE',
    });

    test(
      'rows without the people JSON rebuild characters from their voice actors',
      () async {
        await insertExtra(
          70,
          nextAt: DateTime.utc(2026, 11, 1, 9).millisecondsSinceEpoch ~/ 1000,
        );
        await insertVoiceActor(70, 1, 11, 'Romi');
        await insertVoiceActor(70, 1, 12, 'Sora');
        await insertVoiceActor(70, 2, 13, 'Yuki');
        await appDb.raw.insert('anilist_anime_extra_link', {
          'mal_id': 70,
          'id': 1,
          'url': 'https://x.test',
          'site': 'X',
        });
        await appDb.raw.insert('anilist_anime_extra_studio', {
          'mal_id': 70,
          'studio_id': 5,
          'name': 'Bones',
          'is_animation_studio': 1,
          'is_main': 1,
        });

        final out = await cache.getAnimeExtra(70);

        expect(out!.people.characters.map((c) => c.id), [1, 2]);
        expect(out.people.characters.every((c) => c.name == 'Unknown'), isTrue);
        expect(out.people.characters.first.voiceActors.map((v) => v.name), [
          'Romi',
          'Sora',
        ]);
        expect(
          out.people.characters.first.voiceActors.first.nativeName,
          'Romi-jp',
        );
        expect(
          out.people.characters.first.voiceActors.first.language,
          'JAPANESE',
        );
        expect(out.people.characters.last.voiceActors.single.name, 'Yuki');
        expect(out.people.staff, isEmpty);
        expect(out.nextAiring!.episode, 8);
        expect(out.nextAiring!.timeUntilAiring, 4000);
        expect(out.nextAiring!.airingAt, DateTime.utc(2026, 11, 1, 9));
        expect(out.externalLinks.single.site, 'X');
        expect(out.studios.single.name, 'Bones');
        expect(out.studios.single.isMain, isTrue);
      },
    );

    test('a stored staff list does not hide the voice actor rows', () async {
      await insertExtra(
        71,
        staffJson: '[{"id":9,"name":"Director X","role":"Director"}]',
      );
      await insertVoiceActor(71, 3, 21, 'Aoi');

      final out = await cache.getAnimeExtra(71);

      expect(out!.people.staff.single.name, 'Director X');
      expect(out.people.characters.single.id, 3);
      expect(out.people.characters.single.voiceActors.single.name, 'Aoi');
    });

    test('stored characters win over the voice actor rows', () async {
      await insertExtra(
        72,
        charactersJson: '[{"id":4,"name":"Real","voiceActors":[]}]',
      );
      await insertVoiceActor(72, 99, 31, 'Ignored');

      final out = await cache.getAnimeExtra(72);

      expect(out!.people.characters.map((c) => c.name), ['Real']);
    });

    test('an anime never fetched is unknown', () async {
      expect(await cache.getAnimeExtra(404), isNull);
    });

    test('a fetch that stored nothing reads as an empty extra', () async {
      await markFetched(405);

      final out = await cache.getAnimeExtra(405);

      expect(out!.people.characters, isEmpty);
      expect(out.people.staff, isEmpty);
      expect(out.nextAiring, isNull);
      expect(out.externalLinks, isEmpty);
    });

    test(
      'a partial refresh keeps the voice actors of cached characters',
      () async {
        const full = AniListAnimeExtra(
          people: AniListAnimePeople(
            characters: [
              AniListCharacter(
                id: 1,
                name: 'Char A',
                voiceActors: [
                  AniListVoiceActor(
                    id: 5,
                    name: 'Voice',
                    nativeName: 'ボイス',
                    imageUrl: 'v.jpg',
                    language: 'JAPANESE',
                  ),
                ],
              ),
            ],
          ),
        );
        await cache.saveAnimeExtra(56, full);

        await cache.saveAnimeExtra(
          56,
          const AniListAnimeExtra(
            externalLinks: [AniListExternalLink(id: 1, url: 'https://z.test')],
          ),
        );

        final voice = (await cache.getAnimeExtra(56))!
            .people
            .characters
            .single
            .voiceActors
            .single;
        expect(voice.name, 'Voice');
        expect(voice.nativeName, 'ボイス');
        expect(voice.imageUrl, 'v.jpg');
        expect(voice.language, 'JAPANESE');
      },
    );
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

    test('an empty response keeps a next airing that is still ahead', () async {
      final ahead = DateTime.now().toUtc().add(const Duration(days: 2));
      await cache.saveAnimeExtra(
        57,
        AniListAnimeExtra(
          nextAiring: AniListNextAiring(
            airingAt: ahead,
            episode: 4,
            timeUntilAiring: 172800,
          ),
        ),
      );

      await cache.saveAnimeExtra(57, const AniListAnimeExtra());

      final next = (await cache.getAnimeExtra(57))!.nextAiring!;
      expect(next.episode, 4);
      expect(
        next.airingAt.millisecondsSinceEpoch ~/ 1000,
        ahead.millisecondsSinceEpoch ~/ 1000,
      );
    });

    test('an empty response drops a next airing that already aired', () async {
      await cache.saveAnimeExtra(
        58,
        AniListAnimeExtra(
          nextAiring: AniListNextAiring(
            airingAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
            episode: 4,
            timeUntilAiring: 60,
          ),
        ),
      );

      await cache.saveAnimeExtra(58, const AniListAnimeExtra());

      expect((await cache.getAnimeExtra(58))!.nextAiring, isNull);
    });

    test('a new next airing replaces one that already aired', () async {
      await cache.saveAnimeExtra(
        59,
        AniListAnimeExtra(
          nextAiring: AniListNextAiring(
            airingAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
            episode: 4,
            timeUntilAiring: 60,
          ),
        ),
      );
      final later = DateTime.now().toUtc().add(const Duration(days: 6));

      await cache.saveAnimeExtra(
        59,
        AniListAnimeExtra(
          nextAiring: AniListNextAiring(
            airingAt: later,
            episode: 5,
            timeUntilAiring: 518400,
          ),
        ),
      );

      expect((await cache.getAnimeExtra(59))!.nextAiring!.episode, 5);
    });

    test('a voice actor voicing two characters and a staff member with two '
        'roles are kept as such', () async {
      const va = AniListVoiceActor(id: 5, name: 'Same Voice');
      const extra = AniListAnimeExtra(
        people: AniListAnimePeople(
          characters: [
            AniListCharacter(
              id: 1,
              name: 'Hero',
              role: 'MAIN',
              voiceActors: [va],
            ),
            AniListCharacter(
              id: 2,
              name: 'Rival',
              role: 'SUPPORTING',
              voiceActors: [va],
            ),
          ],
          staff: [
            AniListStaff(id: 9, name: 'Busy Person', role: 'Director'),
            AniListStaff(id: 9, name: 'Busy Person', role: 'Storyboard'),
          ],
        ),
      );

      await cache.saveAnimeExtra(60, extra);

      final out = (await cache.getAnimeExtra(60))!;
      expect(out.people.characters.map((c) => c.voiceActors.single.id), [5, 5]);
      expect(out.people.staff.map((s) => s.role), ['Director', 'Storyboard']);
      final pairs = await appDb.raw.query(
        'anilist_anime_extra_voice_actor',
        where: 'anime_mal_id = ?',
        whereArgs: [60],
        orderBy: 'character_id',
      );
      expect(pairs.map((r) => r['character_id']), [1, 2]);
    });

    test('a link or studio AniList repeats does not fail the save', () async {
      const extra = AniListAnimeExtra(
        externalLinks: [
          AniListExternalLink(id: 1, url: 'https://a.test', site: 'A'),
          AniListExternalLink(id: 1, url: 'https://a.test', site: 'A'),
        ],
        studios: [
          AniListStudio(id: 7, name: 'Bones', isAnimationStudio: true),
          AniListStudio(id: 7, name: 'Bones', isAnimationStudio: true),
        ],
      );

      await cache.saveAnimeExtra(61, extra);

      final out = (await cache.getAnimeExtra(61))!;
      expect(out.externalLinks.map((l) => l.id), [1]);
      expect(out.studios.map((s) => s.id), [7]);
    });

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
