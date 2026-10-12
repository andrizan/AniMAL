import 'package:animal/shared/widgets/pill_tab_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _labels = ['Mon', 'Tue', 'Wed'];

Future<TabController> _show(
  WidgetTester tester, {
  List<String> labels = _labels,
  List<IconData>? icons,
  bool scrollable = true,
  bool segmented = false,
  int initialIndex = 0,
}) async {
  final controller = TabController(
    length: labels.length,
    vsync: const TestVSync(),
    initialIndex: initialIndex,
  );
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PillTabBar(
          controller: controller,
          labels: labels,
          icons: icons,
          scrollable: scrollable,
          segmented: segmented,
        ),
      ),
    ),
  );
  return controller;
}

/// Whether the tab carries its own tonal pill (an unselected tab).
bool _isFilled(WidgetTester tester, String label) {
  final tab = find.widgetWithText(Tab, label);
  final scheme = Theme.of(tester.element(tab)).colorScheme;
  return tester
      .widgetList<Container>(
        find.descendant(of: tab, matching: find.byType(Container)),
      )
      .any(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration! as BoxDecoration).color == scheme.surfaceContainer,
      );
}

void main() {
  group('tabs', () {
    testWidgets('builds one real Tab per label, in order', (tester) async {
      await _show(tester);

      expect(find.byType(Tab), findsNWidgets(3));
      final xs = [
        for (final label in _labels)
          tester.getTopLeft(find.widgetWithText(Tab, label)).dx,
      ];
      expect(xs, [...xs]..sort());
    });

    testWidgets('only the selected tab goes without its own pill', (
      tester,
    ) async {
      await _show(tester);

      expect(_isFilled(tester, 'Mon'), isFalse);
      expect(_isFilled(tester, 'Tue'), isTrue);
      expect(_isFilled(tester, 'Wed'), isTrue);
    });

    testWidgets('starts on the initial index', (tester) async {
      await _show(tester, initialIndex: 2);

      expect(_isFilled(tester, 'Wed'), isFalse);
      expect(_isFilled(tester, 'Mon'), isTrue);
    });

    testWidgets('moves the plain pill when the controller moves', (
      tester,
    ) async {
      final controller = await _show(tester);

      controller.animateTo(2);
      await tester.pumpAndSettle();

      expect(_isFilled(tester, 'Wed'), isFalse);
      expect(_isFilled(tester, 'Mon'), isTrue);
      expect(_isFilled(tester, 'Tue'), isTrue);
    });

    testWidgets('tapping a label selects that tab', (tester) async {
      final controller = await _show(tester);

      await tester.tap(find.text('Tue'));
      await tester.pumpAndSettle();

      expect(controller.index, 1);
      expect(_isFilled(tester, 'Tue'), isFalse);
      expect(_isFilled(tester, 'Mon'), isTrue);
    });

    testWidgets('a single tab is never filled', (tester) async {
      await _show(tester, labels: const ['Only']);

      expect(_isFilled(tester, 'Only'), isFalse);
    });
  });

  group('layout', () {
    testWidgets('scrolls by default and fills the width when asked', (
      tester,
    ) async {
      await _show(tester);
      expect(tester.widget<TabBar>(find.byType(TabBar)).isScrollable, isTrue);

      await _show(tester, scrollable: false);
      expect(tester.widget<TabBar>(find.byType(TabBar)).isScrollable, isFalse);
    });

    testWidgets('pill tabs are 40px tall', (tester) async {
      await _show(tester);

      expect(tester.getSize(find.widgetWithText(Tab, 'Mon')).height, 40);
    });

    testWidgets('segmented tabs are 60px tall and share the width', (
      tester,
    ) async {
      await _show(tester, scrollable: false, segmented: true);

      final widths = [
        for (final label in _labels)
          tester.getSize(find.widgetWithText(Tab, label)).width,
      ];
      expect(tester.getSize(find.widgetWithText(Tab, 'Mon')).height, 60);
      expect(widths.toSet(), hasLength(1));
    });

    testWidgets('segmented tabs never carry their own pill', (tester) async {
      await _show(tester, scrollable: false, segmented: true);

      for (final label in _labels) {
        expect(_isFilled(tester, label), isFalse, reason: label);
      }
    });

    testWidgets('segmented tabs sit on one tonal track', (tester) async {
      await _show(tester, scrollable: false, segmented: true);
      final scheme = Theme.of(tester.element(find.byType(TabBar))).colorScheme;

      final track = tester.widget<Container>(
        find
            .ancestor(of: find.byType(TabBar), matching: find.byType(Container))
            .first,
      );
      expect(
        (track.decoration! as BoxDecoration).color,
        scheme.surfaceContainer,
      );
    });
  });

  group('icons', () {
    testWidgets('shows one icon above each label', (tester) async {
      await _show(
        tester,
        icons: const [Icons.ac_unit, Icons.park, Icons.schedule],
        scrollable: false,
        segmented: true,
      );

      for (final icon in [Icons.ac_unit, Icons.park, Icons.schedule]) {
        expect(find.byIcon(icon), findsOneWidget, reason: '$icon');
      }
      expect(
        tester.getTopLeft(find.byIcon(Icons.ac_unit)).dy,
        lessThan(tester.getTopLeft(find.text('Mon')).dy),
      );
    });

    testWidgets('no icons means text only', (tester) async {
      await _show(tester);

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('rejects an icon list that does not match the labels', (
      tester,
    ) async {
      final controller = TabController(length: 2, vsync: const TestVSync());
      addTearDown(controller.dispose);

      expect(
        () => PillTabBar(
          controller: controller,
          labels: const ['a', 'b'],
          icons: const [Icons.add],
        ),
        throwsAssertionError,
      );
    });
  });
}
