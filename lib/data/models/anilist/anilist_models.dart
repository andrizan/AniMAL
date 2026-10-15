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

/// Where a works list stopped: the next 1-based page to request and whether
/// AniList reported more after the pages stored so far.
class AniListWorksCursor {
  const AniListWorksCursor({this.nextPage = 2, this.hasMore = false});
  final int nextPage;
  final bool hasMore;
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
    this.worksCursor = const AniListWorksCursor(),
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
  final AniListWorksCursor worksCursor;
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
    this.worksCursor = const AniListWorksCursor(),
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
  final AniListWorksCursor worksCursor;
}

class AniListMediaAppearance {
  const AniListMediaAppearance({
    required this.anilistId,
    required this.title,
    this.malId,
    this.titleEnglish,
    this.titleNative,
    this.imageUrl,
    this.type,
    this.format,
    this.episodes,
    this.status,
    this.meanScore,
    this.role,
  });
  final int anilistId;
  final int? malId;
  final String title;
  final String? titleEnglish;
  final String? titleNative;
  final String? imageUrl;
  final String? type;

  /// AniList's format (`TV`, `MOVIE`, ...), episode count, status
  /// (`RELEASING`, ...) and mean score out of 100, so a work can be shown
  /// before MAL is ever asked about it.
  final String? format;
  final int? episodes;
  final String? status;
  final double? meanScore;
  final String? role;
}

/// Which AniList entity a works list belongs to.
enum AniListWorksSource { character, staff, studio }

/// One page of a character's appearances, a staff member's works or a
/// studio's productions, in popularity order.
class AniListWorksPage {
  const AniListWorksPage({
    required this.items,
    required this.hasNextPage,
    this.total,
  });
  final List<AniListMediaAppearance> items;
  final bool hasNextPage;
  final int? total;
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
    this.nextAiringAt,
    this.nextEpisode,
    this.nextTimeUntilAiring,
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
  final DateTime? nextAiringAt;
  final int? nextEpisode;
  final int? nextTimeUntilAiring;
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

  int _remaining(DateTime now) => airingAt.toUtc().difference(now).inSeconds;

  bool hasAired(DateTime now) => _remaining(now) <= 0;

  String countdownAt(DateTime now) {
    final remaining = _remaining(now);
    if (remaining <= 0) return 'Aired';
    final days = remaining ~/ 86400;
    final hours = (remaining % 86400) ~/ 3600;
    final minutes = (remaining % 3600) ~/ 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  bool isUrgentAt(DateTime now) {
    final remaining = _remaining(now);
    return remaining > 0 && remaining < 21600;
  }
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

  String get displaySite {
    if (site != null && site!.isNotEmpty) return site!;
    try {
      return Uri.parse(url).host;
    } on FormatException {
      return url;
    }
  }
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
    this.worksCursor = const AniListWorksCursor(),
  });
  final int id;
  final String name;
  final bool isAnimationStudio;
  final String? siteUrl;
  final int? favourites;
  final List<AniListMediaAppearance> mediaWorks;
  final AniListWorksCursor worksCursor;
}
