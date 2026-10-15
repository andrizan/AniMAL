import 'dart:io';

import 'package:animal/core/constants/anilist_queries.dart';
import 'package:animal/core/network/api_exception.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/data/local/anilist_cache.dart';
import 'package:animal/data/local/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/fake_adapter.dart';

const _farFuture = 4102444800;

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
    'airingAt': _farFuture,
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
  'title': {
    'romaji': 'Title $id',
    'english': 'English $id',
    'native': 'Native $id',
  },
  'coverImage': {'medium': 'm$id.jpg'},
  'type': 'ANIME',
  'format': 'TV',
  'episodes': 12,
  'status': 'FINISHED',
  'meanScore': 85,
};

class _FailingCache extends SqliteAniListCache {
  _FailingCache(AppDatabase db) : super(db);

  int attempts = 0;

  @override
  Future<void> appendWorks(
    AniListWorksSource source,
    int id,
    int pageNumber,
    AniListWorksPage page,
  ) async {
    attempts++;
    throw StateError('disk full');
  }
}

class _SaveFailingStudioCache extends SqliteAniListCache {
  _SaveFailingStudioCache(AppDatabase db) : super(db);

  @override
  Future<void> saveStudio(AniListStudioDetail detail) async {
    throw StateError('database is locked');
  }
}

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
          DateTime.fromMillisecondsSinceEpoch(_farFuture * 1000, isUtc: true),
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

    group('a cached next episode that has aired', () {
      Future<void> cacheAired() => cache.saveAnimeExtra(
        1,
        AniListAnimeExtra(
          nextAiring: AniListNextAiring(
            airingAt: DateTime.now().toUtc().subtract(const Duration(hours: 3)),
            episode: 6,
            timeUntilAiring: 600,
          ),
          externalLinks: const [
            AniListExternalLink(id: 9, url: 'https://old.test'),
          ],
        ),
      );

      test('is asked about once and then replaced', () async {
        await cacheAired();

        final extra = await client.getAnimeExtraInfo(1);

        expect(gqlCalls(), 1);
        expect(extra.nextAiring!.episode, 7);
        expect(extra.people.characters, hasLength(2));

        await client.getAnimeExtraInfo(1);
        expect(gqlCalls(), 1);
      });

      test('is dropped when AniList has no later episode', () async {
        await cacheAired();
        respond = (_) => FakeResponse.json(
          _gql({'Media': _extraMedia()..remove('nextAiringEpisode')}),
        );

        final extra = await client.getAnimeExtraInfo(1);
        await client.getAnimeExtraInfo(1);

        expect(extra.nextAiring, isNull);
        expect(gqlCalls(), 1);
      });

      test('stays as cached when the refresh fails', () async {
        await cacheAired();
        respond = (_) => const FakeResponse.json({}, status: 500);

        final extra = await client.getAnimeExtraInfo(1);

        expect(gqlCalls(), 1);
        expect(extra.nextAiring!.episode, 6);
      });
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
      expect(c.mediaAppearances.single.titleNative, 'Native 10');
      expect(c.mediaAppearances.single.format, 'TV');
      expect(c.mediaAppearances.single.episodes, 12);
      expect(c.mediaAppearances.single.status, 'FINISHED');
      expect(c.mediaAppearances.single.meanScore, 85);
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

    test(
      'a work listed twice is kept once and the detail still saves',
      () async {
        respond = (_) => FakeResponse.json(
          _gql({
            'Studio': {
              'id': 7,
              'name': 'Bones',
              'isAnimationStudio': true,
              'siteUrl': null,
              'favourites': null,
              'media': {
                'edges': [
                  {'node': _media(12)},
                  {'node': _media(13)},
                  {'node': _media(12)},
                ],
              },
            },
          }),
        );

        final s = await client.getStudioDetail(7);
        final stored = (await cache.getStudio(7))!;

        expect(s.mediaWorks.map((m) => m.anilistId), [12, 13]);
        expect(stored.mediaWorks.map((m) => m.anilistId), [12, 13]);
      },
    );

    test('a detail that cannot be stored is still shown', () async {
      respond = (_) => FakeResponse.json(
        _gql({
          'Studio': {
            'id': 7,
            'name': 'Bones',
            'isAnimationStudio': true,
            'siteUrl': null,
            'favourites': null,
            'media': {
              'edges': [
                {'node': _media(12)},
              ],
            },
          },
        }),
      );
      final failing = AniListClient(
        cache: _SaveFailingStudioCache(appDb),
        logger: Logger(level: Level.off),
      )..dio.httpClientAdapter = adapter;

      final s = await failing.getStudioDetail(7);

      expect(s.name, 'Bones');
      expect(s.mediaWorks.single.anilistId, 12);
    });
  });

  group('getWorksPage', () {
    FakeResponse pageOf(
      String root,
      String field,
      List<Map<String, dynamic>> edges, {
      bool next = false,
      int? total,
    }) => FakeResponse.json(
      _gql({
        root: {
          field: {
            'pageInfo': {'hasNextPage': next, 'total': total},
            'edges': edges,
          },
        },
      }),
    );

    Map<String, dynamic> lastVariables() =>
        (adapter.requests.last.data as Map<String, dynamic>)['variables']
            as Map<String, dynamic>;

    test('asks for the right page of a staff member', () async {
      respond = (_) => pageOf('Staff', 'staffMedia', const []);

      await client.getWorksPage(AniListWorksSource.staff, 8, 2);

      expect(queryOf(adapter.requests.last.data), contains('staffMedia'));
      expect(lastVariables(), {
        'id': 8,
        'page': 2,
        'perPage': AniListClient.worksPageSize,
      });
    });

    test('asks for the right page of a character', () async {
      respond = (_) => pageOf('Character', 'media', const []);

      await client.getWorksPage(AniListWorksSource.character, 3, 4);

      expect(queryOf(adapter.requests.last.data), contains('Character(id'));
      expect(lastVariables(), {
        'id': 3,
        'page': 4,
        'perPage': AniListClient.worksPageSize,
      });
    });

    test('asks for the right page of a studio', () async {
      respond = (_) => pageOf('Studio', 'media', const []);

      await client.getWorksPage(AniListWorksSource.studio, 7, 3);

      expect(queryOf(adapter.requests.last.data), contains('Studio(id'));
      expect(lastVariables(), {
        'id': 7,
        'page': 3,
        'perPage': AniListClient.worksPageSize,
      });
    });

    test('reads each source role from its own field', () async {
      respond = (_) => pageOf('Character', 'media', [
        {'characterRole': 'MAIN', 'node': _media(1, malId: 11)},
      ]);
      final character = await client.getWorksPage(
        AniListWorksSource.character,
        3,
        2,
      );

      respond = (_) => pageOf('Staff', 'staffMedia', [
        {'staffRole': 'Director', 'node': _media(2)},
      ]);
      final staff = await client.getWorksPage(AniListWorksSource.staff, 3, 2);

      respond = (_) => pageOf('Studio', 'media', [
        {'node': _media(3, malId: 33)},
      ]);
      final studio = await client.getWorksPage(AniListWorksSource.studio, 3, 2);

      expect(character.items.single.role, 'MAIN');
      expect(character.items.single.malId, 11);
      expect(staff.items.single.role, 'Director');
      expect(studio.items.single.role, isNull);
      expect(studio.items.single.malId, 33);
      expect(studio.items.single.titleEnglish, 'English 3');
    });

    test(
      'reports whether more pages follow and how many works exist',
      () async {
        respond = (_) => pageOf(
          'Staff',
          'staffMedia',
          [
            {'staffRole': 'Music', 'node': _media(1)},
          ],
          next: true,
          total: 57,
        );

        final page = await client.getWorksPage(AniListWorksSource.staff, 8, 2);

        expect(page.hasNextPage, isTrue);
        expect(page.total, 57);
        expect(page.items, hasLength(1));
      },
    );

    test('treats a missing pageInfo as the last page', () async {
      respond = (_) => FakeResponse.json(
        _gql({
          'Studio': {
            'media': {
              'edges': [
                {'node': _media(1)},
              ],
            },
          },
        }),
      );

      final page = await client.getWorksPage(AniListWorksSource.studio, 7, 2);

      expect(page.hasNextPage, isFalse);
      expect(page.total, isNull);
    });

    test('keeps the order AniList sent', () async {
      respond = (_) => pageOf('Studio', 'media', [
        for (final id in [30, 10, 20]) {'node': _media(id)},
      ]);

      final page = await client.getWorksPage(AniListWorksSource.studio, 7, 2);

      expect(page.items.map((m) => m.anilistId), [30, 10, 20]);
    });

    test(
      'remembers a page, so scrolling back never repeats the request',
      () async {
        respond = (_) => pageOf('Staff', 'staffMedia', [
          {'staffRole': 'Director', 'node': _media(1)},
        ]);

        final first = await client.getWorksPage(AniListWorksSource.staff, 8, 2);
        final again = await client.getWorksPage(AniListWorksSource.staff, 8, 2);

        expect(gqlCalls(), 1);
        expect(again, same(first));
      },
    );

    test('keeps pages, people and kinds apart', () async {
      respond = (_) => pageOf('Staff', 'staffMedia', const []);
      await client.getWorksPage(AniListWorksSource.staff, 8, 2);
      await client.getWorksPage(AniListWorksSource.staff, 8, 3);
      await client.getWorksPage(AniListWorksSource.staff, 9, 2);
      respond = (_) => pageOf('Studio', 'media', const []);
      await client.getWorksPage(AniListWorksSource.studio, 8, 2);

      expect(gqlCalls(), 4);
    });

    test(
      'shares one request between callers asking at the same time',
      () async {
        respond = (_) => pageOf('Staff', 'staffMedia', const []);

        await Future.wait([
          client.getWorksPage(AniListWorksSource.staff, 8, 2),
          client.getWorksPage(AniListWorksSource.staff, 8, 2),
          client.getWorksPage(AniListWorksSource.staff, 8, 2),
        ]);

        expect(gqlCalls(), 1);
      },
    );

    test('a failed request is reported and not remembered', () async {
      respond = (_) => const FakeResponse.json({}, status: 500);

      await expectLater(
        client.getWorksPage(AniListWorksSource.staff, 8, 2),
        throwsA(isA<ApiException>()),
      );

      respond = (_) => pageOf('Staff', 'staffMedia', [
        {'staffRole': 'Director', 'node': _media(1)},
      ]);
      final page = await client.getWorksPage(AniListWorksSource.staff, 8, 2);

      expect(page.items, hasLength(1));
      expect(gqlCalls(), 2);
    });

    test('a GraphQL error is reported and not remembered', () async {
      respond = (_) => FakeResponse.json({
        'errors': [
          {'message': 'boom'},
        ],
      });

      await expectLater(
        client.getWorksPage(AniListWorksSource.studio, 7, 2),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        client.getWorksPage(AniListWorksSource.studio, 7, 2),
        throwsA(isA<ApiException>()),
      );
      expect(gqlCalls(), 2);
    });

    test('a 429 surfaces as a rate-limit error', () async {
      respond = (_) => const FakeResponse.json(
        {},
        status: 429,
        headers: {
          'retry-after': ['30'],
        },
      );

      await expectLater(
        client.getWorksPage(AniListWorksSource.staff, 8, 2),
        throwsA(isA<ApiException>()),
      );
    });

    test('a page is as big as AniList allows', () {
      expect(AniListClient.worksPageSize, 50);
    });

    test('the detail and page queries take the page size as a variable', () {
      for (final query in [
        AniListQueries.characterDetail,
        AniListQueries.staffDetail,
        AniListQueries.studioDetail,
        AniListQueries.characterWorksPage,
        AniListQueries.staffWorksPage,
        AniListQueries.studioWorksPage,
      ]) {
        expect(query, contains(r'$perPage: Int'));
        expect(query, contains(r'perPage: $perPage'));
        expect(query, contains('pageInfo { hasNextPage'));
      }
    });
  });

  group('works lists in SQLite', () {
    FakeResponse staffDetail(List<Map<String, dynamic>> edges, {bool? next}) =>
        FakeResponse.json(
          _gql({
            'Staff': {
              'id': 8,
              'name': {'full': 'Hiromu Arakawa', 'native': null},
              'image': {'large': null, 'medium': null},
              'description': null,
              'primaryOccupations': <Object>[],
              'gender': null,
              'dateOfBirth': null,
              'dateOfDeath': null,
              'age': null,
              'yearsActive': <Object>[],
              'homeTown': null,
              'staffMedia': {
                if (next != null) 'pageInfo': {'hasNextPage': next},
                'edges': edges,
              },
            },
          }),
        );

    FakeResponse staffPage(
      List<Map<String, dynamic>> edges, {
      required bool next,
    }) => FakeResponse.json(
      _gql({
        'Staff': {
          'staffMedia': {
            'pageInfo': {'hasNextPage': next, 'total': 99},
            'edges': edges,
          },
        },
      }),
    );

    List<Map<String, dynamic>> staffEdges(int from, int count) => [
      for (var i = from; i < from + count; i++)
        {'staffRole': 'Director', 'node': _media(i, malId: i + 1000)},
    ];

    AniListClient newClient({AniListCache? over}) {
      final c = AniListClient(
        cache: over ?? cache,
        logger: Logger(level: Level.off),
      );
      c.dio.httpClientAdapter = adapter;
      return c;
    }

    test(
      'the detail asks for a full page and records where it stopped',
      () async {
        respond = (_) => staffDetail(staffEdges(1, 3), next: true);

        final detail = await client.getStaffDetail(8);

        expect(
          (adapter.requests.single.data! as Map<String, dynamic>)['variables'],
          {'id': 8, 'perPage': AniListClient.worksPageSize},
        );
        expect(detail.worksCursor.hasMore, isTrue);
        expect(detail.worksCursor.nextPage, 2);
      },
    );

    test('a detail that ends on its first page has nothing more', () async {
      respond = (_) => staffDetail(staffEdges(1, 3), next: false);

      final detail = await client.getStaffDetail(8);

      expect(detail.worksCursor.hasMore, isFalse);
    });

    test('without pageInfo a full first page is taken to continue', () async {
      respond = (_) => staffDetail(staffEdges(1, AniListClient.worksPageSize));
      final full = await client.getStaffDetail(8);

      respond = (_) => staffDetail(staffEdges(1, 3));
      final short = await newClient().getStaffDetail(9);

      expect(full.worksCursor.hasMore, isTrue);
      expect(short.worksCursor.hasMore, isFalse);
    });

    test('every kind of detail records its cursor', () async {
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
            'media': {
              'pageInfo': {'hasNextPage': true},
              'edges': <Object>[],
            },
          },
        }),
      );
      final character = await client.getCharacterDetail(3);

      respond = (_) => FakeResponse.json(
        _gql({
          'Studio': {
            'id': 7,
            'name': 'Bones',
            'isAnimationStudio': true,
            'siteUrl': null,
            'favourites': null,
            'media': {
              'pageInfo': {'hasNextPage': true},
              'edges': <Object>[],
            },
          },
        }),
      );
      final studio = await client.getStudioDetail(7);

      expect(character.worksCursor.hasMore, isTrue);
      expect(studio.worksCursor.hasMore, isTrue);
    });

    test('a fetched page is stored with the detail', () async {
      respond = (_) => staffDetail(staffEdges(1, 3), next: true);
      await client.getStaffDetail(8);
      respond = (_) => staffPage(staffEdges(4, 3), next: true);

      await client.getWorksPage(AniListWorksSource.staff, 8, 2);

      final stored = (await cache.getStaff(8))!;
      expect(stored.mediaWorks.map((m) => m.anilistId), [
        for (var i = 1; i <= 6; i++) i,
      ]);
      expect(stored.worksCursor.nextPage, 3);
      expect(stored.worksCursor.hasMore, isTrue);
    });

    test('the last page closes the stored list', () async {
      respond = (_) => staffDetail(staffEdges(1, 3), next: true);
      await client.getStaffDetail(8);
      respond = (_) => staffPage(staffEdges(4, 2), next: false);

      await client.getWorksPage(AniListWorksSource.staff, 8, 2);

      final stored = (await cache.getStaff(8))!;
      expect(stored.mediaWorks, hasLength(5));
      expect(stored.worksCursor.hasMore, isFalse);
      expect(stored.worksCursor.nextPage, 3);
    });

    test('a later visit shows every stored page without a request', () async {
      respond = (_) => staffDetail(staffEdges(1, 3), next: true);
      await client.getStaffDetail(8);
      respond = (_) => staffPage(staffEdges(4, 3), next: true);
      await client.getWorksPage(AniListWorksSource.staff, 8, 2);
      respond = (_) => staffPage(staffEdges(7, 3), next: false);
      await client.getWorksPage(AniListWorksSource.staff, 8, 3);
      final before = gqlCalls();

      final reopened = await newClient().getStaffDetail(8);

      expect(gqlCalls(), before);
      expect(reopened.mediaWorks, hasLength(9));
      expect(reopened.worksCursor.nextPage, 4);
      expect(reopened.worksCursor.hasMore, isFalse);
    });

    test('a page for a detail that is not stored is still returned', () async {
      respond = (_) => staffPage(staffEdges(1, 2), next: true);

      final page = await client.getWorksPage(AniListWorksSource.staff, 8, 2);

      expect(page.items, hasLength(2));
      expect(await cache.getStaff(8), isNull);
    });

    test('a storage failure never fails the page', () async {
      final failing = _FailingCache(appDb);
      respond = (_) => staffPage(staffEdges(1, 2), next: true);

      final page = await newClient(over: failing)
          .getWorksPage(AniListWorksSource.staff, 8, 2);

      expect(failing.attempts, 1);
      expect(page.items, hasLength(2));
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
