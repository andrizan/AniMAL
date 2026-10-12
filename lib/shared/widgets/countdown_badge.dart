import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/shared/providers/clock_provider.dart';
import 'package:animal/shared/widgets/info_chip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// A live countdown badge driven by the shared [clockProvider].
///
/// Shows the remaining time until [airingAt], prefixed with the [episode]
/// number unless [showEpisode] is false. Once the air time has passed it
/// shows "Aired". Under six hours it switches to the alert icon and the
/// dropped tint, so urgency is not carried by colour alone.
class CountdownBadge extends ConsumerWidget {
  const CountdownBadge({
    required this.airingAt,
    required this.episode,
    super.key,
    this.showEpisode = true,
  });

  final DateTime airingAt;
  final int episode;
  final bool showEpisode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref
        .watch(clockProvider)
        .maybeWhen(data: (t) => t.toUtc(), orElse: DateTime.now().toUtc);
    final remaining = airingAt.toUtc().difference(now).inSeconds;
    final scheme = Theme.of(context).colorScheme;
    final colors = StatusColors.of(context);
    final prefix = showEpisode ? 'Ep $episode · ' : '';

    if (remaining <= 0) {
      return InfoChip(
        dense: true,
        icon: Icons.check_rounded,
        label: '${prefix}Aired',
        color: colors.onPlanContainer,
        background: colors.planContainer,
      );
    }

    final isUrgent = remaining < 21600;
    return InfoChip(
      dense: true,
      icon: isUrgent ? Icons.warning_amber_rounded : Icons.schedule_rounded,
      label: '${prefix}in ${_formatCountdown(remaining)}',
      color: isUrgent ? colors.onDroppedContainer : scheme.onPrimaryContainer,
      background: isUrgent ? colors.droppedContainer : scheme.primaryContainer,
    );
  }

  String _formatCountdown(int seconds) {
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}
