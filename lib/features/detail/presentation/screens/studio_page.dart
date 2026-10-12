import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/shared/providers/anilist_providers.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:animal/shared/widgets/anime_card.dart';
import 'package:animal/shared/widgets/error_view.dart';
import 'package:animal/shared/widgets/info_chip.dart';
import 'package:animal/shared/widgets/scrim_icon_button.dart';
import 'package:animal/shared/widgets/section_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class StudioProfilePage extends ConsumerWidget {
  const StudioProfilePage({required this.studioId, super.key});

  final int studioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStudio = ref.watch(anilistStudioDetailProvider(studioId));
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return asyncStudio.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: 'Failed to load studio info',
          onRetry: () => ref.invalidate(anilistStudioDetailProvider(studioId)),
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
                expandedHeight: 240,
                pinned: true,
                foregroundColor: AppColors.iconLight,
                backgroundColor: scheme.surface,
                leading: ScrimIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: SelectableText(
                    studio.name,
                    style: theme.textTheme.titleMedium,
                  ),
                  titlePadding: const EdgeInsets.only(
                    left: AppSpacing.page,
                    bottom: AppSpacing.lg,
                  ),
                  background: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [scheme.primaryContainer, scheme.surface],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(
                            AppRadius.sheet + AppSpacing.xs,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.shadow.withValues(alpha: 0.12),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.business_rounded,
                          size: 48,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.xs,
                    AppSpacing.page,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          if (studio.isAnimationStudio)
                            InfoChip(
                              icon: Icons.movie_outlined,
                              label: 'Animation Studio',
                              color: scheme.onPrimaryContainer,
                              background: scheme.primaryContainer,
                            ),
                          if (studio.favourites != null)
                            InfoChip(
                              icon: Icons.favorite_border,
                              label: '${studio.favourites} favourites',
                            ),
                        ],
                      ),
                      if (malIds.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xs,
                            AppSpacing.xl,
                            AppSpacing.xs,
                            0,
                          ),
                          child: SectionHeader(
                            'Works',
                            trailing: '${malIds.length} titles',
                            bottomPadding: 2,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (malIds.isNotEmpty)
                SliverToBoxAdapter(child: _AnimeWorksList(malIds: malIds)),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
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
    final asyncAnime = ref.watch(animeListProvider(malIds.join(',')));

    return asyncAnime.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
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
