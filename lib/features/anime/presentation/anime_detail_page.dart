import 'dart:async';

import 'package:animal/features/anime/data/anilist_api.dart';
import 'package:animal/features/anime/domain/anime_detail.dart';
import 'package:animal/features/anime/domain/watch_status.dart';
import 'package:animal/features/anime/presentation/anilist_providers.dart';
import 'package:animal/features/anime/presentation/anime_list_controller.dart';
import 'package:animal/features/anime/presentation/anime_providers.dart';
import 'package:animal/features/anime/presentation/anime_search_controller.dart';
import 'package:animal/features/anime/presentation/full_screen_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Detail page for a single anime.
class AnimeDetailPage extends ConsumerWidget {
  const AnimeDetailPage({required this.animeId, super.key});

  final int animeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(animeDetailProvider(animeId));
    final asyncExtra = ref.watch(anilistAnimeExtraProvider(animeId));
    final theme = Theme.of(context);

    return asyncDetail.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                const Text('Failed to load anime detail'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      ref.invalidate(animeDetailProvider(animeId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (detail) {
        if (detail == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    const Text('Anime not found'),
                    const SizedBox(height: 8),
                    Text(
                      'This anime may not be available on MyAnimeList.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final inList = detail.myListStatus != null;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // App bar with cover image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                foregroundColor: Colors.white,
                backgroundColor: theme.colorScheme.surface,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    detail.title,
                    style: const TextStyle(
                      fontSize: 16,
                      shadows: [
                        Shadow(blurRadius: 8, color: Colors.black54),
                      ],
                    ),
                  ),
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  background: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (detail.mainPicture?.large != null) {
                        FullScreenImageViewer.show(
                          context,
                          imageUrl: detail.mainPicture!.large!,
                          heroTag: 'anime_cover',
                        );
                      }
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (detail.mainPicture?.large != null)
                          CachedNetworkImage(
                            imageUrl: detail.mainPicture!.large!,
                            fit: BoxFit.cover,
                          )
                        else
                          Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.transparent,
                                theme.colorScheme.surface.withValues(alpha: 0.7),
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

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Info Chips ──
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (detail.mean != null)
                            _InfoChip(
                              icon: Icons.star_rounded,
                              label: detail.mean!.toStringAsFixed(2),
                              color: Colors.amber,
                            ),
                          if (detail.rank != null)
                            _InfoChip(
                              icon: Icons.leaderboard,
                              label: '#${detail.rank}',
                            ),
                          if (detail.numEpisodes != null)
                            _InfoChip(
                              icon: Icons.movie_outlined,
                              label: '${detail.numEpisodes} eps',
                            ),
                          if (detail.mediaType != null)
                            _InfoChip(
                              label:
                                  _mediaTypeLabel(detail.mediaType!),
                            ),
                          if (detail.status != null)
                            _InfoChip(
                              label: _statusLabel(detail.status!),
                              color: _statusColor(detail.status!),
                            ),
                          if (detail.rating != null)
                            _InfoChip(
                              label: _ratingLabel(detail.rating!),
                              color: Colors.red,
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Alternative Titles ──
                      if (detail.alternativeTitles != null) ...[
                        Text('Alternative Titles',
                            style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        if (detail.alternativeTitles!.ja != null &&
                            detail.alternativeTitles!.ja!.isNotEmpty)
                          _TitleRow(
                            label: 'Japanese',
                            title: detail.alternativeTitles!.ja!,
                          ),
                        if (detail.alternativeTitles!.en != null &&
                            detail.alternativeTitles!.en!.isNotEmpty)
                          _TitleRow(
                            label: 'English',
                            title: detail.alternativeTitles!.en!,
                          ),
                        for (final synonym
                            in detail.alternativeTitles!.synonyms)
                          if (synonym.isNotEmpty)
                            _TitleRow(
                              label: 'Synonym',
                              title: synonym,
                            ),
                        const SizedBox(height: 20),
                      ],

                      // ── My List Status Card ──
                      if (inList) ...[
                        _MyListStatusCard(
                          detail: detail,
                          onStatusChanged: () =>
                              _invalidateAll(ref, currentStatus: detail.myListStatus?.status),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Genres ──
                      if (detail.genres.isNotEmpty) ...[
                        Text('Genres',
                            style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: detail.genres
                              .map((g) => Chip(
                                    label: Text(g.name),
                                    visualDensity:
                                        VisualDensity.compact,
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Broadcast ──
                      if (detail.broadcast?.dayOfWeek != null) ...[
                        Text('Broadcast',
                            style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 18,
                                color: theme
                                    .colorScheme.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Text(
                              '${_capitalize(detail.broadcast!.dayOfWeek!)}'
                              ' at ${detail.broadcast!.startTime ?? '?'} JST',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Next Episode, External Links, Characters & Staff ──
                      _AniListExtraSection(
                        malId: animeId,
                        asyncExtra: asyncExtra,
                      ),

                      // ── Source ──
                      if (detail.source != null &&
                          detail.source!.isNotEmpty) ...[
                        Text('Source',
                            style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.book_outlined,
                                size: 18,
                                color: theme
                                    .colorScheme.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Text(_sourceLabel(detail.source!)),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Related Anime ──
                      if (detail.relatedAnime.isNotEmpty) ...[
                        Text('Related Anime',
                            style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        ...detail.relatedAnime.map(
                          (related) => _RelatedAnimeTile(
                            related: related,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Synopsis ──
                      if (detail.synopsis != null &&
                          detail.synopsis!.isNotEmpty) ...[
                        Text('Synopsis',
                            style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Text(
                          detail.synopsis!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme
                                .colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Action Buttons ──
                      _ActionButtons(
                        animeId: animeId,
                        detail: detail,
                        inList: inList,
                      ),
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

  void _invalidateAll(WidgetRef ref, {WatchStatus? currentStatus}) {
    ref.invalidate(animeDetailProvider(animeId));
    if (currentStatus != null) {
      ref.invalidate(userAnimeListProvider(currentStatus));
    } else {
      ref.invalidate(userAnimeListProvider(WatchStatus.watching));
    }
  }

  String _capitalize(String s) =>
      s[0].toUpperCase() + s.substring(1);

  String _mediaTypeLabel(String type) => switch (type) {
        'tv' => 'TV',
        'movie' => 'Movie',
        'ova' => 'OVA',
        'ona' => 'ONA',
        'special' => 'Special',
        'music' => 'Music',
        _ => type,
      };

  String _statusLabel(String status) => switch (status) {
        'currently_airing' => 'Airing',
        'finished_airing' => 'Finished',
        'not_yet_aired' => 'Upcoming',
        _ => status,
      };

  Color _statusColor(String status) => switch (status) {
        'currently_airing' => Colors.green,
        'finished_airing' => Colors.blue,
        'not_yet_aired' => Colors.orange,
        _ => Colors.grey,
      };

  String _ratingLabel(String rating) => switch (rating) {
        'g' => 'G - All Ages',
        'pg' => 'PG - Children',
        'pg_13' => 'PG-13',
        'r' => 'R - 17+',
        'r+' => 'R+ - Profanity',
        'rx' => 'Rx - Hentai',
        _ => rating,
      };

  String _sourceLabel(String source) => switch (source) {
        'original' => 'Original',
        'manga' => 'Manga',
        'light_novel' => 'Light Novel',
        'visual_novel' => 'Visual Novel',
        'video_game' => 'Video Game',
        'other' => 'Other',
        'novel' => 'Novel',
        'doujinshi' => 'Doujinshi',
        'anime' => 'Anime',
        'web_manga' => 'Web Manga',
        'web_novel' => 'Web Novel',
        'game' => 'Game',
        'comic' => 'Comic',
        'multimedia_project' => 'Multimedia Project',
        'picture_book' => 'Picture Book',
        _ => source,
      };
}

// ═══════════════════════════════════════════════════════════════════
// My List Status Card with inline editing
// ═══════════════════════════════════════════════════════════════════

class _MyListStatusCard extends ConsumerWidget {
  const _MyListStatusCard({
    required this.detail,
    required this.onStatusChanged,
  });

  final AnimeDetail detail;
  final VoidCallback onStatusChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = detail.myListStatus!;
    final watched = status.numEpisodesWatched ?? 0;
    final total = detail.numEpisodes;
    final score = status.score ?? 0;

    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status + Edit Status button
            Row(
              children: [
                Icon(
                  _statusIcon(status.status),
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  status.status.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showStatusPicker(context, ref),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Change'),
                ),
              ],
            ),
            const Divider(),

            // Episodes watched
            Row(
              children: [
                Icon(Icons.movie_outlined,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Episodes',
                  style: theme.textTheme.bodyLarge,
                ),
                const Spacer(),
                // Decrement button
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: watched > 0
                      ? () => _updateEpisodes(ref, watched - 1)
                      : null,
                ),
                // Editable episode count
                SizedBox(
                  width: 60,
                  height: 36,
                  child: TextField(
                    controller: TextEditingController(
                      text: '$watched',
                    ),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                      suffixText: total != null ? '/$total' : null,
                      suffixStyle: theme.textTheme.bodySmall,
                    ),
                    onSubmitted: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed >= 0) {
                        unawaited(_updateEpisodes(ref, parsed));
                      }
                    },
                  ),
                ),
                // Increment button
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: (total == null || watched < total)
                      ? () => _updateEpisodes(ref, watched + 1)
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Score dropdown
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    size: 20, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Score',
                  style: theme.textTheme.bodyLarge,
                ),
                const Spacer(),
                DropdownButton<int>(
                  value: score,
                  items: List.generate(11, (i) {
                    return DropdownMenuItem(
                      value: i,
                      child: Text(
                        i == 0 ? 'Not rated' : '$i',
                        style: TextStyle(
                          fontWeight: i == score
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) unawaited(_updateScore(ref, value));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateEpisodes(WidgetRef ref, int newCount) async {
    final repo = ref.read(animeRepositoryProvider);
    await repo.updateAnimeListStatus(
      detail.id,
      numWatchedEpisodes: newCount,
    );
    onStatusChanged();
  }

  Future<void> _updateScore(WidgetRef ref, int newScore) async {
    final repo = ref.read(animeRepositoryProvider);
    await repo.updateAnimeListStatus(
      detail.id,
      score: newScore,
    );
    onStatusChanged();
  }

  void _showStatusPicker(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    unawaited(showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Change Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            for (final s in WatchStatus.values)
              ListTile(
                leading: Icon(_statusIcon(s)),
                title: Text(s.label),
                trailing: s == detail.myListStatus!.status
                    ? Icon(Icons.check,
                        color: theme.colorScheme.primary)
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  final repo = ref.read(animeRepositoryProvider);
                  await repo.updateAnimeListStatus(
                    detail.id,
                    status: s,
                  );
                  onStatusChanged();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ));
  }

  static IconData _statusIcon(WatchStatus status) {
    return switch (status) {
      WatchStatus.watching => Icons.play_circle,
      WatchStatus.completed => Icons.check_circle,
      WatchStatus.onHold => Icons.pause_circle,
      WatchStatus.dropped => Icons.cancel,
      WatchStatus.planToWatch => Icons.bookmark,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════
// Action Buttons
// ═══════════════════════════════════════════════════════════════════

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({
    required this.animeId,
    required this.detail,
    required this.inList,
  });

  final int animeId;
  final AnimeDetail detail;
  final bool inList;

  void _invalidateAll(WidgetRef ref, {WatchStatus? currentStatus}) {
    ref.invalidate(animeDetailProvider(animeId));
    if (currentStatus != null) {
      ref.invalidate(userAnimeListProvider(currentStatus));
    } else {
      ref.invalidate(userAnimeListProvider(WatchStatus.watching));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!inList) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () async {
            final repo = ref.read(animeRepositoryProvider);
            await repo.updateAnimeListStatus(
              animeId,
              status: WatchStatus.watching,
            );
            _invalidateAll(ref, currentStatus: WatchStatus.watching);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to Watching')),
              );
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Add to Watching'),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Remove from List'),
              content: Text(
                'Remove "${detail.title}" from your list?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Remove'),
                ),
              ],
            ),
          );

          if (confirmed == true && context.mounted) {
            final repo = ref.read(animeRepositoryProvider);
            await repo.deleteAnimeFromList(animeId);
            final currentStatus = detail.myListStatus?.status ?? WatchStatus.watching;
            _invalidateAll(ref, currentStatus: currentStatus);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Removed from list')),
              );
            }
          }
        },
        icon: const Icon(Icons.delete_outline),
        label: const Text('Remove from List'),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Info Chip
// ═══════════════════════════════════════════════════════════════════

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, this.icon, this.color});

  final IconData? icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color != null
            ? color!.withValues(alpha: 0.15)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Title Row for alternative titles
// ═══════════════════════════════════════════════════════════════════

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.label, required this.title});

  final String label;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Related Anime Tile
// ═══════════════════════════════════════════════════════════════════

class _RelatedAnimeTile extends StatelessWidget {
  const _RelatedAnimeTile({required this.related});

  final RelatedAnime related;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final node = related.node;
    final relationType = related.relationTypeFormatted ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: node.mainPicture?.medium != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: node.mainPicture!.medium!,
                  width: 40,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                width: 40,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.movie,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
        title: Text(
          node.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          relationType,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        dense: true,
        visualDensity: VisualDensity.compact,
        onTap: () => context.pushNamed(
          'animeDetail',
          pathParameters: {'id': '${node.id}'},
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// AniList Extra Section (combined: next airing + external links + people)
// ═══════════════════════════════════════════════════════════════════

class _AniListExtraSection extends StatefulWidget {
  const _AniListExtraSection({
    required this.malId,
    required this.asyncExtra,
  });

  final int malId;
  final AsyncValue<AniListAnimeExtra> asyncExtra;

  @override
  State<_AniListExtraSection> createState() => _AniListExtraSectionState();
}

class _AniListExtraSectionState extends State<_AniListExtraSection> {
  bool _showAllCharacters = false;
  bool _showAllStaff = false;

  static const _defaultLimit = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return widget.asyncExtra.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (extra) {
        final nextAiring = extra.nextAiring;
        final links = extra.externalLinks;
        final people = extra.people;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Next Episode ──
            if (nextAiring != null) ...[
              _buildNextEpisode(theme, nextAiring),
            ],

            // ── External Links ──
            if (links.isNotEmpty) ...[
              _buildExternalLinks(theme, links),
            ],

            // ── Characters & Staff ──
            if (people.characters.isNotEmpty ||
                people.staff.isNotEmpty) ...[
              _buildCharactersAndStaff(theme, people),
              const SizedBox(height: 20),
            ],
          ],
        );
      },
    );
  }

  Widget _buildNextEpisode(ThemeData theme, AniListNextAiring next) {
    final isUrgent = next.isUrgent;
    final localAiring = next.airingAt.toLocal();
    final timeStr =
        '${localAiring.hour.toString().padLeft(2, '0')}:'
        '${localAiring.minute.toString().padLeft(2, '0')}';
    final dateStr = '${localAiring.day}/${localAiring.month} at $timeStr';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Next Episode', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUrgent
                  ? theme.colorScheme.errorContainer
                  : theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.upcoming,
                  size: 20,
                  color: isUrgent
                      ? theme.colorScheme.onErrorContainer
                      : theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Episode ${next.episode}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isUrgent
                              ? theme.colorScheme.onErrorContainer
                              : theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$dateStr · ${next.countdown}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isUrgent
                              ? theme.colorScheme.onErrorContainer
                              : theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExternalLinks(
      ThemeData theme, List<AniListExternalLink> links) {
    final official = links.where((l) => l.type == 'INFO').toList();
    final streaming = links.where((l) => l.type == 'STREAMING').toList();
    final social = links.where((l) => l.type == 'SOCIAL').toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('External Links', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...official.map((l) => _LinkChip(
                    label: l.displaySite,
                    url: l.url,
                    icon: Icons.language,
                    color: theme.colorScheme.primaryContainer,
                    textColor: theme.colorScheme.onPrimaryContainer,
                  )),
              ...streaming.map((l) => _LinkChip(
                    label: l.displaySite,
                    url: l.url,
                    icon: Icons.play_circle_outline,
                    color: theme.colorScheme.tertiaryContainer,
                    textColor: theme.colorScheme.onTertiaryContainer,
                  )),
              ...social.map((l) => _LinkChip(
                    label: l.displaySite,
                    url: l.url,
                    icon: Icons.public,
                    color: theme.colorScheme.secondaryContainer,
                    textColor: theme.colorScheme.onSecondaryContainer,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharactersAndStaff(
      ThemeData theme, AniListAnimePeople people) {
    final charLimit =
        _showAllCharacters ? people.characters.length : _defaultLimit;
    final staffLimit =
        _showAllStaff ? people.staff.length : _defaultLimit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Characters
        if (people.characters.isNotEmpty) ...[
          Row(
            children: [
              Text('Characters & Voice Actors',
                  style: theme.textTheme.titleSmall),
              const Spacer(),
              if (people.characters.length > _defaultLimit)
                TextButton(
                  onPressed: () =>
                      setState(() => _showAllCharacters = !_showAllCharacters),
                  child: Text(
                    _showAllCharacters
                        ? 'Show Less'
                        : 'See All (${people.characters.length})',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...people.characters
              .take(charLimit)
              .map((c) => _CharacterTile(character: c)),
          const SizedBox(height: 20),
        ],

        // Staff
        if (people.staff.isNotEmpty) ...[
          Row(
            children: [
              Text('Staff', style: theme.textTheme.titleSmall),
              const Spacer(),
              if (people.staff.length > _defaultLimit)
                TextButton(
                  onPressed: () =>
                      setState(() => _showAllStaff = !_showAllStaff),
                  child: Text(
                    _showAllStaff
                        ? 'Show Less'
                        : 'See All (${people.staff.length})',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...people.staff
              .take(staffLimit)
              .map((s) => _StaffTile(staff: s)),
        ],
      ],
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({
    required this.label,
    required this.url,
    required this.icon,
    required this.color,
    required this.textColor,
  });

  final String label;
  final String url;
  final IconData icon;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        await launchUrl(uri);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Character tile with VA on the right.
class _CharacterTile extends StatelessWidget {
  const _CharacterTile({required this.character});

  final AniListCharacter character;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final va = character.voiceActors.isNotEmpty
        ? character.voiceActors.first
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: () => context.pushNamed(
          'characterProfile',
          pathParameters: {'id': '${character.id}'},
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            children: [
              // Character image
              _CircleAvatar(
                imageUrl: character.imageUrl,
                fallbackIcon: Icons.person,
              ),
              const SizedBox(width: 10),

              // Character info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (character.role != null)
                      Text(
                        character.role!,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),

              // Voice Actor
              if (va != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => context.pushNamed(
                    'staffProfile',
                    pathParameters: {'id': '${va.id}'},
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            va.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (va.language != null)
                            Text(
                              va.language!,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme
                                    .colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      _CircleAvatar(
                        imageUrl: va.imageUrl,
                        fallbackIcon: Icons.mic,
                        size: 35,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Staff tile.
class _StaffTile extends StatelessWidget {
  const _StaffTile({required this.staff});

  final AniListStaff staff;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: _CircleAvatar(
          imageUrl: staff.imageUrl,
          fallbackIcon: Icons.work_outline,
        ),
        title: Text(
          staff.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        subtitle: staff.role != null
            ? Text(
                staff.role!,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: const Icon(Icons.chevron_right, size: 20),
        dense: true,
        visualDensity: VisualDensity.compact,
        onTap: () => context.pushNamed(
          'staffProfile',
          pathParameters: {'id': '${staff.id}'},
        ),
      ),
    );
  }
}

/// Reusable circular avatar with network image fallback.
class _CircleAvatar extends StatelessWidget {
  const _CircleAvatar({
    required this.imageUrl,
    required this.fallbackIcon,
    this.size = 45,
  });

  final String? imageUrl;
  final IconData fallbackIcon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
              )
            : ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  fallbackIcon,
                  size: size * 0.45,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}
