import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/shared/providers/airing_entry.dart';
import 'package:animal/shared/providers/anime_list_providers.dart';
import 'package:animal/shared/widgets/anime_card.dart';
import 'package:animal/shared/widgets/empty_view.dart';
import 'package:animal/shared/widgets/error_view.dart';
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
      error: (error, _) => ErrorView(
        message: 'Failed to load ${status.label.toLowerCase()} list',
        onRetry: () => ref.invalidate(userAnimeListProvider(status)),
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
    if (sorted.isEmpty) {
      return const EmptyView(
        icon: Icons.inbox_outlined,
        message: 'No anime here yet',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(refreshUserAnimeListProvider)(status),
      child: ListView.builder(
        key: PageStorageKey<String>('anime_list_${status.value}'),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemExtent: 126,
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          final anime = sorted[index];
          final nextAiring = airingMap[anime.id];
          return AnimeCard(anime: anime, nextAiring: nextAiring);
        },
      ),
    );
  }
}
