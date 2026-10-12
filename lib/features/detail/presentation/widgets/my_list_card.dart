import 'dart:async';

import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:animal/shared/widgets/score_picker.dart';
import 'package:animal/shared/widgets/section_card.dart';
import 'package:animal/shared/widgets/status_chip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class MyListCard extends ConsumerStatefulWidget {
  const MyListCard({
    required this.detail,
    required this.onUpdated,
    required this.onRemoved,
    super.key,
  });

  final AnimeDetail detail;
  final void Function(MyListStatus updatedStatus) onUpdated;
  final VoidCallback onRemoved;

  @override
  ConsumerState<MyListCard> createState() => _MyListCardState();
}

class _MyListCardState extends ConsumerState<MyListCard> {
  bool _busy = false;

  Future<void> _save({
    required Future<MyListStatus> Function(AnimeRepository repo) update,
    required String Function() message,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final updated = await update(ref.read(animeRepositoryProvider));
      if (!mounted) return;
      widget.onUpdated(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message()),
          duration: const Duration(seconds: 2),
        ),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _updateEpisodes(int newCount) => _save(
    update: (repo) => repo.updateAnimeListStatus(
      widget.detail.id,
      numWatchedEpisodes: newCount,
    ),
    message: () => 'Episodes updated to $newCount',
  );

  Future<void> _updateScore(int newScore) => _save(
    update: (repo) =>
        repo.updateAnimeListStatus(widget.detail.id, score: newScore),
    message: () => newScore == 0 ? 'Score cleared' : 'Score set to $newScore',
  );

  Future<void> _changeStatus(WatchStatus newStatus) {
    final totalEps = widget.detail.numEpisodes != 0
        ? widget.detail.numEpisodes
        : null;
    final completing = newStatus == WatchStatus.completed && totalEps != null;
    return _save(
      update: (repo) => repo.updateAnimeListStatus(
        widget.detail.id,
        status: newStatus,
        numWatchedEpisodes: completing ? totalEps : null,
      ),
      message: () => 'Status changed to ${newStatus.label}',
    );
  }

  Future<void> _remove() async {
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
      await ref
          .read(animeRepositoryProvider)
          .deleteAnimeFromList(widget.detail.id);
      widget.onRemoved();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Removed from list')));
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to remove: $e')));
      }
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    0,
                    AppSpacing.page,
                    AppSpacing.sm,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Change Status',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
                for (final s in WatchStatus.values)
                  Builder(
                    builder: (context) {
                      final disabled =
                          _busy || (s == WatchStatus.completed && !isFinished);
                      final colors = listStatusColors(context, s);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.page,
                        ),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: colors.background,
                          child: Icon(
                            listStatusIcon(s),
                            size: 20,
                            color: colors.foreground,
                          ),
                        ),
                        title: Text(
                          s.label,
                          style: TextStyle(
                            color: disabled
                                ? theme.colorScheme.onSurfaceVariant
                                : null,
                          ),
                        ),
                        subtitle: disabled && s == WatchStatus.completed
                            ? Text(
                                'Only available for finished anime',
                                style: theme.textTheme.bodySmall,
                              )
                            : null,
                        trailing: s == widget.detail.myListStatus!.status
                            ? Icon(
                                Icons.check,
                                color: theme.colorScheme.primary,
                              )
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
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showScorePicker(BuildContext context) {
    final theme = Theme.of(context);
    final score = widget.detail.myListStatus!.score ?? 0;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              0,
              AppSpacing.page,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your score', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.lg),
                ScorePicker(
                  value: score,
                  onChanged: (value) {
                    Navigator.pop(ctx);
                    unawaited(_updateScore(value));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final detail = widget.detail;
    final status = detail.myListStatus!;
    final watched = status.numEpisodesWatched ?? 0;
    final total = detail.numEpisodes != 0 ? detail.numEpisodes : null;
    final score = status.score ?? 0;
    final statusColors = listStatusColors(context, status.status);
    final canAdvance = total == null || watched < total;

    return SectionCard(
      title: 'Your list',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _PickerButton(
                  tooltip: 'Change status',
                  icon: listStatusIcon(status.status),
                  label: status.status.label,
                  background: statusColors.background,
                  foreground: statusColors.foreground,
                  onTap: _busy ? null : () => _showStatusPicker(context),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _PickerButton(
                  tooltip: 'Change score',
                  icon: Icons.star_rounded,
                  iconColor: StatusColors.of(context).star,
                  label: 'Score',
                  value: score == 0 ? 'None' : '$score',
                  background: scheme.surfaceContainer,
                  foreground: scheme.onSurface,
                  onTap: _busy ? null : () => _showScorePicker(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Episodes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                total != null ? '$watched / $total' : '$watched',
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
          if (total != null) ...[
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: (watched / total).clamp(0.0, 1.0),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              semanticsLabel: '$watched of $total episodes watched',
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: 'One episode less',
                icon: const Icon(Icons.remove),
                onPressed: (_busy || watched <= 0)
                    ? null
                    : () => _updateEpisodes(watched - 1),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: (_busy || !canAdvance)
                      ? null
                      : () => _updateEpisodes(watched + 1),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                  ),
                  child: Text(
                    canAdvance
                        ? 'Mark episode ${watched + 1} watched'
                        : 'All episodes watched',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              IconButton.filledTonal(
                tooltip: 'One episode more',
                icon: const Icon(Icons.add),
                onPressed: (_busy || !canAdvance)
                    ? null
                    : () => _updateEpisodes(watched + 1),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _busy ? null : _remove,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              label: const Text('Remove from List'),
              style: TextButton.styleFrom(
                foregroundColor: scheme.error,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A pill button that opens a picker sheet: icon, label, optional value.
class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.tooltip,
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.iconColor,
    this.value,
  });

  final String tooltip;
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String? value;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.pill);
    final style = theme.textTheme.labelLarge?.copyWith(color: foreground);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: iconColor ?? foreground),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style,
                    ),
                  ),
                  if (value != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      value!,
                      style: style?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                  const SizedBox(width: AppSpacing.xs),
                  Icon(Icons.expand_more_rounded, size: 18, color: foreground),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AddToListButton extends ConsumerStatefulWidget {
  const AddToListButton({
    required this.animeId,
    required this.onAdded,
    super.key,
  });

  final int animeId;
  final void Function(MyListStatus updatedStatus) onAdded;

  @override
  ConsumerState<AddToListButton> createState() => _AddToListButtonState();
}

class _AddToListButtonState extends ConsumerState<AddToListButton> {
  bool _busy = false;

  Future<void> _add() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final updated = await ref
          .read(animeRepositoryProvider)
          .updateAnimeListStatus(widget.animeId, status: WatchStatus.watching);
      widget.onAdded(updated);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Added to Watching')));
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to add: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: _busy ? null : _add,
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
}
