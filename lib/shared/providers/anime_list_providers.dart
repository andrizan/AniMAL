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
          final aTime = airingMap[a.id]?.timeUntilAiring ?? 999999999;
          final bTime = airingMap[b.id]?.timeUntilAiring ?? 999999999;
          cmp = aTime.compareTo(bTime);
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
final userAnimeListProvider = FutureProvider.family<List<Anime>, WatchStatus>(
  (ref, status) async {
    ref.watch(animeListVersionProvider);
    final repo = ref.watch(animeRepositoryProvider);
    return repo.getUserAnimeList(status: status);
  },
);

/// Memoized, sorted and filtered user anime list together with the airing map.
// ignore: specify_nonobvious_property_types
final sortedUserAnimeListProvider =
    FutureProvider.family<SortedUserAnimeList, AnimeListParams>(
      (ref, params) async {
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
      },
    );
