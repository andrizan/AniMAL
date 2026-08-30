import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;

  Database get raw => _db;

  static const _schemaVersion = 3;
  static const _fileName = 'animal_cache.db';

  static Future<AppDatabase> open({
    String? pathOverride,
    bool runMigrations = true,
  }) async {
    final dbPath = pathOverride ?? p.join(await getDatabasesPath(), _fileName);
    final db = await openDatabase(
      dbPath,
      version: _schemaVersion,
      onConfigure: _onConfigure,
      onCreate: (db, version) async {
        await _createV1(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createV1(db);
        if (oldVersion < 2) {
          await _migrateV1ToV2(db);
        }
        if (oldVersion < 3) {
          await _migrateV2ToV3(db);
        }
      },
    );
    final appDb = AppDatabase._(db);
    if (runMigrations) {
      await appDb._runStartupCleanup();
    }
    return appDb;
  }

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _runStartupCleanup() async {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    final oneDayAgo = now.subtract(const Duration(days: 1));
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final ninetyDaysAgo = now.subtract(const Duration(days: 90));
    final fourteenDaysAgo = now.subtract(const Duration(days: 14));

    await _db.transaction((txn) async {
      await txn.delete(
        'cache_meta',
        where: 'cache_key LIKE ? AND fetched_at < ?',
        whereArgs: ['search_%', oneHourAgo.millisecondsSinceEpoch],
      );
      await txn.delete(
        'cache_meta',
        where: 'cache_key LIKE ? AND fetched_at < ?',
        whereArgs: ['ranking_%', oneDayAgo.millisecondsSinceEpoch],
      );
      await txn.delete(
        'cache_meta',
        where: 'cache_key LIKE ? AND fetched_at < ?',
        whereArgs: ['seasonal_%', ninetyDaysAgo.millisecondsSinceEpoch],
      );
      await txn.delete(
        'cache_meta',
        where: 'cache_key LIKE ? AND fetched_at < ?',
        whereArgs: ['userlist_%', oneDayAgo.millisecondsSinceEpoch],
      );
      await txn.delete(
        'cache_meta',
        where: 'cache_key = ? AND fetched_at < ?',
        whereArgs: ['userInfo', oneDayAgo.millisecondsSinceEpoch],
      );
      await txn.delete(
        'cache_meta',
        where: 'cache_key LIKE ? AND fetched_at < ?',
        whereArgs: ['detail_%', thirtyDaysAgo.millisecondsSinceEpoch],
      );
      await txn.delete(
        'cache_meta',
        where: 'cache_key LIKE ? AND fetched_at < ?',
        whereArgs: [
          'weeklyAiringSchedule:%',
          fourteenDaysAgo.millisecondsSinceEpoch,
        ],
      );
      await txn.delete(
        'cache_meta',
        where: 'cache_key LIKE ? AND fetched_at < ?',
        whereArgs: ['animeExtra_%', thirtyDaysAgo.millisecondsSinceEpoch],
      );
      await txn.delete(
        'cache_meta',
        where: 'cache_key LIKE ? AND fetched_at < ?',
        whereArgs: ['character_%', ninetyDaysAgo.millisecondsSinceEpoch],
      );
      await txn.delete(
        'cache_meta',
        where: 'cache_key LIKE ? AND fetched_at < ?',
        whereArgs: ['staff_%', ninetyDaysAgo.millisecondsSinceEpoch],
      );
      await txn.delete(
        'cache_meta',
        where: 'cache_key LIKE ? AND fetched_at < ?',
        whereArgs: ['studio_%', ninetyDaysAgo.millisecondsSinceEpoch],
      );
      final fourteenDaysEpochSec =
          fourteenDaysAgo.millisecondsSinceEpoch ~/ 1000;
      await txn.delete(
        'airing_schedule',
        where: 'airing_at < ?',
        whereArgs: [fourteenDaysEpochSec],
      );
      await txn.delete(
        'anime_query_item',
        where: "cache_key NOT IN (SELECT cache_key FROM cache_meta WHERE cache_key LIKE 'search_%' OR cache_key LIKE 'seasonal_%' OR cache_key LIKE 'ranking_%')",
      );
      await txn.delete(
        'user_anime_list_item',
        where: "cache_key NOT IN (SELECT cache_key FROM cache_meta WHERE cache_key LIKE 'userlist_%')",
      );
      await txn.delete(
        'anime',
        where:
            'mal_id NOT IN (SELECT DISTINCT mal_id FROM anime_query_item) '
            'AND mal_id NOT IN (SELECT DISTINCT mal_id FROM user_anime_list_item) '
            'AND (mal_id NOT IN (SELECT DISTINCT mal_id FROM airing_schedule WHERE mal_id IS NOT NULL)) '
            'AND mal_id NOT IN (SELECT mal_id FROM anime_detail) '
            'AND mal_id NOT IN (SELECT mal_id FROM anilist_anime_extra)',
      );
      await txn.delete(
        'merged_airing_entry',
        where: "week_key NOT IN (SELECT cache_key FROM cache_meta WHERE cache_key LIKE 'weekly_schedule:%')",
      );
    });
  }

  static Future<void> _createV1(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cache_meta (
        cache_key   TEXT PRIMARY KEY,
        fetched_at  INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS genre (
        id    INTEGER PRIMARY KEY,
        name  TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS anime (
        mal_id                  INTEGER PRIMARY KEY,
        title                   TEXT NOT NULL,
        picture_medium          TEXT,
        picture_large           TEXT,
        alt_title_en            TEXT,
        alt_title_ja            TEXT,
        alt_title_synonyms_json TEXT,
        mean                    REAL,
        rank                    INTEGER,
        popularity              INTEGER,
        num_episodes            INTEGER,
        status                  TEXT,
        rating                  TEXT,
        media_type              TEXT,
        broadcast_day_of_week   TEXT,
        broadcast_start_time    TEXT,
        my_list_status_json     TEXT,
        my_list_status_user     TEXT
      );
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_anime_my_list_status_user '
      'ON anime(my_list_status_user);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS anime_genre (
        mal_id    INTEGER NOT NULL,
        genre_id  INTEGER NOT NULL,
        PRIMARY KEY (mal_id, genre_id),
        FOREIGN KEY (mal_id)   REFERENCES anime(mal_id) ON DELETE CASCADE,
        FOREIGN KEY (genre_id) REFERENCES genre(id)    ON DELETE CASCADE
      );
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_anime_genre_genre_id '
      'ON anime_genre(genre_id);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS anime_detail (
        mal_id                    INTEGER PRIMARY KEY,
        synopsis                  TEXT,
        source                    TEXT,
        start_date                TEXT,
        end_date                  TEXT,
        num_scoring_users         INTEGER,
        average_episode_duration  INTEGER,
        start_season_year         INTEGER,
        start_season_season       TEXT,
        related_anime_json        TEXT,
        FOREIGN KEY (mal_id) REFERENCES anime(mal_id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS anime_query_item (
        cache_key  TEXT NOT NULL,
        mal_id     INTEGER NOT NULL,
        position   INTEGER NOT NULL,
        PRIMARY KEY (cache_key, mal_id),
        FOREIGN KEY (mal_id) REFERENCES anime(mal_id) ON DELETE CASCADE
      );
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_anime_query_item_position '
      'ON anime_query_item(cache_key, position);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_anime_query_item_cache_key '
      'ON anime_query_item(cache_key);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_anime_list_item (
        cache_key  TEXT NOT NULL,
        mal_id     INTEGER NOT NULL,
        position   INTEGER NOT NULL,
        PRIMARY KEY (cache_key, mal_id),
        FOREIGN KEY (mal_id) REFERENCES anime(mal_id) ON DELETE CASCADE
      );
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_user_anime_list_item_position '
      'ON user_anime_list_item(cache_key, position);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS anilist_anime_extra (
        mal_id                INTEGER PRIMARY KEY,
        next_airing_at        INTEGER,
        next_airing_episode   INTEGER,
        next_airing_time_until INTEGER,
        characters_json       TEXT,
        staff_json            TEXT,
        FOREIGN KEY (mal_id) REFERENCES anime(mal_id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS anilist_anime_extra_link (
        mal_id    INTEGER NOT NULL,
        id        INTEGER NOT NULL,
        url       TEXT NOT NULL,
        site      TEXT,
        type      TEXT,
        language  TEXT,
        icon      TEXT,
        PRIMARY KEY (mal_id, id),
        FOREIGN KEY (mal_id) REFERENCES anilist_anime_extra(mal_id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS anilist_anime_extra_studio (
        mal_id              INTEGER NOT NULL,
        studio_id           INTEGER NOT NULL,
        name                TEXT NOT NULL,
        is_animation_studio INTEGER NOT NULL,
        site_url            TEXT,
        is_main             INTEGER NOT NULL,
        PRIMARY KEY (mal_id, studio_id),
        FOREIGN KEY (mal_id) REFERENCES anilist_anime_extra(mal_id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS anilist_anime_extra_voice_actor (
        anime_mal_id    INTEGER NOT NULL,
        character_id    INTEGER NOT NULL,
        va_id           INTEGER NOT NULL,
        name            TEXT NOT NULL,
        native_name     TEXT,
        image_url       TEXT,
        language        TEXT,
        PRIMARY KEY (anime_mal_id, character_id, va_id),
        FOREIGN KEY (anime_mal_id) REFERENCES anilist_anime_extra(mal_id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS anilist_character (
        id            INTEGER PRIMARY KEY,
        name          TEXT NOT NULL,
        native_name   TEXT,
        image_url     TEXT,
        description   TEXT,
        birth_year    INTEGER,
        birth_month   INTEGER,
        birth_day     INTEGER,
        age           TEXT,
        gender        TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS anilist_character_media (
        character_id  INTEGER NOT NULL,
        anilist_id    INTEGER NOT NULL,
        mal_id        INTEGER,
        title         TEXT NOT NULL,
        title_english TEXT,
        image_url     TEXT,
        type          TEXT,
        role          TEXT,
        position      INTEGER NOT NULL,
        PRIMARY KEY (character_id, anilist_id),
        FOREIGN KEY (character_id) REFERENCES anilist_character(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS anilist_staff (
        id              INTEGER PRIMARY KEY,
        name            TEXT NOT NULL,
        native_name     TEXT,
        image_url       TEXT,
        description     TEXT,
        gender          TEXT,
        birth_year      INTEGER,
        birth_month     INTEGER,
        birth_day       INTEGER,
        death_year      INTEGER,
        death_month     INTEGER,
        death_day       INTEGER,
        age             INTEGER,
        years_active_json TEXT,
        home_town       TEXT,
        occupations_json TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS anilist_staff_media (
        staff_id      INTEGER NOT NULL,
        anilist_id    INTEGER NOT NULL,
        mal_id        INTEGER,
        title         TEXT NOT NULL,
        title_english TEXT,
        image_url     TEXT,
        type          TEXT,
        role          TEXT,
        position      INTEGER NOT NULL,
        PRIMARY KEY (staff_id, anilist_id),
        FOREIGN KEY (staff_id) REFERENCES anilist_staff(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS anilist_studio (
        id                   INTEGER PRIMARY KEY,
        name                 TEXT NOT NULL,
        is_animation_studio  INTEGER NOT NULL,
        site_url             TEXT,
        favourites           INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS anilist_studio_media (
        studio_id    INTEGER NOT NULL,
        anilist_id   INTEGER NOT NULL,
        mal_id       INTEGER,
        title        TEXT NOT NULL,
        title_english TEXT,
        image_url    TEXT,
        type         TEXT,
        role         TEXT,
        position     INTEGER NOT NULL,
        PRIMARY KEY (studio_id, anilist_id),
        FOREIGN KEY (studio_id) REFERENCES anilist_studio(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS airing_schedule (
        anilist_id              INTEGER NOT NULL,
        episode                 INTEGER NOT NULL,
        mal_id                  INTEGER,
        airing_at               INTEGER NOT NULL,
        title_romaji            TEXT NOT NULL,
        title_english           TEXT,
        title_native            TEXT,
        image_url               TEXT,
        image_url_large         TEXT,
        status                  TEXT,
        episodes                INTEGER,
        mean_score              REAL,
        format                  TEXT,
        description             TEXT,
        time_until_airing       INTEGER,
        next_airing_at          INTEGER,
        next_airing_episode     INTEGER,
        next_airing_time_until  INTEGER,
        PRIMARY KEY (anilist_id, episode)
      );
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_airing_schedule_airing_at '
      'ON airing_schedule(airing_at);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_airing_schedule_mal_id '
      'ON airing_schedule(mal_id);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS mal_user_cache (
        cache_key  TEXT PRIMARY KEY,
        id         INTEGER,
        name       TEXT,
        picture    TEXT,
        gender     TEXT,
        birthday   TEXT,
        location   TEXT,
        joined_at  TEXT,
        stats_json TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS merged_airing_entry (
        week_key              TEXT NOT NULL,
        day                   TEXT NOT NULL,
        anilist_id            INTEGER NOT NULL,
        position              INTEGER NOT NULL,
        mal_id                INTEGER,
        title                 TEXT NOT NULL,
        title_english         TEXT,
        title_native          TEXT,
        image_url             TEXT,
        airing_at             INTEGER NOT NULL,
        episode               INTEGER NOT NULL,
        time_until_airing     INTEGER NOT NULL,
        next_airing_at        INTEGER,
        next_airing_episode   INTEGER,
        next_airing_time_until INTEGER,
        mal_score             REAL,
        genres_json           TEXT,
        episodes              INTEGER,
        format                TEXT,
        status                TEXT,
        my_list_status_json   TEXT,
        PRIMARY KEY (week_key, anilist_id, episode)
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_merged_airing_entry_week '
      'ON merged_airing_entry(week_key);',
    );
  }

  static Future<void> _migrateV1ToV2(Database db) async {
    final columns = await db.rawQuery(
      'PRAGMA table_info(anilist_anime_extra)',
    );
    final hasChars = columns.any((c) => c['name'] == 'characters_json');
    final hasStaff = columns.any((c) => c['name'] == 'staff_json');
    if (!hasChars) {
      await db.execute(
        'ALTER TABLE anilist_anime_extra ADD COLUMN characters_json TEXT',
      );
    }
    if (!hasStaff) {
      await db.execute(
        'ALTER TABLE anilist_anime_extra ADD COLUMN staff_json TEXT',
      );
    }
  }

  static Future<void> _migrateV2ToV3(Database db) async {
    for (final table in ['airing_schedule', 'merged_airing_entry']) {
      final cols = await db.rawQuery('PRAGMA table_info($table)');
      final hasNextAt = cols.any((c) => c['name'] == 'next_airing_at');
      final hasNextEp = cols.any((c) => c['name'] == 'next_airing_episode');
      final hasNextUntil = cols.any(
        (c) => c['name'] == 'next_airing_time_until',
      );
      if (!hasNextAt) {
        await db.execute(
          'ALTER TABLE $table ADD COLUMN next_airing_at INTEGER',
        );
      }
      if (!hasNextEp) {
        await db.execute(
          'ALTER TABLE $table ADD COLUMN next_airing_episode INTEGER',
        );
      }
      if (!hasNextUntil) {
        await db.execute(
          'ALTER TABLE $table ADD COLUMN next_airing_time_until INTEGER',
        );
      }
    }
  }

  Future<void> close() => _db.close();
}
