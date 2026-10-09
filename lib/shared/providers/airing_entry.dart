import 'dart:async';

import 'package:animal/core/logger/app_logger.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/data/local/airing_cache.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/season.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/shared/providers/anilist_providers.dart';
import 'package:animal/shared/providers/anime_providers.dart'
    show AnimeRepository, animeRepositoryProvider;
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
  final DateTime airingAt;
  final int episode;
  final int timeUntilAiring;
  final double? malScore;
  final List<String> genres;
  final int? episodes;
  final String? format;
  final String? status;
  final MyListStatus? myListStatus;
  final DateTime? nextAiringAt;
  final int? nextEpisode;
  final int? nextTimeUntilAiring;

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

  final Map<String, Future<Map<String, List<AiringEntry>>>> _inFlight = {};

  int _currentWeekStartEpochSec() {
    final now = DateTime.now().toUtc();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime.utc(monday.year, monday.month, monday.day);
    return weekStart.millisecondsSinceEpoch ~/ 1000;
  }

  Future<Map<String, List<AiringEntry>>> getWeeklySchedule() async {
    final weekStartSec = _currentWeekStartEpochSec();
    final key = _weekKey(weekStartSec);
    final existing = _inFlight[key];
    if (existing != null) return existing;
    final fut = _getWeeklyScheduleInner(weekStartSec);
    _inFlight[key] = fut;
    unawaited(fut.whenComplete(() => _inFlight.remove(key)));
    return fut;
  }

  Future<Map<String, List<AiringEntry>>> _getWeeklyScheduleInner(
    int weekStartSec,
  ) async {
    // Cache-first: SQLite wins. Network only on a genuine miss or via the
    // explicit `refreshWeeklySchedule` wired to the refresh button.
    final cached = await cache.getMergedWeek(weekStartSec);
    final fetchedAt = await cache.getFetchedAt(_weekKey(weekStartSec));
    if (cached != null && fetchedAt != null) {
      return _filterExpired(cached);
    }
    _logger.d('Airing cache miss for week $weekStartSec, building');
    return _buildAndSave(weekStartSec);
  }

  Map<String, List<AiringEntry>> _filterExpired(
    Map<String, List<AiringEntry>> week,
  ) {
    // Whole-week rule: return every stored entry as-is, including episodes
    // that already aired earlier this week. Only the live countdown is
    // recomputed (zero/negative means already aired, shown as "Aired").
    final now = DateTime.now().toUtc();
    final result = <String, List<AiringEntry>>{};
    for (final entry in week.entries) {
      final list =
          entry.value
              .map(
                (e) => AiringEntry(
                  anilistId: e.anilistId,
                  malId: e.malId,
                  title: e.title,
                  titleEnglish: e.titleEnglish,
                  titleNative: e.titleNative,
                  imageUrl: e.imageUrl,
                  airingAt: e.airingAt.toUtc(),
                  episode: e.episode,
                  timeUntilAiring: e.airingAt.toUtc().difference(now).inSeconds,
                  malScore: e.malScore,
                  genres: e.genres,
                  episodes: e.episodes,
                  format: e.format,
                  status: e.status,
                  myListStatus: e.myListStatus,
                  nextAiringAt: e.nextAiringAt?.toUtc(),
                  nextEpisode: e.nextEpisode,
                  nextTimeUntilAiring: e.nextTimeUntilAiring,
                ),
              )
              .toList()
            ..sort((a, b) => a.airingAt.compareTo(b.airingAt));
      result[entry.key] = list;
    }
    return result;
  }

  Future<Map<String, List<AiringEntry>>> _buildAndSave(
    int weekStartSec, {
    bool force = false,
  }) async {
    final results = await Future.wait([
      _fetchAniListSchedule(force: force),
      _fetchMalSeasonal(),
      _fetchUserWatchingMap(),
    ]);

    final anilistSchedule =
        results[0] as Map<String, List<AniListScheduleEntry>>;
    final malAnimeMap = results[1] as Map<int, Anime>;
    final userWatchingMap = results[2] as Map<int, Anime>;
    final titleLookup = <String, Anime>{};
    for (final m in {...malAnimeMap, ...userWatchingMap}.values) {
      titleLookup[m.title.toLowerCase()] = m;
      final altEn = m.alternativeTitles?.en?.toLowerCase();
      if (altEn != null) titleLookup[altEn] = m;
    }

    final merged = <String, List<AiringEntry>>{};
    var matchedCount = 0;
    final now = DateTime.now().toUtc();
    final seen = <String>{};
    for (final day in anilistSchedule.keys) {
      final list = <AiringEntry>[];
      for (final entry in anilistSchedule[day]!) {
        // Whole-week rule: merge everything, including episodes that
        // already aired earlier this week (shown as "Aired" in UI).
        final dedupKey = '${entry.anilistId}_${entry.episode}';
        if (seen.contains(dedupKey)) continue;
        seen.add(dedupKey);
        int? effectiveMalId = entry.malId;
        Anime? malAnime = effectiveMalId != null
            ? malAnimeMap[effectiveMalId]
            : null;
        malAnime ??= effectiveMalId != null
            ? userWatchingMap[effectiveMalId]
            : null;
        if (effectiveMalId == null) {
          final lowerTitle = entry.title.toLowerCase();
          final lowerEnglish = entry.titleEnglish?.toLowerCase();
          malAnime =
              titleLookup[lowerTitle] ??
              (lowerEnglish != null ? titleLookup[lowerEnglish] : null);
          effectiveMalId = malAnime?.id;
        }
        if (malAnime != null) matchedCount++;
        final liveRemaining = entry.airingAt.toUtc().difference(now).inSeconds;
        list.add(
          AiringEntry(
            anilistId: entry.anilistId,
            malId: effectiveMalId,
            title: entry.titleEnglish ?? entry.title,
            titleEnglish: entry.titleEnglish,
            titleNative: entry.titleNative,
            imageUrl: entry.imageUrl,
            airingAt: entry.airingAt.toUtc(),
            episode: entry.episode ?? 0,
            timeUntilAiring: liveRemaining > 0 ? liveRemaining : 0,
            malScore: malAnime?.mean ?? entry.meanScore,
            genres: entry.genres,
            episodes: malAnime?.numEpisodes ?? entry.episodes,
            format: entry.format,
            status: entry.status,
            myListStatus: malAnime?.myListStatus,
            nextAiringAt: entry.nextAiringAt?.toUtc(),
            nextEpisode: entry.nextEpisode,
            nextTimeUntilAiring: entry.nextTimeUntilAiring,
          ),
        );
      }
      list.sort((a, b) => a.airingAt.compareTo(b.airingAt));
      merged[day] = list;
    }
    final totalAnilist = anilistSchedule.values.fold<int>(
      0,
      (s, l) => s + l.length,
    );
    if (totalAnilist == 0) {
      final cached = await cache.getMergedWeek(weekStartSec);
      if (cached != null) {
        _logger.w('AniList schedule empty — keeping cached week');
        return _filterExpired(cached);
      }
      throw Exception('Airing schedule unavailable');
    }
    _logger.d('Merge: $matchedCount entries matched with MAL scores');

    final finalTotal = merged.values.fold<int>(0, (s, l) => s + l.length);
    if (finalTotal == 0) {
      final cached = await cache.getMergedWeek(weekStartSec);
      if (cached != null) {
        _logger.w('Merged schedule empty — keeping cached week');
        return _filterExpired(cached);
      }
      throw Exception('Airing schedule unavailable');
    }

    await cache.saveMergedWeek(weekStartSec, merged);
    return merged;
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

  /// Force refresh: bypasses all TTLs, refetches AniList schedule + MAL
  /// data, and merges into SQLite (merge-on-save keeps existing rows).
  Future<Map<String, List<AiringEntry>>> refreshWeeklySchedule() async {
    final weekStartSec = _currentWeekStartEpochSec();
    final existing = _inFlight[_weekKey(weekStartSec)];
    if (existing != null) return existing;
    final fut = _buildAndSave(weekStartSec, force: true);
    _inFlight[_weekKey(weekStartSec)] = fut;
    unawaited(fut.whenComplete(() => _inFlight.remove(_weekKey(weekStartSec))));
    return fut;
  }

  Future<Map<String, List<AniListScheduleEntry>>> _fetchAniListSchedule({
    bool force = false,
  }) async {
    try {
      if (force) return await _anilistApi.refreshWeeklySchedule();
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

  Future<Map<int, Anime>> _fetchUserWatchingMap() async {
    try {
      final list = await _animeRepo.getUserAnimeList(
        status: WatchStatus.watching,
      );
      return {for (final a in list) a.id: a};
    } on Object catch (_) {
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
  return repo;
});

/// Fetches weekly airing schedule (AniList schedule + MAL scores).
/// SQLite first: no version watch here, so list mutations (score/episode
/// edits) never trigger an AniList fetch. `myListStatus` inside schedule
/// refreshes on TTL expiry or an explicit refresh from the airing or home page.
final weeklyAiringProvider =
    FutureProvider.autoDispose<Map<String, List<AiringEntry>>>((ref) async {
      final repo = ref.watch(airingRepositoryProvider);
      return repo.getWeeklySchedule();
    });

/// Map of MAL ID to next AiringEntry for quick lookup.
/// No version watch: rebuilt only when the schedule itself changes.
final airingByMalIdProvider = FutureProvider.autoDispose<Map<int, AiringEntry>>(
  (ref) async {
    final schedule = await ref.watch(weeklyAiringProvider.future);
    final now = DateTime.now().toUtc();
    final map = <int, AiringEntry>{};
    for (final entries in schedule.values) {
      for (final entry in entries) {
        if (entry.malId == null) continue;
        final remaining = entry.airingAt.toUtc().difference(now).inSeconds;
        if (remaining <= 0) continue;
        final existing = map[entry.malId!];
        final existingRemaining =
            existing?.airingAt.toUtc().difference(now).inSeconds ?? 999999999;
        if (existing == null || remaining < existingRemaining) {
          map[entry.malId!] = entry;
        }
      }
    }
    return map;
  },
);
