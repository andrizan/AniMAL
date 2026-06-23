import 'dart:async';

import 'package:animal/core/utils/anime_labels.dart';
import 'package:animal/core/utils/date_utils.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/features/airing/providers/airing_providers.dart';
import 'package:animal/features/home/providers/anime_list_providers.dart';
import 'package:animal/shared/providers/anime_notification_providers.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:animal/core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Unified anime card used across all pages.
///
/// Layout: full-height image (left) + info (right).
/// Image has rounded corners only on the left side.
/// Supports edit modal via 3-dot button or long press.
class AnimeCard extends ConsumerWidget {
  const AnimeCard({
    required this.anime,
    super.key,
    this.trailing,
    this.nextAiring,
  });

  final Anime anime;

  /// Optional trailing widget below the main info (e.g. countdown).
  final Widget? trailing;

  /// Optional next airing info from AniList schedule.
  final AiringEntry? nextAiring;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final jaTitle = anime.alternativeTitles?.ja;
    final episodes = anime.numEpisodes;
    final statusLabel = AnimeLabels.statusLabel(anime.status, compact: true);
    final statusColor = AnimeLabels.statusColor(anime.status);
    final personalScore = anime.myListStatus?.score;
    final watchedEps = anime.myListStatus?.numEpisodesWatched;
    final notifEnabled = ref
        .watch(animeNotificationProvider)
        .contains(anime.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          'animeDetail',
          pathParameters: {'id': '${anime.id}'},
        ),
        onLongPress: () => _showUpdateModal(context, ref),
        child: SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Cover image (left rounded only) ──
              _CoverImage(
                anime: anime,
                statusLabel: statusLabel,
                statusColor: statusColor,
              ),

              // ── Info section ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row + edit button
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              anime.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              icon: Icon(
                                Icons.more_vert,
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: () => _showUpdateModal(context, ref),
                            ),
                          ),
                        ],
                      ),

                      // Japanese title
                      if (jaTitle != null && jaTitle.isNotEmpty)
                        Text(
                          jaTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),

                      // Genres
                      if (anime.genres.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: anime.genres.take(3).map((g) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  g.name,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      const Spacer(),

                      // Scores + episodes
                      Row(
                        children: [
                          if (anime.mean != null) ...[
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: AppColors.starColor,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              anime.mean!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (personalScore != null && personalScore > 0) ...[
                            const SizedBox(width: 10),
                            Icon(
                              Icons.star,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '$personalScore',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (watchedEps != null && episodes != null)
                            Text(
                              '$watchedEps/$episodes ep',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          else if (episodes != null)
                            Text(
                              '${episodes}ep',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),

                      // Bottom: rating + broadcast (left) | badge (right)
                      Row(
                        children: [
                          if (anime.rating != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                AnimeLabels.ratingLabel(
                                  anime.rating!,
                                  compact: true,
                                ),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          if (anime.broadcast?.startTime != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              convertJstToLocal(anime.broadcast?.startTime) ??
                                  '',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (notifEnabled &&
                              anime.status != 'finished_airing') ...[
                            Icon(
                              Icons.notifications_active,
                              size: 14,
                              color: AppColors.starColor,
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (nextAiring != null)
                            _NextEpisodeBadge(
                              episode: nextAiring!.episode,
                              countdown: nextAiring!.countdown ?? '',
                              isUrgent: nextAiring!.isUrgent,
                            ),
                          if (trailing != null) trailing!,
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateModal(BuildContext context, WidgetRef ref) {
    final currentStatus = anime.myListStatus?.status ?? WatchStatus.watching;
    final currentScore = anime.myListStatus?.score ?? 0;
    final currentEps = anime.myListStatus?.numEpisodesWatched ?? 0;
    final totalEps = anime.numEpisodes;

    var selectedScore = currentScore;
    var selectedEps = currentEps;
    var selectedStatus = currentStatus;

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setModalState) {
              final notifEnabled = ref
                  .watch(animeNotificationProvider)
                  .contains(anime.id);

              if (notifEnabled && anime.status == 'finished_airing') {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    ref
                        .read(animeNotificationProvider.notifier)
                        .removeAnime(anime.id);
                  }
                });
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime.title,
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),

                    // Notification toggle (only for airing anime with nextAiring)
                    if (nextAiring != null) ...[
                      Text(
                        'Notification',
                        style: Theme.of(ctx).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            notifEnabled
                                ? Icons.notifications_active
                                : Icons.notifications_none,
                            color: notifEnabled ? AppColors.starColor : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              notifEnabled
                                  ? 'Notification enabled for Ep ${nextAiring!.episode}'
                                  : 'Get notified before episode airs',
                              style: Theme.of(ctx).textTheme.bodyMedium,
                            ),
                          ),
                          Switch(
                            value: notifEnabled,
                            onChanged: (value) async {
                              final success = await ref
                                  .read(animeNotificationProvider.notifier)
                                  .toggle(
                                    animeId: anime.id,
                                    title: anime.title,
                                    episode: nextAiring!.episode,
                                    airingAt: nextAiring!.airingAt,
                                  );
                              if (!success && ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Notification permission denied',
                                    ),
                                  ),
                                );
                              }
                              setModalState(() {});
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Status
                    Text('Status', style: Theme.of(ctx).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: WatchStatus.values.map((s) {
                        return ChoiceChip(
                          label: Text(s.label),
                          selected: selectedStatus == s,
                          onSelected: (_) =>
                              setModalState(() => selectedStatus = s),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Episodes
                    Text(
                      'Episodes Watched',
                      style: Theme.of(ctx).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: selectedEps > 0
                              ? () => setModalState(() => selectedEps--)
                              : null,
                        ),
                        SizedBox(
                          width: 70,
                          child: TextField(
                            controller: TextEditingController(
                              text: '$selectedEps',
                            ),
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixText: totalEps != null
                                  ? '/$totalEps'
                                  : null,
                            ),
                            onSubmitted: (v) {
                              final parsed = int.tryParse(v);
                              if (parsed != null && parsed >= 0) {
                                setModalState(() => selectedEps = parsed);
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed:
                              (totalEps == null || selectedEps < totalEps)
                              ? () => setModalState(() => selectedEps++)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Score
                    Text('Score', style: Theme.of(ctx).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    DropdownButton<int>(
                      value: selectedScore,
                      isExpanded: true,
                      items: List.generate(11, (i) {
                        return DropdownMenuItem(
                          value: i,
                          child: Text(i == 0 ? 'Not rated' : '$i'),
                        );
                      }),
                      onChanged: (v) {
                        if (v != null) setModalState(() => selectedScore = v);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Save
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final repo = ref.read(animeRepositoryProvider);
                          await repo.updateAnimeListStatus(
                            anime.id,
                            status: selectedStatus,
                            numWatchedEpisodes: selectedEps,
                            score: selectedScore,
                          );
                          for (final s in WatchStatus.values) {
                            ref.invalidate(userAnimeListProvider(s));
                          }
                          if (selectedStatus != WatchStatus.watching) {
                            ref
                                .read(animeNotificationProvider.notifier)
                                .removeAnime(anime.id);
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${anime.title} updated')),
                            );
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Cover image with left-side rounded corners only.
class _CoverImage extends StatelessWidget {
  const _CoverImage({
    required this.anime,
    required this.statusLabel,
    required this.statusColor,
  });

  final Anime anime;
  final String? statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        bottomLeft: Radius.circular(12),
      ),
      child: SizedBox(
        width: 80,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            if (anime.mainPicture?.medium != null)
              CachedNetworkImage(
                imageUrl: anime.mainPicture!.medium!,
                fit: BoxFit.cover,
              )
            else
              ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.movie,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            // Status badge (top-left)
            if (statusLabel != null)
              Positioned(
                top: 2,
                left: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    statusLabel!,
                    style: const TextStyle(
                      color: AppColors.iconLight,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            // Media type badge (bottom-left)
            if (anime.mediaType != null)
              Positioned(
                bottom: 2,
                left: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.overlayDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    AnimeLabels.mediaTypeLabel(anime.mediaType!, compact: true),
                    style: const TextStyle(
                      color: AppColors.iconLight,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Next episode badge shown on anime cards.
class _NextEpisodeBadge extends StatelessWidget {
  const _NextEpisodeBadge({
    required this.episode,
    required this.countdown,
    required this.isUrgent,
  });

  final int episode;
  final String countdown;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isUrgent
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 12,
            color: isUrgent
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Ep $episode · $countdown',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isUrgent
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
