import 'package:animal/core/logger/app_logger.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/season.dart';
import 'package:animal/shared/providers/airing_entry.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

export 'package:animal/shared/providers/airing_entry.dart';

/// Repository that merges AniList schedule with MAL scores.
class AiringRepository {
  AiringRepository({
    required this._animeRepo,
    required this._anilistApi,
    Logger? logger,
  }) : _logger = logger ?? appLogger;

  final AnimeRepository _animeRepo;
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
      final animeList = await _animeRepo.getSeasonalAnime(
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
    animeRepo: ref.watch(animeRepositoryProvider),
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
