import 'dart:async';

import 'package:animal/core/notification/anime_notification_service.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/features/airing/presentation/screens/anime_airing_page.dart';
import 'package:animal/shared/providers/airing_entry.dart';
import 'package:animal/shared/widgets/anime_card.dart';
import 'package:animal/shared/widgets/countdown_badge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _days = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

class _Airing extends Fake implements AiringRepository {
  int refreshes = 0;
  Object? failure;
  Map<String, List<AiringEntry>> result = {};
  Completer<void>? gate;

  @override
  Future<Map<String, List<AiringEntry>>> refreshWeeklySchedule() async {
    refreshes++;
    await gate?.future;
    final error = failure;
    if (error != null) throw error;
    return result;
  }
}

class _Notifications extends Fake implements AnimeNotificationService {
  @override
  bool get permissionGranted => true;

  @override
  Set<int> get notificationIds => const {};
}

AiringEntry _entry(
  int id, {
  Duration airsIn = const Duration(hours: 3),
  int episode = 4,
  MyListStatus? list,
}) => AiringEntry(
  anilistId: id,
  malId: id,
  title: 'Show $id',
  airingAt: DateTime.now().toUtc().add(airsIn),
  episode: episode,
  timeUntilAiring: airsIn.inSeconds,
  malScore: 8.1,
  episodes: 12,
  myListStatus: list,
);

void main() {
  late _Airing airing;
  late String today;

  Map<String, List<AiringEntry>> week({
    List<AiringEntry>? onToday,
    Map<String, List<AiringEntry>> other = const {},
  }) => {
    for (final d in _days) d: <AiringEntry>[],
    ...other,
    if (onToday != null) today: onToday,
  };

  Future<void> open(
    WidgetTester tester,
    FutureOr<Map<String, List<AiringEntry>>> Function() schedule,
  ) async {
    airing = _Airing();
    today = _days[DateTime.now().toUtc().weekday - 1];
    await tester.pumpWidget(
      ProviderScope(
        retry: noProviderRetry,
        overrides: [
          notificationServiceProvider.overrideWithValue(_Notifications()),
          airingRepositoryProvider.overrideWithValue(airing),
          weeklyAiringProvider.overrideWith((ref) async => schedule()),
        ],
        child: const MaterialApp(home: Scaffold(body: AnimeAiringPage())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows a spinner while the schedule loads', (tester) async {
    final gate = Completer<Map<String, List<AiringEntry>>>();
    airing = _Airing();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationServiceProvider.overrideWithValue(_Notifications()),
          airingRepositoryProvider.overrideWithValue(airing),
          weeklyAiringProvider.overrideWith((ref) => gate.future),
        ],
        child: const MaterialApp(home: Scaffold(body: AnimeAiringPage())),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    gate.complete({for (final d in _days) d: <AiringEntry>[]});
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('has one tab per weekday', (tester) async {
    await open(tester, () => week(onToday: [_entry(1)]));

    for (final label in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
      expect(find.widgetWithText(Tab, label), findsOneWidget, reason: label);
    }
  });

  testWidgets('opens on today and lists its anime with a countdown', (
    tester,
  ) async {
    await open(
      tester,
      () => week(
        onToday: [
          _entry(1),
          _entry(2, airsIn: const Duration(hours: 5)),
        ],
      ),
    );

    final cards = tester.widgetList<AnimeCard>(find.byType(AnimeCard)).toList();
    expect(cards.map((c) => c.anime.title), ['Show 1', 'Show 2']);
    expect(find.byType(CountdownBadge), findsNWidgets(2));
    expect(find.textContaining('Ep 4'), findsNWidgets(2));
  });

  testWidgets('shows the personal list progress on the card', (tester) async {
    await open(
      tester,
      () => week(
        onToday: [
          _entry(
            1,
            list: const MyListStatus(
              status: WatchStatus.watching,
              numEpisodesWatched: 3,
            ),
          ),
        ],
      ),
    );

    expect(find.text('3/12 ep'), findsOneWidget);
    expect(find.text('Watching'), findsOneWidget);
  });

  testWidgets('a day without anime says so', (tester) async {
    await open(tester, () => week(onToday: [_entry(1)]));
    final other = _days[(DateTime.now().toUtc().weekday) % 7];
    final label = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ][_days.indexOf(other)];

    await tester.tap(find.widgetWithText(Tab, label));
    await tester.pumpAndSettle();

    expect(find.text('No anime on $label'), findsOneWidget);
  });

  group('when the week is empty', () {
    testWidgets('offers a retry that refreshes the schedule', (tester) async {
      await open(tester, week);
      expect(find.text('No airing schedule yet'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(airing.refreshes, 1);
    });
  });

  group('when loading fails', () {
    testWidgets('shows the error and retries', (tester) async {
      var fail = true;
      await open(tester, () {
        if (fail) throw Exception('offline');
        return week(onToday: [_entry(1)]);
      });
      expect(find.text('Failed to load airing schedule'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(airing.refreshes, 1);
      expect(find.byType(AnimeCard), findsOneWidget);
    });

    testWidgets('keeps the error visible if the retry also fails', (
      tester,
    ) async {
      await open(tester, () => throw Exception('offline'));
      airing.failure = Exception('still offline');

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load airing schedule'), findsOneWidget);
    });
  });

  group('refresh button', () {
    testWidgets('refreshes the schedule', (tester) async {
      await open(tester, () => week(onToday: [_entry(1)]));
      airing.result = week(onToday: [_entry(1)]);

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();

      expect(airing.refreshes, 1);
      expect(find.textContaining('empty'), findsNothing);
    });

    testWidgets('warns when the refreshed schedule is empty', (tester) async {
      await open(tester, () => week(onToday: [_entry(1)]));
      airing.result = week();

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Airing schedule is empty, try again later'),
        findsOneWidget,
      );
    });

    testWidgets('reports a failure and keeps showing the cached schedule', (
      tester,
    ) async {
      await open(tester, () => week(onToday: [_entry(1)]));
      airing.failure = Exception('offline');

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Refresh failed, showing cached schedule'),
        findsOneWidget,
      );
      expect(find.byType(AnimeCard), findsOneWidget);
    });

    testWidgets('shows a spinner and ignores taps while refreshing', (
      tester,
    ) async {
      await open(tester, () => week(onToday: [_entry(1)]));
      airing.gate = Completer<void>();

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pump(const Duration(milliseconds: 50));

      final button = find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Refresh',
      );
      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(tester.widget<IconButton>(button).onPressed, isNull);

      airing.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });
}
