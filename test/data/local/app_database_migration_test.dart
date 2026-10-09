import 'dart:io';

import 'package:animal/data/local/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _day = Duration(days: 1);

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  String tmpPath(String name) {
    final tmp = Directory.systemTemp.createTempSync('animal_migration_');
    return '${tmp.path}/$name.db';
  }

  Future<Set<String>> columns(AppDatabase db, String table) async =>
      (await db.raw.rawQuery('PRAGMA table_info($table)'))
          .map((r) => r['name']! as String)
          .toSet();

  Future<Set<String>> metaKeys(AppDatabase db) async => (await db.raw.query(
    'cache_meta',
    columns: ['cache_key'],
  )).map((r) => r['cache_key']! as String).toSet();

  Future<void> putMeta(AppDatabase db, String key, Duration age) =>
      db.raw.insert('cache_meta', {
        'cache_key': key,
        'fetched_at': DateTime.now().subtract(age).millisecondsSinceEpoch,
      });

  group('upgrading an older database', () {
    Future<String> oldDatabase(int version) async {
      final path = tmpPath('v$version');
      final db = await AppDatabase.open(
        pathOverride: path,
        runMigrations: false,
      );
      await db.raw.insert('anime', {'mal_id': 1, 'title': 'Kept anime'});
      await db.raw.insert('anilist_anime_extra', {
        'mal_id': 1,
        'next_airing_episode': 4,
        'characters_json': '[{"id":1}]',
        'staff_json': '[{"id":2}]',
      });
      await db.raw.insert('airing_schedule', {
        'anilist_id': 10,
        'episode': 2,
        'airing_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'title_romaji': 'Kept schedule',
      });
      await db.raw.insert('merged_airing_entry', {
        'week_key': 'weekly_schedule:2026-01-05',
        'day': 'monday',
        'anilist_id': 10,
        'position': 0,
        'title': 'Kept merged',
        'airing_at': 1,
        'episode': 2,
        'time_until_airing': 0,
      });
      if (version < 2) {
        await db.raw.execute(
          'ALTER TABLE anilist_anime_extra DROP COLUMN characters_json',
        );
        await db.raw.execute(
          'ALTER TABLE anilist_anime_extra DROP COLUMN staff_json',
        );
      }
      if (version < 3) {
        for (final table in ['airing_schedule', 'merged_airing_entry']) {
          for (final col in [
            'next_airing_at',
            'next_airing_episode',
            'next_airing_time_until',
          ]) {
            await db.raw.execute('ALTER TABLE $table DROP COLUMN $col');
          }
        }
      }
      await db.raw.setVersion(version);
      await db.close();
      return path;
    }

    test(
      'v1 gains the character/staff and next-airing columns and keeps its data',
      () async {
        final path = await oldDatabase(1);

        final db = await AppDatabase.open(
          pathOverride: path,
          runMigrations: false,
        );
        addTearDown(db.close);

        expect(await db.raw.getVersion(), 3);
        expect(
          await columns(db, 'anilist_anime_extra'),
          containsAll(['characters_json', 'staff_json']),
        );
        for (final table in ['airing_schedule', 'merged_airing_entry']) {
          expect(
            await columns(db, table),
            containsAll([
              'next_airing_at',
              'next_airing_episode',
              'next_airing_time_until',
            ]),
            reason: table,
          );
        }
        expect((await db.raw.query('anime')).single['title'], 'Kept anime');
        expect(
          (await db.raw.query('airing_schedule')).single['title_romaji'],
          'Kept schedule',
        );
        expect(
          (await db.raw.query('merged_airing_entry')).single['title'],
          'Kept merged',
        );
        expect(
          (await db.raw.query('anilist_anime_extra'))
              .single['next_airing_episode'],
          4,
        );
      },
    );

    test('v2 only gains the next-airing columns', () async {
      final path = await oldDatabase(2);

      final db = await AppDatabase.open(
        pathOverride: path,
        runMigrations: false,
      );
      addTearDown(db.close);

      expect(await db.raw.getVersion(), 3);
      expect(await columns(db, 'airing_schedule'), contains('next_airing_at'));
      expect(
        (await db.raw.query('anilist_anime_extra')).single['characters_json'],
        '[{"id":1}]',
      );
    });

    test('is safe when the columns already exist', () async {
      final path = await oldDatabase(3);
      final raw = await databaseFactory.openDatabase(path);
      await raw.setVersion(1);
      await raw.close();

      final db = await AppDatabase.open(
        pathOverride: path,
        runMigrations: false,
      );
      addTearDown(db.close);

      expect(await db.raw.getVersion(), 3);
      expect((await db.raw.query('anime')).single['title'], 'Kept anime');
    });
  });

  group('startup cleanup keeps what is fresh and drops what is stale', () {
    final retention = <String, ({Duration fresh, Duration stale})>{
      'search_q_20': (
        fresh: const Duration(minutes: 30),
        stale: const Duration(hours: 2),
      ),
      'ranking_all_20': (fresh: const Duration(hours: 12), stale: _day * 2),
      'seasonal_2026_fall_100': (fresh: _day * 60, stale: _day * 100),
      'userlist_watching_500_0': (
        fresh: const Duration(hours: 12),
        stale: _day * 2,
      ),
      'userInfo': (fresh: const Duration(hours: 12), stale: _day * 2),
      'detail_5': (fresh: _day * 20, stale: _day * 40),
      'weeklyAiringSchedule:2026-01-05': (fresh: _day * 10, stale: _day * 20),
      'weekly_schedule:2026-01-05': (fresh: _day * 10, stale: _day * 20),
      'animeExtra_5': (fresh: _day * 20, stale: _day * 40),
      'character_5': (fresh: _day * 60, stale: _day * 100),
      'staff_5': (fresh: _day * 60, stale: _day * 100),
      'studio_5': (fresh: _day * 60, stale: _day * 100),
    };

    Future<Set<String>> cleaned(String key, Duration age) async {
      final path = tmpPath('retention');
      final db1 = await AppDatabase.open(
        pathOverride: path,
        runMigrations: false,
      );
      await putMeta(db1, key, age);
      await db1.close();

      final db2 = await AppDatabase.open(pathOverride: path);
      addTearDown(db2.close);
      return metaKeys(db2);
    }

    for (final entry in retention.entries) {
      final name = entry.key;
      test('$name is purged once stale', () async {
        expect(await cleaned(name, entry.value.stale), isNot(contains(name)));
      });

      test('$name is kept while fresh', () async {
        expect(await cleaned(name, entry.value.fresh), contains(name));
      });
    }
  });

  group('startup cleanup of orphans', () {
    test(
      'removes expired merged-week rows together with their metadata',
      () async {
        final path = tmpPath('merged');
        final db1 = await AppDatabase.open(
          pathOverride: path,
          runMigrations: false,
        );
        Future<void> week(String key, Duration age) async {
          await putMeta(db1, key, age);
          await db1.raw.insert('merged_airing_entry', {
            'week_key': key,
            'day': 'monday',
            'anilist_id': key.hashCode.abs() % 100000,
            'position': 0,
            'title': key,
            'airing_at': 1,
            'episode': 1,
            'time_until_airing': 0,
          });
        }

        await week('weekly_schedule:2026-10-05', const Duration(days: 1));
        await week('weekly_schedule:2025-01-06', _day * 300);
        await db1.close();

        final db2 = await AppDatabase.open(pathOverride: path);
        addTearDown(db2.close);

        final rows = (await db2.raw.query('merged_airing_entry'))
            .map((r) => r['week_key'])
            .toList();
        expect(rows, ['weekly_schedule:2026-10-05']);
      },
    );

    test(
      'keeps an anime that any list, query, detail or schedule still uses',
      () async {
        final path = tmpPath('anime');
        final db1 = await AppDatabase.open(
          pathOverride: path,
          runMigrations: false,
        );
        for (final id in [1, 2, 3, 4, 5, 6]) {
          await db1.raw.insert('anime', {'mal_id': id, 'title': 'A$id'});
        }
        await putMeta(db1, 'userlist_watching_500_0', const Duration(hours: 1));
        await db1.raw.insert('user_anime_list_item', {
          'cache_key': 'userlist_watching_500_0',
          'mal_id': 1,
          'position': 0,
        });
        await putMeta(db1, 'search_x_20', const Duration(minutes: 1));
        await db1.raw.insert('anime_query_item', {
          'cache_key': 'search_x_20',
          'mal_id': 2,
          'position': 0,
        });
        await db1.raw.insert('anime_detail', {'mal_id': 3});
        await db1.raw.insert('airing_schedule', {
          'anilist_id': 9,
          'episode': 1,
          'mal_id': 4,
          'airing_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'title_romaji': 'x',
        });
        await db1.raw.insert('anilist_anime_extra', {'mal_id': 5});
        await db1.close();

        final db2 = await AppDatabase.open(pathOverride: path);
        addTearDown(db2.close);

        final ids = (await db2.raw.query('anime'))
            .map((r) => r['mal_id'])
            .toSet();
        expect(ids, {1, 2, 3, 4, 5});
      },
    );

    test('drops list rows whose list metadata expired', () async {
      final path = tmpPath('list');
      final db1 = await AppDatabase.open(
        pathOverride: path,
        runMigrations: false,
      );
      await db1.raw.insert('anime', {'mal_id': 1, 'title': 'A'});
      await putMeta(db1, 'userlist_watching_500_0', _day * 3);
      await db1.raw.insert('user_anime_list_item', {
        'cache_key': 'userlist_watching_500_0',
        'mal_id': 1,
        'position': 0,
      });
      await db1.close();

      final db2 = await AppDatabase.open(pathOverride: path);
      addTearDown(db2.close);

      expect(await db2.raw.query('user_anime_list_item'), isEmpty);
      expect(await db2.raw.query('anime'), isEmpty);
    });

    test('removes aired schedule rows older than two weeks only', () async {
      final path = tmpPath('schedule');
      final db1 = await AppDatabase.open(
        pathOverride: path,
        runMigrations: false,
      );
      Future<void> row(int id, Duration ago) =>
          db1.raw.insert('airing_schedule', {
            'anilist_id': id,
            'episode': 1,
            'airing_at':
                DateTime.now().subtract(ago).millisecondsSinceEpoch ~/ 1000,
            'title_romaji': 'x',
          });
      await row(1, _day * 20);
      await row(2, _day * 5);
      await db1.close();

      final db2 = await AppDatabase.open(pathOverride: path);
      addTearDown(db2.close);

      expect(
        (await db2.raw.query('airing_schedule')).map((r) => r['anilist_id']),
        [2],
      );
    });
  });
}
