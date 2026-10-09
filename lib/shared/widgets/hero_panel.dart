import 'package:animal/core/theme/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

class HeroPanel extends StatelessWidget {
  const HeroPanel({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(20),
  });

  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.hero),
        border: Border.all(color: scheme.outlineVariant),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.surfaceContainer],
        ),
      ),
      child: child,
    );
  }
}
