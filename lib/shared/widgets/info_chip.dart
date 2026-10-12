import 'package:animal/core/theme/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

/// A pill with an optional leading icon. Tonal by default; pass a
/// [background] and [color] pair for a status tint. [dense] is the card size.
class InfoChip extends StatelessWidget {
  const InfoChip({
    required this.label,
    super.key,
    this.icon,
    this.color,
    this.background,
    this.dense = false,
  });

  final IconData? icon;
  final String label;
  final Color? color;
  final Color? background;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = color ?? theme.colorScheme.onSurface;
    final textStyle = dense
        ? theme.textTheme.labelMedium
        : theme.textTheme.labelLarge;
    final horizontal = dense ? 10.0 : 14.0;
    final leading = icon == null ? horizontal : horizontal - AppSpacing.xs;

    return Container(
      padding: EdgeInsets.fromLTRB(
        leading,
        dense ? 3 : 6,
        horizontal,
        dense ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: background ?? theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 16, color: foreground),
            SizedBox(width: dense ? AppSpacing.xs : 6),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
