import 'dart:async';

import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/core/utils/anime_labels.dart';
import 'package:animal/core/utils/date_utils.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/shared/providers/airing_entry.dart';
import 'package:animal/shared/providers/anime_list_providers.dart';
import 'package:animal/shared/providers/anime_notification_providers.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:animal/shared/widgets/app_cached_image.dart';
import 'package:animal/shared/widgets/countdown_badge.dart';
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
    this.onTap,
  });

  final Anime anime;

  /// Optional trailing widget below the main info (e.g. countdown).
  final Widget? trailing;

  /// Optional next airing info from AniList schedule.
  final AiringEntry? nextAiring;

  /// Optional tap callback. When provided, replaces the default navigation.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final jaTitle = anime.alternativeTitles?.ja;
    final episodes = anime.numEpisodes;
    final statusLabel = AnimeLabels.statusLabel(anime.status, compact: true);
    final statusColor = AnimeLabels.statusColor(anime.status);
    final personalScore = anime.myListStatus?.score;
    final watchedEps = anime.myListStatus?.numEpisodesWatched;
    final notifEnabled = ref.watch(
      animeNotificationProvider.select((s) => s.contains(anime.id)),
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            onTap ??
            () => context.pushNamed(
              'animeDetail',
              pathParameters: {'id': '${anime.id}'},
            ),
        onLongPress: onTap != null ? null : () => _showUpdateModal(context),
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
                          if (anime.myListStatus != null)
                            Container(
                              margin: const EdgeInsets.only(right: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: _listStatusColor(
                                  anime.myListStatus!.status,
                                ).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                anime.myListStatus!.status.label,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: _listStatusColor(
                                    anime.myListStatus!.status,
                                  ),
                                ),
                              ),
                            ),
                          if (onTap == null)
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
                                onPressed: () => _showUpdateModal(context),
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
                                  anime.rating,
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
                            const Icon(
                              Icons.notifications_active,
                              size: 14,
                              color: AppColors.starColor,
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (nextAiring case final next?)
                            CountdownBadge(
                              airingAt: next.airingAt,
                              episode: next.episode,
                            ),
                          if (trailing case final trailing?) trailing,
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

  void _showUpdateModal(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (ctx) {
          return _UpdateListStatusModal(
            anime: anime,
            nextAiring: nextAiring,
          );
        },
      ),
    );
  }

  static Color _listStatusColor(WatchStatus status) => switch (status) {
    WatchStatus.watching => AppColors.listWatching,
    WatchStatus.completed => AppColors.listCompleted,
    WatchStatus.onHold => AppColors.listOnHold,
    WatchStatus.dropped => AppColors.listDropped,
    WatchStatus.planToWatch => AppColors.listPlanToWatch,
  };
}

/// Modal content for updating an anime's list status.
class _UpdateListStatusModal extends ConsumerStatefulWidget {
  const _UpdateListStatusModal({
    required this.anime,
    required this.nextAiring,
  });

  final Anime anime;
  final AiringEntry? nextAiring;

  @override
  ConsumerState<_UpdateListStatusModal> createState() =>
      _UpdateListStatusModalState();
}

class _UpdateListStatusModalState
    extends ConsumerState<_UpdateListStatusModal> {
  late final TextEditingController _epsController;
  late WatchStatus _selectedStatus;
  late int _selectedScore;
  late int _selectedEps;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.anime.myListStatus?.status ?? WatchStatus.watching;
    _selectedScore = widget.anime.myListStatus?.score ?? 0;
    _selectedEps = widget.anime.myListStatus?.numEpisodesWatched ?? 0;
    _epsController = TextEditingController(text: '$_selectedEps');

    if (widget.anime.status == 'finished_airing') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final enabled = ref
            .read(animeNotificationProvider)
            .contains(
              widget.anime.id,
            );
        if (enabled) {
          ref
              .read(animeNotificationProvider.notifier)
              .removeAnime(
                widget.anime.id,
              );
        }
      });
    }
  }

  @override
  void dispose() {
    _epsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(animeRepositoryProvider);
      await repo.updateAnimeListStatus(
        widget.anime.id,
        status: _selectedStatus,
        numWatchedEpisodes: _selectedEps,
        score: _selectedScore,
      );
      final currentStatus =
          widget.anime.myListStatus?.status ?? WatchStatus.watching;
      ref.invalidate(userAnimeListProvider(currentStatus));
      if (_selectedStatus != currentStatus) {
        ref.invalidate(userAnimeListProvider(_selectedStatus));
      }
      if (_selectedStatus != WatchStatus.watching) {
        ref
            .read(animeNotificationProvider.notifier)
            .removeAnime(
              widget.anime.id,
            );
      }
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.anime.title} updated')),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalEps = widget.anime.numEpisodes != 0
        ? widget.anime.numEpisodes
        : null;
    final notifEnabled = ref.watch(
      animeNotificationProvider.select(
        (s) => s.contains(widget.anime.id),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.anime.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),

            // Notification toggle (only for airing anime with nextAiring)
            if (widget.nextAiring != null) ...[
              Text('Notification', style: theme.textTheme.titleSmall),
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
                          ? 'Notification enabled for Ep ${widget.nextAiring!.episode}'
                          : 'Get notified before episode airs',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Switch(
                    value: notifEnabled,
                    onChanged: _saving
                        ? null
                        : (value) async {
                            final success = await ref
                                .read(animeNotificationProvider.notifier)
                                .toggle(
                                  animeId: widget.anime.id,
                                  title: widget.anime.title,
                                  episode: widget.nextAiring!.episode,
                                  airingAt: widget.nextAiring!.airingAt,
                                );
                            if (!success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Notification permission denied',
                                  ),
                                ),
                              );
                            }
                          },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Status
            Text('Status', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: WatchStatus.values.map((s) {
                final isCompleted = s == WatchStatus.completed;
                final canMarkCompleted =
                    !isCompleted || widget.anime.status == 'finished_airing';
                return Tooltip(
                  message:
                      isCompleted && widget.anime.status != 'finished_airing'
                      ? 'Only available for finished anime'
                      : '',
                  child: ChoiceChip(
                    label: Text(s.label),
                    selected: _selectedStatus == s,
                    onSelected: _saving || !canMarkCompleted
                        ? null
                        : (_) {
                            setState(() {
                              _selectedStatus = s;
                              if (isCompleted && totalEps != null) {
                                _selectedEps = totalEps;
                                _epsController.text = '$totalEps';
                              }
                            });
                          },
                  ),
                );
              }).toList(),
            ),
            if (widget.anime.status != 'finished_airing')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Completed can only be set for finished anime',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Episodes
            Text(
              'Episodes Watched',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: (_saving || _selectedEps <= 0)
                      ? null
                      : () {
                          setState(() => _selectedEps--);
                          _epsController.text = '$_selectedEps';
                        },
                ),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: _epsController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    enabled: !_saving,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixText: totalEps != null ? '/$totalEps' : null,
                    ),
                    onSubmitted: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null && parsed >= 0) {
                        setState(() => _selectedEps = parsed);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed:
                      (_saving ||
                          (totalEps != null && _selectedEps >= totalEps))
                      ? null
                      : () {
                          setState(() => _selectedEps++);
                          _epsController.text = '$_selectedEps';
                        },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Score
            Text('Score', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: _selectedScore,
              isExpanded: true,
              items: List.generate(11, (i) {
                return DropdownMenuItem(
                  value: i,
                  child: Text(i == 0 ? 'Not rated' : '$i'),
                );
              }),
              onChanged: _saving
                  ? null
                  : (v) {
                      if (v != null) setState(() => _selectedScore = v);
                    },
            ),
            const SizedBox(height: 24),

            // Save
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
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
            AppCachedImage(
              imageUrl: anime.mainPicture?.medium ?? '',
              fallbackSize: 20,
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
                    AnimeLabels.mediaTypeLabel(anime.mediaType, compact: true),
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
