import 'dart:async';

import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/shared/providers/anilist_providers.dart';
import 'package:animal/shared/widgets/full_screen_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
                  background: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (studio.imageUrl != null) {
                        FullScreenImageViewer.show(
                          context,
                          imageUrl: studio.imageUrl!,
                          heroTag: 'studio',
                        );
                      }
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (studio.imageUrl != null)
                          CachedNetworkImage(
                            imageUrl: studio.imageUrl!,
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(
                                Icons.business,
                                size: 64,
                                color: AppColors.iconLight,
                              ),
                            ),
                          )
                        else
                          Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(
                              Icons.business,
                              size: 64,
                              color: AppColors.iconLight,
                            ),
                          ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.transparent,
                                AppColors.transparent,
                                theme.colorScheme.surface
                                    .withValues(alpha: 0.7),
                                theme.colorScheme.surface,
                              ],
                              stops: const [0.0, 0.4, 0.75, 1.0],
                            ),
                          ),
                        ),
                      ],
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

                      if (studio.siteUrl != null) ...[
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.language),
                            title: const Text('Official Website'),
                            subtitle: Text(
                              Uri.parse(studio.siteUrl!).host,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            trailing: const Icon(Icons.open_in_new, size: 18),
                            onTap: () {
                              final uri = Uri.parse(studio.siteUrl!);
                              unawaited(launchUrl(uri));
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      if (studio.mediaWorks.isNotEmpty) ...[
                        Text('Works', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        ...studio.mediaWorks.map(
                          (media) => _MediaWorkTile(media: media),
                        ),
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

class _MediaWorkTile extends StatelessWidget {
  const _MediaWorkTile({required this.media});

  final AniListMediaAppearance media;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeLabel = switch (media.type) {
      'ANIME' => 'Anime',
      'MANGA' => 'Manga',
      'NOVEL' => 'Novel',
      'ONE_SHOT' => 'One Shot',
      _ => null,
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 40,
            height: 56,
            child: media.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: media.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.movie,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.movie,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
        title: Text(
          media.titleEnglish ?? media.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
        subtitle: typeLabel != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              )
            : null,
        trailing: const Icon(Icons.chevron_right, size: 20),
        dense: true,
        visualDensity: VisualDensity.compact,
        onTap: () {
          if (media.malId != null) {
            unawaited(
              context.pushNamed(
                'animeDetail',
                pathParameters: {'id': '${media.malId}'},
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'No MAL link available for "${media.titleEnglish ?? media.title}"',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }
}
