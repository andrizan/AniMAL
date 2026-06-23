import 'package:animal/core/config/env.dart';
import 'package:animal/core/constants/anilist_queries.dart';
import 'package:animal/core/constants/mal_endpoints.dart';
import 'package:animal/core/logger/app_logger.dart';
import 'package:animal/core/network/api_exception.dart';
import 'package:animal/data/local/memory_cache.dart';
import 'package:animal/data/models/anilist/anilist_models.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

export 'package:animal/data/models/anilist/anilist_models.dart';

final _anilistCache = MemoryCache();

class AniListClient {
  AniListClient({Logger? logger})
    : _logger = logger ?? appLogger,
      _dio = Dio(
        BaseOptions(
          baseUrl: Env.anilistBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          contentType: 'application/json',
          headers: {'Accept': 'application/json'},
        ),
      );

  final Dio _dio;
  final Logger _logger;

  Future<dynamic> _query(
    String query, [
    Map<String, dynamic>? variables,
  ]) async {
    _logger.d('AniList: sending GraphQL query');
    try {
      final response = await _dio.post<dynamic>(
        '',
        data: {'query': query, if (variables != null) 'variables': variables},
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
      throw ApiException.network(
        message: 'AniList connection failed: ${e.message}',
      );
    }
  }

  Future<Map<String, List<AniListScheduleEntry>>>
  getWeeklyAiringSchedule() async {
    const key = 'weeklyAiringSchedule';
    final cached =
        _anilistCache.get<Map<String, List<AniListScheduleEntry>>>(key);
    if (cached != null) {
      _logger.d('AniList weekly schedule cache hit');
      return cached;
    }

    _logger.d('AniList: fetching weekly schedule');
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    final weekEnd = weekStart.add(const Duration(days: 7));
    final startSec = weekStart.millisecondsSinceEpoch ~/ 1000;
    final endSec = weekEnd.millisecondsSinceEpoch ~/ 1000;

    final allEntries = <AniListScheduleEntry>[];
    var page = 1;
    var hasNextPage = true;

    while (hasNextPage && page <= ApiConstants.anilistWeekPageLimit) {
      final data =
          await _query(AniListQueries.airingSchedule, {
                'startAt': startSec,
                'endAt': endSec,
                'page': page,
              })
              as Map<String, dynamic>;
      final pageData = data['Page'] as Map<String, dynamic>;
      final pageInfo = pageData['pageInfo'] as Map<String, dynamic>;
      hasNextPage = pageInfo['hasNextPage'] as bool? ?? false;
      final schedules = pageData['airingSchedules'] as List<dynamic>;
      for (final s in schedules) {
        allEntries.add(_parseScheduleEntry(s as Map<String, dynamic>));
      }
      page++;
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
    for (final entry in allEntries) {
      final day = _dayName(entry.airingAt.weekday);
      if (grouped.containsKey(day)) grouped[day]!.add(entry);
    }
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => a.airingAt.compareTo(b.airingAt));
    }

    _anilistCache.put(key, grouped, ttl: const Duration(minutes: 15));
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

  AniListScheduleEntry _parseScheduleEntry(Map<String, dynamic> schedule) {
    final media = schedule['media'] as Map<String, dynamic>;
    final title = media['title'] as Map<String, dynamic>;
    final cover = media['coverImage'] as Map<String, dynamic>?;
    final airingAt = schedule['airingAt'] as int;
    final airingDate = DateTime.fromMillisecondsSinceEpoch(airingAt * 1000);
    final genres =
        (media['genres'] as List<dynamic>?)?.map((g) => g as String).toList() ??
        [];

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
      airingAt: airingDate,
      episode: schedule['episode'] as int?,
      timeUntilAiring: schedule['timeUntilAiring'] as int?,
    );
  }

  Future<AniListAnimeExtra> getAnimeExtraInfo(int malId) async {
    final key = 'animeExtra_$malId';
    final cached = _anilistCache.get<AniListAnimeExtra>(key);
    if (cached != null) return cached;

    final data =
        await _query(AniListQueries.animeExtra, {'idMal': malId})
            as Map<String, dynamic>;
    final media = data['Media'] as Map<String, dynamic>?;
    if (media == null) return const AniListAnimeExtra();

    final people = _parsePeople(media);

    AniListNextAiring? nextAiring;
    final nextRaw = media['nextAiringEpisode'] as Map<String, dynamic>?;
    if (nextRaw != null) {
      nextAiring = AniListNextAiring(
        airingAt: DateTime.fromMillisecondsSinceEpoch(
          (nextRaw['airingAt'] as int) * 1000,
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

    final result = AniListAnimeExtra(
      people: people,
      nextAiring: nextAiring,
      externalLinks: externalLinks,
      studios: _parseStudios(media),
    );
    _anilistCache.put(key, result, ttl: const Duration(minutes: 15));
    return result;
  }

  Future<AniListCharacterDetail> getCharacterDetail(int id) async {
    final key = 'character_$id';
    final cached = _anilistCache.get<AniListCharacterDetail>(key);
    if (cached != null) return cached;

    final data =
        await _query(AniListQueries.characterDetail, {'id': id})
            as Map<String, dynamic>;
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

    final result = AniListCharacterDetail(
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
    _anilistCache.put(key, result, ttl: const Duration(minutes: 30));
    return result;
  }

  Future<AniListStaffDetail> getStaffDetail(int id) async {
    final key = 'staff_$id';
    final cached = _anilistCache.get<AniListStaffDetail>(key);
    if (cached != null) return cached;

    final data =
        await _query(AniListQueries.staffDetail, {'id': id})
            as Map<String, dynamic>;
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

    final result = AniListStaffDetail(
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
    _anilistCache.put(key, result, ttl: const Duration(minutes: 30));
    return result;
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

  Future<AniListStudioDetail> getStudioDetail(int id) async {
    final key = 'studio_$id';
    final cached = _anilistCache.get<AniListStudioDetail>(key);
    if (cached != null) return cached;

    final data =
        await _query(AniListQueries.studioDetail, {'id': id})
            as Map<String, dynamic>;
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
        role: null,
      );
    }).toList();

    final result = AniListStudioDetail(
      id: s['id'] as int,
      name: s['name'] as String,
      isAnimationStudio: s['isAnimationStudio'] as bool? ?? false,
      siteUrl: s['siteUrl'] as String?,
      favourites: s['favourites'] as int?,
      mediaWorks: media,
    );
    _anilistCache.put(key, result, ttl: const Duration(minutes: 30));
    return result;
  }
}

