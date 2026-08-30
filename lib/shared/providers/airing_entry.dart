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
import 'package:animal/shared/providers/clock_provider.dart';
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

  static const _ttlMerged = Duration(minutes: 15);

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
    final cached = await cache.getMergedWeek(weekStartSec);
    final fetchedAt = await cache.getFetchedAt(_weekKey(weekStartSec));
    if (cached != null && fetchedAt != null) {
      final filtered = _filterExpired(cached);
      if (DateTime.now().difference(fetchedAt) < _ttlMerged) {
        return filtered;
      }
      unawaited(_refreshMerged(weekStartSec));
      return filtered;
    }
    _logger.d('Airing cache miss for week $weekStartSec, building');
    return _buildAndSave(weekStartSec);
  }

  Map<String, List<AiringEntry>> _filterExpired(
    Map<String, List<AiringEntry>> week,
  ) {
    final now = DateTime.now().toUtc();
    final result = <String, List<AiringEntry>>{};
    final seenSynthetic = <String>{};
    for (final entry in week.entries) {
      final filtered = <AiringEntry>[];
      for (final e in entry.value) {
        final remaining = e.airingAt.toUtc().difference(now).inSeconds;
        if (remaining <= 0) {
          final isFinished =
              e.status == 'FINISHED' ||
              e.status == 'finished_airing' ||
              e.status == 'CANCELLED';
          if (!isFinished) {
            DateTime? accurateNextAt = e.nextAiringAt?.toUtc();
            int? accurateNextEp = e.nextEpisode;
            int? accurateNextUntil = e.nextTimeUntilAiring;
            late final DateTime nextAiringAt;
            late final int nextEpisode;
            late final int nextRemaining;
            if (accurateNextAt != null &&
                accurateNextEp != null &&
                accurateNextAt.isAfter(now)) {
              nextAiringAt = accurateNextAt;
              nextEpisode = accurateNextEp;
              nextRemaining =
                  accurateNextUntil ?? nextAiringAt.difference(now).inSeconds;
            } else {
              nextAiringAt = e.airingAt.toUtc().add(
                const Duration(days: 7),
              );
              nextEpisode = e.episode + 1;
              nextRemaining = nextAiringAt.difference(now).inSeconds;
            }
            if (nextRemaining > 0) {
              final syntheticKey = '${e.anilistId}_$nextEpisode';
              if (!seenSynthetic.contains(syntheticKey)) {
                seenSynthetic.add(syntheticKey);
                final syntheticDay = _dayName(nextAiringAt.toUtc().weekday);
                final synthetic = AiringEntry(
                  anilistId: e.anilistId,
                  malId: e.malId,
                  title: e.title,
                  titleEnglish: e.titleEnglish,
                  titleNative: e.titleNative,
                  imageUrl: e.imageUrl,
                  airingAt: nextAiringAt,
                  episode: nextEpisode,
                  timeUntilAiring: nextRemaining,
                  malScore: e.malScore,
                  genres: e.genres,
                  episodes: e.episodes,
                  format: e.format,
                  status: e.status,
                  myListStatus: e.myListStatus,
                );
                result.putIfAbsent(syntheticDay, () => []).add(synthetic);
              }
            }
          }
          continue;
        }
        filtered.add(
          AiringEntry(
            anilistId: e.anilistId,
            malId: e.malId,
            title: e.title,
            titleEnglish: e.titleEnglish,
            titleNative: e.titleNative,
            imageUrl: e.imageUrl,
            airingAt: e.airingAt.toUtc(),
            episode: e.episode,
            timeUntilAiring: remaining,
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
        );
      }
      filtered.sort((a, b) => a.airingAt.compareTo(b.airingAt));
      result[entry.key] = [...?result[entry.key], ...filtered]
        ..sort(
          (a, b) => a.airingAt.compareTo(b.airingAt),
        );
    }
    for (final day in result.keys) {
      result[day]!.sort((a, b) => a.airingAt.compareTo(b.airingAt));
    }
    return result;
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
    final now = DateTime.now().toUtc();
    final seen = <String>{};
    for (final day in anilistSchedule.keys) {
      final list = <AiringEntry>[];
      for (final entry in anilistSchedule[day]!) {
        final remaining = entry.airingAt.toUtc().difference(now).inSeconds;
        final effectiveRemaining = entry.timeUntilAiring ?? remaining;
        if (effectiveRemaining <= 0 && entry.airingAt.toUtc().isBefore(now)) {
          continue;
        }
        final dedupKey = '${entry.anilistId}_${entry.episode}';
        if (seen.contains(dedupKey)) continue;
        seen.add(dedupKey);
        final malAnime = entry.malId != null ? malAnimeMap[entry.malId!] : null;
        if (malAnime != null) matchedCount++;
        final liveRemaining = entry.airingAt.toUtc().difference(now).inSeconds;
        list.add(
          AiringEntry(
            anilistId: entry.anilistId,
            malId: entry.malId,
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
  ref.watch(clockProvider);
  final repo = ref.watch(airingRepositoryProvider);
  return repo.getWeeklySchedule();
});

/// Map of MAL ID to next AiringEntry for quick lookup.
final airingByMalIdProvider = FutureProvider<Map<int, AiringEntry>>((
  ref,
) async {
  ref.watch(animeListVersionProvider);
  ref.watch(clockProvider);
  final schedule = await ref.watch(weeklyAiringProvider.future);
  final now = DateTime.now().toUtc();
  final map = <int, AiringEntry>{};
  for (final entries in schedule.values) {
    for (final entry in entries) {
      if (entry.malId == null) continue;
      final remaining = entry.airingAt.toUtc().difference(now).inSeconds;
      if (remaining <= 0) continue;
      final existing = map[entry.malId!];
      final entryRemaining = remaining;
      final existingRemaining =
          existing?.airingAt.toUtc().difference(now).inSeconds ?? 999999999;
      if (existing == null || entryRemaining < existingRemaining) {
        map[entry.malId!] = entry;
      }
    }
  }
  return map;
});
