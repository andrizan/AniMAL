import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/shared/providers/anilist_providers.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:animal/shared/widgets/anime_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudioProfilePage extends ConsumerWidget {
  const StudioProfilePage({required this.studioId, super.key});

  final int studioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStudio = ref.watch(anilistStudioDetailProvider(studioId));
    final theme = Theme.of(context);

    return asyncStudio.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              const Text('Failed to load studio info'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(
                  anilistStudioDetailProvider(studioId),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (studio) {
        final malIds = studio.mediaWorks
            .where((m) => m.malId != null)
            .map((m) => m.malId!)
            .toList();

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                foregroundColor: AppColors.iconLight,
                backgroundColor: theme.colorScheme.surface,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.overlayDarker,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.iconLight,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: SelectableText(
                    studio.name,
                    style: const TextStyle(fontSize: 16),
                  ),
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  background: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.business,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (studio.isAnimationStudio)
                            _InfoChip(
                              icon: Icons.movie,
                              label: 'Animation Studio',
                              color: theme.colorScheme.primary,
                            ),
                          if (studio.favourites != null)
                            _InfoChip(
                              icon: Icons.favorite_border,
                              label: '${studio.favourites} favourites',
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (malIds.isNotEmpty) ...[
                        Text('Works', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        _AnimeWorksList(malIds: malIds),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimeWorksList extends ConsumerWidget {
  const _AnimeWorksList({required this.malIds});

  final List<int> malIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAnime = ref.watch(animeListProvider(malIds));

    return asyncAnime.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (animeList) => Column(
        children: animeList.map((anime) => AnimeCard(anime: anime)).toList(),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, this.icon, this.color});

  final IconData? icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: effectiveColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
