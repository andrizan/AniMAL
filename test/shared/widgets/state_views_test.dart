import 'package:animal/shared/widgets/empty_view.dart';
import 'package:animal/shared/widgets/error_view.dart';
import 'package:animal/shared/widgets/section_header.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _show(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

void main() {
  group('ErrorView', () {
    testWidgets('shows the message with the error icon in the error colour', (
      tester,
    ) async {
      await _show(tester, const ErrorView(message: 'Failed to load things'));

      expect(find.text('Failed to load things'), findsOneWidget);
      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.size, 48);
      expect(
        icon.color,
        Theme.of(tester.element(find.byType(ErrorView))).colorScheme.error,
      );
    });

    testWidgets('offers Retry only when it can retry', (tester) async {
      await _show(tester, const ErrorView(message: 'x'));
      expect(find.text('Retry'), findsNothing);

      var retried = 0;
      await _show(tester, ErrorView(message: 'x', onRetry: () => retried++));
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retried, 1);
    });

    testWidgets('a long message wraps instead of overflowing', (tester) async {
      await _show(tester, ErrorView(message: 'word ' * 60, onRetry: () {}));

      expect(tester.takeException(), isNull);
    });
  });

  group('EmptyView', () {
    testWidgets('shows the icon and message', (tester) async {
      await _show(
        tester,
        const EmptyView(icon: Icons.inbox_outlined, message: 'Nothing here'),
      );

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('shows the hint when given', (tester) async {
      await _show(
        tester,
        const EmptyView(
          icon: Icons.search_off,
          message: 'Not found',
          hint: 'Try another word',
        ),
      );

      expect(find.text('Try another word'), findsOneWidget);
    });

    testWidgets('Retry calls back', (tester) async {
      var retried = 0;
      await _show(
        tester,
        EmptyView(
          icon: Icons.tv_off,
          message: 'No schedule',
          onRetry: () => retried++,
        ),
      );

      await tester.tap(find.text('Retry'));

      expect(retried, 1);
    });
  });

  group('SectionHeader', () {
    testWidgets('shows the title and an optional trailing caption', (
      tester,
    ) async {
      await _show(tester, const SectionHeader('Genres', trailing: '3 genres'));

      expect(find.text('Genres'), findsOneWidget);
      expect(find.text('3 genres'), findsOneWidget);
    });

    testWidgets('leaves the bottom gap to the caller', (tester) async {
      await _show(tester, const SectionHeader('Genres'));
      final tight = tester.getSize(find.byType(SectionHeader)).height;

      await _show(tester, const SectionHeader('Genres', bottomPadding: 24));
      final roomy = tester.getSize(find.byType(SectionHeader)).height;

      expect(roomy - tight, 16);
    });
  });
}
