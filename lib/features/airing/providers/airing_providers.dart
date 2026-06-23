import 'package:animal/core/providers.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/data/mal/mal_api_client.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/season.dart';
import 'package:animal/features/airing/domain/entities/airing_entry.dart';
import 'package:animal/features/airing/domain/repositories/airing_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class AiringRepositoryImpl implements AiringRepository {
  AiringRepositoryImpl({
    required MalApiClient malApi,
    required AniListClient anilistApi,
  })  : _malApi = malApi,
        _anilistApi = anilistApi;

  final MalApiClient _malApi;
  final AniListClient _anilistApi;

  Map<String, List<AiringEntry>>? _cachedSchedule;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 15);

  bool get _isCacheValid =>
      _cachedSchedule != null &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheDuration;

  @override
  Future<Map<String, List<AiringEntry>>> getWeeklySchedule() async {
    if (_isCacheValid) return _cachedSchedule!;

    final results = await Future.wait([
      _anilistApi.getWeeklyAiringSchedule(),
      _fetchMalSeasonal(),
    ]);

    final anilistSchedule = results[0] as Map<String, List<AniListScheduleEntry>>;
    final malAnimeMap = results[1] as Map<int, Anime>;

    final merged = <String, List<AiringEntry>>{};
    for (final day in anilistSchedule.keys) {
      merged[day] = anilistSchedule[day]!.map((entry) {
        final malAnime = entry.malId != null ? malAnimeMap[entry.malId!] : null;
        return AiringEntry(
          anilistId: entry.anilistId,
          malId: entry.malId,
          title: entry.titleEnglish ?? entry.title,
          titleEnglish: entry.titleEnglish,
          imageUrl: entry.imageUrl,
          airingAt: entry.airingAt,
          episode: entry.episode ?? 0,
          timeUntilAiring: entry.timeUntilAiring ?? 0,
          malScore: malAnime?.mean ?? entry.meanScore,
          genres: entry.genres,
          episodes: malAnime?.numEpisodes ?? entry.episodes,
          format: entry.format,
          status: entry.status,
        );
      }).toList();
    }

    _cachedSchedule = merged;
    _cacheTime = DateTime.now();
    return merged;
  }

  @override
  void invalidateCache() {
    _cachedSchedule = null;
    _cacheTime = null;
  }

  Future<Map<int, Anime>> _fetchMalSeasonal() async {
    try {
      final now = DateTime.now();
      final animeList = await _malApi.getSeasonalAnime(
        year: now.year,
        season: Season.fromDate(now),
        limit: 500,
      );
      return {for (final a in animeList) a.id: a};
    } on Exception {
      return {};
    }
  }
}

final airingRepositoryProvider = Provider<AiringRepository>((ref) {
  return AiringRepositoryImpl(
    malApi: MalApiClient(ref.watch(dioProvider)),
    anilistApi: AniListClient(logger: ref.watch(loggerProvider)),
  );
});

final weeklyAiringProvider =
    FutureProvider<Map<String, List<AiringEntry>>>((ref) async {
  final repo = ref.watch(airingRepositoryProvider);
  return repo.getWeeklySchedule();
});

final airingByMalIdProvider =
    FutureProvider<Map<int, AiringEntry>>((ref) async {
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
