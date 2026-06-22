import 'package:animal/features/anime/domain/anime.dart';
import 'package:animal/features/anime/domain/watch_status.dart';
import 'package:animal/features/anime/presentation/anime_list_controller.dart';
import 'package:animal/features/anime/presentation/anime_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Anime card with cover image, info, and update modal.
class AnimeListCard extends ConsumerWidget {
  const AnimeListCard({
    required this.anime, super.key,
    this.showBroadcast = true,
  });

  final Anime anime;
  final bool showBroadcast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jaTitle = anime.alternativeTitles?.ja;
    final episodes = anime.numEpisodes;
    final broadcastTime =
        showBroadcast ? _convertJstToLocal(anime.broadcast?.startTime) : null;
    final statusLabel = _statusLabel(anime.status);
    final statusColor = _statusColor(anime.status);
    final personalScore = anime.myListStatus?.score;
    final watchedEps = anime.myListStatus?.numEpisodesWatched;

    return GestureDetector(
      onTap: () => context.pushNamed(
        'animeDetail',
        pathParameters: {'id': '${anime.id}'},
      ),
      onLongPress: () => _showUpdateModal(context, ref),
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
        child: SizedBox(
          height: 125,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover image with badges
              _CoverImage(
                anime: anime,
                statusLabel: statusLabel,
                statusColor: statusColor,
              ),

              // Info section
              Expanded(
                child: _InfoSection(
                  anime: anime,
                  jaTitle: jaTitle,
                  episodes: episodes,
                  broadcastTime: broadcastTime,
                  personalScore: personalScore,
                  watchedEps: watchedEps,
                  onUpdate: () => _showUpdateModal(context, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _convertJstToLocal(String? jstTime) {
    if (jstTime == null || jstTime.isEmpty) return null;
    try {
      final parts = jstTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final now = DateTime.now();
      final jstDate =
          DateTime.utc(now.year, now.month, now.day, hour - 9, minute);
      final localDate = jstDate.toLocal();
      return '${localDate.hour.toString().padLeft(2, '0')}:'
          '${localDate.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return jstTime;
    }
  }

  String? _statusLabel(String? status) => switch (status) {
        'currently_airing' => 'AIRING',
        'finished_airing' => 'FINISHED',
        'not_yet_aired' => 'UPCOMING',
        _ => null,
      };

  Color _statusColor(String? status) => switch (status) {
        'currently_airing' => Colors.green,
        'finished_airing' => Colors.blue,
        'not_yet_aired' => Colors.orange,
        _ => Colors.grey,
      };

  void _showUpdateModal(BuildContext context, WidgetRef ref) {
    final currentStatus = anime.myListStatus?.status ?? WatchStatus.watching;
    final currentScore = anime.myListStatus?.score ?? 0;
    final currentEps = anime.myListStatus?.numEpisodesWatched ?? 0;
    final totalEps = anime.numEpisodes;

    var selectedScore = currentScore;
    var selectedEps = currentEps;
    var selectedStatus = currentStatus;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
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
                  Text('Episodes Watched',
                      style: Theme.of(ctx).textTheme.titleSmall),
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
                          controller:
                              TextEditingController(text: '$selectedEps'),
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixText:
                                totalEps != null ? '/$totalEps' : null,
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
                        onPressed: (totalEps == null || selectedEps < totalEps)
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
    );
  }
}

/// Cover image with status and media type badges.
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
    return SizedBox(
      width: 80,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (anime.mainPicture?.medium != null) CachedNetworkImage(
                  imageUrl: anime.mainPicture!.medium!,
                  fit: BoxFit.cover,
                ) else Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.movie,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
        if (statusLabel != null)
          Positioned(
            top: 2,
            left: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                statusLabel!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        if (anime.mediaType != null)
          Positioned(
            bottom: 2,
            left: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                _mediaTypeLabel(anime.mediaType!),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    ),
    );
  }

  String _mediaTypeLabel(String type) => switch (type) {
        'tv' => 'TV',
        'movie' => 'MOVIE',
        'ova' => 'OVA',
        'ona' => 'ONA',
        'special' => 'SP',
        'music' => 'MV',
        _ => type.toUpperCase(),
      };
}

/// Info section with title, genres, scores, and metadata.
class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.anime,
    required this.jaTitle,
    required this.episodes,
    required this.broadcastTime,
    required this.personalScore,
    required this.watchedEps,
    required this.onUpdate,
  });

  final Anime anime;
  final String? jaTitle;
  final int? episodes;
  final String? broadcastTime;
  final int? personalScore;
  final int? watchedEps;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + edit button
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
                  onPressed: onUpdate,
                ),
              ),
            ],
          ),

          // Japanese title
          if (jaTitle != null && jaTitle!.isNotEmpty)
            Text(
              jaTitle!,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      g.name,
                      style: TextStyle(
                        fontSize: 9,
                        color: theme.colorScheme.onSecondaryContainer,
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
                const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  anime.mean!.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (personalScore != null && personalScore! > 0) ...[
                const SizedBox(width: 10),
                Icon(Icons.star, size: 14, color: theme.colorScheme.primary),
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

          const SizedBox(height: 4),

          // Rating + broadcast
          Row(
            children: [
              if (anime.rating != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    _ratingLabel(anime.rating!),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              if (anime.rating != null && broadcastTime != null)
                const SizedBox(width: 8),
              if (broadcastTime != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 2),
                    Text(
                      broadcastTime!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _ratingLabel(String rating) => switch (rating) {
        'g' => 'G',
        'pg' => 'PG',
        'pg_13' => 'PG-13',
        'r' => 'R',
        'r+' => 'R+',
        'rx' => 'Rx',
        _ => rating.toUpperCase(),
      };
}
