import 'package:material_ui/material_ui.dart';

/// A tonal filled button. The filled-button theme reserves its focus ring
/// colour for the primary fill, so the tonal variant brings its own.
class TonalButton extends StatelessWidget {
  const TonalButton({
    required this.onPressed,
    required this.child,
    super.key,
    this.style,
  });

  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ring = ButtonStyle(
      side: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? BorderSide(color: primary, width: 3)
            : null,
      ),
    );
    return FilledButton.tonal(
      onPressed: onPressed,
      style: style == null ? ring : ring.merge(style),
      child: child,
    );
  }
}
