import 'package:animal/core/theme/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

/// Ten score pills in two rows. Tapping the selected score clears it (0).
class ScorePicker extends StatelessWidget {
  const ScorePicker({
    required this.value,
    required this.onChanged,
    super.key,
    this.enabled = true,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final start in const [1, 6]) ...[
          if (start > 1) const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (var n = start; n < start + 5; n++) ...[
                if (n > start) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ScorePill(score: n, picker: this),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(
          value == 0 ? 'Not rated' : 'Tap the score again to clear it',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score, required this.picker});

  final int score;
  final ScorePicker picker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = score == picker.value;
    final radius = BorderRadius.circular(AppRadius.pill);

    return Semantics(
      button: true,
      selected: selected,
      label: 'Score $score',
      excludeSemantics: true,
      child: Material(
        color: selected ? scheme.primary : scheme.surfaceContainer,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: picker.enabled
              ? () => picker.onChanged(selected ? 0 : score)
              : null,
          child: SizedBox(
            height: 44,
            child: Center(
              child: Text(
                '$score',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
