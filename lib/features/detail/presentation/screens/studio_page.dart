import 'dart:async';

import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/shared/providers/anilist_providers.dart';
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
          appBar: AppBar(
            title: Text(
              studio.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info chips
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

              // Site link
              if (studio.siteUrl != null) ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('Website'),
                    subtitle: Text(
                      Uri.parse(studio.siteUrl!).host,
                      style: TextStyle(color: theme.colorScheme.primary),
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

              // Media works
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
