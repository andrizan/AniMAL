import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class AniListApi {
  AniListApi({Logger? logger}) : _logger = logger ?? Logger() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://graphql.anilist.co',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
      headers: {'Accept': 'application/json'},
    ));
  }

  late final Dio _dio;
  final Logger _logger;

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
        throw Exception('AniList API error');
      }

      _logger.d('AniList: query OK');
      return body['data'];
    } on DioException catch (e) {
      _logger.e('AniList DioException: ${e.message}');
      if (e.response?.data != null) {
        _logger.e('AniList response: ${e.response?.data}');
      }
      rethrow;
    }
  }

  /// Fetch airing schedule for a specific day of the week.
  ///
  /// Returns anime airing on [dayOfWeek] with their schedule info.
  /// [dayOfWeek] should be lowercase: 'monday', 'tuesday', etc.
  Future<List<AniListScheduleEntry>> getAiringScheduleForDay(
    String dayOfWeek,
  ) async {
    final q = '''
      query {
        Page(page: 1, perPage: 50) {
          airingSchedules(
            notYetAired: true
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

    final data = await _query(q) as Map<String, dynamic>;
    final page = data['Page'] as Map<String, dynamic>;
    final schedules = page['airingSchedules'] as List<dynamic>;

    final entries = schedules.map((s) {
      final schedule = s as Map<String, dynamic>;
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
    }).toList();

    // Filter by day of week
    return entries.where((e) {
      final day = _dayName(e.airingAt.weekday);
      return day == dayOfWeek;
    }).toList();
  }

  /// Fetch airing schedule for the entire week.
  ///
  /// Returns a map of day -> list of schedule entries.
  Future<Map<String, List<AniListScheduleEntry>>>
      getWeeklyAiringSchedule() async {
    final q = '''
      query {
        Page(page: 1, perPage: 50) {
          airingSchedules(
            notYetAired: true
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

    final data = await _query(q) as Map<String, dynamic>;
    final page = data['Page'] as Map<String, dynamic>;
    final schedules = page['airingSchedules'] as List<dynamic>;

    final entries = schedules.map((s) {
      final schedule = s as Map<String, dynamic>;
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
    }).toList();

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

    for (final entry in entries) {
      final day = _dayName(entry.airingAt.weekday);
      if (grouped.containsKey(day)) {
        grouped[day]!.add(entry);
      }
    }

    // Sort each day by airing time
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
  final int? birthYear, birthMonth, birthDay;
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
  final int? birthYear, birthMonth, birthDay;
  final int? deathYear, deathMonth, deathDay;
  final int? age;
  final List<int>? yearsActive;
  final String? homeTown;
  final List<String>? occupations;
  final List<AniListMediaAppearance> mediaWorks;
}

class AniListMediaAppearance {
  const AniListMediaAppearance({
    required this.anilistId,
    this.malId,
    required this.title,
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
    this.malId,
    required this.title,
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
    required this.airingAt,
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
