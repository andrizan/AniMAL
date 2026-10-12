import 'package:animal/core/theme/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

/// A [TabBar] drawn as pills on a tonal track. The selected pill comes from
/// `tabBarTheme`; [segmented] swaps it for a raised card pill with the
/// primary label, used by the season picker.
class PillTabBar extends StatelessWidget {
  const PillTabBar({
    required this.controller,
    required this.tabs,
    super.key,
    this.scrollable = true,
    this.segmented = false,
  });

  final TabController controller;
  final List<Widget> tabs;
  final bool scrollable;
  final bool segmented;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = segmented ? AppRadius.card : AppRadius.pill;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: TabBar(
        controller: controller,
        tabs: tabs,
        isScrollable: scrollable,
        tabAlignment: scrollable ? TabAlignment.start : TabAlignment.fill,
        padding: EdgeInsets.zero,
        indicator: segmented
            ? BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(radius - AppSpacing.xs),
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
            ? theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)
            : null,
        unselectedLabelStyle: segmented ? theme.textTheme.labelSmall : null,
        labelPadding: segmented ? EdgeInsets.zero : null,
      ),
    );
  }
}
