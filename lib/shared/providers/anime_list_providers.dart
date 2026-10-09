import 'package:animal/core/constants/mal_endpoints.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/shared/providers/airing_entry.dart';
import 'package:animal/shared/providers/anime_providers.dart'
    show animeListVersionProvider, animeRepositoryProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sort options for the anime list.
enum ListSort {
  name('Name'),
  score('Score'),
  episodes('Episodes'),
  airing('Airing');

  const ListSort(this.label);
  final String label;
}

/// Airing status filter.
enum AiringFilter {
  all('All'),
  airing('Airing'),
  finished('Finished'),
  upcoming('Upcoming');

  const AiringFilter(this.label);
  final String label;
}

/// Parameters for [sortedUserAnimeListProvider].
typedef AnimeListParams = ({
  WatchStatus status,
  ListSort sortBy,
  bool ascending,
  AiringFilter airingFilter,
});

/// Result of [sortedUserAnimeListProvider].
typedef SortedUserAnimeList = ({
  List<Anime> anime,
  Map<int, AiringEntry> airingMap,
});

List<Anime> _sortAnimeList(
  List<Anime> list,
  Map<int, AiringEntry> airingMap,
  ListSort sortBy,
  bool ascending,
) {
  final now = DateTime.now().toUtc();
  final sorted = List<Anime>.from(list)
    ..sort((a, b) {
      int cmp;
      switch (sortBy) {
        case ListSort.name:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case ListSort.score:
          final aScore = a.mean ?? 0;
          final bScore = b.mean ?? 0;
          cmp = aScore.compareTo(bScore);
        case ListSort.episodes:
          final aEps = a.numEpisodes ?? 0;
          final bEps = b.numEpisodes ?? 0;
          cmp = aEps.compareTo(bEps);
        case ListSort.airing:
          final aEntry = airingMap[a.id];
          final bEntry = airingMap[b.id];
          final aHas = aEntry != null;
          final bHas = bEntry != null;
          if (!aHas && !bHas) {
            cmp = 0;
          } else if (!aHas) {
            return 1;
          } else if (!bHas) {
            return -1;
          } else {
            final aTime = aEntry.airingAt.toUtc().difference(now).inSeconds;
            final bTime = bEntry.airingAt.toUtc().difference(now).inSeconds;
            cmp = aTime.compareTo(bTime);
          }
      }
      return ascending ? cmp : -cmp;
    });
  return sorted;
}

List<Anime> _filterAnimeList(List<Anime> list, AiringFilter airingFilter) {
  if (airingFilter == AiringFilter.all) return list;
  return list.where((a) {
    return switch (airingFilter) {
      AiringFilter.airing => a.status == 'currently_airing',
      AiringFilter.finished => a.status == 'finished_airing',
      AiringFilter.upcoming => a.status == 'not_yet_aired',
      _ => true,
    };
  }).toList();
}

/// Fetches the current user's anime list filtered by [WatchStatus].
// ignore: specify_nonobvious_property_types
final userAnimeListProvider = FutureProvider.family<List<Anime>, WatchStatus>((
  ref,
  status,
) async {
  ref.watch(animeListVersionProvider);
  final repo = ref.watch(animeRepositoryProvider);
  return repo.getUserAnimeList(status: status);
});

/// Force-refreshes the user list of a status together with the airing
/// schedule. The AniList schedule and the MAL list are fetched in parallel.
final refreshUserAnimeListProvider =
    Provider<Future<void> Function(WatchStatus)>((ref) {
      return (status) async {
        await ref
            .read(animeCacheProvider)
            .invalidateUserAnimeList(
              status.value,
              ApiConstants.malUserListPageSize,
              0,
            );
        await Future.wait([
          _refreshSchedule(ref),
          _refreshUserList(ref, status),
        ]);
      };
    });

Future<void> _refreshSchedule(Ref ref) async {
  try {
    await ref.read(airingRepositoryProvider).refreshWeeklySchedule();
  } on Object catch (_) {}
  ref.invalidate(weeklyAiringProvider);
}

Future<void> _refreshUserList(Ref ref, WatchStatus status) async {
  ref.invalidate(userAnimeListProvider(status));
  try {
    await ref.read(userAnimeListProvider(status).future);
  } on Object catch (_) {}
}

/// Memoized, sorted and filtered user anime list together with the airing map.
// ignore: specify_nonobvious_property_types
final sortedUserAnimeListProvider = FutureProvider.autoDispose
    .family<SortedUserAnimeList, AnimeListParams>((ref, params) async {
      // SQLite first: no clock watch here. Live countdowns are rendered
      // purely in UI (`CountdownBadge` watches `clockProvider`), so the
      // per-minute tick never re-triggers repository/API fetches.
      final animeList = await ref.watch(
        userAnimeListProvider(params.status).future,
      );
      final airingMap = await ref.watch(airingByMalIdProvider.future);
      final filtered = _filterAnimeList(animeList, params.airingFilter);
      final sorted = _sortAnimeList(
        filtered,
        airingMap,
        params.sortBy,
        params.ascending,
      );
      return (anime: sorted, airingMap: airingMap);
    });
