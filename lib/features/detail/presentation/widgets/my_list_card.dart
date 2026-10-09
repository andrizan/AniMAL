import 'dart:async';

import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:animal/shared/widgets/section_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

IconData _statusIcon(WatchStatus status) => switch (status) {
  WatchStatus.watching => Icons.play_circle,
  WatchStatus.completed => Icons.check_circle,
  WatchStatus.onHold => Icons.pause_circle,
  WatchStatus.dropped => Icons.cancel,
  WatchStatus.planToWatch => Icons.bookmark,
};

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
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Change Status',
                    style: theme.textTheme.titleMedium,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final detail = widget.detail;
    final status = detail.myListStatus!;
    final watched = status.numEpisodesWatched ?? 0;
    final total = detail.numEpisodes != 0 ? detail.numEpisodes : null;
    final score = status.score ?? 0;

    return SectionCard(
      color: scheme.primaryContainer.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_statusIcon(status.status), color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  status.status.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: _busy ? null : () => _showStatusPicker(context),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Change'),
              ),
            ],
          ),
          if (total != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: (watched / total).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: scheme.surfaceContainerHigh,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          Row(
            children: [
              Icon(
                Icons.movie_outlined,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Episodes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
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
                      borderRadius: BorderRadius.circular(AppRadius.sm),
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
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add_circle_outline),
                onPressed: (_busy || (total != null && watched >= total))
                    ? null
                    : () => _updateEpisodes(watched + 1),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 20,
                color: AppColors.starColor,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('Score', style: theme.textTheme.bodyLarge)),
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
                        if (value != null) unawaited(_updateScore(value));
                      },
              ),
            ],
          ),
          const Divider(),
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
              style: TextButton.styleFrom(foregroundColor: scheme.error),
            ),
          ),
        ],
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
