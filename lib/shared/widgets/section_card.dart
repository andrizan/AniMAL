import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/shared/widgets/section_header.dart';
import 'package:material_ui/material_ui.dart';

/// A titled block on a page: the card look from `cardTheme` with the larger
/// `AppRadius.hero` corners that section blocks use.
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.child,
    super.key,
    this.title,
    this.trailing,
    this.color,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final String? title;
  final String? trailing;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.hero),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              SectionHeader(title!, trailing: trailing, bottomPadding: 16),
            child,
          ],
        ),
      ),
    );
  }
}
