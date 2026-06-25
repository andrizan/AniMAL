import 'dart:async';

import 'package:animal/core/config/env.dart';
import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/core/utils/anime_labels.dart';
import 'package:animal/data/anilist/anilist_client.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/shared/providers/anilist_providers.dart';
import 'package:animal/shared/providers/anime_list_providers.dart';
import 'package:animal/shared/providers/anime_notification_providers.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:animal/shared/widgets/app_cached_image.dart';
import 'package:animal/shared/widgets/full_screen_image.dart';
import 'package:animal/shared/widgets/info_chip.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
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
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                const Text('Failed to load anime detail'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(animeDetailProvider(animeId)),
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
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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
                foregroundColor: theme.colorScheme.onSurfaceVariant,
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
                actions: [
                  if (asyncExtra.value?.nextAiring != null)
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.overlayDarker,
                        shape: BoxShape.circle,
                      ),
                      child: _NotificationBell(
                        animeId: animeId,
                        title: detail.title,
                        nextAiring: asyncExtra.value!.nextAiring!,
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.overlayDarker,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.share, color: AppColors.iconLight),
                      onPressed: () => _shareAnime(detail),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: SelectableText(
                    detail.title,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
                        AppCachedImage(
                          imageUrl: detail.mainPicture?.large ?? '',
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.transparent,
                                AppColors.transparent,
                                theme.colorScheme.surface.withValues(
                                  alpha: 0.6,
                                ),
                                theme.colorScheme.surface,
                              ],
                              stops: const [0.0, 0.45, 0.8, 1.0],
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
                            InfoChip(
                              icon: Icons.star_rounded,
                              label: detail.mean!.toStringAsFixed(2),
                              color: AppColors.starColor,
                            ),
                          if (detail.rank != null)
                            InfoChip(
                              icon: Icons.leaderboard,
                              label: '#${detail.rank}',
                            ),
                          if (detail.numEpisodes != null)
                            InfoChip(
                              icon: Icons.movie_outlined,
                              label: '${detail.numEpisodes} eps',
                            ),
                          if (detail.mediaType != null)
                            InfoChip(
                              label: AnimeLabels.mediaTypeLabel(
                                detail.mediaType!,
                              ),
                            ),
                          if (detail.status != null)
                            InfoChip(
                              label: AnimeLabels.statusLabel(detail.status!),
                              color: AnimeLabels.statusColor(detail.status!),
                            ),
                          if (detail.rating != null)
                            InfoChip(
                              label: AnimeLabels.ratingLabel(detail.rating!),
                              color: theme.colorScheme.error,
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Alternative Titles ──
                      if (detail.alternativeTitles != null) ...[
                        Text(
                          'Alternative Titles',
                          style: theme.textTheme.titleSmall,
                        ),
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
                          onUpdated: (newStatus) => _invalidateForStatus(
                            ref,
                            detail.myListStatus?.status,
                            newStatus,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Genres ──
                      if (detail.genres.isNotEmpty) ...[
                        Text('Genres', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: detail.genres
                              .map(
                                (g) => Chip(
                                  label: Text(g.name),
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Broadcast ──
                      if (detail.broadcast?.dayOfWeek != null) ...[
                        Text('Broadcast', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_capitalize(detail.broadcast!.dayOfWeek!)}'
                              ' at ${detail.broadcast!.startTime ?? '?'} JST',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Airing Dates ──
                      if (detail.startDate != null ||
                          detail.endDate != null) ...[
                        Text('Airing', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        if (detail.startDate != null)
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${detail.endDate != null ? 'Aired' : 'Airing'}: ${_formatDate(detail.startDate!)}'
                                '${detail.endDate != null ? ' to ${_formatDate(detail.endDate!)}' : ''}',
                              ),
                            ],
                          ),
                        if (detail.endDate != null && detail.startDate == null)
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text('Ended: ${_formatDate(detail.endDate!)}'),
                            ],
                          ),
                        const SizedBox(height: 20),
                      ],

                      // ── Start Season ──
                      if (detail.startSeason != null) ...[
                        Text('Season', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${AnimeLabels.seasonLabel(detail.startSeason!.season)} ${detail.startSeason!.year}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Episode Duration ──
                      if (detail.averageEpisodeDuration != null &&
                          detail.averageEpisodeDuration! > 0) ...[
                        Text(
                          'Episode Duration',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AnimeLabels.durationLabel(
                                detail.averageEpisodeDuration,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Next Episode, External Links, Characters & Staff, Studios ──
                      _AniListExtraSection(
                        malId: animeId,
                        asyncExtra: asyncExtra,
                      ),

                      // ── Source ──
                      if (detail.source != null &&
                          detail.source!.isNotEmpty) ...[
                        Text('Source', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(AnimeLabels.sourceLabel(detail.source!)),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Related Anime ──
                      if (detail.relatedAnime.isNotEmpty) ...[
                        Text(
                          'Related Anime',
                          style: theme.textTheme.titleSmall,
                        ),
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
                        Text('Synopsis', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        SelectableText(
                          detail.synopsis!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
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

  void _invalidateForStatus(
    WidgetRef ref,
    WatchStatus? oldStatus,
    WatchStatus newStatus,
  ) {
    ref.invalidate(animeDetailProvider(animeId));
    if (oldStatus != null) {
      ref.invalidate(userAnimeListProvider(oldStatus));
    }
    ref.invalidate(userAnimeListProvider(newStatus));
    for (final s in WatchStatus.values) {
      if (s != oldStatus && s != newStatus) {
        ref.invalidate(userAnimeListProvider(s));
      }
    }
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  String _formatDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = int.tryParse(parts[1]);
    if (month == null || month < 1 || month > 12) return dateStr;
    return '${months[month - 1]} ${int.tryParse(parts[2]) ?? ''}, ${parts[0]}';
  }

  Future<void> _shareAnime(AnimeDetail detail) async {
    final url = Env.malAnimeUrl(animeId);
    await SharePlus.instance.share(ShareParams(text: '${detail.title}\n$url'));
  }
}

// ═══════════════════════════════════════════════════════════════════
// My List Status Card with inline editing
// ═══════════════════════════════════════════════════════════════════

class _MyListStatusCard extends ConsumerStatefulWidget {
  const _MyListStatusCard({
    required this.detail,
    required this.onUpdated,
  });

  final AnimeDetail detail;
  final void Function(WatchStatus newStatus) onUpdated;

  @override
  ConsumerState<_MyListStatusCard> createState() => _MyListStatusCardState();
}

class _MyListStatusCardState extends ConsumerState<_MyListStatusCard> {
  bool _busy = false;

  Future<void> _updateEpisodes(int newCount) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(animeRepositoryProvider);
      final updated = await repo.updateAnimeListStatus(
        widget.detail.id,
        numWatchedEpisodes: newCount,
      );
      if (!mounted) return;
      widget.onUpdated(updated.status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Episodes updated to $newCount'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _updateScore(int newScore) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(animeRepositoryProvider);
      final updated = await repo.updateAnimeListStatus(
        widget.detail.id,
        score: newScore,
      );
      if (!mounted) return;
      widget.onUpdated(updated.status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newScore == 0 ? 'Score cleared' : 'Score set to $newScore',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeStatus(WatchStatus newStatus) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(animeRepositoryProvider);
      final isCompleted = newStatus == WatchStatus.completed;
      final totalEps = widget.detail.numEpisodes;
      final updated = await repo.updateAnimeListStatus(
        widget.detail.id,
        status: newStatus,
        numWatchedEpisodes: isCompleted && totalEps != null ? totalEps : null,
      );
      if (!mounted) return;
      widget.onUpdated(updated.status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status changed to ${newStatus.label}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showStatusPicker(BuildContext context) {
    final theme = Theme.of(context);
    final isFinished = widget.detail.status == 'finished_airing';
    unawaited(
      showModalBottomSheet<void>(
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
                Builder(
                  builder: (_) {
                    final disabled =
                        _busy || (s == WatchStatus.completed && !isFinished);
                    return ListTile(
                      leading: Icon(_statusIcon(s)),
                      title: Text(
                        s.label,
                        style: TextStyle(
                          color: disabled
                              ? theme.colorScheme.onSurfaceVariant
                              : null,
                        ),
                      ),
                      subtitle: disabled && s == WatchStatus.completed
                          ? const Text(
                              'Only available for finished anime',
                              style: TextStyle(fontSize: 11),
                            )
                          : null,
                      trailing: s == widget.detail.myListStatus!.status
                          ? Icon(Icons.check, color: theme.colorScheme.primary)
                          : null,
                      onTap: disabled
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              unawaited(_changeStatus(s));
                            },
                    );
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = widget.detail;
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
                  onPressed: _busy ? null : () => _showStatusPicker(context),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Change'),
                ),
              ],
            ),
            const Divider(),

            // Episodes watched
            Row(
              children: [
                Icon(
                  Icons.movie_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Episodes',
                  style: theme.textTheme.bodyLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: (_busy || watched <= 0)
                      ? null
                      : () => _updateEpisodes(watched - 1),
                ),
                SizedBox(
                  width: 60,
                  height: 36,
                  child: TextFormField(
                    key: ValueKey('episodes_$watched'),
                    initialValue: '$watched',
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    enabled: !_busy,
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
                    onFieldSubmitted: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed >= 0) {
                        unawaited(_updateEpisodes(parsed));
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: (_busy || (total != null && watched >= total))
                      ? null
                      : () => _updateEpisodes(watched + 1),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Score dropdown
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 20,
                  color: AppColors.starColor,
                ),
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
                  onChanged: _busy
                      ? null
                      : (value) {
                          if (value != null) {
                            unawaited(_updateScore(value));
                          }
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Action Buttons
// ═══════════════════════════════════════════════════════════════════

class _ActionButtons extends ConsumerStatefulWidget {
  const _ActionButtons({
    required this.animeId,
    required this.detail,
    required this.inList,
  });

  final int animeId;
  final AnimeDetail detail;
  final bool inList;

  @override
  ConsumerState<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends ConsumerState<_ActionButtons> {
  bool _busy = false;

  void _invalidateAll({WatchStatus? currentStatus}) {
    ref.invalidate(animeDetailProvider(widget.animeId));
    if (currentStatus != null) {
      ref.invalidate(userAnimeListProvider(currentStatus));
    } else {
      ref.invalidate(userAnimeListProvider(WatchStatus.watching));
    }
  }

  Future<void> _addToList() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(animeRepositoryProvider);
      await repo.updateAnimeListStatus(
        widget.animeId,
        status: WatchStatus.watching,
      );
      _invalidateAll(currentStatus: WatchStatus.watching);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to Watching')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeFromList() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from List'),
        content: Text('Remove "${widget.detail.title}" from your list?'),
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

    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(animeRepositoryProvider);
      await repo.deleteAnimeFromList(widget.animeId);
      final currentStatus =
          widget.detail.myListStatus?.status ?? WatchStatus.watching;
      _invalidateAll(currentStatus: currentStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from list')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.inList) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _busy ? null : _addToList,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add),
          label: const Text('Add to Watching'),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _busy ? null : _removeFromList,
        icon: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.delete_outline),
        label: const Text('Remove from List'),
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
            child: SelectableText(
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
        leading: AppCachedImage(
          imageUrl: node.mainPicture?.medium ?? '',
          width: 40,
          height: 56,
          borderRadius: BorderRadius.circular(4),
          fallbackSize: 16,
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
            // ── Studios ──
            if (extra.studios.isNotEmpty) ...[
              _buildStudios(theme, extra.studios),
            ],

            // ── Next Episode ──
            if (nextAiring != null) ...[
              _buildNextEpisode(theme, nextAiring),
            ],

            // ── External Links ──
            if (links.isNotEmpty) ...[
              _buildExternalLinks(theme, links),
            ],

            // ── Characters & Staff ──
            if (people.characters.isNotEmpty || people.staff.isNotEmpty) ...[
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

  Widget _buildExternalLinks(ThemeData theme, List<AniListExternalLink> links) {
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
              ...official.map(
                (l) => _LinkChip(
                  label: l.displaySite,
                  url: l.url,
                  icon: Icons.language,
                  color: theme.colorScheme.primaryContainer,
                  textColor: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              ...streaming.map(
                (l) => _LinkChip(
                  label: l.displaySite,
                  url: l.url,
                  icon: Icons.play_circle_outline,
                  color: theme.colorScheme.tertiaryContainer,
                  textColor: theme.colorScheme.onTertiaryContainer,
                ),
              ),
              ...social.map(
                (l) => _LinkChip(
                  label: l.displaySite,
                  url: l.url,
                  icon: Icons.public,
                  color: theme.colorScheme.secondaryContainer,
                  textColor: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharactersAndStaff(ThemeData theme, AniListAnimePeople people) {
    final charLimit = _showAllCharacters
        ? people.characters.length
        : _defaultLimit;
    final staffLimit = _showAllStaff ? people.staff.length : _defaultLimit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Characters
        if (people.characters.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'Characters & Voice Actors',
                style: theme.textTheme.titleSmall,
              ),
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
          ...people.staff.take(staffLimit).map((s) => _StaffTile(staff: s)),
        ],
      ],
    );
  }

  Widget _buildStudios(ThemeData theme, List<AniListStudio> studios) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Studios', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        ...studios.map((studio) => _StudioCard(studio: studio)),
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
                    SelectableText(
                      character.name,
                      maxLines: 1,
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
                          SelectableText(
                            va.name,
                            maxLines: 1,
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
                                color: theme.colorScheme.onSurfaceVariant,
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
        title: SelectableText(
          staff.name,
          maxLines: 1,
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
    return SizedBox(
      width: size,
      height: size,
      child: AppCachedImage(
        imageUrl: imageUrl ?? '',
        width: size,
        height: size,
        borderRadius: BorderRadius.circular(size / 2),
        fallbackIcon: fallbackIcon,
        fallbackSize: size * 0.45,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Notification Bell for airing anime
// ═══════════════════════════════════════════════════════════════════

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell({
    required this.animeId,
    required this.title,
    required this.nextAiring,
  });

  final int animeId;
  final String title;
  final AniListNextAiring nextAiring;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      animeNotificationProvider.select((s) => s.contains(animeId)),
    );

    return IconButton(
      icon: Icon(
        enabled ? Icons.notifications_active : Icons.notifications_none,
        color: enabled ? AppColors.starColor : AppColors.iconLight,
      ),
      onPressed: () async {
        final success = await ref
            .read(animeNotificationProvider.notifier)
            .toggle(
              animeId: animeId,
              title: title,
              episode: nextAiring.episode,
              airingAt: nextAiring.airingAt,
            );

        if (!context.mounted) return;

        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification permission denied'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        final nowEnabled = ref
            .read(animeNotificationProvider)
            .contains(animeId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nowEnabled
                  ? 'Notification enabled for Episode ${nextAiring.episode}'
                  : 'Notification disabled',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
}

class _StudioCard extends StatelessWidget {
  const _StudioCard({required this.studio});

  final AniListStudio studio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: Icon(
          Icons.business,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          studio.name,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: studio.isAnimationStudio
            ? Text(
                'Animation Studio',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              )
            : null,
        trailing: const Icon(Icons.chevron_right, size: 20),
        dense: true,
        visualDensity: VisualDensity.compact,
        onTap: () => context.pushNamed(
          'studioProfile',
          pathParameters: {'id': '${studio.id}'},
        ),
      ),
    );
  }
}
