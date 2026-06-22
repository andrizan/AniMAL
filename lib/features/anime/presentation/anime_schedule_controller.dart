import 'package:animal/features/anime/domain/anime.dart';
import 'package:animal/features/anime/domain/broadcast.dart';
import 'package:animal/features/anime/domain/season.dart';
import 'package:animal/features/anime/presentation/anime_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/src/providers/future_provider.dart';

/// Parameters for [animeScheduleProvider].
typedef ScheduleParams = ({int year, Season season});

/// Fetches the seasonal anime schedule for a given year / season.
///
/// Each [Anime] in the result carries its [Broadcast] info so the
/// UI can group entries by day of the week.
final FutureProviderFamily<List<Anime>, ScheduleParams>
    animeScheduleProvider =
    FutureProvider.family<List<Anime>, ScheduleParams>(
        (ref, params) async {
  final repo = ref.watch(animeRepositoryProvider);
  return repo.getSeasonalAnime(
    year: params.year,
    season: params.season,
  );
});

/// The current season based on today's date.
final Provider<({int year, Season season})> currentSeasonProvider =
    Provider<({int year, Season season})>((ref) {
  final now = DateTime.now();
  return (
    year: Season.yearFromDate(now),
    season: Season.fromDate(now),
  );
});

/// Fetches the current season's anime schedule.
final FutureProvider<List<Anime>> currentAnimeScheduleProvider =
    FutureProvider<List<Anime>>((ref) async {
  final params = ref.watch(currentSeasonProvider);
  return ref.watch(animeScheduleProvider(params).future);
});
