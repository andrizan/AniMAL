import 'package:animal/core/theme/app_colors.dart';
import 'package:material_ui/material_ui.dart';

/// A 48px circular icon button on a dark scrim, for controls that sit on
/// top of imagery. White on the scrim reads at 7:1 even over a white cover.
class ScrimIconButton extends StatelessWidget {
  const ScrimIconButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.tooltip,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 48,
        height: 48,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.overlayDarker,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            tooltip: tooltip,
            icon: Icon(icon, color: color ?? AppColors.iconLight),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
