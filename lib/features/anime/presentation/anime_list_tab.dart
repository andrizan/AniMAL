import 'package:animal/features/anime/domain/anime.dart';
import 'package:animal/features/anime/domain/watch_status.dart';
import 'package:animal/features/anime/presentation/anime_card.dart';
import 'package:animal/features/anime/presentation/anime_home_tab.dart';
import 'package:animal/features/anime/presentation/anime_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tab that displays the user's anime list for a given [WatchStatus].
///
/// Supports sorting by [sortBy] and [ascending].
class AnimeListTab extends ConsumerWidget {
  const AnimeListTab({
    required this.status, super.key,
    this.sortBy = ListSort.name,
    this.ascending = true,
  });

  final WatchStatus status;
  final ListSort sortBy;
  final bool ascending;

  List<Anime> _sort(List<Anime> list) {
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
      }
      return ascending ? cmp : -cmp;
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAnime = ref.watch(userAnimeListProvider(status));
    final theme = Theme.of(context);

    return asyncAnime.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: 'Failed to load ${status.label.toLowerCase()} list',
        onRetry: () => ref.invalidate(userAnimeListProvider(status)),
      ),
      data: (animeList) {
        if (animeList.isEmpty) {
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

        final sorted = _sort(animeList);

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(userAnimeListProvider(status)),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final anime = sorted[index];
              return AnimeCard(anime: anime);
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
