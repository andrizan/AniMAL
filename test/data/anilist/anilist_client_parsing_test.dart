import 'dart:io';

import 'package:animal/core/network/api_exception.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/data/local/anilist_cache.dart';
import 'package:animal/data/local/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/fake_adapter.dart';

Map<String, dynamic> _gql(Object data) => {'data': data};

Map<String, dynamic> _extraMedia() => {
  'characters': {
    'edges': [
      {
        'role': 'MAIN',
        'node': {
          'id': 1,
          'name': {'full': 'Edward Elric', 'native': 'エドワード'},
          'image': {'medium': 'c1.jpg'},
        },
        'voiceActors': [
          {
            'id': 10,
            'name': {'full': 'Romi Park', 'native': '朴璐美'},
            'image': {'medium': 'va1.jpg'},
            'language': 'Japanese',
          },
        ],
      },
      {
        'role': 'SUPPORTING',
        'node': {
          'id': 2,
          'name': {'full': 'Alphonse', 'native': null},
          'image': {'medium': null},
        },
      },
    ],
  },
  'staff': {
    'edges': [
      {
        'role': 'Director',
        'node': {
          'id': 5,
          'name': {'full': 'Seiji Mizushima', 'native': null},
          'image': {'medium': 's.jpg'},
        },
      },
    ],
  },
  'studios': {
    'edges': [
      {
        'isMain': true,
        'node': {
          'id': 7,
          'name': 'Bones',
          'isAnimationStudio': true,
          'siteUrl': 'https://bones.test',
        },
      },
    ],
  },
  'nextAiringEpisode': {
    'airingAt': 1800000000,
    'episode': 7,
    'timeUntilAiring': 3600,
  },
  'externalLinks': [
    {
      'id': 1,
      'url': 'https://crunchyroll.test/x',
      'site': 'Crunchyroll',
      'type': 'STREAMING',
      'language': 'English',
      'icon': null,
    },
  ],
};

Map<String, dynamic> _media(int id, {int? malId}) => {
  'id': id,
  'idMal': malId,
  'title': {'romaji': 'Title $id', 'english': 'English $id'},
  'coverImage': {'medium': 'm$id.jpg'},
  'type': 'ANIME',
};

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase appDb;
  late SqliteAniListCache cache;
  late AniListClient client;
  late FakeAdapter adapter;
  var respond = (String query) => FakeResponse.json(_gql({'Media': null}));

  String queryOf(Object? data) =>
      (data! as Map<String, dynamic>)['query'] as String;

  int gqlCalls() => adapter.requests.length;

  setUp(() async {
    final tmp = Directory.systemTemp.createTempSync('anilist_parsing_');
    appDb = await AppDatabase.open(
      pathOverride: '${tmp.path}/test.db',
      runMigrations: false,
    );
    cache = SqliteAniListCache(appDb);
    client = AniListClient(
      cache: cache,
      logger: Logger(level: Level.off),
    );
    respond = (_) => FakeResponse.json(_gql({'Media': _extraMedia()}));
    adapter = FakeAdapter((o) async {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      return respond(queryOf(o.data));
    });
    client.dio.httpClientAdapter = adapter;
  });

  tearDown(() async {
    await appDb.close();
  });

  group('getAnimeExtraInfo', () {
    test(
      'maps characters, voice actors, staff, studios, airing and links',
      () async {
        final extra = await client.getAnimeExtraInfo(1);

        final ed = extra.people.characters.first;
        expect(ed.id, 1);
        expect(ed.name, 'Edward Elric');
        expect(ed.nativeName, 'エドワード');
        expect(ed.role, 'MAIN');
        expect(ed.imageUrl, 'c1.jpg');
        expect(ed.voiceActors.single.name, 'Romi Park');
        expect(ed.voiceActors.single.language, 'Japanese');

        expect(extra.people.staff.single.role, 'Director');
        expect(extra.studios.single.name, 'Bones');
        expect(extra.studios.single.isMain, isTrue);
        expect(extra.studios.single.isAnimationStudio, isTrue);

        expect(extra.nextAiring!.episode, 7);
        expect(extra.nextAiring!.timeUntilAiring, 3600);
        expect(
          extra.nextAiring!.airingAt,
          DateTime.fromMillisecondsSinceEpoch(1800000000 * 1000, isUtc: true),
        );

        expect(extra.externalLinks.single.displaySite, 'Crunchyroll');
        expect(extra.externalLinks.single.type, 'STREAMING');
      },
    );

    test('tolerates optional parts that are missing', () async {
      final ed2 = extraWithoutOptionals();
      respond = (_) => FakeResponse.json(_gql({'Media': ed2}));

      final extra = await client.getAnimeExtraInfo(1);

      expect(extra.people.characters.single.voiceActors, isEmpty);
      expect(extra.people.characters.single.imageUrl, isNull);
      expect(extra.nextAiring, isNull);
      expect(extra.studios, isEmpty);
      expect(extra.externalLinks, isEmpty);
    });

    test('serves later calls from the cache without any request', () async {
      await client.getAnimeExtraInfo(1);
      final after = gqlCalls();

      final again = await client.getAnimeExtraInfo(1);

      expect(gqlCalls(), after);
      expect(again.people.characters, hasLength(2));
      expect(again.nextAiring!.episode, 7);
    });

    test('caches an unknown anime so it is not asked again', () async {
      respond = (_) => FakeResponse.json(_gql({'Media': null}));

      final first = await client.getAnimeExtraInfo(99);
      final second = await client.getAnimeExtraInfo(99);

      expect(first.people.characters, isEmpty);
      expect(second.nextAiring, isNull);
      expect(gqlCalls(), 1);
    });

    test('merges concurrent calls into one request', () async {
      await Future.wait([
        client.getAnimeExtraInfo(1),
        client.getAnimeExtraInfo(1),
        client.getAnimeExtraInfo(1),
      ]);

      expect(gqlCalls(), 1);
    });

    test('a failed fetch is not cached, so the next call retries', () async {
      respond = (_) => const FakeResponse.json({}, status: 500);
      await expectLater(
        client.getAnimeExtraInfo(1),
        throwsA(isA<NetworkException>()),
      );

      respond = (_) => FakeResponse.json(_gql({'Media': _extraMedia()}));
      final extra = await client.getAnimeExtraInfo(1);

      expect(extra.studios.single.name, 'Bones');
    });

    test('refreshAnimeExtra fetches even when something is cached', () async {
      await client.getAnimeExtraInfo(1);
      final before = gqlCalls();

      await client.refreshAnimeExtra(1);

      expect(gqlCalls(), before + 1);
    });
  });

  group('error mapping', () {
    test('GraphQL errors become a server exception', () async {
      respond = (_) => const FakeResponse.json({
        'errors': [
          {'message': 'bad query'},
        ],
        'data': null,
      });

      await expectLater(
        client.getAnimeExtraInfo(1),
        throwsA(isA<ServerException>()),
      );
    });

    test(
      'HTTP 429 becomes a rate-limit exception with the Retry-After delay',
      () async {
        respond = (_) => const FakeResponse.json(
          {},
          status: 429,
          headers: {
            'retry-after': ['17'],
          },
        );

        await expectLater(
          client.getAnimeExtraInfo(1),
          throwsA(
            isA<RateLimitException>().having(
              (e) => e.retryAfter,
              'retryAfter',
              const Duration(seconds: 17),
            ),
          ),
        );
      },
    );

    test('HTTP 429 without Retry-After defaults to a minute', () async {
      respond = (_) => const FakeResponse.json({}, status: 429);

      await expectLater(
        client.getAnimeExtraInfo(1),
        throwsA(
          isA<RateLimitException>().having(
            (e) => e.retryAfter,
            'retryAfter',
            const Duration(seconds: 60),
          ),
        ),
      );
    });

    test('other HTTP failures become a network exception', () async {
      respond = (_) => const FakeResponse.json({}, status: 503);

      await expectLater(
        client.getAnimeExtraInfo(1),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('detail pages', () {
    test('getCharacterDetail maps the profile and appearances', () async {
      respond = (_) => FakeResponse.json(
        _gql({
          'Character': {
            'id': 3,
            'name': {'full': 'Roy Mustang', 'native': 'ロイ'},
            'image': {'large': 'big.jpg', 'medium': 'm.jpg'},
            'description': 'Flame alchemist',
            'dateOfBirth': {'year': 1885, 'month': 6, 'day': 1},
            'age': '29',
            'gender': 'Male',
            'media': {
              'edges': [
                {
                  'characterRole': 'SUPPORTING',
                  'node': _media(10, malId: 5114),
                },
              ],
            },
          },
        }),
      );

      final c = await client.getCharacterDetail(3);

      expect(c.name, 'Roy Mustang');
      expect(c.imageUrl, 'big.jpg');
      expect((c.birthYear, c.birthMonth, c.birthDay), (1885, 6, 1));
      expect(c.age, '29');
      expect(c.mediaAppearances.single.malId, 5114);
      expect(c.mediaAppearances.single.role, 'SUPPORTING');
      expect(c.mediaAppearances.single.titleEnglish, 'English 10');
    });

    test('getCharacterDetail tolerates a missing birth date', () async {
      respond = (_) => FakeResponse.json(
        _gql({
          'Character': {
            'id': 3,
            'name': {'full': 'X', 'native': null},
            'image': {'large': null, 'medium': null},
            'description': null,
            'dateOfBirth': null,
            'age': null,
            'gender': null,
            'media': {'edges': <Object>[]},
          },
        }),
      );

      final c = await client.getCharacterDetail(3);

      expect(c.birthYear, isNull);
      expect(c.mediaAppearances, isEmpty);
    });

    test('getStaffDetail maps lifetime dates, occupations and works', () async {
      respond = (_) => FakeResponse.json(
        _gql({
          'Staff': {
            'id': 8,
            'name': {'full': 'Hiromu Arakawa', 'native': '荒川弘'},
            'image': {'large': 'staff.jpg', 'medium': 'sm.jpg'},
            'description': 'Mangaka',
            'primaryOccupations': ['Mangaka'],
            'gender': 'Female',
            'dateOfBirth': {'year': 1973, 'month': 5, 'day': 8},
            'dateOfDeath': {'year': null, 'month': null, 'day': null},
            'age': 52,
            'yearsActive': [1999, 2010],
            'homeTown': 'Hokkaido',
            'staffMedia': {
              'edges': [
                {'staffRole': 'Original Creator', 'node': _media(11)},
              ],
            },
          },
        }),
      );

      final s = await client.getStaffDetail(8);

      expect(s.name, 'Hiromu Arakawa');
      expect(s.occupations, ['Mangaka']);
      expect(s.yearsActive, [1999, 2010]);
      expect(s.homeTown, 'Hokkaido');
      expect(s.age, 52);
      expect(s.deathYear, isNull);
      expect(s.mediaWorks.single.role, 'Original Creator');
    });

    test('getStudioDetail maps the studio and its works', () async {
      respond = (_) => FakeResponse.json(
        _gql({
          'Studio': {
            'id': 7,
            'name': 'Bones',
            'isAnimationStudio': true,
            'siteUrl': 'https://bones.test',
            'favourites': 1234,
            'media': {
              'edges': [
                {'node': _media(12, malId: 25)},
                {'node': _media(13)},
              ],
            },
          },
        }),
      );

      final s = await client.getStudioDetail(7);

      expect(s.name, 'Bones');
      expect(s.isAnimationStudio, isTrue);
      expect(s.favourites, 1234);
      expect(s.mediaWorks.map((m) => m.malId), [25, null]);
    });

    test('detail results are cached', () async {
      respond = (_) => FakeResponse.json(
        _gql({
          'Studio': {
            'id': 7,
            'name': 'Bones',
            'isAnimationStudio': false,
            'siteUrl': null,
            'favourites': null,
            'media': {'edges': <Object>[]},
          },
        }),
      );

      await client.getStudioDetail(7);
      final again = await client.getStudioDetail(7);

      expect(again.name, 'Bones');
      expect(gqlCalls(), 1);
    });
  });

  test('an empty schedule refresh keeps the cached week', () async {
    final now = DateTime.now().toUtc();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime.utc(monday.year, monday.month, monday.day);
    final weekStartSec = weekStart.millisecondsSinceEpoch ~/ 1000;
    await cache.saveWeeklySchedule(weekStartSec, {
      'monday': [
        AniListScheduleEntry(
          anilistId: 1,
          malId: 1,
          title: 'Kept',
          airingAt: weekStart.add(const Duration(hours: 3)),
          episode: 1,
          timeUntilAiring: 0,
        ),
      ],
    });
    respond = (_) => FakeResponse.json(
      _gql({
        'Page': {
          'pageInfo': {'hasNextPage': false},
          'airingSchedules': <Object>[],
        },
      }),
    );

    final refreshed = await client.refreshWeeklySchedule();

    expect(refreshed.values.every((l) => l.isEmpty), isTrue);
    final stored = await cache.getWeeklySchedule(weekStartSec);
    expect(stored!['monday']!.single.title, 'Kept');
  });
}

Map<String, dynamic> extraWithoutOptionals() => {
  'characters': {
    'edges': [
      {
        'role': 'MAIN',
        'node': {
          'id': 2,
          'name': {'full': 'Alphonse', 'native': null},
          'image': {'medium': null},
        },
      },
    ],
  },
  'staff': {'edges': <Object>[]},
};
