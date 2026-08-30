import 'dart:async';

import 'package:animal/core/config/env.dart';
import 'package:animal/core/constants/anilist_queries.dart';
import 'package:animal/core/constants/mal_endpoints.dart';
import 'package:animal/core/logger/app_logger.dart';
import 'package:animal/core/network/api_exception.dart';
import 'package:animal/core/network/api_health_interceptor.dart';
import 'package:animal/data/local/anilist_cache.dart';
import 'package:animal/data/models/anilist/anilist_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

export 'package:animal/data/models/anilist/anilist_models.dart';

class AniListClient {
  AniListClient({
    required this.cache,
    Ref? ref,
    Logger? logger,
  }) : _logger = logger ?? appLogger,
       _dio = Dio(
         BaseOptions(
           baseUrl: Env.anilistBaseUrl,
           connectTimeout: const Duration(seconds: 15),
           receiveTimeout: const Duration(seconds: 15),
           contentType: 'application/json',
           headers: {'Accept': 'application/json'},
         ),
       ) {
    if (ref != null) {
      _dio.interceptors.add(ApiHealthInterceptor(ref));
    }
  }

  final Dio _dio;

  /// The underlying [Dio] instance.
  Dio get dio => _dio;

  final AniListCache cache;
  final Logger _logger;

  static const _ttlSchedule = Duration(minutes: 15);
  static const _ttlAnimeExtra = Duration(minutes: 15);
  static const _ttlDetail = Duration(minutes: 30);

  final Map<String, Future<dynamic>> _inFlight = <String, Future<dynamic>>{};

  // ---------- Internal: GraphQL with 429 handling ----------

  Future<dynamic> _query(
    String query, [
    Map<String, dynamic>? variables,
  ]) async {
    _logger.d('AniList: sending GraphQL query');
    try {
      final response = await _dio.post<dynamic>(
        '',
        // ignore: use_null_aware_elements
        data: <String, dynamic>{
          'query': query,
          if (variables != null) 'variables': variables,
        },
      );
      final body = response.data as Map<String, dynamic>;
      if (body['errors'] != null) {
        _logger.e('AniList errors: ${body['errors']}');
        throw const ApiException.server(
          statusCode: 0,
          message: 'AniList API error',
        );
      }
      _logger.d('AniList: query OK');
      return body['data'];
    } on DioException catch (e) {
      _logger.e('AniList DioException: ${e.message}');
      final status = e.response?.statusCode;
      if (status == 429) {
        final retryAfter = _parseRetryAfter(e.response?.headers.map);
        throw ApiException.rateLimited(
          retryAfter: retryAfter,
          message: e.message,
        );
      }
      throw ApiException.network(
        message: 'AniList connection failed: ${e.message}',
      );
    }
  }

  Duration _parseRetryAfter(Map<String, List<String>>? headers) {
    if (headers == null) return const Duration(seconds: 60);
    final values = headers['retry-after'] ?? headers['Retry-After'];
    if (values == null || values.isEmpty) return const Duration(seconds: 60);
    final seconds = int.tryParse(values.first);
    return Duration(seconds: seconds ?? 60);
  }

  // ---------- Weekly schedule ----------

  Future<Map<String, List<AniListScheduleEntry>>>
  getWeeklyAiringSchedule() async {
    final now = DateTime.now().toUtc();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime.utc(monday.year, monday.month, monday.day);
    final weekStartSec = weekStart.millisecondsSinceEpoch ~/ 1000;
    final key = SqliteAniListCache.weeklyKey(weekStartSec);

    return _swr<Map<String, List<AniListScheduleEntry>>>(
      key: key,
      ttl: _ttlSchedule,
      readFresh: () => cache.getWeeklySchedule(weekStartSec),
      networkFetch: () => _fetchWeeklySchedule(weekStartSec),
      writeCache: (data) => cache.saveWeeklySchedule(weekStartSec, data),
    );
  }

  Future<Map<String, List<AniListScheduleEntry>>> _fetchWeeklySchedule(
    int weekStartSec,
  ) async {
    final weekEnd = weekStartSec + 7 * 24 * 60 * 60;
    final allEntries = <AniListScheduleEntry>[];
    var page = 1;
    var hasNextPage = true;
    while (hasNextPage && page <= ApiConstants.anilistWeekPageLimit) {
      final data = await _query(AniListQueries.airingSchedule, {
        'startAt': weekStartSec,
        'endAt': weekEnd,
        'page': page,
      }) as Map<String, dynamic>;
      final pageData = data['Page'] as Map<String, dynamic>;
      final pageInfo = pageData['pageInfo'] as Map<String, dynamic>;
      hasNextPage = pageInfo['hasNextPage'] as bool? ?? false;
      final schedules = pageData['airingSchedules'] as List<dynamic>;
      for (final s in schedules) {
        final parsed = _parseScheduleEntry(s as Map<String, dynamic>);
        if (parsed != null) allEntries.add(parsed);
      }
      page++;
    }
    final now = DateTime.now().toUtc();
    final filtered = <AniListScheduleEntry>[];
    final seen = <String>{};
    for (final entry in allEntries) {
      final remaining = entry.airingAt.toUtc().difference(now).inSeconds;
      final effectiveRemaining = entry.timeUntilAiring ?? remaining;
      if (effectiveRemaining <= 0 && entry.airingAt.toUtc().isBefore(now)) {
        continue;
      }
      final dedupKey = '${entry.anilistId}_${entry.episode}';
      if (seen.contains(dedupKey)) continue;
      seen.add(dedupKey);
      filtered.add(entry);
    }
    final grouped = <String, List<AniListScheduleEntry>>{
      'monday': [],
      'tuesday': [],
      'wednesday': [],
      'thursday': [],
      'friday': [],
      'saturday': [],
      'sunday': [],
    };
    for (final entry in filtered) {
      final day = _dayName(entry.airingAt.toUtc().weekday);
      if (grouped.containsKey(day)) grouped[day]!.add(entry);
    }
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => a.airingAt.compareTo(b.airingAt));
    }
    return grouped;
  }

  String _dayName(int weekday) {
    return switch (weekday) {
      1 => 'monday',
      2 => 'tuesday',
      3 => 'wednesday',
      4 => 'thursday',
      5 => 'friday',
      6 => 'saturday',
      7 => 'sunday',
      _ => 'monday',
    };
  }

  AniListScheduleEntry? _parseScheduleEntry(Map<String, dynamic> schedule) {
    final media = schedule['media'] as Map<String, dynamic>;
    final title = media['title'] as Map<String, dynamic>;
    final cover = media['coverImage'] as Map<String, dynamic>?;
    final airingAt = schedule['airingAt'] as int;
    final airingDate = DateTime.fromMillisecondsSinceEpoch(
      airingAt * 1000,
      isUtc: true,
    );
    final genres =
        (media['genres'] as List<dynamic>?)?.map((g) => g as String).toList() ??
        [];
    var finalAiringAt = airingDate;
    var finalEpisode = schedule['episode'] as int?;
    var finalTimeUntil = schedule['timeUntilAiring'] as int?;
    final nextRaw = media['nextAiringEpisode'] as Map<String, dynamic>?;
    if (nextRaw != null) {
      final nextAiringAt = nextRaw['airingAt'] as int?;
      final nextEpisode = nextRaw['episode'] as int?;
      final nextTimeUntil = nextRaw['timeUntilAiring'] as int?;
      if (nextAiringAt != null && nextEpisode != null) {
        final nextDate = DateTime.fromMillisecondsSinceEpoch(
          nextAiringAt * 1000,
          isUtc: true,
        );
        final now = DateTime.now().toUtc();
        final isExpired =
            (finalTimeUntil != null && finalTimeUntil <= 0) ||
            finalAiringAt.toUtc().isBefore(now);
        final nextRemaining =
            nextTimeUntil ?? nextDate.toUtc().difference(now).inSeconds;
        if (isExpired && nextRemaining > 0 && nextDate.toUtc().isAfter(now)) {
          finalAiringAt = nextDate;
          finalEpisode = nextEpisode;
          finalTimeUntil = nextTimeUntil ?? nextRemaining;
        }
      }
    }
    return AniListScheduleEntry(
      anilistId: media['id'] as int,
      malId: media['idMal'] as int?,
      title: title['romaji'] as String,
      titleEnglish: title['english'] as String?,
      titleNative: title['native'] as String?,
      imageUrl: cover?['medium'] as String?,
      imageUrlLarge: cover?['large'] as String?,
      status: media['status'] as String?,
      episodes: media['episodes'] as int?,
      meanScore: (media['meanScore'] as num?)?.toDouble(),
      genres: genres,
      format: media['format'] as String?,
      description: media['description'] as String?,
      airingAt: finalAiringAt,
      episode: finalEpisode,
      timeUntilAiring: finalTimeUntil,
    );
  }

  // ---------- Anime extra ----------

  Future<AniListAnimeExtra> getAnimeExtraInfo(int malId) {
    return _swr<AniListAnimeExtra>(
      key: 'animeExtra_$malId',
      ttl: _ttlAnimeExtra,
      readFresh: () => cache.getAnimeExtra(malId),
      networkFetch: () => _fetchAnimeExtra(malId),
      writeCache: (data) => cache.saveAnimeExtra(malId, data),
      isMissingNetworkValue: (v) =>
          v.people.characters.isEmpty &&
          v.people.staff.isEmpty &&
          v.studios.isEmpty &&
          v.externalLinks.isEmpty &&
          v.nextAiring == null,
    );
  }

  Future<AniListAnimeExtra> _fetchAnimeExtra(int malId) async {
    final data = await _query(AniListQueries.animeExtra, {
      'idMal': malId,
    }) as Map<String, dynamic>;
    final media = data['Media'] as Map<String, dynamic>?;
    if (media == null) return const AniListAnimeExtra();

    final people = _parsePeople(media);

    AniListNextAiring? nextAiring;
    final nextRaw = media['nextAiringEpisode'] as Map<String, dynamic>?;
    if (nextRaw != null) {
      nextAiring = AniListNextAiring(
        airingAt: DateTime.fromMillisecondsSinceEpoch(
          (nextRaw['airingAt'] as int) * 1000,
          isUtc: true,
        ),
        episode: nextRaw['episode'] as int,
        timeUntilAiring: nextRaw['timeUntilAiring'] as int,
      );
    }

    final linksRaw = media['externalLinks'] as List<dynamic>? ?? [];
    final externalLinks = linksRaw.map((l) {
      final link = l as Map<String, dynamic>;
      return AniListExternalLink(
        id: link['id'] as int,
        url: link['url'] as String,
        site: link['site'] as String?,
        type: link['type'] as String?,
        language: link['language'] as String?,
        icon: link['icon'] as String?,
      );
    }).toList();

    return AniListAnimeExtra(
      people: people,
      nextAiring: nextAiring,
      externalLinks: externalLinks,
      studios: _parseStudios(media),
    );
  }

  AniListAnimePeople _parsePeople(Map<String, dynamic> media) {
    final charEdges =
        (media['characters'] as Map<String, dynamic>)['edges'] as List<dynamic>;
    final characters = charEdges.map((e) {
      final edge = e as Map<String, dynamic>;
      final node = edge['node'] as Map<String, dynamic>;
      final name = node['name'] as Map<String, dynamic>;
      final image = node['image'] as Map<String, dynamic>;
      final vaRaw = (edge['voiceActors'] as List<dynamic>?) ?? [];
      final vas = vaRaw.map((v) {
        final vm = v as Map<String, dynamic>;
        final vn = vm['name'] as Map<String, dynamic>;
        final vi = vm['image'] as Map<String, dynamic>;
        return AniListVoiceActor(
          id: vm['id'] as int,
          name: vn['full'] as String,
          nativeName: vn['native'] as String?,
          imageUrl: vi['medium'] as String?,
          language: vm['language'] as String?,
        );
      }).toList();
      return AniListCharacter(
        id: node['id'] as int,
        name: name['full'] as String,
        nativeName: name['native'] as String?,
        imageUrl: image['medium'] as String?,
        role: edge['role'] as String?,
        voiceActors: vas,
      );
    }).toList();

    final staffEdges =
        (media['staff'] as Map<String, dynamic>)['edges'] as List<dynamic>;
    final staff = staffEdges.map((e) {
      final edge = e as Map<String, dynamic>;
      final node = edge['node'] as Map<String, dynamic>;
      final name = node['name'] as Map<String, dynamic>;
      final image = node['image'] as Map<String, dynamic>;
      return AniListStaff(
        id: node['id'] as int,
        name: name['full'] as String,
        nativeName: name['native'] as String?,
        imageUrl: image['medium'] as String?,
        role: edge['role'] as String?,
      );
    }).toList();

    return AniListAnimePeople(characters: characters, staff: staff);
  }

  List<AniListStudio> _parseStudios(Map<String, dynamic> media) {
    final studiosData = media['studios'] as Map<String, dynamic>?;
    if (studiosData == null) return [];
    final edges = studiosData['edges'] as List<dynamic>? ?? [];
    return edges.map((e) {
      final edge = e as Map<String, dynamic>;
      final node = edge['node'] as Map<String, dynamic>;
      return AniListStudio(
        id: node['id'] as int,
        name: node['name'] as String,
        isAnimationStudio: node['isAnimationStudio'] as bool? ?? false,
        siteUrl: node['siteUrl'] as String?,
        isMain: edge['isMain'] as bool? ?? false,
      );
    }).toList();
  }

  // ---------- Character ----------

  Future<AniListCharacterDetail> getCharacterDetail(int id) {
    return _swr<AniListCharacterDetail>(
      key: 'character_$id',
      ttl: _ttlDetail,
      readFresh: () => cache.getCharacter(id),
      networkFetch: () => _fetchCharacter(id),
      writeCache: (d) => cache.saveCharacter(d),
    );
  }

  Future<AniListCharacterDetail> _fetchCharacter(int id) async {
    final data = await _query(AniListQueries.characterDetail, {
      'id': id,
    }) as Map<String, dynamic>;
    final c = data['Character'] as Map<String, dynamic>;
    final name = c['name'] as Map<String, dynamic>;
    final image = c['image'] as Map<String, dynamic>;
    final dob = c['dateOfBirth'] as Map<String, dynamic>?;
    final mediaEdges =
        (c['media'] as Map<String, dynamic>)['edges'] as List<dynamic>;

    final media = mediaEdges.map((e) {
      final edge = e as Map<String, dynamic>;
      final node = edge['node'] as Map<String, dynamic>;
      final title = node['title'] as Map<String, dynamic>;
      final cover = node['coverImage'] as Map<String, dynamic>;
      return AniListMediaAppearance(
        anilistId: node['id'] as int,
        malId: node['idMal'] as int?,
        title: title['romaji'] as String,
        titleEnglish: title['english'] as String?,
        imageUrl: cover['medium'] as String?,
        type: node['type'] as String?,
        role: edge['characterRole'] as String?,
      );
    }).toList();

    return AniListCharacterDetail(
      id: c['id'] as int,
      name: name['full'] as String,
      nativeName: name['native'] as String?,
      imageUrl: image['large'] as String?,
      description: c['description'] as String?,
      birthYear: dob?['year'] as int?,
      birthMonth: dob?['month'] as int?,
      birthDay: dob?['day'] as int?,
      age: c['age'] as String?,
      gender: c['gender'] as String?,
      mediaAppearances: media,
    );
  }

  // ---------- Staff ----------

  Future<AniListStaffDetail> getStaffDetail(int id) {
    return _swr<AniListStaffDetail>(
      key: 'staff_$id',
      ttl: _ttlDetail,
      readFresh: () => cache.getStaff(id),
      networkFetch: () => _fetchStaff(id),
      writeCache: (d) => cache.saveStaff(d),
    );
  }

  Future<AniListStaffDetail> _fetchStaff(int id) async {
    final data = await _query(AniListQueries.staffDetail, {
      'id': id,
    }) as Map<String, dynamic>;
    final s = data['Staff'] as Map<String, dynamic>;
    final name = s['name'] as Map<String, dynamic>;
    final image = s['image'] as Map<String, dynamic>;
    final dob = s['dateOfBirth'] as Map<String, dynamic>?;
    final dod = s['dateOfDeath'] as Map<String, dynamic>?;
    final mediaEdges =
        (s['staffMedia'] as Map<String, dynamic>)['edges'] as List<dynamic>;

    final works = mediaEdges.map((e) {
      final edge = e as Map<String, dynamic>;
      final node = edge['node'] as Map<String, dynamic>;
      final title = node['title'] as Map<String, dynamic>;
      final cover = node['coverImage'] as Map<String, dynamic>;
      return AniListMediaAppearance(
        anilistId: node['id'] as int,
        malId: node['idMal'] as int?,
        title: title['romaji'] as String,
        titleEnglish: title['english'] as String?,
        imageUrl: cover['medium'] as String?,
        type: node['type'] as String?,
        role: edge['staffRole'] as String?,
      );
    }).toList();

    return AniListStaffDetail(
      id: s['id'] as int,
      name: name['full'] as String,
      nativeName: name['native'] as String?,
      imageUrl: image['large'] as String?,
      description: s['description'] as String?,
      gender: s['gender'] as String?,
      birthYear: dob?['year'] as int?,
      birthMonth: dob?['month'] as int?,
      birthDay: dob?['day'] as int?,
      deathYear: dod?['year'] as int?,
      deathMonth: dod?['month'] as int?,
      deathDay: dod?['day'] as int?,
      age: s['age'] as int?,
      yearsActive: (s['yearsActive'] as List<dynamic>?)?.cast<int>(),
      homeTown: s['homeTown'] as String?,
      occupations: (s['primaryOccupations'] as List<dynamic>?)?.cast<String>(),
      mediaWorks: works,
    );
  }

  // ---------- Studio ----------

  Future<AniListStudioDetail> getStudioDetail(int id) {
    return _swr<AniListStudioDetail>(
      key: 'studio_$id',
      ttl: _ttlDetail,
      readFresh: () => cache.getStudio(id),
      networkFetch: () => _fetchStudio(id),
      writeCache: (d) => cache.saveStudio(d),
    );
  }

  Future<AniListStudioDetail> _fetchStudio(int id) async {
    final data = await _query(AniListQueries.studioDetail, {
      'id': id,
    }) as Map<String, dynamic>;
    final s = data['Studio'] as Map<String, dynamic>;

    final mediaEdges =
        (s['media'] as Map<String, dynamic>)['edges'] as List<dynamic>;
    final media = mediaEdges.map((e) {
      final edge = e as Map<String, dynamic>;
      final node = edge['node'] as Map<String, dynamic>;
      final title = node['title'] as Map<String, dynamic>;
      final cover = node['coverImage'] as Map<String, dynamic>;
      return AniListMediaAppearance(
        anilistId: node['id'] as int,
        malId: node['idMal'] as int?,
        title: title['romaji'] as String,
        titleEnglish: title['english'] as String?,
        imageUrl: cover['medium'] as String?,
        type: node['type'] as String?,
      );
    }).toList();

    return AniListStudioDetail(
      id: s['id'] as int,
      name: s['name'] as String,
      isAnimationStudio: s['isAnimationStudio'] as bool? ?? false,
      siteUrl: s['siteUrl'] as String?,
      favourites: s['favourites'] as int?,
      mediaWorks: media,
    );
  }

  // ---------- SWR helper ----------

  Future<T> _swr<T>({
    required String key,
    required Duration ttl,
    required Future<T?> Function() readFresh,
    required Future<T> Function() networkFetch,
    required Future<void> Function(T) writeCache,
    bool Function(T)? isMissingNetworkValue,
  }) {
    final existing = _inFlight[key];
    if (existing != null) return existing as Future<T>;
    final fut = _doSwr(
      key: key,
      ttl: ttl,
      readFresh: readFresh,
      networkFetch: networkFetch,
      writeCache: writeCache,
      isMissingNetworkValue: isMissingNetworkValue,
    );
    unawaited(
      fut.whenComplete(() {
        _inFlight.remove(key);
      }),
    );
    _inFlight[key] = fut;
    return fut;
  }

  Future<T> _doSwr<T>({
    required String key,
    required Duration ttl,
    required Future<T?> Function() readFresh,
    required Future<T> Function() networkFetch,
    required Future<void> Function(T) writeCache,
    bool Function(T)? isMissingNetworkValue,
  }) async {
    final cached = await readFresh();
    final fetchedAt = await cache.getFetchedAt(key);
    if (cached != null && fetchedAt != null) {
      if (DateTime.now().difference(fetchedAt) < ttl) {
        return cached as T;
      }
      unawaited(_refresh(key, networkFetch, writeCache));
      return cached as T;
    }
    try {
      final fresh = await networkFetch();
      if (isMissingNetworkValue == null || !isMissingNetworkValue(fresh)) {
        await writeCache(fresh);
      }
      return fresh;
    } on Object {
      if (cached != null) return cached as T;
      rethrow;
    }
  }

  Future<void> _refresh<T>(
    String key,
    Future<T> Function() networkFetch,
    Future<void> Function(T) writeCache,
  ) async {
    try {
      final fresh = await networkFetch();
      await writeCache(fresh);
    } on Object catch (_) {
      // best-effort; stale data remains visible
    }
  }
}
