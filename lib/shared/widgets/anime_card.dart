import 'dart:async';

import 'package:animal/core/constants/mal_endpoints.dart';
import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/core/utils/anime_labels.dart';
import 'package:animal/core/utils/date_utils.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/shared/providers/airing_entry.dart';
import 'package:animal/shared/providers/anime_notification_providers.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:animal/shared/widgets/app_cached_image.dart';
import 'package:animal/shared/widgets/countdown_badge.dart';
import 'package:animal/shared/widgets/score_picker.dart';
import 'package:animal/shared/widgets/status_chip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const _coverWidth = 84.0;
const _coverHeight = 120.0;
const _cardInset = 14.0;
const _titleTopInset = 10.0;
const double _infoRightInset = _cardInset - AppSpacing.xs;

/// Unified anime card used across all pages.
///
/// Layout: inset cover (left) + info (right). The card sizes to its content
/// so large text never clips. Supports the edit modal via the ⋮ button or a
/// long press.
class AnimeCard extends ConsumerWidget {
  const AnimeCard({
    required this.anime,
    super.key,
    this.header,
    this.trailing,
    this.nextAiring,
    this.rank,
    this.note,
    this.showListStatus = true,
    this.onTap,
  });

  final Anime anime;

  /// Optional line above the title, e.g. the airing time on the Airing page.
  final Widget? header;

  /// Optional trailing widget in the footer row (e.g. countdown).
  final Widget? trailing;

  /// Optional next airing info from AniList schedule.
  final AiringEntry? nextAiring;

  /// Optional ranking position shown on the cover.
  final int? rank;

  /// Optional muted note under the footer, e.g. why the card cannot open.
  final String? note;

  /// Whether to show the list status chip; off where the list is implied.
  final bool showListStatus;

  /// Optional tap callback. When provided, replaces the default navigation.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.labelMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );
    final jaTitle = anime.alternativeTitles?.ja;
    final list = anime.myListStatus;
    final total = (anime.numEpisodes ?? 0) > 0 ? anime.numEpisodes : null;
    final watched = list?.numEpisodesWatched;
    final personalScore = list?.score ?? 0;
    final time = _broadcastTime();
    final notifEnabled = ref.watch(
      animeNotificationProvider.select((s) => s.contains(anime.id)),
    );
    final title = Text(
      anime.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleMedium,
    );

    final stats = <Widget>[
      if (anime.mean case final mean?)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: 16,
              color: StatusColors.of(context).star,
            ),
            const SizedBox(width: 2),
            Text(mean.toStringAsFixed(1), style: theme.textTheme.labelLarge),
          ],
        ),
      if (personalScore > 0) _PersonalScore(score: personalScore),
      if (list != null && showListStatus)
        ListStatusChip(status: list.status, dense: true),
    ];

    final footer = <Widget>[
      if (nextAiring case final next?)
        CountdownBadge(airingAt: next.airingAt, episode: next.episode),
      ?trailing,
      if (notifEnabled && anime.status != 'finished_airing')
        Semantics(
          label: 'Reminder on',
          child: Icon(
            Icons.notifications_active,
            size: 16,
            color: StatusColors.of(context).star,
          ),
        ),
      if (time != null)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Text(time, style: muted),
          ],
        ),
    ];

    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.md / 2,
        horizontal: AppSpacing.page,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            onTap ??
            () => context.pushNamed(
              'animeDetail',
              pathParameters: {'id': '${anime.id}'},
            ),
        onLongPress: onTap != null ? null : () => _showUpdateModal(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            _cardInset,
            AppSpacing.xs,
            AppSpacing.xs,
            _cardInset,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: _titleTopInset),
                child: _Cover(anime: anime, rank: rank),
              ),
              const SizedBox(width: _cardInset),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: _titleTopInset),
                            child: header ?? title,
                          ),
                        ),
                        if (onTap == null)
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 20,
                              tooltip: 'Edit list entry',
                              icon: Icon(
                                Icons.more_vert,
                                color: scheme.onSurfaceVariant,
                              ),
                              onPressed: () => _showUpdateModal(context),
                            ),
                          )
                        else
                          const SizedBox(width: _infoRightInset),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: _infoRightInset),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (header != null) title,
                          if (jaTitle != null && jaTitle.isNotEmpty)
                            Text(
                              jaTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          if (stats.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.xs,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: stats,
                            ),
                          ],
                          if (list != null && total != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: ((watched ?? 0) / total).clamp(
                                      0.0,
                                      1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                    semanticsLabel:
                                        '${watched ?? 0} of $total '
                                        'episodes watched',
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm + 2),
                                Text(
                                  '${watched ?? 0} / $total',
                                  style: muted?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ] else if (list != null && watched != null) ...[
                            const SizedBox(height: 6),
                            Text('$watched eps watched', style: muted),
                          ] else if (list == null) ...[
                            if (_meta(total) case final meta?) ...[
                              const SizedBox(height: 6),
                              Text(meta, style: muted),
                            ],
                          ],
                          if (footer.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.xs,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: footer,
                            ),
                          ],
                          if (note case final note?) ...[
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(child: Text(note, style: muted)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _meta(int? total) {
    final parts = [
      AnimeLabels.mediaTypeLabel(anime.mediaType),
      if (total != null) '$total eps',
      AnimeLabels.statusLabel(anime.status),
    ].where((p) => p.isNotEmpty);
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// The air time shown in the footer. It comes from [resolveAirSlot], the
  /// same function the detail page uses, so a card and its detail page never
  /// show different times: the next AniList airing wins over the MAL slot.
  String? _broadcastTime() {
    final broadcast = anime.broadcast;
    final start = broadcast?.startTime;
    final slot = resolveAirSlot(
      nextAiringAt: nextAiring?.airingAt,
      jstDay: broadcast?.dayOfWeek,
      jstTime: start,
    );
    if (slot != null) return shortAirSlotLabel(slot);
    if (start == null || start.isEmpty) return null;
    return convertJstToLocal(start);
  }

  void _showUpdateModal(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (ctx) {
          return _UpdateListStatusModal(anime: anime, nextAiring: nextAiring);
        },
      ),
    );
  }
}

/// The user's own score as a small primary pill.
class _PersonalScore extends StatelessWidget {
  const _PersonalScore({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'You $score',
        style: theme.textTheme.labelMedium?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Modal content for updating an anime's list status.
class _UpdateListStatusModal extends ConsumerStatefulWidget {
  const _UpdateListStatusModal({required this.anime, required this.nextAiring});

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
            .contains(widget.anime.id);
        if (enabled) {
          unawaited(
            ref
                .read(animeNotificationProvider.notifier)
                .removeAnime(widget.anime.id),
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
      if (_selectedStatus != WatchStatus.watching) {
        await ref
            .read(animeNotificationProvider.notifier)
            .removeAnime(widget.anime.id);
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final jaTitle = widget.anime.alternativeTitles?.ja;
    final totalEps = widget.anime.numEpisodes != 0
        ? widget.anime.numEpisodes
        : null;
    final notifEnabled = ref.watch(
      animeNotificationProvider.select((s) => s.contains(widget.anime.id)),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.anime.title,
              style: theme.textTheme.titleLarge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (jaTitle != null && jaTitle.isNotEmpty)
              Text(
                jaTitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

            if (widget.nextAiring != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.card - 4),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(
                        notifEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_none,
                        size: 20,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notify me before Ep ${widget.nextAiring!.episode}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${ApiConstants.notificationLeadMinutes} minutes '
                            'ahead',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: notifEnabled,
                      onChanged: _saving
                          ? null
                          : (value) async {
                              final episode = widget.nextAiring!.episode;
                              final result = await ref
                                  .read(animeNotificationProvider.notifier)
                                  .toggle(
                                    animeId: widget.anime.id,
                                    title: widget.anime.title,
                                    episode: episode,
                                    airingAt: widget.nextAiring!.airingAt,
                                  );
                              if (!result.changedState && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result.message(episode)),
                                  ),
                                );
                              }
                            },
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
            const _SheetLabel('Status'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
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
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'Completed can only be set for finished anime',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),

            const SizedBox(height: AppSpacing.lg),
            const _SheetLabel('Episodes Watched'),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'One episode less',
                  icon: const Icon(Icons.remove),
                  onPressed: (_saving || _selectedEps <= 0)
                      ? null
                      : () {
                          setState(() => _selectedEps--);
                          _epsController.text = '$_selectedEps';
                        },
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextField(
                    controller: _epsController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    enabled: !_saving,
                    style: theme.textTheme.titleMedium,
                    decoration: InputDecoration(
                      suffixText: totalEps != null ? '/ $totalEps' : null,
                    ),
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null && parsed >= 0) {
                        setState(() => _selectedEps = parsed);
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                IconButton.filledTonal(
                  tooltip: 'One episode more',
                  icon: const Icon(Icons.add),
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

            const SizedBox(height: AppSpacing.lg),
            const _SheetLabel('Score'),
            const SizedBox(height: AppSpacing.sm),
            ScorePicker(
              value: _selectedScore,
              enabled: !_saving,
              onChanged: (v) => setState(() => _selectedScore = v),
            ),

            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 56,
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

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// Inset cover with rounded corners and an optional rank badge.
class _Cover extends StatelessWidget {
  const _Cover({required this.anime, this.rank});

  final Anime anime;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.cover),
      child: SizedBox(
        width: _coverWidth,
        height: _coverHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppCachedImage(
              imageUrl: anime.mainPicture?.medium ?? '',
              fallbackSize: 20,
              memCacheWidth: 252,
            ),
            if (rank case final rank?)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.overlayDarker,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '#$rank',
                    semanticsLabel: 'Rank $rank',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.iconLight,
                      fontWeight: FontWeight.w700,
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
