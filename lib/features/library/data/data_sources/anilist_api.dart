import 'package:animal/core/network/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class AniListApi {
  AniListApi({Logger? logger})
      : _logger = logger ?? Logger(),
        _dio = Dio(BaseOptions(
          baseUrl: 'https://graphql.anilist.co',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          contentType: 'application/json',
          headers: {'Accept': 'application/json'},
        ));

  final Dio _dio;
  final Logger _logger;

  // ── Cache for weekly schedule ──
  Map<String, List<AniListScheduleEntry>>? _cachedWeeklySchedule;
  DateTime? _weeklyScheduleCacheTime;
  static const _cacheDuration = Duration(minutes: 15);

  bool get _isWeeklyCacheValid =>
      _cachedWeeklySchedule != null &&
      _weeklyScheduleCacheTime != null &&
      DateTime.now().difference(_weeklyScheduleCacheTime!) < _cacheDuration;

  Future<dynamic> _query(String query, [Map<String, dynamic>? variables]) async {
    _logger.d('AniList: sending GraphQL query');

    try {
      final response = await _dio.post<dynamic>(
        '',
        data: {
          'query': query,
          if (variables != null) 'variables': variables,
        },
      );

      final body = response.data as Map<String, dynamic>;
      if (body['errors'] != null) {
        _logger.e('AniList errors: ${body['errors']}');
        throw const ApiException.server(statusCode: 0, message: 'AniList API error');
      }

      _logger.d('AniList: query OK');
      return body['data'];
    } on DioException catch (e) {
      _logger.e('AniList DioException: ${e.message}');
      _logger.e('AniList type: ${e.type}');
      _logger.e('AniList error: ${e.error}');
      if (e.response?.data != null) {
        _logger.e('AniList response: ${e.response?.data}');
      }
      throw ApiException.network(message: 'AniList connection failed: ${e.message}');
    }
  }

  /// Fetch airing schedule for a specific day of the week.
  ///
  /// Returns anime airing on [dayOfWeek] with their schedule info.
  /// [dayOfWeek] should be lowercase: 'monday', 'tuesday', etc.
  Future<List<AniListScheduleEntry>> getAiringScheduleForDay(
    String dayOfWeek,
  ) async {
    // Calculate the target day's start/end timestamps (local time)
    final now = DateTime.now();
    final targetWeekday = _weekdayNumber(dayOfWeek);
    final diff = targetWeekday - now.weekday;
    final targetDate = now.add(Duration(days: diff >= 0 ? diff : diff + 7));
    final dayStart = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final startSec = dayStart.millisecondsSinceEpoch ~/ 1000;
    final endSec = dayEnd.millisecondsSinceEpoch ~/ 1000;

    const q = r'''
      query ($startAt: Int, $endAt: Int, $page: Int) {
        Page(page: $page, perPage: 50) {
          pageInfo { hasNextPage }
          airingSchedules(
            airingAt_greater: $startAt
            airingAt_lesser: $endAt
            sort: TIME
          ) {
            id
            airingAt
            episode
            timeUntilAiring
            media {
              id
              idMal
              title {
                romaji
                english
                native
              }
              coverImage {
                medium
                large
              }
              status
              episodes
              meanScore
              genres
              description
              format
              startDate {
                year
                month
                day
              }
            }
          }
        }
      }
    ''';

    final allEntries = <AniListScheduleEntry>[];
    var page = 1;
    var hasNextPage = true;

    while (hasNextPage && page <= 5) {
      final data = await _query(q, {
        'startAt': startSec,
        'endAt': endSec,
        'page': page,
      }) as Map<String, dynamic>;

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

  /// Fetch airing schedule for the entire week.
  ///
  /// Returns a map of day -> list of schedule entries.
  /// Cached for 15 minutes.
  ///
  /// Uses date range filtering (Monday 00:00 to next Monday 00:00 local)
  /// with pagination to ensure full week coverage.
  Future<Map<String, List<AniListScheduleEntry>>>
      getWeeklyAiringSchedule() async {
    if (_isWeeklyCacheValid) {
      _logger.d('AniList weekly schedule cache hit');
      return _cachedWeeklySchedule!;
    }

    _logger.d('AniList: fetching weekly schedule');

    // Calculate Monday 00:00 and next Monday 00:00 (local time → UTC seconds)
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    final weekEnd = weekStart.add(const Duration(days: 7));
    final startSec = weekStart.millisecondsSinceEpoch ~/ 1000;
    final endSec = weekEnd.millisecondsSinceEpoch ~/ 1000;

    _logger.d(
      'AniList week range: ${weekStart.toIso8601String()} – ${weekEnd.toIso8601String()}',
    );

    const q = r'''
      query ($startAt: Int, $endAt: Int, $page: Int) {
        Page(page: $page, perPage: 50) {
          pageInfo { hasNextPage }
          airingSchedules(
            airingAt_greater: $startAt
            airingAt_lesser: $endAt
            sort: TIME
          ) {
            id
            airingAt
            episode
            timeUntilAiring
            media {
              id
              idMal
              title {
                romaji
                english
                native
              }
              coverImage {
                medium
                large
              }
              status
              episodes
              meanScore
              genres
              description
              format
              startDate {
                year
                month
                day
              }
            }
          }
        }
      }
    ''';

    final allEntries = <AniListScheduleEntry>[];
    var page = 1;
    var hasNextPage = true;

    while (hasNextPage && page <= 10) {
      final data = await _query(q, {
        'startAt': startSec,
        'endAt': endSec,
        'page': page,
      }) as Map<String, dynamic>;

      final pageData = data['Page'] as Map<String, dynamic>;
      final pageInfo = pageData['pageInfo'] as Map<String, dynamic>;
      hasNextPage = pageInfo['hasNextPage'] as bool? ?? false;

      final schedules = pageData['airingSchedules'] as List<dynamic>;

      for (final s in schedules) {
        allEntries.add(_parseScheduleEntry(s as Map<String, dynamic>));
      }

      page++;
    }

    _logger.d('AniList: fetched ${allEntries.length} schedule entries');

    // Group by day of week
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
      if (grouped.containsKey(day)) {
        grouped[day]!.add(entry);
      }
    }

    // Sort each day by airing time
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => a.airingAt.compareTo(b.airingAt));
    }

    for (final e in grouped.entries) {
      _logger.d('  ${e.key}: ${e.value.length} entries');
    }

    // Cache the result
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
    final airingDate =
        DateTime.fromMillisecondsSinceEpoch(airingAt * 1000);

    final genres = (media['genres'] as List<dynamic>?)
            ?.map((g) => g as String)
            .toList() ??
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

  // ── Existing methods ─────────────────────────────────────────

  Future<AniListAnimePeople> getCharactersAndStaff(int malId) async {
    const q = r'''
      query ($idMal: Int) {
        Media(idMal: $idMal, type: ANIME) {
          characters(sort: ROLE, perPage: 25) {
            edges {
              role
              node { id name { full native } image { medium } }
              voiceActors(language: JAPANESE) {
                id name { full native } image { medium } language
              }
            }
          }
          staff(sort: RELEVANCE, perPage: 20) {
            edges {
              role
              node { id name { full native } image { medium } }
            }
          }
        }
      }
    ''';

    final data = await _query(q, {'idMal': malId}) as Map<String, dynamic>;
    final media = data['Media'] as Map<String, dynamic>?;
    if (media == null) return const AniListAnimePeople();

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

  /// Fetch the next upcoming airing schedule for a specific anime by MAL ID.
  ///
  /// Returns the next not-yet-aired episode info, or `null` if none found.
  Future<AniListNextAiring?> getNextAiringSchedule(int malId) async {
    const q = r'''
      query ($idMal: Int) {
        Media(idMal: $idMal, type: ANIME) {
          nextAiringEpisode {
            airingAt
            episode
            timeUntilAiring
          }
        }
      }
    ''';

    final data = await _query(q, {'idMal': malId}) as Map<String, dynamic>;
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

  /// Fetch external links for an anime by MAL ID.
  ///
  /// Returns official sites, streaming platforms, and social media.
  Future<List<AniListExternalLink>> getExternalLinks(int malId) async {
    const q = r'''
      query ($idMal: Int) {
        Media(idMal: $idMal, type: ANIME) {
          externalLinks {
            id url site type language icon
          }
        }
      }
    ''';

    final data = await _query(q, {'idMal': malId}) as Map<String, dynamic>;
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

  /// Fetch characters, staff, next airing, and external links in one call.
  Future<AniListAnimeExtra> getAnimeExtraInfo(int malId) async {
    const q = r'''
      query ($idMal: Int) {
        Media(idMal: $idMal, type: ANIME) {
          characters(sort: ROLE, perPage: 25) {
            edges {
              role
              node { id name { full native } image { medium } }
              voiceActors(language: JAPANESE) {
                id name { full native } image { medium } language
              }
            }
          }
          staff(sort: RELEVANCE, perPage: 20) {
            edges {
              role
              node { id name { full native } image { medium } }
            }
          }
          nextAiringEpisode {
            airingAt
            episode
            timeUntilAiring
          }
          externalLinks {
            id url site type language icon
          }
        }
      }
    ''';

    final data = await _query(q, {'idMal': malId}) as Map<String, dynamic>;
    final media = data['Media'] as Map<String, dynamic>?;
    if (media == null) return const AniListAnimeExtra();

    // Characters + Staff
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

    final people = AniListAnimePeople(characters: characters, staff: staff);

    // Next Airing
    final nextRaw = media['nextAiringEpisode'] as Map<String, dynamic>?;
    AniListNextAiring? nextAiring;
    if (nextRaw != null) {
      nextAiring = AniListNextAiring(
        airingAt: DateTime.fromMillisecondsSinceEpoch(
          (nextRaw['airingAt'] as int) * 1000,
        ),
        episode: nextRaw['episode'] as int,
        timeUntilAiring: nextRaw['timeUntilAiring'] as int,
      );
    }

    // External Links
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
    );
  }

  Future<AniListCharacterDetail> getCharacterDetail(int id) async {
    const q = r'''
      query ($id: Int) {
        Character(id: $id) {
          id name { full native } image { large medium }
          description dateOfBirth { year month day } age gender
          media(sort: POPULARITY_DESC, perPage: 10) {
            edges {
              characterRole
              node { id idMal title { romaji english } coverImage { medium } type }
            }
          }
        }
      }
    ''';

    final data = await _query(q, {'id': id}) as Map<String, dynamic>;
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

  Future<AniListStaffDetail> getStaffDetail(int id) async {
    const q = r'''
      query ($id: Int) {
        Staff(id: $id) {
          id name { full native } image { large medium }
          description primaryOccupations gender
          dateOfBirth { year month day } dateOfDeath { year month day }
          age yearsActive homeTown
          staffMedia(sort: POPULARITY_DESC, perPage: 10) {
            edges {
              staffRole
              node { id idMal title { romaji english } coverImage { medium } type }
            }
          }
        }
      }
    ''';

    final data = await _query(q, {'id': id}) as Map<String, dynamic>;
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
      occupations:
          (s['primaryOccupations'] as List<dynamic>?)?.cast<String>(),
      mediaWorks: works,
    );
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
  });
  final AniListAnimePeople people;
  final AniListNextAiring? nextAiring;
  final List<AniListExternalLink> externalLinks;
}
