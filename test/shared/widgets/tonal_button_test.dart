import 'package:animal/shared/widgets/tonal_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _show(
  WidgetTester tester, {
  VoidCallback? onPressed,
  ButtonStyle? style,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: Center(
        child: TonalButton(
          onPressed: onPressed,
          style: style,
          child: const Text('Go'),
        ),
      ),
    ),
  ),
);

BorderSide _edge(WidgetTester tester) {
  final material = tester.widget<Material>(
    find
        .descendant(
          of: find.byType(TonalButton),
          matching: find.byType(Material),
        )
        .first,
  );
  return (material.shape! as OutlinedBorder).side;
}

void main() {
  testWidgets('shows its child and calls onPressed', (tester) async {
    var taps = 0;
    await _show(tester, onPressed: () => taps++);

    await tester.tap(find.text('Go'));

    expect(find.text('Go'), findsOneWidget);
    expect(taps, 1);
  });

  testWidgets('is a tonal filled button, not the primary one', (tester) async {
    await _show(tester, onPressed: () {});
    final scheme = Theme.of(tester.element(find.text('Go'))).colorScheme;

    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(TonalButton),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.color, isNot(scheme.primary));
  });

  testWidgets('is disabled without a callback', (tester) async {
    await _show(tester);

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('draws a 3px primary ring only while focused', (tester) async {
    await _show(tester, onPressed: () {});
    final scheme = Theme.of(tester.element(find.text('Go'))).colorScheme;
    expect(_edge(tester).width, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(_edge(tester).width, 3);
    expect(_edge(tester).color, scheme.primary);
  });

  testWidgets('keeps the ring when a custom style is merged in', (
    tester,
  ) async {
    await _show(
      tester,
      onPressed: () {},
      style: FilledButton.styleFrom(minimumSize: const Size(200, 60)),
    );

    expect(tester.getSize(find.byType(FilledButton)).width, 200);
    expect(tester.getSize(find.byType(FilledButton)).height, 60);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(_edge(tester).width, 3);
  });
}
