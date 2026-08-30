import 'package:animal/core/providers.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/shared/providers/airing_entry.dart';
import 'package:animal/shared/providers/anime_list_providers.dart';
import 'package:animal/shared/widgets/anime_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Tab that displays the user's anime list for a given [WatchStatus].
///
/// Supports sorting by [sortBy] and [ascending].
/// Supports filtering by [airingFilter].
class AnimeListTab extends ConsumerWidget {
  const AnimeListTab({
    required this.status,
    super.key,
    this.sortBy = ListSort.name,
    this.ascending = true,
    this.airingFilter = AiringFilter.all,
  });

  final WatchStatus status;
  final ListSort sortBy;
  final bool ascending;
  final AiringFilter airingFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (
      status: status,
      sortBy: sortBy,
      ascending: ascending,
      airingFilter: airingFilter,
    );
    final asyncList = ref.watch(sortedUserAnimeListProvider(params));

    if (asyncList.hasValue) {
      final result = asyncList.requireValue;
      return _buildList(context, result.anime, result.airingMap, ref);
    }

    return asyncList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: 'Failed to load ${status.label.toLowerCase()} list',
        onRetry: () => ref.invalidate(sortedUserAnimeListProvider(params)),
      ),
      data: (result) {
        return _buildList(context, result.anime, result.airingMap, ref);
      },
    );
  }

  Widget _buildList(
    BuildContext context,
    List<Anime> sorted,
    Map<int, AiringEntry> airingMap,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);

    if (sorted.isEmpty) {
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

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(animeCacheProvider)
            .invalidateUserAnimeList(status.value, 100, 0);
        ref
          ..invalidate(userAnimeListProvider(status))
          ..invalidate(weeklyAiringProvider)
          ..invalidate(airingByMalIdProvider);
        // Wait until fresh data is fetched so indicator shows correct state
        try {
          await Future.wait([
            ref.read(userAnimeListProvider(status).future),
            ref.read(weeklyAiringProvider.future),
          ]);
        } catch (_) {}
      },
      child: ListView.builder(
        key: PageStorageKey<String>('anime_list_${status.value}'),
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
