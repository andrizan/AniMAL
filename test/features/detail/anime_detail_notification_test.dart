import 'package:animal/core/notification/anime_notification_service.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/models/anilist/anilist_models.dart';
import 'package:animal/data/models/anime_detail.dart';
import 'package:animal/features/detail/presentation/screens/anime_detail_page.dart';
import 'package:animal/shared/providers/anilist_providers.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _FakeNotificationService extends Fake
    implements AnimeNotificationService {
  _FakeNotificationService(this.result);

  final ScheduleResult result;
  final ids = <int>{};

  @override
  bool get permissionGranted => true;

  @override
  Set<int> get notificationIds => Set.unmodifiable(ids);

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<ScheduleResult> scheduleAnimeNotification({
    required int animeId,
    required String title,
    required int episode,
    required DateTime airingAt,
  }) async {
    if (result == ScheduleResult.scheduled) ids.add(animeId);
    return result;
  }

  @override
  Future<void> cancelNotification(int animeId) async => ids.remove(animeId);

  @override
  Future<bool> isNotificationScheduled(int animeId) async =>
      ids.contains(animeId);
}

List<Override> _overrides(ScheduleResult result) => [
  notificationServiceProvider.overrideWithValue(
    _FakeNotificationService(result),
  ),
  animeDetailProvider(1)
      .overrideWith((ref) async => const AnimeDetail(id: 1, title: 'Anime 1')),
  anilistAnimeExtraProvider(1).overrideWith(
    (ref) async => AniListAnimeExtra(
      nextAiring: AniListNextAiring(
        airingAt: DateTime.now().add(const Duration(minutes: 5)),
        episode: 5,
        timeUntilAiring: 300,
      ),
    ),
  ),
];

void main() {
  testWidgets('a too-late schedule is not reported as "disabled"', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(ScheduleResult.tooLate),
        child: const MaterialApp(home: AnimeDetailPage(animeId: 1)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_none));
    await tester.pumpAndSettle();

    expect(find.text('Notification disabled'), findsNothing);
    expect(find.textContaining('Too late to schedule'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
  });

  testWidgets('enabling then disabling reports each change', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(ScheduleResult.scheduled),
        child: const MaterialApp(home: AnimeDetailPage(animeId: 1)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_none));
    await tester.pumpAndSettle();
    expect(find.text('Notification enabled for Episode 5'), findsOneWidget);

    ScaffoldMessenger.of(tester.element(find.byType(AnimeDetailPage)))
        .clearSnackBars();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_active));
    await tester.pumpAndSettle();
    expect(find.text('Notification disabled'), findsOneWidget);
  });

  testWidgets('a snackbar from the previous page does not follow to the next '
      'anime page', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(ScheduleResult.scheduled),
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification disabled'),
                      duration: Duration(seconds: 30),
                    ),
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AnimeDetailPage(animeId: 1),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(AnimeDetailPage), findsOneWidget);
    expect(find.text('Notification disabled'), findsNothing);
  });
}
