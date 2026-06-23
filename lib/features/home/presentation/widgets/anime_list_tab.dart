import 'package:animal/features/library/data/models/anime.dart';
import 'package:animal/features/library/data/models/watch_status.dart';
import 'package:animal/features/airing/presentation/providers/anime_airing_providers.dart';
import 'package:animal/features/library/presentation/widgets/anime_card.dart';
import 'package:animal/features/home/presentation/widgets/anime_home_tab.dart';
import 'package:animal/features/home/presentation/providers/anime_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tab that displays the user's anime list for a given [WatchStatus].
///
/// Supports sorting by [sortBy] and [ascending].
/// Supports filtering by [airingFilter].
class AnimeListTab extends ConsumerWidget {
  const AnimeListTab({
    required this.status, super.key,
    this.sortBy = ListSort.name,
    this.ascending = true,
    this.airingFilter = AiringFilter.all,
  });

  final WatchStatus status;
  final ListSort sortBy;
  final bool ascending;
  final AiringFilter airingFilter;

  List<Anime> _sort(List<Anime> list, Map<int, AiringEntry> airingMap) {
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

  List<Anime> _filter(List<Anime> list) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAnime = ref.watch(userAnimeListProvider(status));
    final asyncAiringMap = ref.watch(airingByMalIdProvider);
    final theme = Theme.of(context);

    return asyncAnime.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: 'Failed to load ${status.label.toLowerCase()} list',
        onRetry: () => ref.invalidate(userAnimeListProvider(status)),
      ),
      data: (animeList) {
        final filtered = _filter(animeList);
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No anime here yet',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        final airingMap = asyncAiringMap.when(
          data: (map) => map,
          loading: () => <int, AiringEntry>{},
          error: (_, _) => <int, AiringEntry>{},
        );
        final sorted = _sort(filtered, airingMap);

        return RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(userAnimeListProvider(status))
              ..invalidate(airingByMalIdProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final anime = sorted[index];
              final nextAiring = airingMap[anime.id];
              return AnimeCard(
                anime: anime,
                nextAiring: nextAiring,
              );
            },
          ),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
