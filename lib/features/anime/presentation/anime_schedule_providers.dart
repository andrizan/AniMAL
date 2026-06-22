import 'package:animal/core/providers.dart';
import 'package:animal/features/anime/data/anilist_api.dart';
import 'package:animal/features/anime/data/anime_schedule_repository.dart';
import 'package:animal/features/anime/domain/anime_with_schedule.dart';
import 'package:animal/features/anime/domain/season.dart';
import 'package:animal/features/anime/presentation/anime_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for [AniListApi].
final anilistApiProvider = Provider<AniListApi>((ref) {
  return AniListApi(logger: ref.watch(loggerProvider));
});

/// Provider for [AnimeScheduleRepository].
final animeScheduleRepositoryProvider = Provider<AnimeScheduleRepository>((ref) {
  return AnimeScheduleRepository(
    malApi: ref.watch(malAnimeApiProvider),
    anilistApi: ref.watch(anilistApiProvider),
    logger: ref.watch(loggerProvider),
  );
});

/// Fetches merged seasonal schedule (MAL + AniList).
// ignore: specify_nonobvious_property_types
final mergedScheduleProvider =
    FutureProvider.family<List<AnimeWithSchedule>, ({int year, Season season})>(
        (ref, params) async {
  final repo = ref.watch(animeScheduleRepositoryProvider);
  return repo.getSeasonalSchedule(
    year: params.year,
    season: params.season,
  );
});

/// Fetches merged schedule for a specific day.
// ignore: specify_nonobvious_property_types
final dayScheduleProvider = FutureProvider.family<List<AnimeWithSchedule>,
    ({int year, Season season, String day})>((ref, params) async {
  final repo = ref.watch(animeScheduleRepositoryProvider);
  return repo.getAnimeForDay(
    year: params.year,
    season: params.season,
    dayOfWeek: params.day,
  );
});
