import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:animal/core/network/api_exception.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/data/local/anilist_cache.dart';
import 'package:animal/data/local/app_database.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/fake_adapter.dart';

class _SchedulePages implements HttpClientAdapter {
  _SchedulePages(this.total, {this.alwaysHasNext = false, this.failPage});

  final int total;
  final bool alwaysHasNext;
  final int? failPage;
  final requestedPages = <int>[];
  var _inFlight = 0;
  int maxInFlight = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final variables =
        (options.data as Map<String, dynamic>)['variables']
            as Map<String, dynamic>;
    final page = variables['page'] as int;
    requestedPages.add(page);
    _inFlight++;
    if (_inFlight > maxInFlight) maxInFlight = _inFlight;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    _inFlight--;

    if (page == failPage) return ResponseBody.fromString('{}', 500);

    final start = (page - 1) * 50;
    final end = (start + 50).clamp(0, total);
    final body = {
      'data': {
        'Page': {
          'pageInfo': {'hasNextPage': alwaysHasNext || end < total},
          'airingSchedules': [
            for (var i = start; i < end; i++)
              {
                'id': i,
                'airingAt': 1700000000 + i * 60,
                'episode': 1,
                'timeUntilAiring': 0,
                'media': {
                  'id': i + 1,
                  'idMal': i + 1,
                  'title': {'romaji': 'T${i + 1}'},
                },
              },
          ],
        },
      },
    };
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase appDb;
  late AniListClient client;

  setUp(() async {
    final tmp = Directory.systemTemp.createTempSync('anilist_client_');
    appDb = await AppDatabase.open(
      pathOverride: '${tmp.path}/test.db',
      runMigrations: false,
    );
    client = AniListClient(
      cache: SqliteAniListCache(appDb),
      logger: Logger(level: Level.off),
    );
  });

  tearDown(() async {
    await appDb.close();
  });

  Future<(_SchedulePages, int)> refresh(_SchedulePages adapter) async {
    client.dio.httpClientAdapter = adapter;
    final schedule = await client.refreshWeeklySchedule();
    return (adapter, schedule.values.fold<int>(0, (s, l) => s + l.length));
  }

  group('AniListClient weekly schedule paging', () {
    test('a single page needs a single request', () async {
      final (adapter, count) = await refresh(_SchedulePages(30));

      expect(count, 30);
      expect(adapter.requestedPages, [1]);
    });

    test('fetches pages in waves and returns every entry', () async {
      final (adapter, count) = await refresh(_SchedulePages(320));

      expect(count, 320);
      expect(adapter.requestedPages.toSet(), {1, 2, 3, 4, 5, 6, 7});
      expect(adapter.requestedPages.first, 1);
      expect(adapter.maxInFlight, 3);
    });

    test('stops right after the last page of a wave', () async {
      final (adapter, count) = await refresh(_SchedulePages(200));

      expect(count, 200);
      expect(adapter.requestedPages.toSet(), {1, 2, 3, 4});
    });

    test('never requests more pages than the page limit', () async {
      final (adapter, _) = await refresh(
        _SchedulePages(500, alwaysHasNext: true),
      );

      expect(adapter.requestedPages.toSet(), {1, 2, 3, 4, 5, 6, 7, 8, 9, 10});
    });

    test('a failing page fails the whole fetch', () async {
      client.dio.httpClientAdapter = _SchedulePages(320, failPage: 3);

      expect(client.refreshWeeklySchedule(), throwsA(isA<ApiException>()));
    });
  });

  group('AniListClient next airings', () {
    FakeAdapter nextAiringAdapter(Map<int, Map<String, dynamic>> media) =>
        FakeAdapter((o) async {
          final ids =
              ((o.data as Map<String, dynamic>)['variables']
                      as Map<String, dynamic>)['ids']
                  as List<dynamic>;
          return FakeResponse.json({
            'data': {
              'Page': {
                'media': [
                  for (final id in ids)
                    if (media[id] != null) {'idMal': id, ...media[id]!},
                ],
              },
            },
          });
        });

    test('maps each anime to its status and next episode', () async {
      final adapter = nextAiringAdapter({
        1: {
          'status': 'RELEASING',
          'nextAiringEpisode': {
            'airingAt': 1700000000,
            'episode': 4,
            'timeUntilAiring': 600,
          },
        },
        2: {'status': 'FINISHED', 'nextAiringEpisode': null},
      });
      client.dio.httpClientAdapter = adapter;

      final found = await client.getNextAirings([1, 2, 3]);

      expect(found.keys, unorderedEquals([1, 2]));
      expect(found[1]!.status, 'RELEASING');
      expect(found[1]!.next!.episode, 4);
      expect(
        found[1]!.next!.airingAt,
        DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000, isUtc: true),
      );
      expect(found[1]!.next!.timeUntilAiring, 600);
      expect(found[2]!.status, 'FINISHED');
      expect(found[2]!.next, isNull);
    });

    test('asks for fifty ids at a time', () async {
      final adapter = nextAiringAdapter({});
      client.dio.httpClientAdapter = adapter;

      await client.getNextAirings([for (var i = 1; i <= 120; i++) i]);

      final sizes = [
        for (final r in adapter.requests)
          (((r.data as Map<String, dynamic>)['variables']
                      as Map<String, dynamic>)['ids']
                  as List<dynamic>)
              .length,
      ];
      expect(sizes, [50, 50, 20]);
    });

    test('makes no request without ids', () async {
      final adapter = nextAiringAdapter({});
      client.dio.httpClientAdapter = adapter;

      expect(await client.getNextAirings([]), isEmpty);
      expect(adapter.requests, isEmpty);
    });

    test('a failing request fails the call', () async {
      client.dio.httpClientAdapter = FakeAdapter(
        (_) async => const FakeResponse.json({}, status: 500),
      );

      expect(client.getNextAirings([1]), throwsA(isA<ApiException>()));
    });
  });
}
