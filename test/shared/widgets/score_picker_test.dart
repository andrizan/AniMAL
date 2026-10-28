import 'dart:ui' show Tristate;

import 'package:animal/shared/widgets/score_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _show(
  WidgetTester tester, {
  required ValueChanged<int> onChanged,
  int value = 0,
  bool enabled = true,
  String? label,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ScorePicker(
          value: value,
          onChanged: onChanged,
          enabled: enabled,
          label: label,
        ),
      ),
    ),
  ),
);

Color? _pillColor(WidgetTester tester, int score) => tester
    .widget<Material>(
      find
          .ancestor(of: find.text('$score'), matching: find.byType(Material))
          .first,
    )
    .color;

void main() {
  group('layout', () {
    testWidgets('shows scores 1 to 10 in two rows of five', (tester) async {
      await _show(tester, onChanged: (_) {});

      for (var n = 1; n <= 10; n++) {
        expect(find.text('$n'), findsOneWidget, reason: '$n');
      }
      double top(int n) => tester.getTopLeft(find.text('$n')).dy;
      expect(top(1), top(5));
      expect(top(6), top(10));
      expect(top(6), greaterThan(top(5)));
      expect(
        tester.getTopLeft(find.text('1')).dx,
        lessThan(tester.getTopLeft(find.text('2')).dx),
      );
    });

    testWidgets('every pill is at least 44px tall', (tester) async {
      await _show(tester, onChanged: (_) {});

      for (var n = 1; n <= 10; n++) {
        final pill = find
            .ancestor(of: find.text('$n'), matching: find.byType(InkWell))
            .first;
        expect(tester.getSize(pill).height, greaterThanOrEqualTo(44));
      }
    });
  });

  group('selection', () {
    testWidgets('highlights only the current score', (tester) async {
      await _show(tester, value: 7, onChanged: (_) {});
      final scheme = Theme.of(tester.element(find.text('7'))).colorScheme;

      expect(_pillColor(tester, 7), scheme.primary);
      expect(_pillColor(tester, 6), scheme.surfaceContainer);
      expect(_pillColor(tester, 8), scheme.surfaceContainer);
    });

    testWidgets('highlights nothing when the anime is not rated', (
      tester,
    ) async {
      await _show(tester, onChanged: (_) {});
      final scheme = Theme.of(tester.element(find.text('7'))).colorScheme;

      for (var n = 1; n <= 10; n++) {
        expect(_pillColor(tester, n), scheme.surfaceContainer, reason: '$n');
      }
    });

    testWidgets('reports the tapped score', (tester) async {
      final picked = <int>[];
      await _show(tester, onChanged: picked.add);

      await tester.tap(find.text('4'));
      await tester.tap(find.text('10'));
      await tester.tap(find.text('1'));

      expect(picked, [4, 10, 1]);
    });

    testWidgets('tapping the current score clears it', (tester) async {
      final picked = <int>[];
      await _show(tester, value: 7, onChanged: picked.add);

      await tester.tap(find.text('7'));
      await tester.tap(find.text('8'));

      expect(picked, [0, 8]);
    });

    testWidgets('ignores taps while disabled', (tester) async {
      final picked = <int>[];
      await _show(tester, value: 7, enabled: false, onChanged: picked.add);

      await tester.tap(find.text('3'));
      await tester.tap(find.text('7'));

      expect(picked, isEmpty);
    });
  });

  group('caption', () {
    testWidgets('says the anime is not rated', (tester) async {
      await _show(tester, onChanged: (_) {});

      expect(find.text('Not rated'), findsOneWidget);
      expect(find.text('Tap the score again to clear it'), findsNothing);
    });

    testWidgets('explains how to clear a score', (tester) async {
      await _show(tester, value: 5, onChanged: (_) {});

      expect(find.text('Tap the score again to clear it'), findsOneWidget);
      expect(find.text('Not rated'), findsNothing);
    });
  });

  group('label', () {
    testWidgets('puts the hint beside the label, above the pills', (
      tester,
    ) async {
      await _show(tester, value: 5, onChanged: (_) {}, label: 'Score');

      final label = tester.getRect(find.text('Score'));
      final hint = tester.getRect(find.text('Tap the score again to clear it'));
      final firstPill = tester.getRect(find.text('1'));
      expect(hint.top, lessThan(firstPill.top));
      expect(label.top, lessThan(firstPill.top));
      expect(label.right, lessThan(hint.left));
      expect(
        (label.center.dy - hint.center.dy).abs(),
        lessThan(8),
        reason: 'the label and its hint share a line',
      );
    });

    testWidgets('is shorter than the hint-below layout by one line', (
      tester,
    ) async {
      await _show(tester, onChanged: (_) {});
      final below = tester.getSize(find.byType(ScorePicker)).height;

      await _show(tester, onChanged: (_) {}, label: 'Score');
      final beside = tester.getSize(find.byType(ScorePicker)).height;

      expect(beside, lessThanOrEqualTo(below + 8));
    });

    testWidgets('without a label the hint stays under the pills', (
      tester,
    ) async {
      await _show(tester, onChanged: (_) {});

      expect(
        tester.getTopLeft(find.text('Not rated')).dy,
        greaterThan(tester.getTopLeft(find.text('10')).dy),
      );
    });
  });

  group('semantics', () {
    testWidgets('each pill is a labelled button that knows if it is chosen', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _show(tester, value: 7, onChanged: (_) {});

      final chosen = tester
          .getSemantics(find.bySemanticsLabel('Score 7'))
          .getSemanticsData()
          .flagsCollection;
      final other = tester
          .getSemantics(find.bySemanticsLabel('Score 8'))
          .getSemanticsData()
          .flagsCollection;

      expect(chosen.isButton, isTrue);
      expect(chosen.isSelected, Tristate.isTrue);
      expect(other.isButton, isTrue);
      expect(other.isSelected, Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('reads the score, not the digit twice', (tester) async {
      final handle = tester.ensureSemantics();
      await _show(tester, onChanged: (_) {});

      expect(find.bySemanticsLabel('Score 3'), findsOneWidget);
      expect(find.bySemanticsLabel('3'), findsNothing);
      handle.dispose();
    });
  });
}
