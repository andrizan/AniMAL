import 'dart:convert';

import 'package:animal/data/local/app_database.dart';
import 'package:animal/data/models/anilist/anilist_models.dart';
import 'package:sqflite/sqflite.dart';

/// Typed cache for AniList endpoints (weekly schedule, anime extra, character,
/// staff, studio).
abstract interface class AniListCache {
  Future<DateTime?> getFetchedAt(String cacheKey);

  // Schedule
  Future<Map<String, List<AniListScheduleEntry>>?> getWeeklySchedule(
    int weekStartEpochSec,
  );
  Future<void> saveWeeklySchedule(
    int weekStartEpochSec,
    Map<String, List<AniListScheduleEntry>> schedule,
  );

  // Anime extra
  Future<AniListAnimeExtra?> getAnimeExtra(int malId);
  Future<void> saveAnimeExtra(int malId, AniListAnimeExtra extra);

  // Character
  Future<AniListCharacterDetail?> getCharacter(int id);
  Future<void> saveCharacter(AniListCharacterDetail detail);

  // Staff
  Future<AniListStaffDetail?> getStaff(int id);
  Future<void> saveStaff(AniListStaffDetail detail);

  // Studio
  Future<AniListStudioDetail?> getStudio(int id);
  Future<void> saveStudio(AniListStudioDetail detail);
}

class SqliteAniListCache implements AniListCache {
  SqliteAniListCache(this._appDb);

  final AppDatabase _appDb;
  Database get _db => _appDb.raw;

  static String weeklyKey(int weekStartEpochSec) {
    final dt = DateTime.fromMillisecondsSinceEpoch(weekStartEpochSec * 1000)
        .toUtc();
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return 'weeklyAiringSchedule:$y-$m-$d';
  }

  static String _animeExtraKey(int malId) => 'animeExtra_$malId';
  static String _characterKey(int id) => 'character_$id';
  static String _staffKey(int id) => 'staff_$id';
  static String _studioKey(int id) => 'studio_$id';

  static const _dayNames = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  @override
  Future<DateTime?> getFetchedAt(String cacheKey) async {
    final rows = await _db.query(
      'cache_meta',
      columns: ['fetched_at'],
      where: 'cache_key = ?',
      whereArgs: [cacheKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      rows.first['fetched_at']! as int,
    );
  }

  Future<void> _upsertMeta(DatabaseExecutor txn, String key) async {
    await txn.insert(
      'cache_meta',
      {
        'cache_key': key,
        'fetched_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---------- Weekly schedule ----------

  @override
  Future<Map<String, List<AniListScheduleEntry>>?> getWeeklySchedule(
    int weekStartEpochSec,
  ) async {
    final key = weeklyKey(weekStartEpochSec);
    if (await getFetchedAt(key) == null) return null;
    final rows = await _db.query(
      'airing_schedule',
      where: 'airing_at >= ? AND airing_at < ?',
      whereArgs: [weekStartEpochSec, weekStartEpochSec + 7 * 24 * 60 * 60],
      orderBy: 'airing_at ASC',
    );
    if (rows.isEmpty) {
      return <String, List<AniListScheduleEntry>>{
        for (final d in _dayNames) d: <AniListScheduleEntry>[],
      };
    }
    final grouped = <String, List<AniListScheduleEntry>>{
      for (final d in _dayNames) d: <AniListScheduleEntry>[],
    };
    for (final row in rows) {
      final entry = _entryFromRow(row);
      final dayIdx = entry.airingAt.toUtc().weekday; // 1..7
      final dayName = _dayNames[dayIdx - 1];
      grouped[dayName]!.add(entry);
    }
    return grouped;
  }

  @override
  Future<void> saveWeeklySchedule(
    int weekStartEpochSec,
    Map<String, List<AniListScheduleEntry>> schedule,
  ) async {
    final key = weeklyKey(weekStartEpochSec);
    final end = weekStartEpochSec + 14 * 24 * 60 * 60;
    await _db.transaction((txn) async {
      // Delete 14d window to also clean synthetic +7d next-week entries.
      await txn.delete(
        'airing_schedule',
        where: 'airing_at >= ? AND airing_at < ?',
        whereArgs: [weekStartEpochSec, end],
      );
      for (final entries in schedule.values) {
        for (final e in entries) {
          await txn.insert('airing_schedule', _entryToRow(e));
        }
      }
      await _upsertMeta(txn, key);
    });
  }

  Map<String, Object?> _entryToRow(AniListScheduleEntry e) {
    return <String, Object?>{
      'anilist_id': e.anilistId,
      'episode': e.episode ?? 0,
      'mal_id': e.malId,
      'airing_at': e.airingAt.millisecondsSinceEpoch ~/ 1000,
      'title_romaji': e.title,
      'title_english': e.titleEnglish,
      'title_native': e.titleNative,
      'image_url': e.imageUrl,
      'image_url_large': e.imageUrlLarge,
      'status': e.status,
      'episodes': e.episodes,
      'mean_score': e.meanScore,
      'format': e.format,
      'description': e.description,
      'time_until_airing': e.timeUntilAiring,
    };
  }

  AniListScheduleEntry _entryFromRow(Map<String, Object?> row) {
    return AniListScheduleEntry(
      anilistId: row['anilist_id']! as int,
      title: row['title_romaji']! as String,
      airingAt: DateTime.fromMillisecondsSinceEpoch(
        (row['airing_at']! as int) * 1000,
      ),
      malId: row['mal_id'] as int?,
      titleEnglish: row['title_english'] as String?,
      titleNative: row['title_native'] as String?,
      imageUrl: row['image_url'] as String?,
      imageUrlLarge: row['image_url_large'] as String?,
      status: row['status'] as String?,
      episodes: row['episodes'] as int?,
      meanScore: (row['mean_score'] as num?)?.toDouble(),
      format: row['format'] as String?,
      description: row['description'] as String?,
      episode: row['episode'] as int?,
      timeUntilAiring: row['time_until_airing'] as int?,
    );
  }

  // ---------- Anime extra ----------

  @override
  Future<AniListAnimeExtra?> getAnimeExtra(int malId) async {
    final key = _animeExtraKey(malId);
    if (await getFetchedAt(key) == null) return null;
    final rows = await _db.query(
      'anilist_anime_extra',
      where: 'mal_id = ?',
      whereArgs: [malId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return const AniListAnimeExtra();
    }
    final row = rows.first;
    final linkRows = await _db.query(
      'anilist_anime_extra_link',
      where: 'mal_id = ?',
      whereArgs: [malId],
    );
    final studioRows = await _db.query(
      'anilist_anime_extra_studio',
      where: 'mal_id = ?',
      whereArgs: [malId],
    );
    final charactersJson = row['characters_json'] as String?;
    final staffJson = row['staff_json'] as String?;
    if (charactersJson != null || staffJson != null) {
      final characters = <AniListCharacter>[];
      final staff = <AniListStaff>[];
      if (charactersJson != null) {
        final decoded = jsonDecode(charactersJson) as List<dynamic>;
        for (final c in decoded) {
          final m = c as Map<String, dynamic>;
          final vas = (m['voiceActors'] as List<dynamic>? ?? [])
              .map(
                (v) => AniListVoiceActor(
                  id: v['id'] as int,
                  name: v['name'] as String,
                  nativeName: v['nativeName'] as String?,
                  imageUrl: v['imageUrl'] as String?,
                  language: v['language'] as String?,
                ),
              )
              .toList();
          characters.add(
            AniListCharacter(
              id: m['id'] as int,
              name: m['name'] as String,
              nativeName: m['nativeName'] as String?,
              imageUrl: m['imageUrl'] as String?,
              role: m['role'] as String?,
              voiceActors: vas,
            ),
          );
        }
      }
      if (staffJson != null) {
        final decoded = jsonDecode(staffJson) as List<dynamic>;
        for (final s in decoded) {
          final m = s as Map<String, dynamic>;
          staff.add(
            AniListStaff(
              id: m['id'] as int,
              name: m['name'] as String,
              nativeName: m['nativeName'] as String?,
              imageUrl: m['imageUrl'] as String?,
              role: m['role'] as String?,
            ),
          );
        }
      }
      final vaRows = await _db.query(
        'anilist_anime_extra_voice_actor',
        where: 'anime_mal_id = ?',
        whereArgs: [malId],
      );
      if (characters.isEmpty && vaRows.isNotEmpty) {
        final vasByChar = <int, List<AniListVoiceActor>>{};
        for (final v in vaRows) {
          final va = AniListVoiceActor(
            id: v['va_id']! as int,
            name: v['name']! as String,
            nativeName: v['native_name'] as String?,
            imageUrl: v['image_url'] as String?,
            language: v['language'] as String?,
          );
          vasByChar.putIfAbsent(v['character_id']! as int, () => []).add(va);
        }
        for (final cid in vasByChar.keys) {
          characters.add(
            AniListCharacter(
              id: cid,
              name: 'Unknown',
              voiceActors: vasByChar[cid]!,
            ),
          );
        }
      }
      final links = linkRows
          .map(
            (l) => AniListExternalLink(
              id: l['id']! as int,
              url: l['url']! as String,
              site: l['site'] as String?,
              type: l['type'] as String?,
              language: l['language'] as String?,
              icon: l['icon'] as String?,
            ),
          )
          .toList();
      final studios = studioRows
          .map(
            (s) => AniListStudio(
              id: s['studio_id']! as int,
              name: s['name']! as String,
              isAnimationStudio: (s['is_animation_studio']! as int) == 1,
              siteUrl: s['site_url'] as String?,
              isMain: (s['is_main']! as int) == 1,
            ),
          )
          .toList();
      AniListNextAiring? nextAiring;
      if (row['next_airing_at'] != null) {
        nextAiring = AniListNextAiring(
          airingAt: DateTime.fromMillisecondsSinceEpoch(
            (row['next_airing_at']! as int) * 1000,
          ),
          episode: row['next_airing_episode']! as int,
          timeUntilAiring: row['next_airing_time_until']! as int,
        );
      }
      return AniListAnimeExtra(
        people: AniListAnimePeople(characters: characters, staff: staff),
        nextAiring: nextAiring,
        externalLinks: links,
        studios: studios,
      );
    }
    final vaRows = await _db.query(
      'anilist_anime_extra_voice_actor',
      where: 'anime_mal_id = ?',
      whereArgs: [malId],
    );
    // Group voice actors by character_id
    final vasByChar = <int, List<AniListVoiceActor>>{};
    for (final v in vaRows) {
      final va = AniListVoiceActor(
        id: v['va_id']! as int,
        name: v['name']! as String,
        nativeName: v['native_name'] as String?,
        imageUrl: v['image_url'] as String?,
        language: v['language'] as String?,
      );
      vasByChar.putIfAbsent(v['character_id']! as int, () => []).add(va);
    }
    final characters = <AniListCharacter>[];
    final staff = <AniListStaff>[];
    for (final cid in vasByChar.keys) {
      characters.add(
        AniListCharacter(
          id: cid,
          name: 'Unknown',
          voiceActors: vasByChar[cid]!,
        ),
      );
    }
    final links = linkRows
        .map(
          (l) => AniListExternalLink(
            id: l['id']! as int,
            url: l['url']! as String,
            site: l['site'] as String?,
            type: l['type'] as String?,
            language: l['language'] as String?,
            icon: l['icon'] as String?,
          ),
        )
        .toList();
    final studios = studioRows
        .map(
          (s) => AniListStudio(
            id: s['studio_id']! as int,
            name: s['name']! as String,
            isAnimationStudio: (s['is_animation_studio']! as int) == 1,
            siteUrl: s['site_url'] as String?,
            isMain: (s['is_main']! as int) == 1,
          ),
        )
        .toList();
    AniListNextAiring? nextAiring;
    if (row['next_airing_at'] != null) {
      nextAiring = AniListNextAiring(
        airingAt: DateTime.fromMillisecondsSinceEpoch(
          (row['next_airing_at']! as int) * 1000,
        ),
        episode: row['next_airing_episode']! as int,
        timeUntilAiring: row['next_airing_time_until']! as int,
      );
    }
    return AniListAnimeExtra(
      people: AniListAnimePeople(characters: characters, staff: staff),
      nextAiring: nextAiring,
      externalLinks: links,
      studios: studios,
    );
  }

  @override
  Future<void> saveAnimeExtra(int malId, AniListAnimeExtra extra) async {
    final key = _animeExtraKey(malId);
    await _db.transaction((txn) async {
      await txn.delete(
        'anilist_anime_extra',
        where: 'mal_id = ?',
        whereArgs: [malId],
      );
      final charactersJson = jsonEncode(
        extra.people.characters
            .map(
              (c) => {
                'id': c.id,
                'name': c.name,
                'nativeName': c.nativeName,
                'imageUrl': c.imageUrl,
                'role': c.role,
                'voiceActors': c.voiceActors
                    .map(
                      (va) => {
                        'id': va.id,
                        'name': va.name,
                        'nativeName': va.nativeName,
                        'imageUrl': va.imageUrl,
                        'language': va.language,
                      },
                    )
                    .toList(),
              },
            )
            .toList(),
      );
      final staffJson = jsonEncode(
        extra.people.staff
            .map(
              (s) => {
                'id': s.id,
                'name': s.name,
                'nativeName': s.nativeName,
                'imageUrl': s.imageUrl,
                'role': s.role,
              },
            )
            .toList(),
      );
      await txn.insert('anilist_anime_extra', {
        'mal_id': malId,
        'next_airing_at': extra.nextAiring == null
            ? null
            : extra.nextAiring!.airingAt.millisecondsSinceEpoch ~/ 1000,
        'next_airing_episode': extra.nextAiring?.episode,
        'next_airing_time_until': extra.nextAiring?.timeUntilAiring,
        'characters_json': charactersJson,
        'staff_json': staffJson,
      });
      await txn.delete(
        'anilist_anime_extra_link',
        where: 'mal_id = ?',
        whereArgs: [malId],
      );
      for (final l in extra.externalLinks) {
        await txn.insert('anilist_anime_extra_link', {
          'mal_id': malId,
          'id': l.id,
          'url': l.url,
          'site': l.site,
          'type': l.type,
          'language': l.language,
          'icon': l.icon,
        });
      }
      await txn.delete(
        'anilist_anime_extra_studio',
        where: 'mal_id = ?',
        whereArgs: [malId],
      );
      for (final s in extra.studios) {
        await txn.insert('anilist_anime_extra_studio', {
          'mal_id': malId,
          'studio_id': s.id,
          'name': s.name,
          'is_animation_studio': s.isAnimationStudio ? 1 : 0,
          'site_url': s.siteUrl,
          'is_main': s.isMain ? 1 : 0,
        });
      }
      await txn.delete(
        'anilist_anime_extra_voice_actor',
        where: 'anime_mal_id = ?',
        whereArgs: [malId],
      );
      for (final c in extra.people.characters) {
        for (final va in c.voiceActors) {
          await txn.insert('anilist_anime_extra_voice_actor', {
            'anime_mal_id': malId,
            'character_id': c.id,
            'va_id': va.id,
            'name': va.name,
            'native_name': va.nativeName,
            'image_url': va.imageUrl,
            'language': va.language,
          });
        }
      }
      await _upsertMeta(txn, key);
    });
  }

  // ---------- Character ----------

  @override
  Future<AniListCharacterDetail?> getCharacter(int id) async {
    final key = _characterKey(id);
    if (await getFetchedAt(key) == null) return null;
    final rows = await _db.query(
      'anilist_character',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final media = await _db.query(
      'anilist_character_media',
      where: 'character_id = ?',
      whereArgs: [id],
      orderBy: 'position ASC',
    );
    return _characterFromRow(rows.first, media);
  }

  @override
  Future<void> saveCharacter(AniListCharacterDetail detail) async {
    final key = _characterKey(detail.id);
    await _db.transaction((txn) async {
      await txn.delete(
        'anilist_character',
        where: 'id = ?',
        whereArgs: [detail.id],
      );
      await txn.insert('anilist_character', {
        'id': detail.id,
        'name': detail.name,
        'native_name': detail.nativeName,
        'image_url': detail.imageUrl,
        'description': detail.description,
        'birth_year': detail.birthYear,
        'birth_month': detail.birthMonth,
        'birth_day': detail.birthDay,
        'age': detail.age,
        'gender': detail.gender,
      });
      await txn.delete(
        'anilist_character_media',
        where: 'character_id = ?',
        whereArgs: [detail.id],
      );
      for (var i = 0; i < detail.mediaAppearances.length; i++) {
        final m = detail.mediaAppearances[i];
        await txn.insert('anilist_character_media', {
          'character_id': detail.id,
          'anilist_id': m.anilistId,
          'mal_id': m.malId,
          'title': m.title,
          'title_english': m.titleEnglish,
          'image_url': m.imageUrl,
          'type': m.type,
          'role': m.role,
          'position': i,
        });
      }
      await _upsertMeta(txn, key);
    });
  }

  AniListCharacterDetail _characterFromRow(
    Map<String, Object?> row,
    List<Map<String, Object?>> mediaRows,
  ) {
    return AniListCharacterDetail(
      id: row['id']! as int,
      name: row['name']! as String,
      nativeName: row['native_name'] as String?,
      imageUrl: row['image_url'] as String?,
      description: row['description'] as String?,
      birthYear: row['birth_year'] as int?,
      birthMonth: row['birth_month'] as int?,
      birthDay: row['birth_day'] as int?,
      age: row['age'] as String?,
      gender: row['gender'] as String?,
      mediaAppearances: mediaRows
          .map(
            (m) => AniListMediaAppearance(
              anilistId: m['anilist_id']! as int,
              title: m['title']! as String,
              malId: m['mal_id'] as int?,
              titleEnglish: m['title_english'] as String?,
              imageUrl: m['image_url'] as String?,
              type: m['type'] as String?,
              role: m['role'] as String?,
            ),
          )
          .toList(),
    );
  }

  // ---------- Staff ----------

  @override
  Future<AniListStaffDetail?> getStaff(int id) async {
    final key = _staffKey(id);
    if (await getFetchedAt(key) == null) return null;
    final rows = await _db.query(
      'anilist_staff',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final media = await _db.query(
      'anilist_staff_media',
      where: 'staff_id = ?',
      whereArgs: [id],
      orderBy: 'position ASC',
    );
    return _staffFromRow(rows.first, media);
  }

  @override
  Future<void> saveStaff(AniListStaffDetail detail) async {
    final key = _staffKey(detail.id);
    await _db.transaction((txn) async {
      await txn.delete(
        'anilist_staff',
        where: 'id = ?',
        whereArgs: [detail.id],
      );
      await txn.insert('anilist_staff', {
        'id': detail.id,
        'name': detail.name,
        'native_name': detail.nativeName,
        'image_url': detail.imageUrl,
        'description': detail.description,
        'gender': detail.gender,
        'birth_year': detail.birthYear,
        'birth_month': detail.birthMonth,
        'birth_day': detail.birthDay,
        'death_year': detail.deathYear,
        'death_month': detail.deathMonth,
        'death_day': detail.deathDay,
        'age': detail.age,
        'years_active_json': detail.yearsActive == null
            ? null
            : jsonEncode(detail.yearsActive),
        'home_town': detail.homeTown,
        'occupations_json': detail.occupations == null
            ? null
            : jsonEncode(detail.occupations),
      });
      await txn.delete(
        'anilist_staff_media',
        where: 'staff_id = ?',
        whereArgs: [detail.id],
      );
      for (var i = 0; i < detail.mediaWorks.length; i++) {
        final m = detail.mediaWorks[i];
        await txn.insert('anilist_staff_media', {
          'staff_id': detail.id,
          'anilist_id': m.anilistId,
          'mal_id': m.malId,
          'title': m.title,
          'title_english': m.titleEnglish,
          'image_url': m.imageUrl,
          'type': m.type,
          'role': m.role,
          'position': i,
        });
      }
      await _upsertMeta(txn, key);
    });
  }

  AniListStaffDetail _staffFromRow(
    Map<String, Object?> row,
    List<Map<String, Object?>> mediaRows,
  ) {
    final yearsJson = row['years_active_json'] as String?;
    final occJson = row['occupations_json'] as String?;
    return AniListStaffDetail(
      id: row['id']! as int,
      name: row['name']! as String,
      nativeName: row['native_name'] as String?,
      imageUrl: row['image_url'] as String?,
      description: row['description'] as String?,
      gender: row['gender'] as String?,
      birthYear: row['birth_year'] as int?,
      birthMonth: row['birth_month'] as int?,
      birthDay: row['birth_day'] as int?,
      deathYear: row['death_year'] as int?,
      deathMonth: row['death_month'] as int?,
      deathDay: row['death_day'] as int?,
      age: row['age'] as int?,
      yearsActive: yearsJson == null
          ? null
          : (jsonDecode(yearsJson) as List<dynamic>).cast<int>(),
      homeTown: row['home_town'] as String?,
      occupations: occJson == null
          ? null
          : (jsonDecode(occJson) as List<dynamic>).cast<String>(),
      mediaWorks: mediaRows
          .map(
            (m) => AniListMediaAppearance(
              anilistId: m['anilist_id']! as int,
              title: m['title']! as String,
              malId: m['mal_id'] as int?,
              titleEnglish: m['title_english'] as String?,
              imageUrl: m['image_url'] as String?,
              type: m['type'] as String?,
              role: m['role'] as String?,
            ),
          )
          .toList(),
    );
  }

  // ---------- Studio ----------

  @override
  Future<AniListStudioDetail?> getStudio(int id) async {
    final key = _studioKey(id);
    if (await getFetchedAt(key) == null) return null;
    final rows = await _db.query(
      'anilist_studio',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final media = await _db.query(
      'anilist_studio_media',
      where: 'studio_id = ?',
      whereArgs: [id],
      orderBy: 'position ASC',
    );
    return AniListStudioDetail(
      id: rows.first['id']! as int,
      name: rows.first['name']! as String,
      isAnimationStudio: (rows.first['is_animation_studio']! as int) == 1,
      siteUrl: rows.first['site_url'] as String?,
      favourites: rows.first['favourites'] as int?,
      mediaWorks: media
          .map(
            (m) => AniListMediaAppearance(
              anilistId: m['anilist_id']! as int,
              title: m['title']! as String,
              malId: m['mal_id'] as int?,
              titleEnglish: m['title_english'] as String?,
              imageUrl: m['image_url'] as String?,
              type: m['type'] as String?,
              role: m['role'] as String?,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> saveStudio(AniListStudioDetail detail) async {
    final key = _studioKey(detail.id);
    await _db.transaction((txn) async {
      await txn.delete(
        'anilist_studio',
        where: 'id = ?',
        whereArgs: [detail.id],
      );
      await txn.insert('anilist_studio', {
        'id': detail.id,
        'name': detail.name,
        'is_animation_studio': detail.isAnimationStudio ? 1 : 0,
        'site_url': detail.siteUrl,
        'favourites': detail.favourites,
      });
      await txn.delete(
        'anilist_studio_media',
        where: 'studio_id = ?',
        whereArgs: [detail.id],
      );
      for (var i = 0; i < detail.mediaWorks.length; i++) {
        final m = detail.mediaWorks[i];
        await txn.insert('anilist_studio_media', {
          'studio_id': detail.id,
          'anilist_id': m.anilistId,
          'mal_id': m.malId,
          'title': m.title,
          'title_english': m.titleEnglish,
          'image_url': m.imageUrl,
          'type': m.type,
          'role': m.role,
          'position': i,
        });
      }
      await _upsertMeta(txn, key);
    });
  }
}
