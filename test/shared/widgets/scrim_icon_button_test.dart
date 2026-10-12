import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/shared/widgets/scrim_icon_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _show(
  WidgetTester tester, {
  VoidCallback? onPressed,
  String? tooltip,
  Color? color,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: ScrimIconButton(
        icon: Icons.arrow_back_rounded,
        tooltip: tooltip,
        color: color,
        onPressed: onPressed,
      ),
    ),
  ),
);

void main() {
  testWidgets('is a 48px circle on the dark scrim', (tester) async {
    await _show(tester, onPressed: () {});

    final box = find
        .descendant(
          of: find.byType(ScrimIconButton),
          matching: find.byType(SizedBox),
        )
        .first;
    expect(tester.getSize(box), const Size(48, 48));

    final decoration =
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(ScrimIconButton),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;
    expect(decoration.color, AppColors.overlayDarker);
    expect(decoration.shape, BoxShape.circle);
  });

  testWidgets('draws a white icon by default and honours a custom colour', (
    tester,
  ) async {
    await _show(tester, onPressed: () {});
    expect(
      tester.widget<Icon>(find.byIcon(Icons.arrow_back_rounded)).color,
      AppColors.iconLight,
    );

    await _show(tester, onPressed: () {}, color: const Color(0xFF123456));
    expect(
      tester.widget<Icon>(find.byIcon(Icons.arrow_back_rounded)).color,
      const Color(0xFF123456),
    );
  });

  testWidgets('shows its tooltip', (tester) async {
    await _show(tester, onPressed: () {}, tooltip: 'Back');

    expect(find.byTooltip('Back'), findsOneWidget);
  });

  testWidgets('calls onPressed when tapped', (tester) async {
    var taps = 0;
    await _show(tester, onPressed: () => taps++);

    await tester.tap(find.byType(IconButton));

    expect(taps, 1);
  });

  testWidgets('is disabled without a callback', (tester) async {
    await _show(tester);

    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );
  });
}
