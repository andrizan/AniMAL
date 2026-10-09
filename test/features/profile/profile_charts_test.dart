import 'package:animal/features/profile/presentation/widgets/profile_charts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _show(WidgetTester tester, Widget child, {double? width = 320}) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: width == null ? child : SizedBox(width: width, child: child),
          ),
        ),
      ),
    );

void main() {
  group('BarChart', () {
    const bars = [
      BarDatum(label: 'A', value: 2),
      BarDatum(label: 'B', value: 8, highlight: true),
      BarDatum(label: 'C', value: 0),
    ];

    testWidgets('labels every bar and counts the non-empty ones', (
      tester,
    ) async {
      await _show(
        tester,
        const BarChart(
          bars: bars,
          color: Color(0xFF0000FF),
          highlightColor: Color(0xFFFFFF00),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('bar heights follow the values and the highlight colour', (
      tester,
    ) async {
      await _show(
        tester,
        const BarChart(
          bars: bars,
          color: Color(0xFF0000FF),
          highlightColor: Color(0xFFFFFF00),
        ),
      );
      await tester.pumpAndSettle();

      final boxes = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.decoration is BoxDecoration)
          .map(
            (c) => (
              c.constraints!.maxHeight,
              (c.decoration! as BoxDecoration).color,
            ),
          )
          .toList();

      expect(boxes, hasLength(3));
      final heights = boxes.map((b) => b.$1).toList();
      expect(heights[1], greaterThan(heights[0]));
      expect(heights[0], greaterThan(heights[2]));
      expect(boxes[0].$2, const Color(0xFF0000FF));
      expect(boxes[1].$2, const Color(0xFFFFFF00));
    });

    testWidgets('all-zero data draws flat stubs without throwing', (
      tester,
    ) async {
      await _show(
        tester,
        const BarChart(
          bars: [
            BarDatum(label: 'A', value: 0),
            BarDatum(label: 'B', value: 0),
          ],
          color: Color(0xFF0000FF),
          highlightColor: Color(0xFFFFFF00),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('large counts scale down instead of overflowing', (
      tester,
    ) async {
      await _show(
        tester,
        BarChart(
          bars: [
            for (var i = 0; i < 12; i++) BarDatum(label: 'Mmm', value: 12345),
          ],
          color: Color(0xFF0000FF),
          highlightColor: Color(0xFFFFFF00),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('HorizontalBars', () {
    testWidgets('shows each label and count', (tester) async {
      await _show(
        tester,
        const HorizontalBars(
          color: Color(0xFF0000FF),
          bars: [
            BarDatum(label: 'Action', value: 10),
            BarDatum(label: 'Drama', value: 5),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Action'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('Drama'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('fills in proportion to the largest value', (tester) async {
      await _show(
        tester,
        const HorizontalBars(
          color: Color(0xFF0000FF),
          bars: [
            BarDatum(label: 'Action', value: 10),
            BarDatum(label: 'Drama', value: 5),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final factors = tester
          .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .map((f) => f.widthFactor)
          .toList();
      expect(factors, [1.0, 0.5]);
    });

    testWidgets('long labels are cut off', (tester) async {
      await _show(
        tester,
        const HorizontalBars(
          color: Color(0xFF0000FF),
          bars: [BarDatum(label: 'An extremely long genre name', value: 1)],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('SegmentedBar', () {
    testWidgets('gives each non-empty segment a share of the width', (
      tester,
    ) async {
      await _show(
        tester,
        const SegmentedBar(
          segments: [
            ChartSegment(label: 'a', value: 3, color: Color(0xFFFF0000)),
            ChartSegment(label: 'b', value: 0, color: Color(0xFF00FF00)),
            ChartSegment(label: 'c', value: 1, color: Color(0xFF0000FF)),
          ],
        ),
      );

      final widths = {
        for (final box in tester.widgetList<ColoredBox>(
          find.descendant(
            of: find.byType(SegmentedBar),
            matching: find.byType(ColoredBox),
          ),
        ))
          box.color: tester.getSize(find.byWidget(box)).width,
      };

      expect(widths.containsKey(const Color(0xFF00FF00)), isFalse);
      expect(
        widths[const Color(0xFFFF0000)]!,
        greaterThan(widths[const Color(0xFF0000FF)]! * 2.9),
      );
      expect(tester.getSize(find.byType(SegmentedBar)).height, 12);
    });

    testWidgets('without data it is an empty track', (tester) async {
      await _show(
        tester,
        const SegmentedBar(
          segments: [
            ChartSegment(label: 'a', value: 0, color: Color(0xFFFF0000)),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(SegmentedBar)).width, 320);
    });
  });

  group('DonutChart', () {
    testWidgets('paints inside a square and shows its centre', (tester) async {
      final semantics = tester.ensureSemantics();
      await _show(
        tester,
        width: null,
        const DonutChart(
          size: 112,
          semanticsLabel: 'Library: a 3, b 1',
          center: Text('4'),
          segments: [
            ChartSegment(label: 'a', value: 3, color: Color(0xFFFF0000)),
            ChartSegment(label: 'b', value: 1, color: Color(0xFF0000FF)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('4'), findsOneWidget);
      expect(tester.getSize(find.byType(DonutChart)), const Size(112, 112));
      expect(
        find.bySemanticsLabel(RegExp('Library: a 3, b 1')),
        findsOneWidget,
      );
      semantics.dispose();
      expect(tester.takeException(), isNull);
    });

    testWidgets('with no data it draws only the track', (tester) async {
      await _show(
        tester,
        width: null,
        const DonutChart(
          size: 112,
          segments: [
            ChartSegment(label: 'a', value: 0, color: Color(0xFFFF0000)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('a single segment is a full ring', (tester) async {
      await _show(
        tester,
        width: null,
        const DonutChart(
          size: 112,
          segments: [
            ChartSegment(label: 'a', value: 5, color: Color(0xFFFF0000)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('ChartLegendItem shows its label and value', (tester) async {
    await _show(
      tester,
      const ChartLegendItem(
        color: Color(0xFFFF0000),
        label: 'Completed',
        value: '12.5d',
      ),
    );

    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('12.5d'), findsOneWidget);
  });
}
