import 'dart:async';

import 'package:animal/core/constants/mal_endpoints.dart';
import 'package:animal/core/notification/anime_notification_service.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/my_list_status.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/shared/providers/airing_entry.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:animal/shared/widgets/anime_card.dart';
import 'package:animal/shared/widgets/score_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

typedef _Save = ({int id, WatchStatus? status, int? episodes, int? score});

class _Repo extends Fake implements AnimeRepository {
  final saves = <_Save>[];
  Exception? failure;
  Completer<void>? gate;

  @override
  Future<MyListStatus> updateAnimeListStatus(
    int animeId, {
    WatchStatus? status,
    int? numWatchedEpisodes,
    int? score,
    bool? isRewatching,
    int? priority,
    int? rewatchValue,
    String? comments,
  }) async {
    saves.add((
      id: animeId,
      status: status,
      episodes: numWatchedEpisodes,
      score: score,
    ));
    await gate?.future;
    if (failure != null) throw failure!;
    return MyListStatus(
      status: status ?? WatchStatus.watching,
      numEpisodesWatched: numWatchedEpisodes ?? 0,
      score: score ?? 0,
    );
  }
}

class _Notifications extends Fake implements AnimeNotificationService {
  _Notifications({Set<int> ids = const {}}) : ids = {...ids};

  final Set<int> ids;
  var granted = true;
  var result = ScheduleResult.scheduled;
  final scheduled = <({int id, String title, int episode, DateTime at})>[];
  final cancelled = <int>[];

  @override
  bool get permissionGranted => granted;

  @override
  Set<int> get notificationIds => Set.unmodifiable(ids);

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Future<bool> isNotificationScheduled(int animeId) async =>
      ids.contains(animeId);

  @override
  Future<void> cancelNotification(int animeId) async {
    cancelled.add(animeId);
    ids.remove(animeId);
  }

  @override
  Future<ScheduleResult> scheduleAnimeNotification({
    required int animeId,
    required String title,
    required int episode,
    required DateTime airingAt,
  }) async {
    scheduled.add((id: animeId, title: title, episode: episode, at: airingAt));
    if (result == ScheduleResult.scheduled) ids.add(animeId);
    return result;
  }
}

final _airingAt = DateTime.utc(2026, 10, 16, 14, 26);

AiringEntry _next({int episode = 5}) => AiringEntry(
  anilistId: 1,
  malId: 1,
  title: 'Frieren',
  airingAt: _airingAt,
  episode: episode,
  timeUntilAiring: 90000,
);

Anime _anime({
  String status = 'currently_airing',
  int episodes = 12,
  MyListStatus? list = const MyListStatus(
    status: WatchStatus.watching,
    numEpisodesWatched: 5,
    score: 7,
  ),
  String? ja,
}) => Anime(
  id: 1,
  title: 'Frieren',
  status: status,
  numEpisodes: episodes,
  myListStatus: list,
  alternativeTitles: ja == null ? null : AlternativeTitles(ja: ja),
);

void main() {
  late _Repo repo;
  late _Notifications notifications;

  setUp(() {
    repo = _Repo();
    notifications = _Notifications();
  });

  Future<void> open(
    WidgetTester tester,
    Anime anime, {
    AiringEntry? nextAiring,
  }) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          animeRepositoryProvider.overrideWithValue(repo),
          notificationServiceProvider.overrideWithValue(notifications),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AnimeCard(anime: anime, nextAiring: nextAiring),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
  }

  String episodesText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  bool selected(WidgetTester tester, String label) => tester
      .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label))
      .selected;

  Finder score(int n) =>
      find.descendant(of: find.byType(ScorePicker), matching: find.text('$n'));

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
  }

  group('opening', () {
    testWidgets('starts from the current status, episodes and score', (
      tester,
    ) async {
      await open(tester, _anime());

      expect(selected(tester, 'Watching'), isTrue);
      expect(selected(tester, 'On Hold'), isFalse);
      expect(episodesText(tester), '5');
      expect(find.text('/ 12'), findsOneWidget);
      expect(find.text('Tap the score again to clear it'), findsOneWidget);
    });

    testWidgets('an anime outside the list starts at Watching, 0 and unrated', (
      tester,
    ) async {
      await open(tester, _anime(list: null));

      expect(selected(tester, 'Watching'), isTrue);
      expect(episodesText(tester), '0');
      expect(find.text('Not rated'), findsOneWidget);
    });

    testWidgets('names the anime in English and Japanese', (tester) async {
      await open(tester, _anime(ja: '葬送のフリーレン'));

      expect(find.text('Frieren'), findsWidgets);
      expect(find.text('葬送のフリーレン'), findsWidgets);
    });

    testWidgets('an unknown episode count has no total', (tester) async {
      await open(tester, _anime(episodes: 0));

      expect(find.textContaining('/ '), findsNothing);
    });

    testWidgets('has no reminder row without a next airing', (tester) async {
      await open(tester, _anime());

      expect(find.byType(Switch), findsNothing);
      expect(find.textContaining('Notify me'), findsNothing);
    });
  });

  group('status', () {
    testWidgets('choosing a status selects only that one', (tester) async {
      await open(tester, _anime());

      await tester.tap(find.widgetWithText(ChoiceChip, 'On Hold'));
      await tester.pump();

      expect(selected(tester, 'On Hold'), isTrue);
      expect(selected(tester, 'Watching'), isFalse);
    });

    testWidgets('Completed is refused for an anime that is still airing', (
      tester,
    ) async {
      await open(tester, _anime());

      await tester.tap(find.widgetWithText(ChoiceChip, 'Completed'));
      await tester.pump();

      expect(selected(tester, 'Completed'), isFalse);
      expect(selected(tester, 'Watching'), isTrue);
      expect(
        find.text('Completed can only be set for finished anime'),
        findsOneWidget,
      );
    });

    testWidgets('Completed fills in every episode of a finished anime', (
      tester,
    ) async {
      await open(tester, _anime(status: 'finished_airing'));

      await tester.tap(find.widgetWithText(ChoiceChip, 'Completed'));
      await tester.pump();

      expect(selected(tester, 'Completed'), isTrue);
      expect(episodesText(tester), '12');
      expect(
        find.text('Completed can only be set for finished anime'),
        findsNothing,
      );
    });

    testWidgets('Completed leaves the count alone when the total is unknown', (
      tester,
    ) async {
      await open(tester, _anime(status: 'finished_airing', episodes: 0));

      await tester.tap(find.widgetWithText(ChoiceChip, 'Completed'));
      await tester.pump();

      expect(episodesText(tester), '5');
    });
  });

  group('episodes', () {
    testWidgets('plus and minus move by one and show it in the field', (
      tester,
    ) async {
      await open(tester, _anime());

      await tester.tap(find.byTooltip('One episode more'));
      await tester.pump();
      await tester.tap(find.byTooltip('One episode more'));
      await tester.pump();
      expect(episodesText(tester), '7');

      await tester.tap(find.byTooltip('One episode less'));
      await tester.pump();
      expect(episodesText(tester), '6');
    });

    testWidgets('minus stops at zero', (tester) async {
      await open(tester, _anime(list: null));

      final minus = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.remove),
      );

      expect(minus.onPressed, isNull);
    });

    testWidgets('plus stops at the total', (tester) async {
      await open(
        tester,
        _anime(
          list: const MyListStatus(
            status: WatchStatus.watching,
            numEpisodesWatched: 12,
          ),
        ),
      );

      final plus = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.add),
      );

      expect(plus.onPressed, isNull);
    });

    testWidgets('plus has no ceiling when the total is unknown', (
      tester,
    ) async {
      await open(tester, _anime(episodes: 0));

      await tester.tap(find.byTooltip('One episode more'));
      await tester.pump();

      expect(episodesText(tester), '6');
    });

    testWidgets('a typed number is used', (tester) async {
      await open(tester, _anime());

      await submit(tester, '9');
      await save(tester);

      expect(repo.saves.single.episodes, 9);
    });

    testWidgets('a typed number counts even without pressing done', (
      tester,
    ) async {
      await open(tester, _anime());

      await tester.enterText(find.byType(TextField), '9');
      await save(tester);

      expect(repo.saves.single.episodes, 9);
    });

    testWidgets('typing nonsense keeps the last good number', (tester) async {
      await open(tester, _anime());

      await submit(tester, 'abc');
      await save(tester);

      expect(repo.saves.single.episodes, 5);
    });

    testWidgets('a negative number is ignored', (tester) async {
      await open(tester, _anime());

      await submit(tester, '-3');
      await save(tester);

      expect(repo.saves.single.episodes, 5);
    });

    testWidgets('plus continues from a typed number', (tester) async {
      await open(tester, _anime());

      await submit(tester, '8');
      await tester.tap(find.byTooltip('One episode more'));
      await tester.pump();

      expect(episodesText(tester), '9');
    });

    testWidgets('plus continues from a number typed without pressing done', (
      tester,
    ) async {
      await open(tester, _anime());

      await tester.enterText(find.byType(TextField), '8');
      await tester.tap(find.byTooltip('One episode more'));
      await tester.pump();
      await save(tester);

      expect(repo.saves.single.episodes, 9);
    });

    testWidgets('a typed number past the end stops plus', (tester) async {
      await open(tester, _anime());

      await tester.enterText(find.byType(TextField), '12');
      await tester.pump();

      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add))
            .onPressed,
        isNull,
      );
    });
  });

  group('score', () {
    testWidgets('a picked score is sent', (tester) async {
      await open(tester, _anime(list: null));

      await tester.tap(score(9));
      await tester.pump();
      await save(tester);

      expect(repo.saves.single.score, 9);
    });

    testWidgets('tapping the current score clears it', (tester) async {
      await open(tester, _anime());

      await tester.tap(score(7));
      await tester.pump();
      await save(tester);

      expect(repo.saves.single.score, 0);
    });
  });

  group('saving', () {
    testWidgets('sends the whole edit, closes the sheet and confirms', (
      tester,
    ) async {
      await open(tester, _anime(status: 'finished_airing'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Completed'));
      await tester.pump();
      await tester.tap(score(10));
      await tester.pump();

      await save(tester);

      expect(repo.saves.single, (
        id: 1,
        status: WatchStatus.completed,
        episodes: 12,
        score: 10,
      ));
      expect(find.text('Save'), findsNothing);
      expect(find.text('Frieren updated'), findsOneWidget);
    });

    testWidgets('an untouched edit saves the values it opened with', (
      tester,
    ) async {
      await open(tester, _anime());

      await save(tester);

      expect(repo.saves.single, (
        id: 1,
        status: WatchStatus.watching,
        episodes: 5,
        score: 7,
      ));
    });

    testWidgets('leaving Watching drops the reminder', (tester) async {
      notifications = _Notifications(ids: {1});
      await open(tester, _anime());
      await tester.tap(find.widgetWithText(ChoiceChip, 'Dropped'));
      await tester.pump();

      await save(tester);

      expect(notifications.cancelled, [1]);
    });

    testWidgets('staying on Watching keeps the reminder', (tester) async {
      notifications = _Notifications(ids: {1});
      await open(tester, _anime());

      await save(tester);

      expect(notifications.cancelled, isEmpty);
    });

    testWidgets('locks the controls and shows progress while saving', (
      tester,
    ) async {
      repo.gate = Completer<void>();
      await open(tester, _anime());

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save'), findsNothing);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Dropped'))
            .onSelected,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add))
            .onPressed,
        isNull,
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      repo.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('a failed save keeps the sheet open and says why', (
      tester,
    ) async {
      repo.failure = Exception('offline');
      await open(tester, _anime());

      await save(tester);

      expect(find.text('Save'), findsOneWidget);
      expect(find.textContaining('Failed to update'), findsOneWidget);
      expect(find.textContaining('offline'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets('a failed save leaves the reminder alone', (tester) async {
      notifications = _Notifications(ids: {1});
      repo.failure = Exception('offline');
      await open(tester, _anime());
      await tester.tap(find.widgetWithText(ChoiceChip, 'Dropped'));
      await tester.pump();

      await save(tester);

      expect(notifications.cancelled, isEmpty);
    });

    testWidgets('after a failure the same edit can be saved again', (
      tester,
    ) async {
      repo.failure = Exception('offline');
      await open(tester, _anime());
      await save(tester);
      repo.failure = null;

      await save(tester);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(repo.saves, hasLength(2));
      expect(find.text('Save'), findsNothing);
      expect(find.text('Frieren updated'), findsOneWidget);
    });
  });

  group('reminder', () {
    testWidgets('names the episode and the lead time', (tester) async {
      await open(tester, _anime(), nextAiring: _next(episode: 6));

      expect(find.text('Notify me before Ep 6'), findsOneWidget);
      expect(
        find.text('${ApiConstants.notificationLeadMinutes} minutes ahead'),
        findsOneWidget,
      );
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });

    testWidgets('turning it on schedules that episode', (tester) async {
      await open(tester, _anime(), nextAiring: _next(episode: 6));

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(notifications.scheduled.single, (
        id: 1,
        title: 'Frieren',
        episode: 6,
        at: _airingAt,
      ));
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(
        find.descendant(
          of: find.byType(CircleAvatar),
          matching: find.byIcon(Icons.notifications_active),
        ),
        findsOneWidget,
      );
    });

    testWidgets('turning it off cancels it', (tester) async {
      notifications = _Notifications(ids: {1});
      await open(tester, _anime(), nextAiring: _next());
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(notifications.cancelled, [1]);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(
        find.descendant(
          of: find.byType(CircleAvatar),
          matching: find.byIcon(Icons.notifications_none),
        ),
        findsOneWidget,
      );
    });

    testWidgets('an episode that airs too soon is explained', (tester) async {
      notifications.result = ScheduleResult.tooLate;
      await open(tester, _anime(), nextAiring: _next(episode: 6));

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.textContaining('Too late to schedule'), findsOneWidget);
      expect(find.textContaining('Episode 6'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });

    testWidgets('a refused permission is reported', (tester) async {
      notifications.granted = false;
      await open(tester, _anime(), nextAiring: _next());

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Notification permission denied'), findsOneWidget);
      expect(notifications.scheduled, isEmpty);
    });

    testWidgets('a scheduling failure is reported', (tester) async {
      notifications.result = ScheduleResult.failed;
      await open(tester, _anime(), nextAiring: _next());

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Could not schedule the notification'), findsOneWidget);
    });

    testWidgets('cannot be changed while the edit is saving', (tester) async {
      repo.gate = Completer<void>();
      await open(tester, _anime(), nextAiring: _next());

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
      repo.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('opening a finished anime cancels its stale reminder', (
      tester,
    ) async {
      notifications = _Notifications(ids: {1});

      await open(tester, _anime(status: 'finished_airing'));

      expect(notifications.cancelled, [1]);
    });

    testWidgets('opening a finished anime without a reminder cancels nothing', (
      tester,
    ) async {
      await open(tester, _anime(status: 'finished_airing'));

      expect(notifications.cancelled, isEmpty);
    });

    testWidgets('opening an airing anime keeps its reminder', (tester) async {
      notifications = _Notifications(ids: {1});

      await open(tester, _anime());

      expect(notifications.cancelled, isEmpty);
    });
  });
}
