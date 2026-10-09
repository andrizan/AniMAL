import 'package:animal/core/notification/anime_notification_service.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/broadcast.dart';
import 'package:animal/data/models/season.dart';
import 'package:animal/features/seasonal/presentation/screens/anime_schedule_page.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:animal/shared/widgets/anime_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Repo extends Fake implements AnimeRepository {
  final calls = <({int year, Season season})>[];
  final failing = <({int year, Season season})>{};
  final data = <({int year, Season season}), List<Anime>>{};
  var undated = <Anime>[];
  var undatedCalls = 0;
  var undatedFails = false;

  @override
  Future<List<Anime>> getUndatedUpcomingAnime() async {
    undatedCalls++;
    if (undatedFails) throw Exception('offline');
    return undated;
  }

  @override
  Future<List<Anime>> getSeasonalAnime({
    required int year,
    required Season season,
    int limit = 100,
  }) async {
    final key = (year: year, season: season);
    calls.add(key);
    if (failing.contains(key)) throw Exception('offline');
    return data[key] ?? const <Anime>[];
  }
}

class _Notifications extends Fake implements AnimeNotificationService {
  @override
  bool get permissionGranted => true;

  @override
  Set<int> get notificationIds => const {};
}

Anime _anime(int id, {String? day, String? time}) => Anime(
  id: id,
  title: 'Anime $id',
  broadcast: day == null ? null : Broadcast(dayOfWeek: day, startTime: time),
);

void main() {
  final now = DateTime.now();
  final year = now.year;
  final season = Season.fromDate(now);
  late _Repo repo;

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: noProviderRetry,
        overrides: [
          notificationServiceProvider.overrideWithValue(_Notifications()),
          animeRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: Scaffold(body: AnimeSchedulePage())),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    repo = _Repo();
    repo.data[(year: year, season: season)] = [
      _anime(1, day: 'monday', time: '23:00'),
      _anime(2, day: 'friday', time: '20:00'),
      _anime(3),
    ];
  });

  testWidgets('shows the four seasons and a Later tab', (tester) async {
    await open(tester);

    for (final label in ['Winter', 'Spring', 'Summer', 'Fall', 'Later']) {
      expect(find.widgetWithText(Tab, label), findsOneWidget, reason: label);
    }
  });

  testWidgets('opens on the current year and season', (tester) async {
    await open(tester);

    expect(find.text('$year'), findsOneWidget);
    expect(repo.calls.first, (year: year, season: season));
  });

  testWidgets('groups the season by broadcast day, unscheduled anime last', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Monday'), findsOneWidget);
    expect(find.text('Friday'), findsOneWidget);
    expect(find.text('Tuesday'), findsNothing);
    final order = tester
        .widgetList<AnimeCard>(find.byType(AnimeCard))
        .map((c) => c.anime.id)
        .toList();
    expect(order, [1, 2, 3]);
  });

  testWidgets('an empty season says so', (tester) async {
    repo.data.clear();
    await open(tester);

    expect(find.text('No anime for ${season.label} $year'), findsOneWidget);
  });

  testWidgets('a failing season shows an error and retries', (tester) async {
    repo.failing.add((year: year, season: season));
    await open(tester);
    expect(find.text('Failed to load ${season.label} $year'), findsOneWidget);

    repo.failing.clear();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.byType(AnimeCard), findsWidgets);
    expect(find.text('Failed to load ${season.label} $year'), findsNothing);
  });

  group('year selector', () {
    testWidgets('the arrows move one year at a time', (tester) async {
      await open(tester);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.text('${year - 1}'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text('${year + 1}'), findsOneWidget);
    });

    testWidgets('cannot go past next year', (tester) async {
      await open(tester);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      final next = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right),
      );
      expect(next.onPressed, isNull);
    });

    testWidgets('loads the chosen year', (tester) async {
      await open(tester);
      repo.calls.clear();

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(repo.calls, contains((year: year - 1, season: season)));
    });

    testWidgets(
      'the picker offers every year from fifty years back to next year',
      (tester) async {
        await open(tester);

        await tester.tap(find.text('$year'));
        await tester.pumpAndSettle();
        final list = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(ListView),
        );

        await tester.drag(list, const Offset(0, 100000));
        await tester.pumpAndSettle();
        expect(find.text('${year - 50}'), findsOneWidget);

        await tester.drag(list, const Offset(0, -100000));
        await tester.pumpAndSettle();
        expect(find.text('${year + 1}'), findsOneWidget);
      },
    );

    testWidgets('picking a year applies it', (tester) async {
      await open(tester);

      await tester.tap(find.text('$year'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('${year - 2}'));
      await tester.pumpAndSettle();

      expect(find.text('Select Year'), findsNothing);
      expect(find.text('${year - 2}'), findsOneWidget);
    });
  });

  group('Later tab', () {
    Future<void> openLater(WidgetTester tester) async {
      await open(tester);
      await tester.tap(find.widgetWithText(Tab, 'Later'));
      await tester.pumpAndSettle();
    }

    testWidgets('lists the anime without a start date', (tester) async {
      repo.undated = [_anime(11), _anime(12)];

      await openLater(tester);

      final ids = tester
          .widgetList<AnimeCard>(find.byType(AnimeCard))
          .map((c) => c.anime.id)
          .toList();
      expect(ids, [11, 12]);
    });

    testWidgets('does not depend on the selected year', (tester) async {
      repo.undated = [_anime(11)];
      await open(tester);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(Tab, 'Later'));
      await tester.pumpAndSettle();

      expect(find.byType(AnimeCard), findsOneWidget);
      expect(repo.undatedCalls, 1);
      expect(
        repo.calls.where(
          (c) => c.season == Season.winter && c.year == year + 1,
        ),
        isEmpty,
      );
    });

    testWidgets('says so when there are none', (tester) async {
      await openLater(tester);

      expect(find.text('No anime without a start date'), findsOneWidget);
    });

    testWidgets('a failure shows an error and Retry reloads', (tester) async {
      repo.undatedFails = true;
      await openLater(tester);
      expect(find.text('Failed to load upcoming anime'), findsOneWidget);

      repo
        ..undatedFails = false
        ..undated = [_anime(11)];
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.byType(AnimeCard), findsOneWidget);
      expect(find.text('Failed to load upcoming anime'), findsNothing);
    });
  });
}
