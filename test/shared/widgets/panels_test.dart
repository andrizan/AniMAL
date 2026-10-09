import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/shared/widgets/hero_panel.dart';
import 'package:animal/shared/widgets/section_card.dart';
import 'package:animal/shared/widgets/stat_highlight.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _show(WidgetTester tester, Widget child, {double width = 320}) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    );

void main() {
  group('SectionCard', () {
    testWidgets('shows an optional title, caption and its content', (
      tester,
    ) async {
      await _show(
        tester,
        const SectionCard(
          title: 'Title',
          trailing: '3',
          child: Text('content'),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('works without a title and can be tinted', (tester) async {
      await _show(
        tester,
        const SectionCard(color: Color(0xFF123456), child: Text('content')),
      );

      expect(find.text('content'), findsOneWidget);
      expect(
        tester.widget<Card>(find.byType(Card)).color,
        const Color(0xFF123456),
      );
    });

    testWidgets('has no outer margin so pages control the spacing', (
      tester,
    ) async {
      await _show(tester, const SectionCard(child: Text('content')));

      expect(tester.widget<Card>(find.byType(Card)).margin, EdgeInsets.zero);
    });
  });

  testWidgets('HeroPanel wraps its child in the hero radius', (tester) async {
    await _show(tester, const HeroPanel(child: Text('inside')));

    final box = tester.widget<Container>(
      find.descendant(
        of: find.byType(HeroPanel),
        matching: find.byType(Container),
      ),
    );
    final decoration = box.decoration! as BoxDecoration;
    expect(find.text('inside'), findsOneWidget);
    expect(decoration.borderRadius, BorderRadius.circular(AppRadius.hero));
    expect(decoration.gradient, isNotNull);
  });

  group('StatHighlight', () {
    testWidgets('shows the value, label and optional icon', (tester) async {
      await _show(
        tester,
        const StatHighlight(
          value: '9.31',
          label: 'Score',
          icon: Icons.star_rounded,
        ),
      );

      expect(find.text('9.31'), findsOneWidget);
      expect(find.text('Score'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('shrinks a long value instead of overflowing', (tester) async {
      await _show(
        tester,
        const StatHighlight(
          value: '1,234,567,890',
          label: 'A rather long caption for a narrow column',
          icon: Icons.star_rounded,
        ),
        width: 60,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
