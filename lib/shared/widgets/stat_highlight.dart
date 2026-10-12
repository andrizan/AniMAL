import 'package:animal/core/theme/app_colors.dart';
import 'package:material_ui/material_ui.dart';

class StatHighlight extends StatelessWidget {
  const StatHighlight({
    required this.value,
    required this.label,
    super.key,
    this.icon,
  });

  final String value;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: StatusColors.of(context).star),
                const SizedBox(width: 3),
              ],
              Text(value, style: theme.textTheme.headlineSmall),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
