import 'dart:async';

import 'package:animal/core/constants/mal_endpoints.dart';
import 'package:animal/core/logger/app_logger.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/core/utils/anilist_mappings.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/data/local/airing_cache.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/season.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/shared/providers/anilist_providers.dart';
import 'package:animal/shared/providers/anime_providers.dart'
    show AnimeRepository, animeListVersionProvider, animeRepositoryProvider;
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

  /// The episode of this anime that airs next as of [now]: this entry while
  /// it is still ahead, otherwise the next episode AniList reported with it
  /// when that one is ahead, otherwise null.
  AiringEntry? upcomingAt(DateTime now) {
    if (airingAt.toUtc().isAfter(now)) return this;
    final at = nextAiringAt?.toUtc();
    final episode = nextEpisode;
    if (at == null || episode == null || !at.isAfter(now)) return null;
    return AiringEntry(
      anilistId: anilistId,
      malId: malId,
      title: title,
      titleEnglish: titleEnglish,
      titleNative: titleNative,
      imageUrl: imageUrl,
      airingAt: at,
      episode: episode,
      timeUntilAiring: at.difference(now).inSeconds,
      malScore: malScore,
      genres: genres,
      episodes: episodes,
      format: format,
      status: status,
      myListStatus: myListStatus,
    );
  }
}

/// Repository that merges AniList schedule with MAL scores.
class AiringRepository {
  AiringRepository({
    required this._animeRepo,
    required this._anilistApi,
    required this.cache,
    this.refreshDelay = ApiConstants.airedRefreshDelay,
    Logger? logger,
  }) : _logger = logger ?? appLogger;

  final AnimeRepository _animeRepo;
  final AniListClient _anilistApi;
  final AiringCache cache;

  /// How long after an episode airs AniList is asked what comes next.
  final Duration refreshDelay;
  final Logger _logger;

  static const _staleNextTtl = Duration(minutes: 15);

  final Map<String, Future<Map<String, List<AiringEntry>>>> _inFlight = {};
  final Map<int, DateTime> _nextCheckedAt = {};

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
    fut.whenComplete(() => _inFlight.remove(key)).ignore();
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
            malScore: malAnime?.mean ?? scoreOutOfTen(entry.meanScore),
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

  /// Force refresh: bypasses all TTLs, refetches AniList schedule + MAL
  /// data, and merges into SQLite (merge-on-save keeps existing rows).
  Future<Map<String, List<AiringEntry>>> refreshWeeklySchedule() async {
    final weekStartSec = _currentWeekStartEpochSec();
    final existing = _inFlight[_weekKey(weekStartSec)];
    if (existing != null) return existing;
    final fut = _buildAndSave(weekStartSec, force: true);
    _inFlight[_weekKey(weekStartSec)] = fut;
    fut.whenComplete(() => _inFlight.remove(_weekKey(weekStartSec))).ignore();
    return fut;
  }

  /// A stored week keeps the next episode AniList reported when it was
  /// fetched, which stops being the answer once that episode has aired. For
  /// every listed anime that is still airing and has no episode ahead, ask
  /// AniList in one batch what comes next and store it. Returns true when
  /// the stored week changed. An anime is asked about at most once per
  /// [_staleNextTtl], answer or not.
  Future<bool> refreshStaleNextAiring(
    Map<String, List<AiringEntry>> week,
  ) async {
    final now = DateTime.now().toUtc();
    final ids = _staleNextAiringIds(week, now)
        .where(
          (id) =>
              now.difference(_nextCheckedAt[id] ?? DateTime(0)) >=
              _staleNextTtl,
        )
        .toList();
    if (ids.isEmpty) return false;
    for (final id in ids) {
      _nextCheckedAt[id] = now;
    }
    try {
      final found = await _anilistApi.getNextAirings(ids);
      for (final entry in found.entries) {
        await cache.updateNextAiring(
          entry.key,
          next: entry.value.next,
          status: entry.value.status,
        );
      }
      return found.isNotEmpty;
    } on Object catch (e) {
      _logger.w('Could not refresh the next episodes of $ids: $e');
      return false;
    }
  }

  /// When the stored week should be looked at again: [refreshDelay] after the
  /// soonest episode of a listed, still airing anime has aired, or null when
  /// no such episode is ahead.
  DateTime? refreshDueAt(Map<String, List<AiringEntry>> week, DateTime now) {
    DateTime? soonest;
    for (final entry in week.values.expand((entries) => entries)) {
      if (entry.malId == null || !_expectsMoreEpisodes(entry)) continue;
      final at = entry.upcomingAt(now)?.airingAt;
      if (at != null && (soonest == null || at.isBefore(soonest))) soonest = at;
    }
    return soonest?.add(refreshDelay);
  }

  Set<int> _staleNextAiringIds(
    Map<String, List<AiringEntry>> week,
    DateTime now,
  ) {
    final ahead = <int>{};
    final latest = <int, AiringEntry>{};
    for (final entry in week.values.expand((entries) => entries)) {
      final id = entry.malId;
      if (id == null) continue;
      if (entry.upcomingAt(now) != null) {
        ahead.add(id);
      } else if (entry.episode > (latest[id]?.episode ?? -1)) {
        latest[id] = entry;
      }
    }
    return {
      for (final MapEntry(:key, :value) in latest.entries)
        if (!ahead.contains(key) && _expectsMoreEpisodes(value)) key,
    };
  }

  bool _expectsMoreEpisodes(AiringEntry entry) {
    final total = entry.episodes ?? 0;
    return entry.myListStatus != null &&
        entry.status == 'RELEASING' &&
        (total <= 0 || entry.episode < total);
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
/// SQLite first: a cached week is never refetched on read. It watches the
/// list version so score/episode/status edits re-read the stored week, whose
/// `myListStatus` is kept in sync by `AiringCache.updateMyListStatus`. The
/// schedule itself only refreshes on an explicit airing or home refresh.
final weeklyAiringProvider =
    FutureProvider.autoDispose<Map<String, List<AiringEntry>>>((ref) async {
      ref.watch(animeListVersionProvider);
      final repo = ref.watch(airingRepositoryProvider);
      final week = await repo.getWeeklySchedule();
      unawaited(
        repo.refreshStaleNextAiring(week).then((changed) {
          if (changed && ref.mounted) ref.invalidateSelf();
        }),
      );
      final now = DateTime.now().toUtc();
      if (repo.refreshDueAt(week, now) case final dueAt?) {
        final timer = Timer(dueAt.difference(now), ref.invalidateSelf);
        ref.onDispose(timer.cancel);
      }
      return week;
    });

/// Map of MAL ID to next AiringEntry for quick lookup.
/// No version watch: rebuilt only when the schedule itself changes.
/// Airing data only decorates MAL lists, so a failed schedule yields an empty
/// map instead of failing every list that uses it.
final airingByMalIdProvider = FutureProvider.autoDispose<Map<int, AiringEntry>>(
  (ref) async {
    final Map<String, List<AiringEntry>> schedule;
    try {
      schedule = await ref.watch(weeklyAiringProvider.future);
    } on Object {
      return const <int, AiringEntry>{};
    }
    final now = DateTime.now().toUtc();
    final map = <int, AiringEntry>{};
    for (final entries in schedule.values) {
      for (final scheduled in entries) {
        if (scheduled.malId == null) continue;
        final entry = scheduled.upcomingAt(now);
        if (entry == null) continue;
        final remaining = entry.airingAt.toUtc().difference(now).inSeconds;
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
