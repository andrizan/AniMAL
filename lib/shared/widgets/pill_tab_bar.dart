import 'package:animal/core/theme/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

/// A [TabBar] drawn as pills: the selected tab gets the primary pill from
/// `tabBarTheme`, every other tab its own tonal pill. [segmented] swaps that
/// for a tonal track with a raised card pill and the primary label, used by
/// the season picker. Tabs stay real [Tab] widgets.
class PillTabBar extends StatelessWidget {
  const PillTabBar({
    required this.controller,
    required this.labels,
    super.key,
    this.icons,
    this.scrollable = true,
    this.segmented = false,
  }) : assert(
         icons == null || icons.length == labels.length,
         'one icon per label',
       );

  final TabController controller;
  final List<String> labels;
  final List<IconData>? icons;
  final bool scrollable;
  final bool segmented;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final animation =
        controller.animation ?? const AlwaysStoppedAnimation<double>(0);
    final sidePadding = segmented
        ? EdgeInsets.zero
        : const EdgeInsets.symmetric(horizontal: AppSpacing.xs);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final current = animation.value.round();
        final bar = TabBar(
          controller: controller,
          isScrollable: scrollable,
          tabAlignment: scrollable ? TabAlignment.start : TabAlignment.fill,
          padding: EdgeInsets.zero,
          labelPadding: sidePadding,
          indicatorPadding: sidePadding,
          indicator: segmented
              ? BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(
                    AppRadius.card - AppSpacing.xs,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                )
              : null,
          labelColor: segmented ? scheme.primary : null,
          unselectedLabelColor: segmented ? scheme.onSurfaceVariant : null,
          labelStyle: segmented
              ? theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                )
              : null,
          unselectedLabelStyle: segmented ? theme.textTheme.labelSmall : null,
          tabs: [
            for (final (i, label) in labels.indexed)
              Tab(
                height: segmented ? 60 : 40,
                child: _PillTab(
                  label: label,
                  icon: icons?[i],
                  filled: !segmented && i != current,
                ),
              ),
          ],
        );

        if (!segmented) return bar;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: bar,
        );
      },
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab({required this.label, required this.filled, this.icon});

  final String label;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: icon == null ? AppSpacing.lg : AppSpacing.md,
      ),
      decoration: filled
          ? BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            )
          : null,
      child: icon == null
          ? Text(label)
          : Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20),
                const SizedBox(height: 2),
                Text(label),
              ],
            ),
    );
  }
}
