import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/core/utils/anime_labels.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/shared/widgets/info_chip.dart';
import 'package:material_ui/material_ui.dart';

typedef ChipColors = ({Color background, Color foreground});

/// Status is never told by colour alone: every chip pairs its tint with an
/// icon and a word.
IconData listStatusIcon(WatchStatus status) => switch (status) {
  WatchStatus.watching => Icons.play_arrow_rounded,
  WatchStatus.completed => Icons.check_rounded,
  WatchStatus.onHold => Icons.pause_rounded,
  WatchStatus.dropped => Icons.close_rounded,
  WatchStatus.planToWatch => Icons.bookmark_rounded,
};

ChipColors listStatusColors(BuildContext context, WatchStatus status) {
  final colors = StatusColors.of(context);
  return switch (status) {
    WatchStatus.watching => (
      background: colors.airingContainer,
      foreground: colors.onAiringContainer,
    ),
    WatchStatus.completed => (
      background: colors.finishedContainer,
      foreground: colors.onFinishedContainer,
    ),
    WatchStatus.onHold => (
      background: colors.upcomingContainer,
      foreground: colors.onUpcomingContainer,
    ),
    WatchStatus.dropped => (
      background: colors.droppedContainer,
      foreground: colors.onDroppedContainer,
    ),
    WatchStatus.planToWatch => (
      background: colors.planContainer,
      foreground: colors.onPlanContainer,
    ),
  };
}

IconData airingStatusIcon(String? status) => switch (status) {
  'currently_airing' => Icons.sensors_rounded,
  'finished_airing' => Icons.check_circle_outline_rounded,
  'not_yet_aired' => Icons.schedule_rounded,
  _ => Icons.info_outline_rounded,
};

ChipColors airingStatusColors(BuildContext context, String? status) {
  final colors = StatusColors.of(context);
  return switch (status) {
    'currently_airing' => (
      background: colors.airingContainer,
      foreground: colors.onAiringContainer,
    ),
    'finished_airing' => (
      background: colors.finishedContainer,
      foreground: colors.onFinishedContainer,
    ),
    'not_yet_aired' => (
      background: colors.upcomingContainer,
      foreground: colors.onUpcomingContainer,
    ),
    _ => (background: colors.planContainer, foreground: colors.onPlanContainer),
  };
}

class ListStatusChip extends StatelessWidget {
  const ListStatusChip({required this.status, super.key, this.dense = false});

  final WatchStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = listStatusColors(context, status);
    return InfoChip(
      label: status.label,
      icon: listStatusIcon(status),
      color: colors.foreground,
      background: colors.background,
      dense: dense,
    );
  }
}

class AiringStatusChip extends StatelessWidget {
  const AiringStatusChip({required this.status, super.key, this.dense = false});

  final String? status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = airingStatusColors(context, status);
    return InfoChip(
      label: AnimeLabels.statusLabel(status),
      icon: airingStatusIcon(status),
      color: colors.foreground,
      background: colors.background,
      dense: dense,
    );
  }
}
