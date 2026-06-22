import 'package:animal/features/anime/data/anilist_api.dart';
import 'package:animal/features/anime/data/mal_anime_api.dart';
import 'package:animal/features/anime/domain/anime.dart';
import 'package:animal/features/anime/domain/anime_with_schedule.dart';
import 'package:animal/features/anime/domain/season.dart';
import 'package:logger/logger.dart';

/// Repository that merges MAL anime data with AniList airing schedule.
///
/// MAL is the primary source for anime info.
/// AniList supplements: airing time, episode number, countdown.
///
/// Caching strategy:
/// - MAL seasonal data: cached per (year, season)
/// - AniList schedule: cached per (year, season)
/// - Merged result: derived from cached data
class AnimeScheduleRepository {
  AnimeScheduleRepository({
    required MalAnimeApi malApi,
    required AniListApi anilistApi,
    Logger? logger,
  })  : _malApi = malApi,
        _anilistApi = anilistApi,
        _logger = logger ?? Logger();

  final MalAnimeApi _malApi;
  final AniListApi _anilistApi;
  final Logger _logger;

  // ── Cache ──────────────────────────────────────────────────────

  final _malCache = <String, List<Anime>>{};
  final _anilistCache = <String, List<AniListScheduleEntry>>{};
  final _mergedCache = <String, List<AnimeWithSchedule>>{};
  final _cacheTime = <String, DateTime>{};

  static const _cacheDuration = Duration(minutes: 15);

  String _cacheKey(int year, Season season) => '${year}_${season.value}';

  bool _isCacheValid(String key) {
    final time = _cacheTime[key];
    if (time == null) return false;
    return DateTime.now().difference(time) < _cacheDuration;
  }

  // ── Public API ─────────────────────────────────────────────────

  /// Fetch merged anime schedule for a given year/season.
  ///
  /// Returns anime sorted by broadcast day, then by time.
  Future<List<AnimeWithSchedule>> getSeasonalSchedule({
    required int year,
    required Season season,
  }) async {
    final key = _cacheKey(year, season);

    // Return cached if valid
    if (_mergedCache.containsKey(key) && _isCacheValid(key)) {
      _logger.d('Schedule cache hit: $key');
      return _mergedCache[key]!;
    }

    _logger.d('Schedule cache miss: $key');

    // Fetch from both APIs in parallel
    final results = await Future.wait([
      _fetchMalSeasonal(year, season),
      _fetchAniListSchedule(year, season),
    ]);

    final malAnime = results[0] as List<Anime>;
    final anilistSchedule = results[1] as List<AniListScheduleEntry>;

    // Build AniList lookup by MAL ID
    final anilistByMalId = <int, AniListScheduleEntry>{};
    for (final entry in anilistSchedule) {
      if (entry.malId != null) {
        anilistByMalId[entry.malId!] = entry;
      }
    }

    // Merge: MAL is primary, AniList supplements
    final merged = malAnime.map((anime) {
      final anilistEntry = anilistByMalId[anime.id];

      return AnimeWithSchedule(
        anime: anime,
        airingAt: anilistEntry?.airingAt,
        nextEpisode: anilistEntry?.episode,
        timeUntilAiring: _calculateTimeUntilAiring(anilistEntry),
      );
    }).toList();

    // Sort by day of week, then by broadcast time
    merged.sort((a, b) {
      final dayCompare = _dayOrder(a.dayOfWeek).compareTo(
        _dayOrder(b.dayOfWeek),
      );
      if (dayCompare != 0) return dayCompare;
      return (a.broadcastTime ?? '').compareTo(b.broadcastTime ?? '');
    });

    // Cache result
    _mergedCache[key] = merged;
    _cacheTime[key] = DateTime.now();

    return merged;
  }

  /// Get anime for a specific day of the week.
  Future<List<AnimeWithSchedule>> getAnimeForDay({
    required int year,
    required Season season,
    required String dayOfWeek,
  }) async {
    final all = await getSeasonalSchedule(year: year, season: season);
    return all.where((a) => a.dayOfWeek == dayOfWeek).toList();
  }

  /// Invalidate cache for a specific season or all.
  void invalidateCache({int? year, Season? season}) {
    if (year != null && season != null) {
      final key = _cacheKey(year, season);
      _malCache.remove(key);
      _anilistCache.remove(key);
      _mergedCache.remove(key);
      _cacheTime.remove(key);
    } else {
      _malCache.clear();
      _anilistCache.clear();
      _mergedCache.clear();
      _cacheTime.clear();
    }
  }

  // ── Private ────────────────────────────────────────────────────

  Future<List<Anime>> _fetchMalSeasonal(int year, Season season) async {
    final key = _cacheKey(year, season);

    if (_malCache.containsKey(key) && _isCacheValid(key)) {
      return _malCache[key]!;
    }

    try {
      final anime = await _malApi.getSeasonalAnime(
        year: year,
        season: season,
        limit: 100,
      );
      _malCache[key] = anime;
      return anime;
    } catch (e) {
      _logger.e('MAL seasonal fetch failed', error: e);
      return _malCache[key] ?? [];
    }
  }

  Future<List<AniListScheduleEntry>> _fetchAniListSchedule(
    int year,
    Season season,
  ) async {
    final key = _cacheKey(year, season);

    if (_anilistCache.containsKey(key) && _isCacheValid(key)) {
      return _anilistCache[key]!;
    }

    try {
      final scheduleMap = await _anilistApi.getWeeklyAiringSchedule();
      // Flatten map into list
      final schedule = scheduleMap.values.expand((list) => list).toList();
      _anilistCache[key] = schedule;
      return schedule;
    } catch (e) {
      _logger.w('AniList schedule fetch failed, using MAL only',
          error: e);
      return _anilistCache[key] ?? [];
    }
  }

  int? _calculateTimeUntilAiring(AniListScheduleEntry? entry) {
    if (entry == null) return null;
    final now = DateTime.now();
    final diff = entry.airingAt.difference(now);
    return diff.inSeconds > 0 ? diff.inSeconds : null;
  }

  int _dayOrder(String? day) {
    return switch (day) {
      'monday' => 0,
      'tuesday' => 1,
      'wednesday' => 2,
      'thursday' => 3,
      'friday' => 4,
      'saturday' => 5,
      'sunday' => 6,
      _ => 7,
    };
  }
}
