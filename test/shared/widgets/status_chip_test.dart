import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/core/theme/app_theme.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/shared/widgets/info_chip.dart';
import 'package:animal/shared/widgets/status_chip.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _show(WidgetTester tester, Widget child, {ThemeData? theme}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(body: Center(child: child)),
      ),
    );

Container _chipBox(WidgetTester tester) => tester.widget<Container>(
  find.descendant(of: find.byType(InfoChip), matching: find.byType(Container)),
);

void main() {
  group('ListStatusChip', () {
    testWidgets('pairs every status with a word and an icon', (tester) async {
      for (final status in WatchStatus.values) {
        await _show(tester, ListStatusChip(status: status));

        expect(find.text(status.label), findsOneWidget, reason: status.name);
        expect(find.byIcon(listStatusIcon(status)), findsOneWidget);
      }
    });

    testWidgets('uses the tonal pair of the installed theme', (tester) async {
      await _show(
        tester,
        const ListStatusChip(status: WatchStatus.dropped),
        theme: buildDarkTheme(),
      );

      final box = _chipBox(tester).decoration! as BoxDecoration;
      expect(box.color, AppColors.darkStatus.droppedContainer);
    });

    testWidgets('falls back to the light palette without the app theme', (
      tester,
    ) async {
      await _show(tester, const ListStatusChip(status: WatchStatus.watching));

      final box = _chipBox(tester).decoration! as BoxDecoration;
      expect(box.color, AppColors.lightStatus.airingContainer);
    });
  });

  group('AiringStatusChip', () {
    testWidgets('maps MAL statuses to labels', (tester) async {
      await _show(tester, const AiringStatusChip(status: 'currently_airing'));
      expect(find.text('Airing'), findsOneWidget);

      await _show(tester, const AiringStatusChip(status: 'finished_airing'));
      expect(find.text('Finished'), findsOneWidget);

      await _show(tester, const AiringStatusChip(status: 'not_yet_aired'));
      expect(find.text('Upcoming'), findsOneWidget);
    });

    testWidgets('an unknown status gets the neutral pair', (tester) async {
      await _show(tester, const AiringStatusChip(status: 'other'));

      final box = _chipBox(tester).decoration! as BoxDecoration;
      expect(box.color, AppColors.lightStatus.planContainer);
      expect(find.text('other'), findsOneWidget);
    });
  });
}
