import 'dart:async';

import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/shared/providers/clock_provider.dart';
import 'package:animal/shared/widgets/countdown_badge.dart';
import 'package:animal/shared/widgets/info_chip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

DateTime _in(Duration d) => DateTime.now().toUtc().add(d);

Future<void> _show(
  WidgetTester tester,
  DateTime airingAt, {
  int episode = 4,
  bool showEpisode = true,
  Stream<DateTime>? clock,
}) => tester.pumpWidget(
  ProviderScope(
    overrides: [if (clock != null) clockProvider.overrideWith((ref) => clock)],
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: CountdownBadge(
            airingAt: airingAt,
            episode: episode,
            showEpisode: showEpisode,
          ),
        ),
      ),
    ),
  ),
);

Color? _background(WidgetTester tester) =>
    (tester
                .widget<Container>(
                  find.descendant(
                    of: find.byType(InfoChip),
                    matching: find.byType(Container),
                  ),
                )
                .decoration!
            as BoxDecoration)
        .color;

/// Feeds one tick to the shared clock. A provider delivers a stream event on
/// the frame after it arrives, so it takes two pumps to reach the widget.
Future<void> _tick(
  WidgetTester tester,
  StreamController<DateTime> clock,
  DateTime time,
) async {
  clock.add(time);
  await tester.pump();
  await tester.pump();
}

void main() {
  const status = AppColors.lightStatus;

  group('label', () {
    testWidgets('counts days and hours for a distant episode', (tester) async {
      await _show(tester, _in(const Duration(days: 1, hours: 2, minutes: 30)));

      expect(find.text('Ep 4 · in 1d 2h'), findsOneWidget);
    });

    testWidgets('counts hours and minutes under a day', (tester) async {
      await _show(
        tester,
        _in(const Duration(hours: 7, minutes: 20, seconds: 30)),
      );

      expect(find.text('Ep 4 · in 7h 20m'), findsOneWidget);
    });

    testWidgets('counts only minutes under an hour', (tester) async {
      await _show(tester, _in(const Duration(minutes: 45, seconds: 30)));

      expect(find.text('Ep 4 · in 45m'), findsOneWidget);
    });

    testWidgets('names the episode number it was given', (tester) async {
      await _show(tester, _in(const Duration(days: 2, hours: 1)), episode: 129);

      expect(find.textContaining('Ep 129 · in 2d'), findsOneWidget);
    });

    testWidgets('can leave the episode out', (tester) async {
      await _show(
        tester,
        _in(const Duration(hours: 3, minutes: 20, seconds: 30)),
        showEpisode: false,
      );

      expect(find.text('in 3h 20m'), findsOneWidget);
      expect(find.textContaining('Ep'), findsNothing);
    });

    testWidgets('says Aired once the time has passed', (tester) async {
      await _show(tester, _in(const Duration(minutes: -1)));

      expect(find.text('Ep 4 · Aired'), findsOneWidget);
    });

    testWidgets('says Aired without the episode when asked', (tester) async {
      await _show(tester, _in(const Duration(hours: -3)), showEpisode: false);

      expect(find.text('Aired'), findsOneWidget);
    });
  });

  group('urgency', () {
    testWidgets('a normal countdown is the primary tint with a clock', (
      tester,
    ) async {
      await _show(tester, _in(const Duration(days: 1, minutes: 30)));
      final scheme = Theme.of(tester.element(find.byType(InfoChip)))
          .colorScheme;

      expect(_background(tester), scheme.primaryContainer);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('under six hours it turns urgent with an alert icon', (
      tester,
    ) async {
      await _show(
        tester,
        _in(const Duration(hours: 5, minutes: 59, seconds: 30)),
      );

      expect(_background(tester), status.droppedContainer);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsNothing);
    });

    testWidgets('a minute over six hours is still calm', (tester) async {
      await _show(tester, _in(const Duration(hours: 6, minutes: 1)));
      final scheme = Theme.of(tester.element(find.byType(InfoChip)))
          .colorScheme;

      expect(_background(tester), scheme.primaryContainer);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('an aired episode is neutral with a check', (tester) async {
      await _show(tester, _in(const Duration(minutes: -5)));

      expect(_background(tester), status.planContainer);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('urgency never rests on colour alone', (tester) async {
      await _show(tester, _in(const Duration(hours: 2, seconds: 30)));

      expect(find.byType(Icon), findsOneWidget);
      expect(find.textContaining('in '), findsOneWidget);
    });
  });

  group('live clock', () {
    testWidgets('re-counts when the shared clock ticks', (tester) async {
      final clock = StreamController<DateTime>();
      addTearDown(clock.close);
      final airingAt = _in(const Duration(hours: 10));

      await _show(tester, airingAt, clock: clock.stream);
      await _tick(
        tester,
        clock,
        airingAt.subtract(const Duration(hours: 3, minutes: 20)),
      );
      expect(find.text('Ep 4 · in 3h 20m'), findsOneWidget);

      await _tick(tester, clock, airingAt.subtract(const Duration(minutes: 5)));
      expect(find.text('Ep 4 · in 5m'), findsOneWidget);
      expect(_background(tester), status.droppedContainer);

      await _tick(tester, clock, airingAt.add(const Duration(minutes: 1)));
      expect(find.text('Ep 4 · Aired'), findsOneWidget);
      expect(_background(tester), status.planContainer);
    });

    testWidgets('an episode that already aired never counts down again', (
      tester,
    ) async {
      final clock = StreamController<DateTime>();
      addTearDown(clock.close);
      final airingAt = _in(const Duration(hours: -2));

      await _show(tester, airingAt, clock: clock.stream);
      await _tick(tester, clock, airingAt.add(const Duration(hours: 5)));

      expect(find.text('Ep 4 · Aired'), findsOneWidget);
    });
  });
}
