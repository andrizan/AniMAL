import 'dart:io';

import 'package:animal/data/local/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  String tmpPath(String suffix) {
    final tmp = Directory.systemTemp.createTempSync('animal_test_');
    return '${tmp.path}/${suffix}_${DateTime.now().microsecondsSinceEpoch}.db';
  }

  group('AppDatabase', () {
    test('opens in-memory DB and reports schema version 1', () async {
      final db = await AppDatabase.open(
        pathOverride: inMemoryDatabasePath,
        runMigrations: false,
      );
      addTearDown(db.close);

      final version = await db.raw.getVersion();
      expect(version, 1);
    });

    test('foreign keys are enabled', () async {
      final db = await AppDatabase.open(
        pathOverride: inMemoryDatabasePath,
        runMigrations: false,
      );
      addTearDown(db.close);

      final result = await db.raw.rawQuery('PRAGMA foreign_keys');
      final fkEnabled = result.first.values.first!;
      expect(fkEnabled, 1);
    });

    test('schema has all expected tables', () async {
      final db = await AppDatabase.open(
        pathOverride: inMemoryDatabasePath,
        runMigrations: false,
      );
      addTearDown(db.close);

      final tables = await db.raw.query(
        'sqlite_master',
        columns: ['name'],
        where: 'type = ?',
        whereArgs: ['table'],
      );
      final names = tables.map((r) => r['name'] as String).toSet();
      expect(
        names,
        containsAll([
          'cache_meta',
          'genre',
          'anime',
          'anime_genre',
          'anime_detail',
          'anime_query_item',
          'user_anime_list_item',
          'anilist_anime_extra',
          'anilist_anime_extra_link',
          'anilist_anime_extra_studio',
          'anilist_anime_extra_voice_actor',
          'anilist_character',
          'anilist_character_media',
          'anilist_staff',
          'anilist_staff_media',
          'anilist_studio',
          'anilist_studio_media',
          'airing_schedule',
          'mal_user_cache',
          'merged_airing_entry',
        ]),
      );
    });

    test('re-opening with same file path keeps data (persistence)', () async {
      final dbPath = tmpPath('persist');
      try {
        final db1 = await AppDatabase.open(
          pathOverride: dbPath,
          runMigrations: false,
        );
        await db1.raw.insert('cache_meta', {
          'cache_key': 'test_key',
          'fetched_at': DateTime.now().millisecondsSinceEpoch,
        });
        await db1.close();

        final db2 = await AppDatabase.open(
          pathOverride: dbPath,
          runMigrations: false,
        );
        final rows = await db2.raw.query(
          'cache_meta',
          where: 'cache_key = ?',
          whereArgs: ['test_key'],
        );
        expect(rows, hasLength(1));
        await db2.close();
      } finally {
        await databaseFactory.deleteDatabase(dbPath);
      }
    });

    test('startup cleanup on file DB removes stale rows', () async {
      final dbPath = tmpPath('cleanup');
      try {
        final db1 = await AppDatabase.open(
          pathOverride: dbPath,
          runMigrations: false,
        );
        final now = DateTime.now();
        await db1.raw.insert('cache_meta', {
          'cache_key': 'search_stale_20',
          'fetched_at': now
              .subtract(const Duration(hours: 5))
              .millisecondsSinceEpoch,
        });
        await db1.raw.insert('cache_meta', {
          'cache_key': 'search_fresh_20',
          'fetched_at': now
              .subtract(const Duration(minutes: 1))
              .millisecondsSinceEpoch,
        });
        await db1.raw.insert('cache_meta', {
          'cache_key': 'ranking_stale_20',
          'fetched_at': now
              .subtract(const Duration(days: 2))
              .millisecondsSinceEpoch,
        });
        await db1.close();

        final db2 = await AppDatabase.open(
          pathOverride: dbPath,
        );
        final keys = (await db2.raw.query(
          'cache_meta',
          columns: ['cache_key'],
        )).map((r) => r['cache_key'] as String).toSet();

        expect(keys, isNot(contains('search_stale_20')));
        expect(keys, contains('search_fresh_20'));
        expect(keys, isNot(contains('ranking_stale_20')));
        await db2.close();
      } finally {
        await databaseFactory.deleteDatabase(dbPath);
      }
    });

    test('idempotent: schema is reusable across open calls', () async {
      final db = await AppDatabase.open(
        pathOverride: inMemoryDatabasePath,
        runMigrations: false,
      );
      addTearDown(db.close);

      final tables = await db.raw.query(
        'sqlite_master',
        columns: ['name'],
        where: 'type = ?',
        whereArgs: ['table'],
      );
      expect(tables.length, greaterThanOrEqualTo(20));
    });
  });
}
