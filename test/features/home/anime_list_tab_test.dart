import 'dart:async';

import 'package:animal/core/notification/anime_notification_service.dart';
import 'package:animal/core/providers.dart';
import 'package:animal/data/models/anime.dart';
import 'package:animal/data/models/watch_status.dart';
import 'package:animal/features/home/presentation/widgets/anime_list_tab.dart';
import 'package:animal/shared/providers/airing_entry.dart';
import 'package:animal/shared/providers/anime_providers.dart';
import 'package:animal/shared/widgets/anime_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Repo extends Fake implements AnimeRepository {
  Object? failure;
  List<Anime> items = const [];
  int loads = 0;

  @override
  Future<List<Anime>> getUserAnimeList({
    WatchStatus status = WatchStatus.watching,
  }) async {
    loads++;
    final error = failure;
    if (error != null) throw error;
    return items;
  }
}

class _Notifications extends Fake implements AnimeNotificationService {
  @override
  bool get permissionGranted => true;

  @override
  Set<int> get notificationIds => const {};
}

void main() {
  late _Repo repo;

  Future<void> open(
    WidgetTester tester, {
    WatchStatus status = WatchStatus.watching,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: noProviderRetry,
        overrides: [
          notificationServiceProvider.overrideWithValue(_Notifications()),
          airingByMalIdProvider.overrideWith((ref) async => {}),
          animeRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: Scaffold(body: AnimeListTab(status: status)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => repo = _Repo());

  testWidgets('shows a card per anime', (tester) async {
    repo.items = [for (var i = 1; i <= 3; i++) Anime(id: i, title: 'Anime $i')];

    await open(tester);

    expect(find.byType(AnimeCard), findsNWidgets(3));
  });

  testWidgets('an empty list says so', (tester) async {
    await open(tester);

    expect(find.text('No anime here yet'), findsOneWidget);
    expect(find.byType(AnimeCard), findsNothing);
  });

  group('when loading fails', () {
    testWidgets('names the list that failed', (tester) async {
      repo.failure = Exception('offline');

      await open(tester, status: WatchStatus.planToWatch);

      expect(find.text('Failed to load plan to watch list'), findsOneWidget);
    });

    testWidgets('Retry fetches the list again and shows it', (tester) async {
      repo.failure = Exception('offline');
      await open(tester);
      expect(repo.loads, 1);

      repo.failure = null;
      repo.items = [const Anime(id: 1, title: 'Back online')];
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repo.loads, 2);
      expect(find.byType(AnimeCard), findsOneWidget);
      expect(find.text('Failed to load watching list'), findsNothing);
    });

    testWidgets('keeps showing the error when the retry fails again', (
      tester,
    ) async {
      repo.failure = Exception('offline');
      await open(tester);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repo.loads, 2);
      expect(find.text('Failed to load watching list'), findsOneWidget);
    });
  });
}
