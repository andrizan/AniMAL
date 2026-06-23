import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/season.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Parameters for [animeScheduleProvider] and [groupedSeasonalAnimeProvider].
typedef ScheduleParams = ({int year, Season season});

/// Result of [groupedSeasonalAnimeProvider].
typedef GroupedSeasonalAnime = ({
  Map<String, List<Anime>> grouped,
  List<Anime> noBroadcast,
});

const _weekDays = <String>[
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

GroupedSeasonalAnime _groupAnimeByDay(List<Anime> animeList) {
  final grouped = <String, List<Anime>>{};
  for (final day in _weekDays) {
    grouped[day] = [];
  }
  final noBroadcast = <Anime>[];

  for (final anime in animeList) {
    final day = anime.broadcast?.dayOfWeek;
    if (day != null && grouped.containsKey(day)) {
      grouped[day]!.add(anime);
    } else {
      noBroadcast.add(anime);
    }
  }

  for (final entry in grouped.entries) {
    entry.value.sort((a, b) {
      final at = a.broadcast?.startTime ?? '';
      final bt = b.broadcast?.startTime ?? '';
      return at.compareTo(bt);
    });
  }

  return (grouped: grouped, noBroadcast: noBroadcast);
}

/// Fetches the seasonal anime schedule for a given year / season.
///
/// Each [Anime] in the result carries its broadcast info so the
/// UI can group entries by day of the week.
// ignore: specify_nonobvious_property_types
final animeScheduleProvider =
    FutureProvider.family<List<Anime>, ScheduleParams>(
      (ref, params) async {
        final repo = ref.watch(animeRepositoryProvider);
        return repo.getSeasonalAnime(
          year: params.year,
          season: params.season,
        );
      },
    );

/// Fetches and groups the seasonal anime schedule by broadcast day.
// ignore: specify_nonobvious_property_types
final groupedSeasonalAnimeProvider =
    FutureProvider.family<GroupedSeasonalAnime, ScheduleParams>(
      (ref, params) async {
        final animeList = await ref.watch(animeScheduleProvider(params).future);
        return _groupAnimeByDay(animeList);
      },
    );

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
