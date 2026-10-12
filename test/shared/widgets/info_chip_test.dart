import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/shared/widgets/info_chip.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _show(WidgetTester tester, Widget chip, {double? width}) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: width == null ? chip : SizedBox(width: width, child: chip),
          ),
        ),
      ),
    );

BoxDecoration _decoration(WidgetTester tester) =>
    tester
            .widget<Container>(
              find.descendant(
                of: find.byType(InfoChip),
                matching: find.byType(Container),
              ),
            )
            .decoration!
        as BoxDecoration;

TextStyle _labelStyle(WidgetTester tester) =>
    tester.widget<Text>(find.byType(Text)).style!;

void main() {
  testWidgets('is a tonal pill by default', (tester) async {
    await _show(tester, const InfoChip(label: 'TV'));
    final scheme = Theme.of(tester.element(find.text('TV'))).colorScheme;

    expect(find.text('TV'), findsOneWidget);
    expect(_decoration(tester).color, scheme.surfaceContainer);
    expect(
      _decoration(tester).borderRadius,
      BorderRadius.circular(AppRadius.pill),
    );
    expect(_labelStyle(tester).color, scheme.onSurface);
    expect(_labelStyle(tester).fontWeight, FontWeight.w600);
  });

  testWidgets('takes a custom foreground and background', (tester) async {
    await _show(
      tester,
      const InfoChip(
        label: 'Airing',
        color: Color(0xFF0B5140),
        background: Color(0xFFDAF3EA),
      ),
    );

    expect(_decoration(tester).color, const Color(0xFFDAF3EA));
    expect(_labelStyle(tester).color, const Color(0xFF0B5140));
  });

  testWidgets('draws the icon in the foreground colour', (tester) async {
    await _show(
      tester,
      const InfoChip(label: 'Airing', icon: Icons.sensors, color: Colors.red),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.sensors));
    expect(icon.color, Colors.red);
    expect(icon.size, 16);
  });

  testWidgets('has no icon unless one is given', (tester) async {
    await _show(tester, const InfoChip(label: 'TV'));

    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('dense is smaller in text, icon and padding', (tester) async {
    await _show(tester, const InfoChip(label: 'TV', icon: Icons.tv));
    final regularSize = _labelStyle(tester).fontSize!;
    final regularHeight = tester.getSize(find.byType(InfoChip)).height;

    await _show(
      tester,
      const InfoChip(label: 'TV', icon: Icons.tv, dense: true),
    );

    expect(_labelStyle(tester).fontSize!, lessThan(regularSize));
    expect(tester.widget<Icon>(find.byIcon(Icons.tv)).size, 12);
    expect(
      tester.getSize(find.byType(InfoChip)).height,
      lessThan(regularHeight),
    );
  });

  testWidgets('an icon pulls the left padding in, a bare label does not', (
    tester,
  ) async {
    await _show(tester, const InfoChip(label: 'TV'));
    final bare = tester.widget<Container>(find.byType(Container)).padding!;

    await _show(tester, const InfoChip(label: 'TV', icon: Icons.tv));
    final withIcon = tester.widget<Container>(find.byType(Container)).padding!;

    expect(
      bare.resolve(TextDirection.ltr).left -
          withIcon.resolve(TextDirection.ltr).left,
      AppSpacing.xs,
    );
  });

  testWidgets('a long label shrinks with an ellipsis instead of overflowing', (
    tester,
  ) async {
    await _show(
      tester,
      const Row(
        children: [
          Flexible(
            child: InfoChip(
              label: 'A very long label that cannot possibly fit in the row',
              icon: Icons.tv,
            ),
          ),
        ],
      ),
      width: 120,
    );

    expect(tester.takeException(), isNull);
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });
}
