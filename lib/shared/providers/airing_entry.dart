import 'dart:async';

import 'package:animal/core/logger/app_logger.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/data/local/airing_cache.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/season.dart';
import 'package:animal/shared/providers/anilist_providers.dart';
import 'package:animal/shared/providers/anime_providers.dart';
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
  final double? malScore;
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
    required this._animeRepo,
    required this._anilistApi,
    required this.cache,
    Logger? logger,
  }) : _logger = logger ?? appLogger;

  final AnimeRepository _animeRepo;
  final AniListClient _anilistApi;
  final AiringCache cache;
  final Logger _logger;

  static const _ttlMerged = Duration(minutes: 15);

  int _currentWeekStartEpochSec() {
    final now = DateTime.now().toUtc();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime.utc(monday.year, monday.month, monday.day);
    return weekStart.millisecondsSinceEpoch ~/ 1000;
  }

  Future<Map<String, List<AiringEntry>>> getWeeklySchedule() async {
    final weekStartSec = _currentWeekStartEpochSec();

    // Freshness check + dedup combined: a single in-flight future per week.
    final cached = await cache.getMergedWeek(weekStartSec);
    final fetchedAt = await cache.getFetchedAt(_weekKey(weekStartSec));
    if (cached != null && fetchedAt != null) {
      if (DateTime.now().difference(fetchedAt) < _ttlMerged) {
        return cached;
      }
      // Stale: return stale, refresh in background.
      unawaited(_refreshMerged(weekStartSec));
      return cached;
    }
    // Missing: blocking fetch + save.
    return _buildAndSave(weekStartSec);
  }

  Future<Map<String, List<AiringEntry>>> _buildAndSave(int weekStartSec) async {
    final results = await Future.wait([
      _fetchAniListSchedule(),
      _fetchMalSeasonal(),
    ]);

    final anilistSchedule =
        results[0] as Map<String, List<AniListScheduleEntry>>;
    final malAnimeMap = results[1] as Map<int, Anime>;

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

    await cache.saveMergedWeek(weekStartSec, merged);
    return merged;
  }

  Future<void> _refreshMerged(int weekStartSec) async {
    try {
      await _buildAndSave(weekStartSec);
    } on Object catch (e) {
      _logger.e('Background refresh failed', error: e);
    }
  }

  String _weekKey(int weekStartSec) {
    final dt = DateTime.fromMillisecondsSinceEpoch(weekStartSec * 1000).toUtc();
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return 'weekly_schedule:$y-$m-$d';
  }

  void invalidateCache() {
    unawaited(cache.invalidateMergedWeek(_currentWeekStartEpochSec()));
  }

  Future<Map<String, List<AniListScheduleEntry>>>
  _fetchAniListSchedule() async {
    try {
      return await _anilistApi.getWeeklyAiringSchedule();
    } on Object catch (e) {
      _logger.e('AniList schedule fetch failed', error: e);
      return <String, List<AniListScheduleEntry>>{};
    }
  }

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
    } on Object catch (e) {
      _logger.e('MAL seasonal fetch failed', error: e);
      return <int, Anime>{};
    }
  }
}

/// Provider for [AiringRepository].
final airingRepositoryProvider = Provider<AiringRepository>((ref) {
  final repo = AiringRepository(
    animeRepo: ref.watch(animeRepositoryProvider),
    anilistApi: ref.watch(anilistApiProvider),
    cache: ref.watch(airingCacheProvider),
    logger: ref.watch(loggerProvider),
  );
  ref.listen(animeListVersionProvider, (_, _) => repo.invalidateCache());
  return repo;
});

/// Fetches weekly airing schedule (AniList schedule + MAL scores).
final weeklyAiringProvider = FutureProvider<Map<String, List<AiringEntry>>>((
  ref,
) async {
  ref.watch(animeListVersionProvider);
  final repo = ref.watch(airingRepositoryProvider);
  return repo.getWeeklySchedule();
});

/// Map of MAL ID to next AiringEntry for quick lookup.
final airingByMalIdProvider = FutureProvider<Map<int, AiringEntry>>((
  ref,
) async {
  ref.watch(animeListVersionProvider);
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
