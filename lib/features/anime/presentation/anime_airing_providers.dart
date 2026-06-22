import 'package:animal/core/providers.dart';
import 'package:animal/features/anime/data/anilist_api.dart';
import 'package:animal/features/anime/data/mal_anime_api.dart';
import 'package:animal/features/anime/domain/anime.dart';
import 'package:animal/features/anime/domain/season.dart';
import 'package:animal/features/anime/presentation/anime_providers.dart';
import 'package:animal/features/anime/presentation/anilist_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// Merged entry combining AniList schedule + MAL anime data.
class AiringEntry {
  const AiringEntry({
    required this.anilistId,
    this.malId,
    required this.title,
    this.titleEnglish,
    this.titleNative,
    this.imageUrl,
    required this.airingAt,
    required this.episode,
    required this.timeUntilAiring,
    this.malScore,
    this.genres = const [],
    this.episodes,
    this.format,
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
    required MalAnimeApi malApi,
    required AniListApi anilistApi,
    Logger? logger,
  })  : _malApi = malApi,
        _anilistApi = anilistApi,
        _logger = logger ?? Logger();

  final MalAnimeApi _malApi;
  final AniListApi _anilistApi;
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

    // Merge: AniList schedule + MAL score
    final merged = <String, List<AiringEntry>>{};
    for (final day in anilistSchedule.keys) {
      merged[day] = anilistSchedule[day]!.map((entry) {
        final malAnime = entry.malId != null
            ? malAnimeMap[entry.malId!]
            : null;

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
        );
      }).toList();
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
    } catch (e) {
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

      final animeList = await _malApi.getSeasonalAnime(
        year: year,
        season: season,
        limit: 500,
      );

      return {for (final a in animeList) a.id: a};
    } catch (e) {
      _logger.w('MAL seasonal fetch failed', error: e);
      return {};
    }
  }
}

/// Provider for [AiringRepository].
final airingRepositoryProvider = Provider<AiringRepository>((ref) {
  return AiringRepository(
    malApi: ref.watch(malAnimeApiProvider),
    anilistApi: ref.watch(anilistApiProvider),
    logger: ref.watch(loggerProvider),
  );
});

/// Fetches weekly airing schedule (AniList schedule + MAL scores).
final weeklyAiringProvider =
    FutureProvider<Map<String, List<AiringEntry>>>((ref) async {
  final repo = ref.watch(airingRepositoryProvider);
  return repo.getWeeklySchedule();
});
