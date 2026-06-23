import 'package:animal/core/config/env.dart';
import 'package:animal/core/constants/anilist_queries.dart';
import 'package:animal/core/constants/mal_endpoints.dart';
import 'package:animal/core/logger/app_logger.dart';
import 'package:animal/core/network/api_exception.dart';
import 'package:animal/data/local/memory_cache.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

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

  Map<String, List<AniListScheduleEntry>>? _cachedWeeklySchedule;
  DateTime? _weeklyScheduleCacheTime;
  static const _cacheDuration = Duration(minutes: 15);

  bool get _isWeeklyCacheValid =>
      _cachedWeeklySchedule != null &&
      _weeklyScheduleCacheTime != null &&
      DateTime.now().difference(_weeklyScheduleCacheTime!) < _cacheDuration;

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

  Future<List<AniListScheduleEntry>> getAiringScheduleForDay(
    String dayOfWeek,
  ) async {
    final now = DateTime.now();
    final targetWeekday = _weekdayNumber(dayOfWeek);
    final diff = targetWeekday - now.weekday;
    final targetDate = now.add(Duration(days: diff >= 0 ? diff : diff + 7));
    final dayStart = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    final dayEnd = dayStart.add(const Duration(days: 1));
    final startSec = dayStart.millisecondsSinceEpoch ~/ 1000;
    final endSec = dayEnd.millisecondsSinceEpoch ~/ 1000;

    final allEntries = <AniListScheduleEntry>[];
    var page = 1;
    var hasNextPage = true;

    while (hasNextPage && page <= ApiConstants.anilistPageLimit) {
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
    return allEntries;
  }

  Future<Map<String, List<AniListScheduleEntry>>>
  getWeeklyAiringSchedule() async {
    if (_isWeeklyCacheValid) {
      _logger.d('AniList weekly schedule cache hit');
      return _cachedWeeklySchedule!;
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

    _cachedWeeklySchedule = grouped;
    _weeklyScheduleCacheTime = DateTime.now();
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

  int _weekdayNumber(String dayName) {
    return switch (dayName) {
      'monday' => 1,
      'tuesday' => 2,
      'wednesday' => 3,
      'thursday' => 4,
      'friday' => 5,
      'saturday' => 6,
      'sunday' => 7,
      _ => 1,
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

  Future<AniListNextAiring?> getNextAiringSchedule(int malId) async {
    final data =
        await _query(AniListQueries.nextAiring, {'idMal': malId})
            as Map<String, dynamic>;
    final media = data['Media'] as Map<String, dynamic>?;
    if (media == null) return null;
    final next = media['nextAiringEpisode'] as Map<String, dynamic>?;
    if (next == null) return null;
    return AniListNextAiring(
      airingAt: DateTime.fromMillisecondsSinceEpoch(
        (next['airingAt'] as int) * 1000,
      ),
      episode: next['episode'] as int,
      timeUntilAiring: next['timeUntilAiring'] as int,
    );
  }

  Future<List<AniListExternalLink>> getExternalLinks(int malId) async {
    final data =
        await _query(AniListQueries.animeExtra, {'idMal': malId})
            as Map<String, dynamic>;
    final media = data['Media'] as Map<String, dynamic>?;
    if (media == null) return [];
    final links = media['externalLinks'] as List<dynamic>? ?? [];
    return links.map((l) {
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

// ── Models ──────────────────────────────────────────────────────

class AniListAnimePeople {
  const AniListAnimePeople({this.characters = const [], this.staff = const []});
  final List<AniListCharacter> characters;
  final List<AniListStaff> staff;
}

class AniListCharacter {
  const AniListCharacter({
    required this.id,
    required this.name,
    this.nativeName,
    this.imageUrl,
    this.role,
    this.voiceActors = const [],
  });
  final int id;
  final String name;
  final String? nativeName;
  final String? imageUrl;
  final String? role;
  final List<AniListVoiceActor> voiceActors;
}

class AniListVoiceActor {
  const AniListVoiceActor({
    required this.id,
    required this.name,
    this.nativeName,
    this.imageUrl,
    this.language,
  });
  final int id;
  final String name;
  final String? nativeName;
  final String? imageUrl;
  final String? language;
}

class AniListStaff {
  const AniListStaff({
    required this.id,
    required this.name,
    this.nativeName,
    this.imageUrl,
    this.role,
  });
  final int id;
  final String name;
  final String? nativeName;
  final String? imageUrl;
  final String? role;
}

class AniListCharacterDetail {
  const AniListCharacterDetail({
    required this.id,
    required this.name,
    this.nativeName,
    this.imageUrl,
    this.description,
    this.birthYear,
    this.birthMonth,
    this.birthDay,
    this.age,
    this.gender,
    this.mediaAppearances = const [],
  });
  final int id;
  final String name;
  final String? nativeName;
  final String? imageUrl;
  final String? description;
  final int? birthYear;
  final int? birthMonth;
  final int? birthDay;
  final String? age;
  final String? gender;
  final List<AniListMediaAppearance> mediaAppearances;
}

class AniListStaffDetail {
  const AniListStaffDetail({
    required this.id,
    required this.name,
    this.nativeName,
    this.imageUrl,
    this.description,
    this.gender,
    this.birthYear,
    this.birthMonth,
    this.birthDay,
    this.deathYear,
    this.deathMonth,
    this.deathDay,
    this.age,
    this.yearsActive,
    this.homeTown,
    this.occupations,
    this.mediaWorks = const [],
  });
  final int id;
  final String name;
  final String? nativeName;
  final String? imageUrl;
  final String? description;
  final String? gender;
  final int? birthYear;
  final int? birthMonth;
  final int? birthDay;
  final int? deathYear;
  final int? deathMonth;
  final int? deathDay;
  final int? age;
  final List<int>? yearsActive;
  final String? homeTown;
  final List<String>? occupations;
  final List<AniListMediaAppearance> mediaWorks;
}

class AniListMediaAppearance {
  const AniListMediaAppearance({
    required this.anilistId,
    required this.title,
    this.malId,
    this.titleEnglish,
    this.imageUrl,
    this.type,
    this.role,
  });
  final int anilistId;
  final int? malId;
  final String title;
  final String? titleEnglish;
  final String? imageUrl;
  final String? type;
  final String? role;
}

class AniListScheduleEntry {
  const AniListScheduleEntry({
    required this.anilistId,
    required this.title,
    required this.airingAt,
    this.malId,
    this.titleEnglish,
    this.titleNative,
    this.imageUrl,
    this.imageUrlLarge,
    this.status,
    this.episodes,
    this.meanScore,
    this.genres = const [],
    this.format,
    this.description,
    this.episode,
    this.timeUntilAiring,
  });
  final int anilistId;
  final int? malId;
  final String title;
  final String? titleEnglish;
  final String? titleNative;
  final String? imageUrl;
  final String? imageUrlLarge;
  final String? status;
  final int? episodes;
  final double? meanScore;
  final List<String> genres;
  final String? format;
  final String? description;
  final DateTime airingAt;
  final int? episode;
  final int? timeUntilAiring;
}

class AniListNextAiring {
  const AniListNextAiring({
    required this.airingAt,
    required this.episode,
    required this.timeUntilAiring,
  });
  final DateTime airingAt;
  final int episode;
  final int timeUntilAiring;

  String get countdown {
    if (timeUntilAiring <= 0) return 'Aired';
    final days = timeUntilAiring ~/ 86400;
    final hours = (timeUntilAiring % 86400) ~/ 3600;
    final minutes = (timeUntilAiring % 3600) ~/ 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  bool get isUrgent => timeUntilAiring > 0 && timeUntilAiring < 21600;
}

class AniListExternalLink {
  const AniListExternalLink({
    required this.id,
    required this.url,
    this.site,
    this.type,
    this.language,
    this.icon,
  });
  final int id;
  final String url;
  final String? site;
  final String? type;
  final String? language;
  final String? icon;

  String get displaySite => site ?? Uri.parse(url).host;
}

class AniListAnimeExtra {
  const AniListAnimeExtra({
    this.people = const AniListAnimePeople(),
    this.nextAiring,
    this.externalLinks = const [],
    this.studios = const [],
  });
  final AniListAnimePeople people;
  final AniListNextAiring? nextAiring;
  final List<AniListExternalLink> externalLinks;
  final List<AniListStudio> studios;
}

class AniListStudio {
  const AniListStudio({
    required this.id,
    required this.name,
    this.isAnimationStudio = false,
    this.siteUrl,
    this.isMain = false,
  });
  final int id;
  final String name;
  final bool isAnimationStudio;
  final String? siteUrl;
  final bool isMain;
}

class AniListStudioDetail {
  const AniListStudioDetail({
    required this.id,
    required this.name,
    this.isAnimationStudio = false,
    this.siteUrl,
    this.favourites,
    this.mediaWorks = const [],
  });
  final int id;
  final String name;
  final bool isAnimationStudio;
  final String? siteUrl;
  final int? favourites;
  final List<AniListMediaAppearance> mediaWorks;
}
