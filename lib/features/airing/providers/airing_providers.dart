import 'package:animal/core/logger/app_logger.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/data/mal/mal_api_client.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/season.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// Merged entry combining AniList schedule + MAL anime data.
class AiringEntry {
  const AiringEntry({
    required this.anilistId,
    required this.title,
    required this.airingAt,
    required this.episode,
    required this.timeUntilAiring,
    this.malId,
    this.titleEnglish,
    this.titleNative,
    this.imageUrl,
    this.malScore,
    this.genres = const [],
    this.episodes,
    this.format,
    this.status,
    this.myListStatus,
  });

  final int anilistId;
  final int? malId;
  final String title;
  final String? titleEnglish;
  final String? titleNative;
  final String? imageUrl;
  final DateTime airingAt;
  final int episode;
  final int timeUntilAiring;
  final double? malScore; // Score from MAL
  final List<String> genres;
  final int? episodes;
  final String? format;
  final String? status;
  final MyListStatus? myListStatus;

  String? get countdown {
    if (timeUntilAiring <= 0) return null;
    final days = timeUntilAiring ~/ 86400;
    final hours = (timeUntilAiring % 86400) ~/ 3600;
    final minutes = (timeUntilAiring % 3600) ~/ 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  bool get isUrgent => timeUntilAiring > 0 && timeUntilAiring < 21600;
}

/// Repository that merges AniList schedule with MAL scores.
class AiringRepository {
  AiringRepository({
    required this._malApi,
    required this._anilistApi,
    Logger? logger,
  }) : _logger = logger ?? appLogger;

  final MalApiClient _malApi;
  final AniListClient _anilistApi;
  final Logger _logger;

  // Cache
  Map<String, List<AiringEntry>>? _cachedSchedule;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 15);

  bool get _isCacheValid =>
      _cachedSchedule != null &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheDuration;

  /// Fetch weekly airing schedule with MAL scores.
  ///
  /// 1. Get schedule from AniList (airingAt, episode, timeUntilAiring)
  /// 2. Get current season from MAL (mean score)
  /// 3. Merge by MAL ID
  Future<Map<String, List<AiringEntry>>> getWeeklySchedule() async {
    if (_isCacheValid) {
      _logger.d('Airing schedule cache hit');
      return _cachedSchedule!;
    }

    _logger.d('Fetching airing schedule...');

    // Fetch both in parallel
    final results = await Future.wait([
      _fetchAniListSchedule(),
      _fetchMalSeasonal(),
    ]);

    final anilistSchedule =
        results[0] as Map<String, List<AniListScheduleEntry>>;
    final malAnimeMap = results[1] as Map<int, Anime>;

    _logger.d(
      'Merge: ${anilistSchedule.values.fold<int>(0, (sum, l) => sum + l.length)} '
      'AniList entries, ${malAnimeMap.length} MAL entries',
    );

    // Merge: AniList schedule + MAL score
    final merged = <String, List<AiringEntry>>{};
    var matchedCount = 0;
    for (final day in anilistSchedule.keys) {
      merged[day] = anilistSchedule[day]!.map((entry) {
        final malAnime = entry.malId != null ? malAnimeMap[entry.malId!] : null;
        if (malAnime != null) matchedCount++;

        return AiringEntry(
          anilistId: entry.anilistId,
          malId: entry.malId,
          title: entry.titleEnglish ?? entry.title,
          titleEnglish: entry.titleEnglish,
          titleNative: entry.titleNative,
          imageUrl: entry.imageUrl,
          airingAt: entry.airingAt,
          episode: entry.episode ?? 0,
          timeUntilAiring: entry.timeUntilAiring ?? 0,
          malScore: malAnime?.mean ?? entry.meanScore,
          genres: entry.genres,
          episodes: malAnime?.numEpisodes ?? entry.episodes,
          format: entry.format,
          status: entry.status,
          myListStatus: malAnime?.myListStatus,
        );
      }).toList();
    }

    _logger.d('Merge: $matchedCount entries matched with MAL scores');

    for (final e in merged.entries) {
      if (e.value.isNotEmpty) {
        _logger.d('  ${e.key}: ${e.value.length} airing entries');
      }
    }

    _cachedSchedule = merged;
    _cacheTime = DateTime.now();
    return merged;
  }

  void invalidateCache() {
    _cachedSchedule = null;
    _cacheTime = null;
  }

  Future<Map<String, List<AniListScheduleEntry>>>
  _fetchAniListSchedule() async {
    try {
      return await _anilistApi.getWeeklyAiringSchedule();
    } on Exception catch (e) {
      _logger.e('AniList schedule fetch failed', error: e);
      return {};
    }
  }

  /// Fetch current season from MAL and return as map by MAL ID.
  Future<Map<int, Anime>> _fetchMalSeasonal() async {
    try {
      final now = DateTime.now();
      final season = Season.fromDate(now);
      final year = now.year;

      _logger.d('Fetching MAL seasonal: $season $year');
      final animeList = await _malApi.getSeasonalAnime(
        year: year,
        season: season,
        limit: 500,
      );

      _logger.d('MAL seasonal returned ${animeList.length} anime');
      return {for (final a in animeList) a.id: a};
    } on Exception catch (e) {
      _logger.e('MAL seasonal fetch failed', error: e);
      return {};
    }
  }
}

/// Provider for [AiringRepository].
final airingRepositoryProvider = Provider<AiringRepository>((ref) {
  return AiringRepository(
    malApi: MalApiClient(ref.watch(dioProvider)),
    anilistApi: AniListClient(logger: ref.watch(loggerProvider)),
    logger: ref.watch(loggerProvider),
  );
});

/// Fetches weekly airing schedule (AniList schedule + MAL scores).
final weeklyAiringProvider = FutureProvider<Map<String, List<AiringEntry>>>((
  ref,
) async {
  final repo = ref.watch(airingRepositoryProvider);
  return repo.getWeeklySchedule();
});

/// Map of MAL ID to next AiringEntry for quick lookup.
final airingByMalIdProvider = FutureProvider<Map<int, AiringEntry>>((
  ref,
) async {
  final schedule = await ref.watch(weeklyAiringProvider.future);
  final map = <int, AiringEntry>{};
  for (final entries in schedule.values) {
    for (final entry in entries) {
      if (entry.malId != null && entry.timeUntilAiring > 0) {
        final existing = map[entry.malId!];
        if (existing == null ||
            entry.timeUntilAiring < existing.timeUntilAiring) {
          map[entry.malId!] = entry;
        }
      }
    }
  }
  return map;
});
